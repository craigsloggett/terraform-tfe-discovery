# This external data source will query the HCP Terraform API for a list of
# variable sets that are configured in the organization.
data "external" "variable_set_names" {
  program = ["sh", "${path.module}/scripts/get_variable_sets.sh"]

  query = {
    organization_name = data.tfe_organization.this.name
  }
}

data "tfe_variable_set" "this" {
  for_each     = local.variable_set_names
  name         = each.key
  organization = data.tfe_organization.this.name
}

data "tfe_variables" "this" {
  for_each        = local.variable_set_names
  variable_set_id = data.tfe_variable_set.this[each.key].id
}

data "tfe_workspace_ids" "this" {
  names        = ["*"]
  organization = data.tfe_organization.this.name
}

data "tfe_workspace" "this" {
  for_each = toset([for name, id in data.tfe_workspace_ids.this.ids : name])

  name         = each.key
  organization = data.tfe_organization.this.name
}
