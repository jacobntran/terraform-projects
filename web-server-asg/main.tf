provider "aws" {
    region = "us-west-1"
}

variable "web_server_port" {
    type = number
    description = "Port used by the web server"
    default = 8080    
}

data "aws_ami" "ubuntu" {
    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20231207"]
    }
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_default_subnet" "default_az1" {
    availability_zone = "us-west-1a"
}

resource "aws_default_subnet" "default_az2" {
    availability_zone = "us-west-1c"
}

resource "aws_security_group" "web_server"{
    name = "web-server-sg"

    ingress {
        from_port = var.web_server_port
        to_port = var.web_server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        name = "Web Server Security Group"
    }
}

resource "aws_launch_template" "asg" {
    name = "web-server-asg-template"
    image_id = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.web_server.id]

    user_data = filebase64("./user-data.sh")

    tags = {
        Name = "Web Server ASG Template"
    }
}

resource "aws_autoscaling_group" "web_servers" {
    name = "web-servers-asg"
    max_size = 2
    min_size = 2
    health_check_grace_period = 300
    health_check_type = "ELB"
    desired_capacity = 2
    launch_template {
        id = aws_launch_template.asg.id
    }
    vpc_zone_identifier = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
    target_group_arns = [aws_lb_target_group.web_servers.arn]

    tag {
        key = "name"
        value = "asg-web-server"
        propagate_at_launch = true
    }
}

output "lb_endpoint" {
    value = aws_lb.this.dns_name
}

resource "aws_security_group" "lb" {
    name = "lb-sg"
    
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        name = "Load Balancer Security Group"
    }
}

resource "aws_lb" "this" {
    load_balancer_type = "application"
    security_groups = [aws_security_group.lb.id]
    subnets = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
}

resource "aws_lb_target_group" "web_servers" {
    name = "web-servers-tg"
    port = 8080
    protocol = "HTTP" 
    vpc_id = aws_default_vpc.default.id
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.this.arn
    port = "80"
    protocol = "HTTP"

    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code = 404
        }
    }
}

resource "aws_lb_listener_rule" "all" {
    listener_arn = aws_lb_listener.http.arn

    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.web_servers.arn
    }

    condition {
        path_pattern {
            values = ["*"]
        }
    }
}