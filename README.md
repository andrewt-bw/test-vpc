## Creating a new VPC without a module.

### Problem Statement:

You are tasked with writing terraform code to provision resources within AWS. Your goal is to create a Virtual Private Cloud (VPC) with both public and private subnets across multiple availability zones. Next provision an EC2 instance in which a hypothetical nginx running on port 80 will later be installed. You will need to ensure that this box is reachable over HTTP (port 80) by IP address.

### Requirements:

• Utilize Terraform to provision resources.
• Create a VPC with CIDR block 10.0.0.0/16.
• Create three public subnets across different availability zones within the VPC
• Create three private subnets across different availability zones within the VPC
• Ensure that instances in the public subnets have internet access, while instances in the private subnets do not have direct internet connectivity.
• Parameterize your Terraform code appropriately for reusability and flexibility.
• Ensure you have meaningful commit messages, so we can follow your thought process
• Code should contain NO comments

### Variables in london.tfvars
```region
region             = "eu-west-2"
vpc-cidr           = "10.0.0.0/16"
ami                = "ami-0e4b8d8a47a5631fc"
name               = "AndrewTest"
private-subnets    = 3
public-subnets     = 3
create_private_ec2 = false
```

### To Run

```region = "eu-west-2"
git clone git@github.com:andrewt-bw/test-vpc.git

terraform init
terraform plan -var-file=london.tfvars
terraform apply -var-file=london.tfvars
```

### Expected output is after apply

```
public_ec2_ip = "18.169.191.28"
```

### To Destroy

```
terraform destory -var-file=london.tfvars
```

