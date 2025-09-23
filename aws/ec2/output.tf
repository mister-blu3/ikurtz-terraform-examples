//Output After Run
output "vpc_arn" {
  description = "VPN ARN"
  value       = data.aws_vpc.selected.arn
  sensitive   = true
}

output "vpc_id" {
  description = "VPN id"
  value       = data.aws_vpc.selected.id
}

output "subnet_id" {
  description = "Subnet ARN"
  value       = data.aws_subnet.selected.id
}

output "ips" {
  description = "VM private IP"
  value = {
    for instance in aws_instance.ec2 :
    instance.tags.name => instance.private_ip
  }
}
