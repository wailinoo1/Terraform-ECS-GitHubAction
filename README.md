# Terraform-ECS-GitHubAction

<h2>Project Overview</h2>
<p>The project aimed to design and implement a scalable and resilient AWS infrastructure using Terraform for hosting containerized applications deployed with ECS Fargate. The infrastructure included network components, ECS clusters, and CI/CD automation using GitHub Actions.</p>

![CHEESE](images/ecs.jpg)

<h2>Pre-requisites</h2>
<p><b>Credentials:</b> Need AWS Configure
<p><b>S3 Bucket:</b> You need to have a S3 Bucket to store Terraform State Files</p>

<h2>Module Structure</h2>

![CHEESE](images/structure.jpg)

<h2>Terraform Command</h2>

```terraform
For Terraform Root Module:

terraform init
terraform validate
terraform plan
terraform apply --auto-approve
```
<h2>Network Module</h2>
<p>The Network module was responsible for creating the foundational components of the architecture within the VPC. This included defining the VPC itself, along with the associated subnets, route tables, and Internet Gateway. Two public subnets were designated for the ALB and one for NAT Gateway, while two private subnets were established across different availability zones to host the Auto Scaling Group with Desired 2 EC2 Instances.</p>

```terraform
module "network" {
  source = "./Network"
  vpc_cidr_block   = "10.200.0.0/16"
  vpcname = "wlo-terraform-vpc"
  subnet-name = "terraform-subnet"
  wlo-terraform-igw-name = "wlo-terraform-igw"
  natgw-name = "terraform-nat-gw"
  publicrtname = "public-subnet-routetable"
  privatertname = "private-subnet-routetable"
}
```
<p>In this module , I've used Terraform Function <b>cidrsubnet</b> for subnets.This function will generate subnetes with "10.200.0.0/24", "10.200.1.0/24", "10.200.2.0/24", "10.200.3.0/24".</p>
<p>You can play subnet ranges as you wish for least subnet ranges</p>

```terraform
locals {
  subnet = cidrsubnets(var.vpc_cidr_block,8,8,8,8)
}
```
<h2>Load Balancer Module</h2>
<p>The Load Balancer module was responsible for setting up the Application Load Balancer (ALB) to evenly distribute incoming traffic across ECS Containers. This component defined the ALB listeners, target groups, and health checks to ensure efficient routing of requests to healthy instances.And aslso Secured Connection with AWS Certificate Manager.</p>

```terraform
module "LoadBalancer" {
  source = "./LoadBalancer"
  public-subnetid = module.network.public-subnetid
  alb-name = "terraform-ecs-alb"
  ecs_sg_name = "terraform-ecs-sg"
  ecs-alblogs3 = "terraform-ecs-alb-log-wlo"
  vpcid = module.network.vpcid
  ecs_tgb_name = "ecs-tgb-terraform"
}
```
<h2>ECS Module</h2>

<h2>Terraform State Management</h2>
<p>We are using S3 Bucket to store Terraform state files for the purpose of collaboration, version control, and consistency across teams by providing a centralized location for storing and sharing infrastructure state. This prevents conflicts and enables concurrent modifications to infrastructure as code while maintaining integrity and facilitating rollbacks when necessary.</p>

```terraform
terraform {
  backend "s3" {
    bucket         = "your S3 Bucket name to store state file"
    key            = "terraform.tfstate"  # Replace with a unique key for each configuration
    region         = "ap-southeast-1"
    encrypt        = true
    acl            = "private"
    #dynamodb_table = "terraform-lock"  # Optional: Use DynamoDB for state locking
  }
}
```

<h2>Conclusion</h2>
