vpc_cidr_block = "10.5.0.0/16"
vpc_tags = {
  Name      = "vpc-5"
  provision = "terraform"
}

subnets_info = {
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
  pri-sub-3 = {
    az         = "ap-south-1a"
    cidr_block = "10.5.3.0/24"
    tags = {
      Name      = "pri-sub-3"
      provision = "terraform"
    }
    map_public_ip_on_launch = false
  }
  pri-sub-4 = {
    az         = "ap-south-1b"
    cidr_block = "10.5.4.0/24"
    tags = {
      Name      = "pri-sub-4"
      provision = "terraform"
    }
    map_public_ip_on_launch = false
  }
}

db_pass_test = "sumit360"

# ec2-launch-info = {
#     ec2-1 = {
#       subnet_id = aws_subnet.subnets["pri-sub-1"].id
#       tags = {
#         Name = "bookstore-1"
#         provision = "terraform"
#       }
#     }
#     ec2-2 = {
#       subnet_id = aws_subnet.subnets["pri-sub-2"].id
#       tags = {
#         Name = "bookstore-2"
#         provision = "terraform"
#       }
#     }
# }