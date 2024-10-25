resource "aws_iam_role" "flow_log" {
  name               = "${var.name}-flow-log-role"
  assume_role_policy = "${file("${path.module}/policies/flow_log_assume.json")}"
}

resource "aws_iam_role_policy" "flow_log" {
  name = "default-flow-log"
  role = "${aws_iam_role.flow_log.id}"

  policy = "${file("${path.module}/policies/flow_log_policy.json")}"
}
