terraform {
  required_version = "~> 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.75.0"

    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }


}

/* provider "google" {

    project = var.gcp_project_id
    region  = var.gcp_region
    zone    = var.gcp_zone

} */


provider "google" {
  alias = "impersonation"

  scopes = [
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/userinfo.email",
  ]

}

