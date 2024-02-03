variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR Block"
  default     = "10.5.0.0/16"
}

variable "vpc_tags" {
  type        = map(string)
  description = "VPC tags"
  default = {
    Name      = "vpc-5"
    provision = "terraform"
  }
}


variable "subnets_info" {
  type = map(object({
    az                      = string
    cidr_block              = string
    tags                    = map(string)
    map_public_ip_on_launch = bool
  }))
  description = "subnets info"
  default = {
    pub-sub-1 = {
      az         = "ap-south-1a"
      cidr_block = "10.5.101.0/24"
      tags = {
        Name      = "pub-sub-1"
        provision = "terraform"
      }
      map_public_ip_on_launch = true
    }
    pub-sub-2 = {
      az         = "ap-south-1b"
      cidr_block = "10.5.102.0/24"
      tags = {
        Name      = "pub-sub-2"
        provision = "terraform"
      }
      map_public_ip_on_launch = true
    }
    pri-sub-1 = {
      az         = "ap-south-1a"
      cidr_block = "10.5.1.0/24"
      tags = {
        Name      = "pri-sub-1"
        provision = "terraform"
      }
      map_public_ip_on_launch = false
    }
    pri-sub-2 = {
      az         = "ap-south-1b"
      cidr_block = "10.5.2.0/24"
      tags = {
        Name      = "pri-sub-2"
        provision = "terraform"
      }
      map_public_ip_on_launch = false
    }
  }
}

variable "db_pass_test" {
  type        = string
  description = "rds db pass"
  default     = "sumit360"
  sensitive   = true
}

variable "db_name" {
  type        = string
  description = "db name used in the template"
  default     = "BookStore"
  sensitive   = true
}

variable "nginx_path" {
  description = "nginx path for using in the template"
  type        = string
  default     = "/usr/share/nginx/bookstore"
}

# variable "ec2-launch-info" {
#   description = "ec2 launch info to launch 2 instance using for_each"
#   type = object({
#     subnet_id = string
#     tags = map(string)
#   })
#   # default = {
#   #   ec2-1 = {
#   #     subnet_id = aws_subnet.subnets["pri-sub-1"].id
#   #     tags = {
#   #       Name = "bookstore-1"
#   #       provision = "terraform"
#   #     }
#   #   }
#   #   ec2-2 = {
#   #     subnet_id = aws_subnet.subnets["pri-sub-2"].id
#   #     tags = {
#   #       Name = "bookstore-2"
#   #       provision = "terraform"
#   #     }
#   #   }
#   # }
# }