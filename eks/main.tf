terraform {
  required_version = ">= 0.12.0"
}

provider "aws" {
  version = ">= 3.4"
  region  = var.aws_region
}

provider "random" {
  version = "~> 2.3"
}

provider "local" {
  version = "~> 1.4"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.13"
}

data "aws_availability_zones" "available" {
}

locals {
  #cluster_name = "test-eks-${random_string.suffix.result}"
  cluster_name = "eks-lab"
  cluster_version = "1.16"
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

  name                 = "test-vpc"
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

module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = local.cluster_name
  subnets      = module.vpc.private_subnets

  #source           = "terraform-aws-modules/eks/aws"
  #cluster_name     = local.cluster_name
  #subnets          = data.terraform_remote_state.network.outputs.pub_sn_id
  #vpc_id           = data.terraform_remote_state.network.outputs.vpc_id
  #cluster_version  = local.cluster_version
  #tags = {
  #  Environment = local.environment_vars.locals.environment
  #}

  worker_groups = [{
    asg_desired_capacity          = var.desired_capacity
    asg_max_size                  = var.max_size
    asg_min_size                  = var.min_size
    instance_type                 = var.instance_type
    spot_price                    = var.spot_price
    root_volume_size              = var.root_volume_size
    root_volume_type              = var.root_volume_type
    key_name                      = var.key_pair
    ebs_optimized                 = true
    public_ip                     = false
    autoscaling_enabled           = true
    protect_from_scale_in         = true
    subnets = data.terraform_remote_state.network.outputs.priv_sn_id
    }]
  }

  worker_groups = [{
      name                          = "worker-group-1"
      instance_type                 = "t2.medium"
      additional_userdata           = "echo hello"
      asg_desired_capacity          = 1
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
    },
    #{
    #  name                          = "worker-group-2"
    #  instance_type                 = "t2.medium"
    #  additional_userdata           = "echo foo bar"
    #  additional_security_group_ids = [aws_security_group.worker_group_mgmt_two.id]
    #  asg_desired_capacity          = 1
    #},
  ]

  worker_additional_security_group_ids = [aws_security_group.all_worker_mgmt.id]
  map_roles                            = var.map_roles
  map_users                            = var.map_users
  map_accounts                         = var.map_accounts
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}