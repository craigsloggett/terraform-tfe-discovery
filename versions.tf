terraform {
  required_version = "~> 1.7"

  # Version 0.71.0 of the `tfe` provider removed service accounts from the
  # tfe_team_organization_members resource. This module has been written
  # to match this behaviour when discovering members of the owners team:
  # https://github.com/hashicorp/terraform-provider-tfe/commit/51c13cc01424fad0d7521022f248c4d3484c0c6f
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = ">= 0.71.0"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.3.0"
    }
  }
}
