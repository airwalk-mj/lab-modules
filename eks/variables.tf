#vpc_name                   = "lab-vpc"
#instance_type              = "t2.large"
#max_size                   = "1"
#min_size                   = "1"
#desired_capacity           = "1"
#max_size_on_demand         = "1"
#min_size_on_demand         = "1
#desired_capacity_on_demand = "1"
#spot_price                 = "0.38"
#root_volume_type           = "standard"
#root_volume_size           = "32"
#cluster_version            = "1.16"
#env                        = "dev"
#region                     = "eu-west-2"
#key_pair                   = "dev"
#resource_name              = "eks-lab"


variable "region" {
  default = "eu-west-2"
}
