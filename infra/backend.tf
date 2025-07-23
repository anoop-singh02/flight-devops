terraform {
  backend "s3" {
    bucket         = "flight-devops-state-285233622609"
    key            = "terraform.tfstate"
    region         = "ca-central-1"
    dynamodb_table = "terraform_locks"
    encrypt        = true
  }
}
