provider "aws" {

  region = "us-east-1"

}

resource "aws_vpc" "devops_vpc" {
    cidr_block = "25.0.0.0/24"
    tags = {
        Name = "DEVOPS"
    }

}

resource "aws_subnet" "devops_public_subnet" {
    vpc_id = aws_vpc.devops_vpc.id
    cidr_block = "25.0.0.0/26"

    tags = {
        Name = "DEVOPS-subnet"
    }
}

resource "aws_internet_gateway" "devops-igw" {
    vpc_id = aws_vpc.devops_vpc.id

    tags = {
        Name = "DEVOPS-IGW"
    }
}

resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.devops_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devops-igw.id
  }

  tags = {
    Name = "Devops-Public-Route-Table"
  }
}

resource "aws_route_table_association" "public_subnet_rt_a" {
  subnet_id      = aws_subnet.devops_public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "devops_sg" {
  name   = "HTTP and SSH"
  vpc_id = aws_vpc.devops_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "devops-server" {

  instance_type = "t3.micro"
  ami           = "ami-0c02fb55956c7d316"
  subnet_id = aws_subnet.devops_public_subnet.id
  vpc_security_group_ids = [aws_security_group.devops_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "EC2-instance"
  }
  provisioner "local-exec" {
    command = <<EOT
      echo "[devops-server]" > inventory
      echo "${aws_instance.devops-server.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa" >> inventory
      ansible-playbook -i inventory playbook.yml
    EOT
  }

}

output "internet_gateway_id" {
  value = aws_internet_gateway.devops-igw.id
}

output "route_table_id" {
  value = aws_route_table.public_rt.id
}

output "security_group_id" {
  value = aws_security_group.devops_sg.id
}

output "instance_id" {
  value = aws_instance.devops-server.id
}

output "instance_public_ip" {
  value = aws_instance.devops-server.public_ip
}
