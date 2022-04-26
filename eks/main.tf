terraform {
  required_version = ">= 0.12.0"
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
    #kubernetes = {
    #  version = ">= 2.10"
    #}
  }
}

provider "aws" {
  region  = var.region
}

#provider "kubernetes" {
#  host                   = data.aws_eks_cluster.cluster.endpoint
#  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
#  token                  = data.aws_eks_cluster_auth.cluster.token
#  #load_config_file       = false
#}

data "aws_availability_zones" "available" {
}

locals {
  #cluster_name = "test-eks-${random_string.suffix.result}"
  cluster_name = "eks-lab"
  cluster_version = "1.21"
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
  version = "2.6.0"

  name                 = "eks-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
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

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name    = local.cluster_name
  cluster_version = "1.21"
  #subnets         = module.vpc.private_subnets
  subnet_ids         = module.vpc.private_subnets

  cluster_encryption_config = [
    {
      provider_key_arn = "arn:aws:kms:eu-west-2:544294979223:key/9f1bd709-ba1b-40ae-a04e-d3ff4850e88d"
      resources        = ["secrets"]
    }
  ]

  #tags = {
  #  GithubRepo  = "terraform-aws-eks"
  #  Environment = local.environment
  #  GithubOrg   = "terraform-aws-modules"
  #}

  vpc_id = module.vpc.vpc_id

  #worker_groups = [
  #  {
  #    name                          = "worker-group-1"
  #    instance_type                 = "t2.xlarge"
  #    additional_userdata           = "echo Mark James"
  #    asg_desired_capacity          = 1
  #    additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
  #  },
  #]

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    disk_size      = 50
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  }

  eks_managed_node_groups = {
    blue = {}
    green = {
      min_size     = 1
      max_size     = 1
      desired_size = 1

      instance_types = ["m5.large"]
      #capacity_type  = "SPOT"
    }
  }
}
