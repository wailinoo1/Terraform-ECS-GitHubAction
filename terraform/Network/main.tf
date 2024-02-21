resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"
  tags = {
    Name = "${var.vpcname}"                  #Naming for VPC
  }
}

resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.wlo-terraform-igw-name}"
  }
  depends_on = [ aws_vpc.main ]
}


locals {
  subnet = cidrsubnets(var.vpc_cidr_block,11,11,8,8)
}

resource "aws_subnet" "subnet" {
  count = length(local.subnet)
  vpc_id     = aws_vpc.main.id
  cidr_block = local.subnet[count.index]

  availability_zone = element(["ap-southeast-1a", "ap-southeast-1b"], count.index)
  tags = {
    Name = "${var.subnet-name}-${local.subnet[count.index]}"
  }
  depends_on = [ aws_vpc.main ]
}

resource "aws_eip" "eip" {
  domain   = "vpc"
  depends_on = [ aws_internet_gateway.internet-gateway ]
}


resource "aws_nat_gateway" "nat-gateway" {
  depends_on    = [aws_subnet.subnet]
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.subnet[0].id
  tags = {
    Name = "${var.natgw-name}"
  }
}

resource "aws_route_table" "public-subnet-routetable" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway.id
  }

  tags = {
    Name = "${var.publicrtname}"
  }
  depends_on = [ aws_vpc.main ]

}

resource "aws_route_table_association" "publicassociation" {
  count = 2
  subnet_id      = aws_subnet.subnet[count.index].id
  route_table_id = aws_route_table.public-subnet-routetable.id

  depends_on = [ aws_route_table.public-subnet-routetable ]
}

resource "aws_route_table" "private-subnet-routetable" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-gateway.id
  }

  tags = {
    Name = "${var.privatertname}"
  }
  depends_on = [ aws_vpc.main ]
}
resource "aws_route_table_association" "privateassociation" {
  count = 2
  subnet_id      = aws_subnet.subnet[count.index + 2 ].id
  route_table_id = aws_route_table.private-subnet-routetable.id

  depends_on = [ aws_route_table.private-subnet-routetable ]
}
