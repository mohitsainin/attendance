variable "vpc_CIDR" {
  default = "192.168.0.0/24"
}

variable "Application_subnet_cidr" {
  default = ["192.168.0.64/27", "192.168.0.96/27"]
}

variable "availability_zones" {
  default = ["us-east-1a", "us-east-1b"]
}

variable "vpc_id" {
  default = "aws_vpc.OT-micro.id"
}

variable "key_name" {
  default = "otms"
}

variable "ami_id" {
  default = "ami-005fc0f236362e99f"
}

variable "instance_type" {
  default = "t2.medium"
}
