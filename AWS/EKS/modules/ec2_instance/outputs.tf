output "instance_id" {
  value = "${aws_instance.instance.id}"
}

output "security_group_id" {
  value = "${aws_security_group.sg.id}"
}

output "instance_role_arn" {
  value = "${aws_iam_role.default.arn}"
}