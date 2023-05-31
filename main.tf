terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.0.0"
    }

  }

  required_version = ">= 1.2.0"

}

provider "aws" {
  region = "eu-north-1"
}


resource "aws_eip" "flask_url" {
  instance = aws_instance.flask_app.id
  tags = {
    Name = "Flask_url"
  }
}


resource "aws_vpc" "terra_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "terra_vpc"
  }
}

### PUBLIC ###

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.terra_vpc.id
  tags = {
    Name = "terra-ig"
  }
}


resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.terra_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = "true" 

  tags = {
    Name = "terra-public_subnet"
  }
}


# Public routes
resource "aws_route_table" "prod-public-routes" {
  vpc_id = aws_vpc.terra_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "terra-public-routes"
  }
}

# соединяет подсеть и таблицу маршрутизации
resource "aws_route_table_association" "prod-crta-public-subnet-1" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.prod-public-routes.id
}


resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.terra_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-north-1a"
 map_public_ip_on_launch = "true" 


  tags = {
    Name = "terra-private-subnet"
  }
}


# Private routes
resource "aws_route_table" "prod-private-routes" {
    vpc_id = aws_vpc.terra_vpc.id
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
     }
    
    tags = {
        Name = "terra-private-routes"
    }
}

# соединяет подсеть и таблицу маршрутизации
resource "aws_route_table_association" "prod-crta-private-subnet-1"{
    subnet_id = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.prod-private-routes.id
}



# NAT Gateway to allow private subnet to connect out the way
resource "aws_eip" "nat_gateway" {
    vpc = true
}
resource "aws_nat_gateway" "prod-nat-gateway" {
    allocation_id = aws_eip.nat_gateway.id
    subnet_id     = aws_subnet.private_subnet.id

    tags = {
    Name = "Terra NAT"
    }

}



resource "aws_security_group" "inner_net" {
  vpc_id      = aws_vpc.terra_vpc.id
  name        = "only_inner_trafik"
  description = "only_inner_trafik"

#   ingress {
#     cidr_blocks = ["10.0.1.0/24"]
#     to_port     = 6379
#     from_port   = 6379
#     protocol    = "tcp"
#   }

#   ingress {
#     cidr_blocks = ["10.0.1.0/24"]
#     to_port     = 22
#     from_port   = 22
#     protocol    = "tcp"
#   }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 8080
    protocol    = "tcp"
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "terra-inner-sg"
  }

}

resource "aws_security_group" "open_to_world" {
  vpc_id      = aws_vpc.terra_vpc.id
  name        = "allow_all"
  description = "Allow all TCP inbound traffic"

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    to_port     = 8080
    from_port   = 8080
    protocol    = "tcp"
  }

  ingress {
    # cidr_blocks = ["79.104.4.112/32"]
    cidr_blocks = ["0.0.0.0/0"]
    to_port     = 22
    from_port   = 22
    protocol    = "tcp"
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # вроде должно позволить пересоздавать sg без удаления инстанса
  lifecycle {
    create_before_destroy = true
  }
  timeouts {
    delete = "2m"
  }
  tags = {
    Name = "terra-outer-sg"
  }

}


resource "aws_instance" "flask_app" {
  ami           = "ami-01a7573bb17a45f12"
  instance_type = "t3.micro"
  key_name      = "abra"
  user_data     = file("user_data.sh")


  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.open_to_world.id]


  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = "12"
    volume_type = "gp2"

  }
  tags = {
    Name = "terra-flask_app"
  }
}


resource "aws_instance" "redis_db" {
  ami           = "ami-01a7573bb17a45f12"
  instance_type = "t3.micro"
  key_name      = "abra"
  user_data     = file("redis.sh")
  private_ip = var.redis_private_ip

  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.inner_net.id]




  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = "12"
    volume_type = "gp2"

  }
  tags = {
    Name = "terra-redis-db"
  }
}


