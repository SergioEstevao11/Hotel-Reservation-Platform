resource "aws_ecr_repository" "app_repo" {
  name = var.name
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}
