# This file contains all of the resources included in a new HCP Terraform
# organization. Additional resources are "discovered" in `discovery.tf`.

data "tfe_organizations" "this" {}

data "tfe_organization" "this" {
  name = data.tfe_organizations.this.names[0]

  lifecycle {
    precondition {
      condition     = length(data.tfe_organizations.this.names) == 1
      error_message = "Expected exactly one TFE organization for this token, but found ${length(data.tfe_organizations.this.names)}."
    }
  }
}

data "tfe_organization_members" "this" {
  organization = data.tfe_organization.this.name
}

data "tfe_organization_membership" "this" {
  for_each = toset(data.tfe_organization_members.this.members[*].organization_membership_id)

  organization               = data.tfe_organization.this.name
  organization_membership_id = each.value
}

data "tfe_team" "owners" {
  name         = "owners"
  organization = data.tfe_organization.this.name
}

# This external data source will query the HCP Terraform API for a list of
# emails for members (users) that are in the "owners" team. It will filter
# service accounts to match the behaviour of the tfe_team_organization_members
# resource:
#
# https://github.com/hashicorp/terraform-provider-tfe/commit/51c13cc01424fad0d7521022f248c4d3484c0c6f
data "external" "owners_team_emails" {
  program = ["sh", "${path.module}/scripts/get_owners_team_emails.sh"]

  query = {
    organization_name = data.tfe_organization.this.name
  }
}

data "tfe_project" "default" {
  name         = "Default Project"
  organization = data.tfe_organization.this.name
}
