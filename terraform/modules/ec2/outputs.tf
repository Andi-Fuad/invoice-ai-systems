output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.main.id
}

output "public_ip" {
  description = "EC2 instance public IP (via Elastic IP)"
  value       = aws_eip.main.public_ip
}

output "private_ip" {
  description = "EC2 instance private IP"
  value       = aws_instance.main.private_ip
}

output "instance_state" {
  description = "EC2 instance state"
  value       = aws_instance.main.instance_state
}

output "availability_zone" {
  description = "Availability zone where instance is running"
  value       = aws_instance.main.availability_zone
}
