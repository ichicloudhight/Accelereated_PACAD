output "ansible_IP" {
  value       = aws_instance.client3_ansible.public_ip
  description = "Ansible public IP"
}

output "Bastonhost_IP" {
  value       = aws_instance.Bastion_host.public_ip
  description = "Bastion host IP"
}

output "docker_stage_IP" {
  value       = aws_instance.client3_docker_stage.private_ip
  description = "Docker public IP"
}

output "docker_prod_IP" {
  value       = aws_instance.client3_docker_prod.private_ip
  description = "Docker public IP"
}

output "sonarqube_IP" {
  value       = aws_instance.client3_sonarqube.public_ip
  description = "sonarqube public IP"
}


output "jenkins_IP" {
  value       = aws_instance.client3_Jenkins.private_ip
  description = "Docker public IP"
}

output "jenkins_lb_dns" {
  value       = aws_lb.client3-jenkins-lb.dns_name
  description = "jenkins_lb"
}

output "docker_stage_lb_dns" {
  value       = aws_lb.client3-docker-stage-lb.dns_name
  description = "docker_stage_lb"
}

output "docker_prod_lb_dns" {
  value       = aws_lb.client3-docker-prod-lb.dns_name
  description = "docker_prod_lb"
}

output "jenkinsPub_IP" {
  value       = aws_instance.client3_Jenkins.public_ip
  description = "sonarqube public IP"
}
