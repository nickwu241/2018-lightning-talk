provider "aws" {
    # Make sure AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are exported.
    region = "us-east-1"
}

variable "public_key" {
    # Generate a SSH key pair if you don't have one.
    # To copy your public SSH key: cat ~/.ssh/id_rsa.pub | pbcopy
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "${var.public_key}"
}

resource "aws_security_group" "allow_all" {
    name = "allow_all"
    description = "Allow all inbound traffic"

    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "web" {
    instance_type = "t2.micro"
    # Amazon Linux AMI 2018.03.0 (HVM), SSD Volume Type.
    ami = "ami-cfe4b2b0"

    security_groups = ["${aws_security_group.allow_all.name}"]
    key_name = "${aws_key_pair.deployer.key_name}"
    associate_public_ip_address = true

    provisioner "remote-exec" {
        inline = [
            "sudo yum install -y docker",
            "sudo service docker start",
            "sudo docker pull nginx",
            "sudo docker run -d -p 80:80 --name nginx nginx"
        ]

        connection {
            # For Amazon Linux AMI, the user name is ec2-user.
            user = "ec2-user"
        }
    }

    tags {
        Name = "EC2 Docker NGINX with Terraform Demo"
    }
}

output "web_ip" {
    value = "${aws_instance.web.public_ip}"
}
