output "tfe_organization" {
  value = {
    this = {
      id    = data.tfe_organization.this.id
      name  = data.tfe_organization.this.name
      email = data.tfe_organization.this.email
    }
  }
  description = "A map of the HCP Terraform organizations details including 'id' and 'name'. Only inludes 'this' organization."
}

output "tfe_organization_membership" {
  value       = data.tfe_organization_membership.this
  description = "A list containing details about the HCP Terraform organization members."
}

output "tfe_team" {
  value = {
    owners = {
      id                          = data.tfe_team.owners.id
      organization_membership_ids = local.owners_team_organization_membership_ids
    }
  }
  description = "A map of the HCP Terraform teams with their 'id' and the members represented as `organization_membership_ids`. Currently, this only supports the 'owners' team."
}

output "tfe_project" {
  value = {
    default = {
      id = data.tfe_project.default.id
    }
  }
  description = "A map of the HCP Terraform projects with their 'id' as the only key. Currently, this only supports the 'Default Project' project."
}

output "tfe_variable_set" {
  value       = local.variable_sets
  description = "A map of variable sets and their details as configured in the HCP Terraform organization."
}
