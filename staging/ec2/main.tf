# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}
# Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-internet-gateway"
  }
}
# Create a Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}
# Create Subnets
resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "subnet-a"
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "subnet-b"
  }
}
# Associate Route Table with Subnets
resource "aws_route_table_association" "subnet_a_association" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "subnet_b_association" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.main.id
}





module "web-server" {
  source = "../../modules/ec2"
  
  ami                    = "ami-005fc0f236362e99f"
  instance_type          = "t2.micro"
  tag_name               = "web-server"
  instance_min_count     = 2
  instance_max_count     = 3
  cluster_name           = "web-server"
  key_pair               = "fachripair"
  asg_availability_zones = ["us-east-1a", "us-east-1b"]
  elb_availability_zones = ["us-east-1a", "us-east-1b"]
  vpc_id                 = aws_vpc.main.id
  subnets                = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
  environment            = "staging"
}