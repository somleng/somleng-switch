resource "aws_ecr_repository" "app" {
  name                 = "somleng-adhearsion"

  image_scanning_configuration {
    scan_on_push = true
  }
}
