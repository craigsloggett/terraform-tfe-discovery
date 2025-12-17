terraform {
  # Version v1.5.0 is the first version to introduce `import` blocks.
  required_version = "~> 1.5"

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.71"
    }
  }
}

# The discovery module is a data source for all of the identifiers being imported.

# It is used to capture the names and configuration of each resource so you don't
# have to enter them in manually for the organization being managed.

# The module expects a Team API Token for the "owners" team to be available as the
# TFE_TOKEN environment variable in the Terraform run environment.
module "discovery" {
  source  = "craigsloggett/discovery/tfe"
  version = "0.14.3"
}

# The following are the resources that come with every new HCP Terraform organization.
resource "tfe_organization" "this" {
  name  = module.discovery.tfe_organization.this.name
  email = module.discovery.tfe_organization.this.email
}

resource "tfe_organization_membership" "this" {
  for_each = module.discovery.tfe_organization_membership

  organization = tfe_organization.this.name
  email        = each.value.email
}

resource "tfe_team" "owners" {
  name         = "owners"
  organization = tfe_organization.this.name
}

resource "tfe_team_organization_members" "owners" {
  team_id                     = tfe_team.owners.id
  organization_membership_ids = module.discovery.tfe_team.owners.organization_membership_ids
}

resource "tfe_project" "default" {
  name         = "Default Project"
  organization = tfe_organization.this.name
}
