/*
 The terraform {} block contains Terraform settings, including the required providers Terraform will use to provision infrastructure.
 Terraform installs providers from the Terraform Registry by default.
 In this example configuration, the aws provider's source is defined as hashicorp/aws,
*/
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.52"
    }
  }

  backend "s3" {
    bucket = "danielms-tf-backup"
    key    = "tfstate.json"
    region = "eu-central-1"
    # optional: dynamodb_table = "<table-name>"
  }

  required_version = ">= 1.2.0"
}


/*
 The provider block configures the specified provider, in this case aws.
 You can use multiple provider blocks in your Terraform configuration to manage resources from different providers.
*/
provider "aws" {
  region  = var.region
#  profile = "<aws-course-profile>"
}


/*
 Use resource blocks to define components of your infrastructure.
 A resource might be a physical or virtual component such as an EC2 instance.
 A resource block declares a resource of a given type ("aws_instance") with a given local name ("app_server").
 The name is used to refer to this resource from elsewhere in the same Terraform module, but has no significance outside that module's scope.
 The resource type and name together serve as an identifier for a given resource and so must be unique within a module.

 For full description of this resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
*/
resource "aws_instance" "app_server" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  availability_zone = "${var.region}a"

  user_data = file("./deploy.sh")

  vpc_security_group_ids = [aws_security_group.sg_web.id]
  # key_name = "dsarid-frankfurt-key"
  key_name = "my-key-pair"

  depends_on = [
#     aws_s3_bucket.data_bucket,
    aws_ebs_volume.ebs_volume,
    aws_key_pair.my-key-pair,
    aws_security_group.sg_web
  ]



  tags = {
    Name = "danielms-terraform-${var.env}"
    Terraform = "true"
    Test = "new-tag"
    Env = var.env
  }
}

resource "aws_ebs_volume" "ebs_volume" {
  availability_zone = "${var.region}a"
  size = 5

  tags = {
    Name = "HelloWorld"
  }
}


resource "aws_security_group" "sg_web" {
  name = "${var.resource_alias}-${var.env}-sg"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
    protocol = -1
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Env         = var.env
    Terraform   = true
  }
}

# resource "aws_s3_bucket" "data_bucket" {
#   bucket = "${var.resource_alias}-bucket"
#
#   tags = {
#     Name = "${var.resource_alias}-bucket"
#     Env = var.env
#     Terraform = true
#   }
# }

resource "aws_key_pair" "my-key-pair" {
  public_key = file("~/.ssh/tf-test.pub")
  key_name = "my-key-pair"
}

resource "aws_volume_attachment" "ebs_attachment" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebs_volume.id
  instance_id = aws_instance.app_server.id
}

# resource "aws_iam_role" "app_server_role" {
#   name               = "${var.resource_alias}-role"
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "ec2.amazonaws.com"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# EOF
# }


# resource "aws_instance" "my_ec2" {
#   ami = "ami-06dd92ecc74fdfb36"
#   instance_type = "t2.micro"
#
#   key_name = "dsarid-frankfurt-key"
#
#   vpc_security_group_ids = ["sg-06f36b928ee91eec3"]
#
#   tags = {
#     Name = "dsarid-webserver"
#   }
# }

# removed {
#   from = aws_instance.my_ec2
#   lifecycle {
#     destroy = false
#   }
# }

# import {
#  to = aws_security_group.sq_ref
#  id = "sg-0b348ebec6308dc32"
# }
#
# resource "aws_security_group" "sq_ref" {
#   name = "launch-wizard-23"
# }

# resource "aws_ec2_instance_state" "test" {
#   instance_id = aws_instance.app_server.id
#   state       = "stopped"
# }
