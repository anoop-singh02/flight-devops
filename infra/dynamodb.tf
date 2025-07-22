resource "aws_dynamodb_table" "flight_status" {
  name         = "flight_status"
  billing_mode = "PAY_PER_REQUEST"   # on-demand (free-tier friendly)

  hash_key  = "FlightId"   # Partition Key
  range_key = "Timestamp"  # Sort Key

  attribute {
    name = "FlightId"
    type = "S"             # string
  }

  attribute {
    name = "Timestamp"
    type = "S"             # ISO date-time stored as string
  }
}
