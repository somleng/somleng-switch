resource "aws_sqs_queue" "this" {
  name           = var.app_identifier
  redrive_policy = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.dead_letter.arn}\",\"maxReceiveCount\":10}"
}

resource "aws_sqs_queue" "dead_letter" {
  name = "${var.app_identifier}-dead-letter"
}
