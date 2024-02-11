provider "aws" {
    region = "us-west-1"
}

variable "public_key" {
    description = "Public key that is copied to EC2 instances"
}

data "aws_ami" "ubuntu" {
    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20231207"]
    }
}

output "ubuntu_server_1_public_ip" {
    value = aws_instance.ubuntu_server_1.public_ip
}

output "ubuntu_server_2_public_ip" {
    value = aws_instance.ubuntu_server_2.public_ip
}

output "ubuntu_server_3_public_ip" {
    value = aws_instance.ubuntu_server_3.public_ip
}

resource "aws_key_pair" "this" {
    public_key = var.public_key
}

resource "aws_instance" "ubuntu_server_1" {
    ami = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.ssh_access.id]
    key_name = aws_key_pair.this.key_name

    tags = {
        Name = "Ubuntu Server 1"
    }
}

resource "aws_instance" "ubuntu_server_2" {
    ami = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.ssh_access.id]
    key_name = aws_key_pair.this.key_name

    tags = {
        Name = "Ubuntu Server 2"
    }
}

resource "aws_instance" "ubuntu_server_3" {
    ami = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.ssh_access.id]
    key_name = aws_key_pair.this.key_name

    tags = {
        Name = "Ubuntu Server 3"
    }
}

resource "aws_security_group" "ssh_access" {
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
} 