variable "region" {
    type = string
    default = "us-west-1"
}
variable "name" {
    type = string
    default = "dynatrace cluster"
}
variable "instance_count" {
    type = number
    default = 3
}
variable "ami" {
    type = string
    default = "ami-005c06c6de69aee84"
}
variable "instance_type" {
    type = string
    default = "t2.micro"
}
variable "key_name" {
    type = string
    default = "devops-key"
}
variable "monitoring" {
    type = bool
    default = true
}
variable "vpc_security_group_ids" {
    type = list
    default = ["sg-ab6c54dd"]
}
variable "subnet_id" {
    type = string
    default = "subnet-e37dc785"
}
variable "Terraform" {
    type = bool
    default = true
}
variable "Environment" {
    type = string
    default = "dev"
}