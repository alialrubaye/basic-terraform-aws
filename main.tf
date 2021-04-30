provider "aws" {
    region = "us-east-1"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable instance_type{}
variable my_public_key_location{}
resource "aws_vpc" "myapp-vpc" {

    cidr_block = var.vpc_cidr_block
    tags = {
      Name: "${var.env_prefix}-vpc"
    }  
}

resource "aws_subnet" "myapp-public-subnet" {

    vpc_id = aws_vpc.myapp-vpc.id 
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
      Name : "${var.env_prefix}-public-subnet"
    }
  
}

resource "aws_route_table" "myapp-subnet-rt" {
  vpc_id = aws_vpc.myapp-vpc.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.myapp-vpc-igw.id
  }  

  tags = {
      Name = "${var.env_prefix}-myapp-vpc-suhbnet-rt"
  }    
}

resource "aws_internet_gateway" "myapp-vpc-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags =  {
      Name = "${var.env_prefix}-myapp-vpc-igw"
  } 
}

resource "aws_route_table_association" "myapp-rt-ass" {
  
  subnet_id = aws_subnet.myapp-public-subnet.id 
  route_table_id = aws_route_table.myapp-subnet-rt.id 
}


resource "aws_security_group" "myapp-sg" {
 
    vpc_id      = aws_vpc.myapp-vpc.id

  ingress {
    description      = "HTTP"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]    
  }

  tags = {
    Name = "${var.env_prefix}-myapp-sg"
  }
}



data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
} 
}

output "aws_ami_id" {
    value = data.aws_ami.latest-amazon-linux-image
}


resource "aws_key_pair" "myapp-instance-pem-key" {

  key_name = "server-linux-key"
  public_key = file(var.my_public_key_location)

}



resource "aws_instance" "myapp" {
  ami           = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type
  
  subnet_id = aws_subnet.myapp-public-subnet.id 
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  availability_zone = var.avail_zone
  associate_public_ip_address = true
  key_name = aws_key_pair.myapp-instance-pem-key.key_name
  tags = {
    Name = "${var.env_prefix}-myapp-instance"
  }
}