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

output "dev_servme_sg_id" {
  value = aws_security_group.dev_servme_sg.id
}

output "private_sg_id" {
  value = aws_security_group.private_ec2.id
}

output "dev_servme_asg_names" {
  value = [for k, v in aws_autoscaling_group.dev_servme_asg : v.name]
}

output "private_asg_names" {
  value = [for k, v in aws_autoscaling_group.private_asg : v.name]
}

output "ssh_private_key_path" {
  value       = local_file.private_key.filename
  description = "Path to generated private key. Protect this file!"
}