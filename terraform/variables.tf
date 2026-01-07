variable "aws_region" {
  description = "AWS region where resources will be provisioned"
  default     = "eu-north-1"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  default     = "ami-0b46816ffa1234887"
}

variable "instance_type" {
  description = "Instance type for the EC2 instance"
  default     = "m7i-flex.large"
}

variable "my_enviroment" {
  description = "Instance type for the EC2 instance"
  default     = "dev"
}
