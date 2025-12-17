terraform {
  required_version = "~> 1.7"

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = ">= 0.44.0"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.3.0"
    }
  }
}
