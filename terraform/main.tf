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

module "LoadBalancer" {
  source = "./LoadBalancer"
  public-subnetid = module.network.public-subnetid
  alb-name = "terraform-ecs-alb"
  ecs_sg_name = "terraform-ecs-sg"
  ecs-alblogs3 = "terraform-ecs-alb-log-wlo"
  vpcid = module.network.vpcid
  ecs_tgb_name = "ecs-tgb-terraform"
}

module "ecs" {
  source = "./ECS"
  family_name = "terraform_node_task_definition"
  cpu = 1024
  memory = 2048
  container_name = "terraform_node"
  container_port = 8080
  image = "Your Image URL from ECR"
  os = "LINUX"
  osarchitecture = "X86_64"
  task_role_arn = "arn:aws:iam::accountID:role/ecsTaskExecutionRole"
  ecs_cluster_name = "terraform_ecs"
  subnetid = module.network.subnetid
  vpcid = module.network.vpcid
  ecs_tgb_name = "ecs-tgb"
  tgb_ecs_arn = module.LoadBalancer.tgb_ecs_arn
  ecs_sg_id = module.LoadBalancer.ecs_sg_id
}
