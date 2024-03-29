provider "aws" {
    region = "us-west-1"
}

variable "web_server_port" {
  type        = number
  default     = 8080
  description = "Web server port number"
}

output "web_server_public_ip" {
  value       = aws_instance.web_server.public_ip
  description = "Web server public IP address"
}


data "aws_ami" "ubuntu" {
    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20231207"]
    }
}

resource "aws_instance" "web_server" {
    ami = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.web_server.id]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.web_server_port} &
                EOF

    user_data_replace_on_change = true

    tags = {
        Name = "Ubuntu Web Server"
    }
}

resource "aws_security_group" "web_server" {
    name = "ec2-web-server-sg"

    ingress {
        from_port = var.web_server_port
        to_port = var.web_server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}