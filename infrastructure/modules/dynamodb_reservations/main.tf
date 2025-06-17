resource "aws_dynamodb_table" "this" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"

  hash_key     = "user_id"
  range_key    = "reservation_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "reservation_id"
    type = "S"
  }

  tags = {
    Project = "HotelReservation"
  }
}
