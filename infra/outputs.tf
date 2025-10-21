output "region" {
  value = var.region
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "dev_classic_sg_id" {
  value = aws_security_group.dev_classic_sg.id
}

output "private_sg_id" {
  value = aws_security_group.private_ec2.id
}

output "dev_classic_asg_names" {
  value = [for k, v in aws_autoscaling_group.dev_classic_asg : v.name]
}

output "private_asg_names" {
  value = [for k, v in aws_autoscaling_group.private_asg : v.name]
}

output "ssh_private_key_path" {
  value       = local_file.private_key.filename
  description = "Path to generated private key. Protect this file!"
}

# -------------------------
# Output Bastion Public IP
# -------------------------
output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_instance.bastion.public_ip
}