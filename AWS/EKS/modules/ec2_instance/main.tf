resource "aws_security_group" "sg" {
  name        = "${var.name}-sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.name}-sg"
    Environment = "${var.environment}"
  }
}

resource "aws_instance" "instance" {
  ami                         = "${var.ami_id}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.key_name}"
  vpc_security_group_ids      = ["${aws_security_group.sg.id}"]
  subnet_id                   = "${var.subnet_id}"
  associate_public_ip_address = "${var.public_ip_address}"
  monitoring                  = "${var.monitoring}"
  iam_instance_profile        = "${aws_iam_instance_profile.default.name}"

  root_block_device {
    volume_type = "gp2"
    volume_size = "${var.storage}"
    encrypted   = true
  }  
 
  tags = {
    Name        = "${var.name}"
    Environment = "${var.environment}"
  }
}

resource "aws_eip" "instance" {
  instance = aws_instance.instance.id
  vpc      = true
}

#################
# IAM
#################

resource "aws_iam_instance_profile" "default" {
  name = "${var.name}"
  role = "${aws_iam_role.default.name}"
}

resource "aws_iam_role" "default" {
  name               = "${var.name}"
  assume_role_policy = "${file("${path.module}/policies/ec2_assume.json")}"
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = "${aws_iam_role.default.name}"
  count      = "${length(var.policy_arns)}"
  policy_arn = "${var.policy_arns[count.index]}"
}
