# test-vpc

## Creating a new VPC without a module.

- setup provider.tf to setup the AWS access

### define variables
```region
vpc-cidr
ami
name
public_key
```

### define subnets
  3 x public
  3 x private

### define internet gateway

### define routes

### define security groups
- for EC2

### define Network ACLS

- create ec2 instance with userdata to install webserver on port 80 
-  public ip will be needed
- needs to be setup in a public AZ

## To run 

- create london.tfvars
```region = "eu-west-2"

vpc-cidr = "10.0.0.0/16"

ami = "ami-0e4b8d8a47a5631fc"

name = "AndrewTest"
```

- terraform init
- terraform plan -var-file=london.tfvars
- terraform apply -var-file=london.tfvars