terraform {

  backend "gcs" {
    bucket = "tf-ws-1-bucket-tfstate"
    prefix = "terraform/state"
  }
}
