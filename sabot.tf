terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}

# use the ~/.aws/credentials in the named profile section
provider "aws" {
  profile = "terraform"
  region  = "us-east-1"
}


# find the id of the ubuntu focal fossa image in region
#
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


# create a permissive security group in the default vpc
#
resource "aws_security_group" "sabot_sg" {
  name        = "sabot_sg"
  description = "allows basic services from any source"

  ingress {
    description = "TLS from any"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP from any"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH from any"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Creator = "sabot-tf"
    Name    = "sabot-sg"
  }
}

# register ssh public key for sabot server
#
resource "aws_key_pair" "awstf" {
  key_name   = "awstf-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDJ/4xt0WZz5uTlxLNuJwJgGyUlzVVsBfv3dTxZiY0qt8x6xAQZdVmcr7p5DuqE7c6hh90qbu3KfBsfXknezwzv20kgoIaxVht2f+1gkNOayhj10Ej5ELClGwQslTJaddCq6uwWCgney30xo/oVY5d656FgHcUTX4vCnrx2vbZuOoJY70FendW2YI42XLiSywCiePwelSDfVNzk8u7n1RBmJDb7feq1SKFF2w/SrjI6fwz3Pv5ck42gH1ZweBpLzhhkc0eIJoXQfLWIPW1SRAjGBxBFYi/QSPNKYluHlmhGsfI7+vm09i6mclGUHqvBy7IY9ol45IlIphuag/WW+ok0X/i+PiKbF72Df9iT2nsV4+hRRle608fQKggwP8I5HBdoOnscdDkwDxLDm+Fvo/+Ub32Z7Jz4zXHclIURjMabi7bp1rbbK4JYpPU4KAk1x14gpRJrcyHcX/hWKqUDczOAlWQ4sb1TJJJCNs6UoGOAye1vByFKV3BXPjBKj1rwais= awstf@omen"
}

resource "aws_instance" "sabot" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [
    aws_security_group.sabot_sg.id
  ]
  tags = {
    Creator = "sabot-tf"
    Name    = "sabot"
  }
  key_name = "awstf-key"
}

output "public_ip" {
  value = aws_instance.sabot.public_ip
}
