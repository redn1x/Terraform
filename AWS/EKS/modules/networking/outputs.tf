output "vpc_id" {
  description = "The ID of the VPC"
  value       = "${aws_vpc.default.id}"
}

output "public_subnet_ids" {
  description = "The IDs of the public subnet(s)"
  value       = "${aws_subnet.public.*.id}"
}

output "private_subnet_ids" {
  description = "The IDs of the private subnet(s)"
  value       = "${aws_subnet.private.*.id}"
}

output "internal_subnet_ids" {
  description = "The IDs of the internal subnet(s) (associated with a routing table that has no gateway)"
  value       = "${aws_subnet.internal.*.id}"
}
