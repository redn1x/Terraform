resource "aws_cloudwatch_log_group" "flow_log" {
  name              = "/${var.name}/vpc-flow-log"
  retention_in_days = "${var.log_retention_period}"
  # kms_key_id        = "${var.log_kms_key}"

  tags = "${merge(var.tags, map("Name", "${var.name}-vpc-flow-log"))}"
}
