terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 3.0"
        }
    }
}

provider "aws" {
    region = "us-east-1"
}

resource "aws_security_group" "remotedocker" {
    name        = "allow_from_do"
    description = "Allow connections from droplet"
    vpc_id      = "vpc-8a7ef5f2"
}

resource "aws_security_group_rule" "ingress" {
    type        = "ingress"
    from_port   = 0
    to_port     = 65536
    protocol    = "all"
    cidr_blocks = ["164.92.216.77/32"]

    security_group_id = aws_security_group.remotedocker.id
}

resource "aws_security_group_rule" "egress" {
    type        = "egress"
    from_port   = 0
    to_port     = 65535
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]

    security_group_id = aws_security_group.remotedocker.id
}

resource "aws_instance" "remotedocker" {
    ami           = "ami-0cff7528ff583bf9a"
    instance_type = "t2.micro"

    associate_public_ip_address = true
    vpc_security_group_ids      = [aws_security_group.remotedocker.id]

    key_name  = "remotedocker"
    subnet_id = "subnet-f36da5dc"

    user_data = <<EOF
#!/bin/bash
yum -y update && yum install -y docker
sed -i 's/-H fd:\/\//-H fd:\/\/ -H tcp:\/\/0.0.0.0:2375/' /usr/lib/systemd/system/docker.service
systemctl daemon-reload
systemctl enable docker
systemctl start docker
EOF
}

output "PublicIP" {
    value = aws_instance.remotedocker.public_ip
}
