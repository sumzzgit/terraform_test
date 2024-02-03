//create the vpc
resource "aws_vpc" "vpc" {
  #   provider   = aws.west
  cidr_block = var.vpc_cidr_block
  tags       = var.vpc_tags
}

//provision the internet gateway 
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "vpc-5-IGW"
  }
}

//create the public rt
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }
}

//create the private rt
resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = var.vpc_cidr_block
    gateway_id = "local"
  }
  route {
    network_interface_id = aws_instance.nat-instance.primary_network_interface_id
    cidr_block           = "0.0.0.0/0"
  }
  depends_on = [aws_route_table.private-rt, aws_instance.nat-instance]
}

//create the subnets
resource "aws_subnet" "subnets" {
  for_each                = var.subnets_info
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = each.value.az
  cidr_block              = each.value.cidr_block
  tags                    = each.value.tags
  map_public_ip_on_launch = each.value.map_public_ip_on_launch

}

locals {
  #   private_subntes_id = toset([ aws_subnet.subnets["pri-sub-1"].id , aws_subnet.subnets["pri-sub-2"].id ])
  #   public_subnets_id = toset([ aws_subnet.subnets["pub-sub-1"].id , aws_subnet.subnets["pub-sub-2"].id ])
  private_subntes_ids = {
    first  = aws_subnet.subnets["pri-sub-1"].id
    second = aws_subnet.subnets["pri-sub-2"].id
    third  = aws_subnet.subnets["pri-sub-3"].id
    fourth = aws_subnet.subnets["pri-sub-4"].id
  }
  public_subnets_ids = {
    first  = aws_subnet.subnets["pub-sub-1"].id
    second = aws_subnet.subnets["pub-sub-2"].id
  }
}

//public rt association
resource "aws_route_table_association" "public-rt-association-1" {
  depends_on     = [aws_subnet.subnets]
  for_each       = local.public_subnets_ids
  subnet_id      = each.value
  route_table_id = aws_route_table.public-rt.id
}

//private rt association
resource "aws_route_table_association" "private-rt-association-1" {
  depends_on     = [aws_subnet.subnets]
  for_each       = local.private_subntes_ids
  subnet_id      = each.value
  route_table_id = aws_route_table.private-rt.id
}

//create the subnet group to launch the RDS
resource "aws_db_subnet_group" "rds-subnet-group" {
  name       = "rds-db-pri-sub-grp"
  subnet_ids = [aws_subnet.subnets["pri-sub-3"].id, aws_subnet.subnets["pri-sub-4"].id]
  tags = {
    Name      = "rds-db-pri-sub-grp"
    provision = "terraform"
  }
}

//create the rds security group
resource "aws_security_group" "rds-sg" {
  name   = "rds-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "allow port 3306 for rds"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "rds-sg"
    provision = "terraform"
  }
}

//create an rds instance 
resource "aws_db_instance" "rds_mysql" {
  allocated_storage    = 10
  db_name              = "mysqldb"
  db_subnet_group_name = "rds-db-pri-sub-grp"
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  multi_az             = false
  password             = var.db_pass_test
  tags = {
    Name      = "mysql-rds"
    provision = "terraform"
  }
  username               = "admin"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds-sg.id]
  # lifecycle {
  #   create_before_destroy = true
  # }
}

//defining the locals to use the attribute reference as the varibles in template
locals {
  db_host    = aws_db_instance.rds_mysql.address
  db_name    = var.db_name
  db_pass    = var.db_pass_test
  nginx_path = var.nginx_path
  db_user    = aws_db_instance.rds_mysql.username
}

//create the public security group
resource "aws_security_group" "pub-sg-1" {
  description = "allow all incoming traffic"
  name        = "pub-sg-1"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name      = "pub-sg-1"
    provision = "terraform"
  }
}

//create the private security group
resource "aws_security_group" "pri-sg-1" {
  description = "allow all incoming traffic only from vpc cidr range"
  name        = "pri-sg-1"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name      = "pri-sg-1"
    provision = "terraform"
  }
}

//launch the nat gateway instance
//installing the ansible in nat instance and sending the files to private instance using ansible
resource "aws_instance" "nat-instance" {
  ami                         = "ami-0a493f6d8c0886281" //community ami for the nat instance 
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  key_name                    = "my-key"
  subnet_id                   = aws_subnet.subnets["pub-sub-1"].id
  source_dest_check           = false //this is importatnt for the NAT instance
  vpc_security_group_ids      = [aws_security_group.pub-sg-1.id]
  depends_on                  = [aws_instance.ec2-instance]
  tags = {
    Name      = "Nat-instance"
    provision = "terraform"
  }


}

//adding the route in the private route table
# resource "aws_route" "NAT-route" {
#   route_table_id         = aws_route_table.private-rt.id
#   destination_cidr_block = "0.0.0.0/0"
#   network_interface_id   = aws_instance.nat-instance.primary_network_interface_id
#   depends_on             = [aws_route_table.private-rt, aws_instance.nat-instance]
# }

//launch the public instance to install install ansible
resource "aws_instance" "bastion-host" {
  ami                         = "ami-0a0f1259dd1c90938"
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  key_name                    = "my-key"
  subnet_id                   = aws_subnet.subnets["pub-sub-1"].id
  vpc_security_group_ids      = [aws_security_group.pub-sg-1.id]
  depends_on                  = [aws_instance.ec2-instance]
  tags = {
    Name      = "bastion-host-test"
    provision = "terraform"
  }

  # provisioner "file" {
  #   source      = "${path.module}/launch_template.sh"
  #   destination = "/home/ec2-user/launch_template.sh"
  # }
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("C:/Users/Minfy/Downloads/my-key.pem")
    host        = self.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y ansible",
      # "touch /home/ec2-user/exports.sh" ,
      # "touch /home/ec2-user/my-key.pem" ,
      # "sudo touch /etc/ansible/hosts"
    ]

  }

  provisioner "file" {
    # source      = templatefile("${path.module}/env_vars.tpl", { db_host = local.db_host, db_name = local.db_name, db_pass = local.db_pass, nginx_path = local.nginx_path, db_user = local.db_user })
    content     = templatefile("${path.module}/launch_template_final.tpl", { db_host = local.db_host, db_name = local.db_name, db_pass = local.db_pass, db_user = local.db_user, nginx_path = local.nginx_path })
    destination = "/home/ec2-user/launch_template.sh"
  }

  provisioner "file" {
    # source      = "${path.module}/../Users/Minfy/Downloads/my-key.pem"
    source      = "C:/Users/Minfy/Downloads/my-key.pem"
    destination = "/home/ec2-user/my-key.pem"
  }

  provisioner "file" {
    content = templatefile("${path.module}/inventory.tpl", {
      input_list = local.ec2-ips
    })
    destination = "/home/ec2-user/hosts"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 400 /home/ec2-user/my-key.pem",
      "sudo cp /home/ec2-user/hosts /etc/ansible/hosts",
      "export ANSIBLE_HOST_KEY_CHECKING=False", //this will automate the ssh respose as yes for first time connecting to hosts
      # "ansible all -m copy -a 'src=/home/ec2-user/exports.sh dest=/home/ec2-user/exports.sh mode=777' ",
      "ansible all -m copy -a 'src=/home/ec2-user/launch_template.sh dest=/home/ec2-user/launch_template.sh mode=777'",
      "ansible all -m shell -a 'sh /home/ec2-user/launch_template.sh' -b"
    ]

  }

}

//launch an two ec2 instance in the private subnet
# resource "aws_instance" "ec2-instance-1"{
#   ami = "ami-0a0f1259dd1c90938"
#   associate_public_ip_address = true
#   instance_type = "t2.micro"
#   key_name = "my-key"
#   subnet_id = aws_subnet.subnets["pri-sub-1"].id
#   vpc_security_group_ids = [ aws_security_group.pri-sg-1.id ]
#   tags = {
#     Name = "bookstore-1"
#     provision = "terraform"
#   }
# }

#create locals to use for_each to launch the two instance
locals {
  subnet_ids = {
    first  = aws_subnet.subnets["pri-sub-1"].id
    second = aws_subnet.subnets["pri-sub-2"].id
  }
}

resource "aws_instance" "ec2-instance" {
  for_each                    = local.subnet_ids
  ami                         = "ami-0a0f1259dd1c90938"
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  key_name                    = "my-key"
  subnet_id                   = each.value
  vpc_security_group_ids      = [aws_security_group.pri-sg-1.id]
  tags = {
    Name      = "bookstore-${each.key}"
    provision = "terraform"
  }

}


locals {
  depends_on = [aws_instance.ec2-instance]
  # ec2-ips = values(aws_instance.ec2-instance[*].public_ip) // values takes a map and returns a list containing the values of the elements in that map.
  ec2-ips = ["${aws_instance.ec2-instance["first"].private_ip}", "${aws_instance.ec2-instance["second"].private_ip}"]
}

# locals {
#   # ec2-ids = values(aws_instance.ec2-instance[*].id)
#    ec2-ids = aws_instance.ec2-instance[*].id
#   # ec2-ids =tolist([ "${aws_instance.ec2-instance["first"].id}" , "${aws_instance.ec2-instance["second"].id}" ])
# }
//create the target group
resource "aws_lb_target_group" "ec2-target-grp" {
  name     = "bookstore-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
  health_check {
    path = "/"
    port = 80
  }
  tags = {
    Name      = "bookstore-tg"
    provision = "terraform"
  }
}

//create the target group attachment to register ec2 instances
resource "aws_lb_target_group_attachment" "ec2-target-grp-attachment-1" {
  target_group_arn = aws_lb_target_group.ec2-target-grp.arn
  # for_each = local.ec2-ids
  target_id = aws_instance.ec2-instance["first"].id
  port      = 80
}

resource "aws_lb_target_group_attachment" "ec2-target-grp-attachment-2" {
  target_group_arn = aws_lb_target_group.ec2-target-grp.arn
  # for_each = local.ec2-ids
  target_id = aws_instance.ec2-instance["second"].id
  port      = 80
}

//create the security group for the load balancer
resource "aws_security_group" "lb-sg" {
  description = "allow all incoming traffic on port 80"
  name        = "lb-sg-1"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name      = "lb-sg-1"
    provision = "terraform"
  }
}

//create the listener for lb and you can also create the listener rule also
resource "aws_lb_listener" "primary-listener" {
  load_balancer_arn = aws_lb.ALB-1.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2-target-grp.arn
  }

}

//create the ALB
resource "aws_lb" "ALB-1" {
  name               = "bookstore-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb-sg.id]
  subnets            = [for k, v in local.public_subnets_ids : v]
  tags = {
    Name      = "bookstore-ALB-1"
    provision = "terraform"
  }
}

# output "test-ec2-ids" {
#   value = aws_instance.ec2-instance["first"].id
# }

