
locals {
  region = "${var.region}"
}  

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name                             = "${var.namespace}-vpc"
  cidr                             = "192.168.0.0/16"
  azs                              = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets                  = ["192.168.0.0/24", "192.168.1.0/24", "192.168.2.0/24"]
  public_subnets                   = ["192.168.3.0/24", "192.168.4.0/24", "192.168.5.0/24"]
  database_subnets                 = ["192.168.6.0/24", "192.168.7.0/24", "192.168.8.0/24"]
  #assign_generated_ipv6_cidr_block = true
  create_database_subnet_group     = false
  enable_nat_gateway               = true
  single_nat_gateway               = true
}

// SG to allow SSH connections to jumpbox from outside. for security purposes replace 0.0.0.0/0 to a secured IP
resource "aws_security_group" "allow_ssh_pub" {
  name        = "${var.namespace}-jumpbox_ssh"
  description = "Allow SSH inbound traffic to Jumbbox/Bastionhost"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH from the internet/outside"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["67.85.77.85/32"]
  }

   ingress {
    description = "SSH from the internet/outside"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${JENKINS_IP}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.namespace}-jumpbox-ssh"
  }
}

// SG to allow SSH connections to web serices from outside. for security purposes replace 0.0.0.0/0 to a secured IP
resource "aws_security_group" "web_sg" {
  name        = "${var.namespace}-web_sg"
  description = "Allow web inbound traffic from the internet"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "web traffic from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh from jumpbox"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.168.5.0/24"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.namespace}-web_sg"
  }
}
// SG to allow db connections to database from private subnet. for security purposes replace 0.0.0.0/0 to a secured IP
resource "aws_security_group" "db_access" {
  name        = "${var.namespace}-db_access"
  description = "Allow database connection within private subnet"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "allow database access"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["192.168.3.0/24"]
  }

  ingress {
    description = "allow ssh access from jumpbox"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.168.5.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.namespace}-db_access_sg"
  }
}

// Security Group to only allow SSH connections from VPC private subnets
resource "aws_security_group" "allow_ssh_priv" {
  name        = "${var.namespace}-allow_ssh_priv"
  description = "Allow SSH inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH only from internal VPC clients"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.168.5.0/24"]
  }
  ingress {
    description = "connection from web_server"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.namespace}-allow_ssh_priv"
  }
}