# test-vpc

## Creating a new VPC without a module.

setup provider.tf to setup the AWS access

define variables
  vpc_cidr
  vpc_name

define subnets
  3 x public
  3 x private

define internet gateway

define routes

define security groups
  1 for EC2

define Network ACLS

create ec2 instance with userdata to install webserver on port 80 
  public ip will be needed
  needs to be setup in a public AZ

