
# output "instance_id" {
#   description = "ID of the EC2 instance"
#   value       = aws_instance.flask_app.id
# }

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.flask_app.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.redis_db.private_ip
}




output "elp_public_ip" {
  description = "My elasticc Public IP"
  value       = aws_eip.flask_url.public_ip
}
