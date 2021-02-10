output "id" {
  description = "List of IDs of instances"
  value       = module.ec2_cluster.*.id
}
output "arn" {
  description = "List of ARNs of instances"
  value       = module.ec2_cluster.*.arn
}
output "public_dns" {
  description = "List of public DNS names assigned to the instances. For EC2-VPC, this is only available if you've enabled DNS hostnames for your VPC"
  value       = module.ec2_cluster.*.public_dns
}
output "public_ip" {
  description = "List of public IP addresses assigned to the instances, if applicable"
  value       = module.ec2_cluster.*.public_ip
}
