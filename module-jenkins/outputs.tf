output "bastion" {
  value = aws_instance.bastion.public_ip
}

output "jenkins-master-elb" {
  value = aws_elb.jenkins_elb.dns_name
}

output "jenkins-dns" {
  value = "https://${aws_route53_record.jenkins_master.name}"
}

output "bastion_sg_id" {
  value = aws_security_group.bastion_host.id
}

output "jenkins_sg_id" {
  value = aws_security_group.jenkins_master_sg.id
}

output "key_pair_management_id" {
  value = aws_key_pair.management.id
}

output "jenkins_vpc_id" {
  value = aws_vpc.management.id
}

output "jenkins_public_subnets" {
  value = [for subnet in aws_subnet.public_subnets : subnet.id]
}