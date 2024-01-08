
terraform {
  required_version = ">= 0.19.0"

  required_providers {
    aws = {
      version = ">= 4.11.0"    }
    null = {
      version = ">= 3.1.1"
    }
    local = {
      version = ">= 2.2.2"
    }
    random = {
      version = ">= 3.1.3"
    }
    kubernetes = {
      version = ">= 2.10"
    }
  }
}

provider "aws" {
  region  = var.region
  #region - local.region
}

# Kubernetes provider
# https://learn.hashicorp.com/terraform/kubernetes/provision-eks-cluster#optional-configure-terraform-kubernetes-provider
# To learn how to schedule deployments and services using the provider, go here: https://learn.hashicorp.com/terraform/kubernetes/deploy-nginx-kubernetes

# The Kubernetes provider is included in this file so the EKS module can complete successfully. Otherwise, it throws an error when creating `kubernetes_config_map.aws_auth`.
# You should **not** schedule deployments and services in this workspace. This keeps workspaces modular (one for provision EKS, another for scheduling Kubernetes resources) as per best practices.

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  #cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

locals {
  #cluster_name = "test-eks-${random_string.suffix.result}"
  cluster_name = "eks-lab"
  cluster_version = "1.28"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

resource "aws_security_group" "worker_group_mgmt_one" {
  name_prefix = "worker_group_mgmt_one"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }
}

resource "aws_security_group" "worker_group_mgmt_two" {
  name_prefix = "worker_group_mgmt_two"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "192.168.0.0/16",
    ]
  }
}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name                 = "eks-vpc"
  cidr                 = "10.0.0.0/16"
  #azs                  = data.aws_availability_zones.available.names
  azs                  = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}


module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "v5.1.2"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.vpc_endpoints_sg.security_group_id]

  endpoints = {
    s3 = {
      service             = "s3"
      tags                = { Name = "s3-vpc-endpoint" }
      service_type        = "Interface"
      private_dns_enabled = true
    }
  }

  tags = var.default_tags

}


data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false
  cluster_encryption_config = [
    {
      resources        = ["secrets"]
      provider_key_arn = "arn:aws:kms:" + region  + ":544294979223:key/9f1bd709-ba1b-40ae-a04e-d3ff4850e88d"
    }
  ]

  tags = {
    GithubRepo  = "terraform-aws-eks"
    Environment = local.environment
    GithubOrg   = "terraform-aws-modules"
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    disk_size      = 50
    instance_types = ["t3.medium", "t3.large"]
  }

  eks_managed_node_groups = {
    blue = {
      min_size       = 1
      max_size       = 1
      desired_size   = 1
      instance_types = ["t3.medium"]
    }
    green = {
      min_size       = 1
      max_size       = 1
      desired_size   = 1
      instance_types = ["t3.medium"]
    }
  }

  # aws-auth configmap
  manage_aws_auth_configmap = true
}

module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0" #ensure to update this to the latest/desired version

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  enable_aws_load_balancer_controller    = true
  enable_cluster_proportional_autoscaler = true
  enable_karpenter                       = true
  enable_kube_prometheus_stack           = true
  enable_metrics_server                  = true
  enable_external_dns                    = true
  enable_cert_manager                    = true
  cert_manager_route53_hosted_zone_arns  = ["arn:aws:route53:::hostedzone/Z064458838N2OGDPML4NA"]

  tags = {
    Environment = "dev"
  }
}