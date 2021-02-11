provider "aws" {
  region = var.region
}
module "ec2_cluster" {
  source         = "./ec2"
  name           = var.name
  instance_count = var.instance_count

  ami           = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name
  monitoring    = var.monitoring
  subnet_id = var.subnet_id

  tags = {
    Terraform   = var.Terraform
    Environment = var.Environment
  }
}
