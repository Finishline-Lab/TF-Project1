# AWS infrastrucure provisioning with Terraform
This  Terraform code will create a VCP with Internet Gateway, private and public subnets two each accross 2 Avialability zones in AWS  using
and terraform and also deploy the following resources:

- A bastion/jumpbox host into the public subnet in Avialability Zone a and a second instance called node in the private subnet in Availability Zone b, 
 which can connect to the internet via a NAT gateway created as part of the VPC.

- An SSH key pair which will be dynamically generated as well and the private key copied over to the bastion/jumpbox host.

- Two security groups, one allowing access via port 22 eternally and the other allowing traffic via port 22 only from within the VPC subnets.
  The The bastion/jumbox host  in the public subnet is assigned to the security group with external or internet access via port 22 for ssh and the node instance in the private 
  subnet is assigned to the security group that only allows ssh access from the VPC public subnet hosting the bastion/jumpbox host. 


## Modules
For simplicity purposes I've broken down this deployment into three separate modules describe below:

- ## ssh-key: 
  Generates an ssh key pair to be use to access the instances created by ec2 module

- ## network: 
  Creates a VPC with IGWs, NAT GWs,RT, 2 public and 2 private subnets each in a different Availability Zone, Security Groups to SSH to bastion/jumpbox host from the internet and within the VPC.
  
  **NB in this module I've referenced terraform-AWS VPC moudle from Terraform registry to facility the creations of RT and other netwok configs** 

- ## ec2: 
  This module creates two Amazon Linux2 t2.micro instances, one called jumbox in the public subnet and the other called node in private subnet
  The private key generated by the ssh-key module  is copied over to the jumbox which is then use to access the node instance in the private subnet via ssh

  Note that the node instance in private subnet can reach the internet or external networks though the NAT gateway making it easy to ping or curl google.com

## Provider

The provider used in this case is AWS with more detail found in **provider.tf** located in  the project's root

## Requirements.
A part of the requirement yo will need to install terraform **1.2.6 (currently latest)**. If you do not have Terraform installed please go to https://www.terraform.io/downloads for help to do so.
You will also need an AWS Access and Secret keys with Admin privileges for programatic access

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
|** namespace** | The project namespace to use for unique resource naming | `string` | `"allamerica-challenge"` | **no** |
| **region** | AWS region | `string` | `"us-east-1"` | **no** |
| **acces_key** | AWS Access Key | `string` | `"enter your aws access key here"` | **yes** |
| **secret_key** | AWS Secret Key | `string` | `"enter your aws secret key here"` | **yes** |

Please not that these inputs are located in **variables.tf** found in the root directory of this project


## Outputs

| Name | Description |
|------|-------------|
| **public\_connection\_string** | SSH connection strings to access jumpbox |
| **private\_connection\_string** | SSH connection string to access private instance also called node |


## Accessing node/instance in private network via SSH

A ssh keypair will be created at the root directory of this project and once terraform is done provisioning the above infrastrucure it will output two paramters:
- SSH connection string to access the jumpbox from the internet as shown in **public\_connection\_string** from Outputs above.
- SSH connection string to access the node (Instance in private subnet) from jumbox within the VPC as shown in **private\_connection\_string** from Outputs Section above

Since the node instance is in a private subnet with a private IP not accessible from the internet you must first SSH into the jumpbox via port 22 using the ssh keypair in the project's home directory  connecting to the node instance via ssh on port 22.

Note that during provisioning the private ssh key is copied to the jumpbox precisely in the ec2-user home directory. From this location you can access the node instance
using the ssh private connection string from Terraform's Outputs. Once in the node instance located in the private subnet and with the help of the NAT Gateway
you can access the internet or try the following commands **ping google.com** or **curl google.com** or **wget google.com** to test internet connectivity
