# HCP Terraform and Terraform Enterprise Discovery

A Terraform module to easily discover resources in an HCP Terraform or Terraform Enterprise organization.

The outputs of the module expose the necessary `id` values to be used in `import` blocks by the consuming root module. Each output is named after the [HCP Terraform and Terraform Enterprise Provider](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs) resource  it is discovering.

For example, the [tfe_organization](https://registry.terraform.io/modules/craigsloggett/discovery/tfe/latest?tab=outputs) output would contain details about the [tfe_organization](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/organization) resource.

This module provides a way to discover existing configuration and expose the relevant details needed to bring them under management with Terraform's `import` command.

This is similar in concept to the `query` functionality introduced in recent versions of Terraform with the added benefit that the module does not require the provider to be updated to include `list` resources. Additionally, this module is backwards compatible with older Terraform versions that did not have these features yet.

Long term, the goal for this module will be to include `list` blocks as the feature and provider matures, giving users the ability to both discover unmanaged resources and generate the code to manage them with a single module.

<!-- BEGIN_TF_DOCS -->
## Usage

### main.tf
```hcl
terraform {
  # Version v1.5.0 is the first version to introduce `import` blocks.
  required_version = "~> 1.5"

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "0.71.0"
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
  version = "0.14.1"
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
```

### imports.tf
```hcl
# Using the outputs of the module, the default resources
# that come with every new organization can be easily
# imported.

# The HCP Terraform organization.
import {
  id = module.discovery.tfe_organization.this.name
  to = tfe_organization.this
}

# The members of the HCP Terraform organization.
import {
  for_each = module.discovery.tfe_organization_membership

  id = each.key
  to = tfe_organization_membership.this[each.key]
}

# The "owners" Team
import {
  id = "${module.discovery.tfe_organization.this.name}/${module.discovery.tfe_team.owners.id}"
  to = tfe_team.owners
}

# The members of the "owners" team.
import {
  id = module.discovery.tfe_team.owners.id
  to = tfe_team_organization_members.owners
}

# The "Default Project" Project
import {
  id = module.discovery.tfe_project.default.id
  to = tfe_project.default
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.7 |
| <a name="requirement_external"></a> [external](#requirement\_external) | >= 2.3.0 |
| <a name="requirement_tfe"></a> [tfe](#requirement\_tfe) | >= 0.44.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_external"></a> [external](#provider\_external) | >= 2.3.0 |
| <a name="provider_tfe"></a> [tfe](#provider\_tfe) | >= 0.44.0 |

## Inputs

No inputs.

## Resources

| Name | Type |
|------|------|
| [external_external.owners_team_emails](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [external_external.variable_set_names](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [tfe_organization.this](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/organization) | data source |
| [tfe_organization_members.this](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/organization_members) | data source |
| [tfe_organization_membership.this](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/organization_membership) | data source |
| [tfe_organizations.this](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/organizations) | data source |
| [tfe_project.default](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/project) | data source |
| [tfe_team.owners](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/team) | data source |
| [tfe_variable_set.this](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/variable_set) | data source |
| [tfe_variables.this](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/variables) | data source |
| [tfe_workspace.this](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/workspace) | data source |
| [tfe_workspace_ids.this](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/workspace_ids) | data source |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_tfe_organization"></a> [tfe\_organization](#output\_tfe\_organization) | A map of the HCP Terraform organizations details including 'id' and 'name'. Only inludes 'this' organization. |
| <a name="output_tfe_organization_membership"></a> [tfe\_organization\_membership](#output\_tfe\_organization\_membership) | A list containing details about the HCP Terraform organization members. |
| <a name="output_tfe_project"></a> [tfe\_project](#output\_tfe\_project) | A map of the HCP Terraform projects with their 'id' as the only key. Currently, this only supports the 'Default Project' project. |
| <a name="output_tfe_project_variable_set"></a> [tfe\_project\_variable\_set](#output\_tfe\_project\_variable\_set) | A map of variable set and project pairs. |
| <a name="output_tfe_team"></a> [tfe\_team](#output\_tfe\_team) | A map of the HCP Terraform teams with their 'id' and the members represented as `organization_membership_ids`. Currently, this only supports the 'owners' team. |
| <a name="output_tfe_variable_set"></a> [tfe\_variable\_set](#output\_tfe\_variable\_set) | A map of variable sets and their details as configured in the HCP Terraform organization. |
| <a name="output_tfe_workspace"></a> [tfe\_workspace](#output\_tfe\_workspace) | A map of workspaces and their details as configured in the HCP Terraform organization. |
<!-- END_TF_DOCS -->

## How It Works

In order to "discover" resources in a Terraform organization, this module uses data sources from the [tfe](https://registry.terraform.io/providers/hashicorp/tfe) and [external](https://registry.terraform.io/providers/hashicorp/external) providers. It expects a [Team API Token](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/api-tokens#team-api-tokens) for the [owners team](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/teams#the-owners-team) to be available as the `TFE_TOKEN` environment variable in the Terraform [run environment](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/run/run-environment).

The resulting data source attributes are then restructured using `locals` and presented as outputs in a structure that aligns resource type names to the discovered resources of that type.

### Example

The resource type `tfe_variable_set` is provided as an output containing a map of variable sets that have been configured.

```hcl

output "tfe_variable_set" {
  value       = local.variable_sets
  description = "A map of variable sets and their details as configured in the HCP Terraform organization."
}

locals {
  # The output of the `external` data source is a jsonencoded string so
  # this local variable does the jsondecode in one spot and converts it
  # to a "set" for convenience when used with "for_each".
  variable_set_names = toset(jsondecode(data.external.variable_set_names.result.names))

  # The `tfe_variable_set` data source includes the variable IDs, but
  # not any details about the variables.
  variable_sets_without_variables = {
    for name in local.variable_set_names :
    data.tfe_variable_set.this[name].id => data.tfe_variable_set.this[name]
  }

  # The `tfe_variable` data source contains a lot of duplicate data so
  # this will clean it up and prepare it to be merged into the relevant
  # variable set map that is output by this module.
  variable_set_variables = {
    for name, variable_set in data.tfe_variables.this :
    variable_set.variable_set_id => {
      for variable in variable_set.variables :
      variable.id => variable
    }
  }

  # Merge the variable set data with the variable data associated with
  # each variable set, giving a convenient place to import variable sets
  # and their relevant variables.
  variable_sets = {
    for id, variable_set in local.variable_sets_without_variables :
    id => merge(
      variable_set,
      {
        variables = try(local.variable_set_variables[id], {})
      }
    )
  }
}
```

The variable sets can then be easily be accessed using the module: `module.discovery.tfe_variable_set`. The variables configured in the variable sets are also grouped in the same output to provide a logical hierarchy of entities (a variable belongs to a variable set). This makes importing the resources straightforward:

```hcl
import {
  for_each = module.discovery.tfe_variable_set

  id = each.key
  to = tfe_variable_set.this[each.key]
}

resource "tfe_variable_set" "this" {
  for_each = module.discovery.tfe_variable_set

  name         = each.value.name
  description  = each.value.description
  organization = tfe_organization.this.name
}
```
