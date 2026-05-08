data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "gatewatch" {
  name               = "${var.name}-nat-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = local.tags
}

# S3 — téléchargement du binaire agent depuis le bucket GateWatch
resource "aws_iam_role_policy" "s3_releases" {
  name = "gatewatch-s3-releases"
  role = aws_iam_role.gatewatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = "arn:aws:s3:::${var.releases_bucket}/*"
    }]
  })
}

# SSM — accès sans SSH via AWS Systems Manager
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.gatewatch.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "gatewatch" {
  name = "${var.name}-nat-profile"
  role = aws_iam_role.gatewatch.name
  tags = local.tags
}
