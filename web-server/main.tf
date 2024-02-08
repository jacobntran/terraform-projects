provider "aws" {
    region = "us-west-1"
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

    tags = {
        Name = "Ubuntu Web Server"
    }
}