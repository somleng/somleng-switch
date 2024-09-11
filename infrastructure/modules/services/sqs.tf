resource "aws_sqs_queue" "dead_letter" {
  name = "${var.identifier}-dead-letter"
}

resource "aws_sqs_queue" "this" {
  name           = var.identifier
  redrive_policy = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.dead_letter.arn}\",\"maxReceiveCount\":10}"

  # https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html#events-sqs-queueconfig
  visibility_timeout_seconds = aws_lambda_function.this.timeout * 10
}
