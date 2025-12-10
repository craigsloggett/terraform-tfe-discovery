# Example: Importing Default Resources

```hcl
provider "tfe" {
  hostname     = "app.terraform.io"
}

# Use the module like a data source to get details about the resources in your organization.
module "discovery" {
  source  = "craigsloggett/discovery/tfe"
  version = "0.12.6"
}

# Using the outputs of the module, the default resources
# that come with every new organization can be easily
# imported.

# HCP Terraform Organization

import {
  id = module.discovery.tfe_organization.this.name
  to = tfe_organization.this
}

resource "tfe_organization" "this" {
  name  = module.discovery.tfe_organization.this.name
  email = module.discovery.tfe_organization.this.email

  assessments_enforced = true
}

# HCP Terraform Organization Members (Users)

import {
  for_each = module.discovery.tfe_organization_membership

  id = each.key
  to = tfe_organization_membership.this[each.key]
}

resource "tfe_organization_membership" "this" {
  for_each = module.discovery.tfe_organization_membership

  organization = tfe_organization.this.name
  email        = each.value.email
}

# The "owners" Team

import {
  id = "${module.discovery.tfe_organization.this.name}/${module.discovery.tfe_team.owners.id}"
  to = tfe_team.owners
}

resource "tfe_team" "owners" {
  name         = "owners"
  organization = tfe_organization.this.name
}

# The "owners" Team Members (Users)

import {
  id = module.discovery.tfe_team.owners.id
  to = tfe_team_organization_members.owners
}

resource "tfe_team_organization_members" "owners" {
  team_id                     = tfe_team.owners.id
  organization_membership_ids = module.discovery.tfe_team.owners.organization_membership_ids
}

# The "Default Project" Project

import {
  id = module.discovery.tfe_project.default.id
  to = tfe_project.default
}

# tflint-ignore: terraform_required_providers
resource "tfe_project" "default" {
  name         = "Default Project"
  organization = tfe_organization.this.name
}
```
