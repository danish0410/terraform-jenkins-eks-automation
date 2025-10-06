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

output "bastion_sg_id" {
  value = aws_security_group.ansible_bastion_sg.id
}

output "bastion_asg_name" {
  value = aws_autoscaling_group.bastion_asg.name
}

output "private_instance_ids" {
  value = aws_instance.dev_ec2_private[*].id
}

output "ssh_private_key_path" {
  value       = local_file.private_key.filename
  description = "Path to generated private key. Protect this file!"
}