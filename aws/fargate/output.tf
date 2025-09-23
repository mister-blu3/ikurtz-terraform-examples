// Outputs
output "frontend_lb_public_ip" {
  value       = aws_lb.frontend.dns_name
  description = "The public DNS name of the frontend load balancer"
}
