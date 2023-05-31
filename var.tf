variable "my_instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "my-instance"
}


variable "redis_private_ip" {
  description = "redis_private_ip"
  type = string 
  default = "10.0.1.189"
}