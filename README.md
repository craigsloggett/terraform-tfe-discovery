# HCP Terraform and Terraform Enterprise Discovery

A Terraform module to easily discover resources in an HCP Terraform or Terraform Enterprise organization.

The outputs of the module expose the necessary `id` values to be used in `import` blocks by the consuming root module. Each output is named after the [HCP Terraform and Terraform Enterprise Provider](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs) resource  it is discovering.

For example, the [tfe_organization](https://registry.terraform.io/modules/craigsloggett/discovery/tfe/latest?tab=outputs) output would contain details about the [tfe_organization](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/organization) resource.

This module provides a way to discover existing configuration and expose the relevant details needed to bring them under management with Terraform's `import` command.

This is similar in concept to the `query` functionality introduced in recent versions of Terraform with the added benefit that the module does not require the provider to be updated to include `list` resources. Additionally, this module is backwards compatible with older Terraform versions that did not have these features yet.

Long term, the goal for this module will be to include `list` blocks as the feature and provider matures, giving users the ability to both discover unmanaged resources and generate the code to manage them with a single module.

If you haven't setup an HCP Terraform organization yet, the [Manual Onboarding Setup](#Manual-Onboarding-Setup) section below walks you through the steps to get started.

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

<!-- BEGIN_TF_DOCS -->
## Usage

### main.tf
```hcl
# tflint-ignore: terraform_required_version

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

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.7 |
| <a name="requirement_external"></a> [external](#requirement\_external) | 2.3.5 |
| <a name="requirement_tfe"></a> [tfe](#requirement\_tfe) | 0.71.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_external"></a> [external](#provider\_external) | 2.3.5 |
| <a name="provider_tfe"></a> [tfe](#provider\_tfe) | 0.71.0 |

## Inputs

No inputs.

## Resources

| Name | Type |
|------|------|
| [external_external.owners_team_emails](https://registry.terraform.io/providers/hashicorp/external/2.3.5/docs/data-sources/external) | data source |
| [external_external.variable_set_names](https://registry.terraform.io/providers/hashicorp/external/2.3.5/docs/data-sources/external) | data source |
| [tfe_organization.this](https://registry.terraform.io/providers/hashicorp/tfe/0.71.0/docs/data-sources/organization) | data source |
| [tfe_organization_members.this](https://registry.terraform.io/providers/hashicorp/tfe/0.71.0/docs/data-sources/organization_members) | data source |
| [tfe_organization_membership.this](https://registry.terraform.io/providers/hashicorp/tfe/0.71.0/docs/data-sources/organization_membership) | data source |
| [tfe_organizations.this](https://registry.terraform.io/providers/hashicorp/tfe/0.71.0/docs/data-sources/organizations) | data source |
| [tfe_project.default](https://registry.terraform.io/providers/hashicorp/tfe/0.71.0/docs/data-sources/project) | data source |
| [tfe_team.owners](https://registry.terraform.io/providers/hashicorp/tfe/0.71.0/docs/data-sources/team) | data source |
| [tfe_variable_set.this](https://registry.terraform.io/providers/hashicorp/tfe/0.71.0/docs/data-sources/variable_set) | data source |
| [tfe_variables.this](https://registry.terraform.io/providers/hashicorp/tfe/0.71.0/docs/data-sources/variables) | data source |
| [tfe_workspace.this](https://registry.terraform.io/providers/hashicorp/tfe/0.71.0/docs/data-sources/workspace) | data source |
| [tfe_workspace_ids.this](https://registry.terraform.io/providers/hashicorp/tfe/0.71.0/docs/data-sources/workspace_ids) | data source |

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

## Manual Onboarding Setup

The following steps can be used as a guide when onboarding a new repository.

### HashiCorp Cloud Platform

1. Create an HCP account.
2. Create an HCP organization.
3. Create an HCP project.

### HCP Terraform

1. Create an HCP Terraform organization.
2. Run `terraform login` to generate a user API token.
3. Update `backend.tf` to use your HCP Terraform organization.
4. Run `terraform init` to create the backend workspace and project.
5. Manually generate a team API token for the "owners" team.
6. Manually create a variable set for the purpose of authenticating the TFE provider.
7. Populate the variable set with the `TFE_TOKEN` environment variable, using the API token as the (sensitive) value.
8. Assign the variable set to the backend workspace (or project).

#### VCS Integration with GitHub

In order to scope the list of repositories shown to users when creating a VCS backed workspace,
it is necessary to either create and install an OAuth App in your GitHub organization or use a
fine-grained personal access token attached to a service account. Using a service account is
not strictly required but is recommended in order to ensure _only_ repositories for an
organization are listed -- and not those belonging to a user.

This steers away from the standard advice of using the pre-installed GitHub App that comes with
HCP Terraform. The reason for this is because of the lack of control for the user experience
as mentioned.

The following documents what is needed to setup an OAuth App in your GitHub Organization.

##### Creating a GitHub Service Account

Create a GitHub service account by navigating to https://github.com/signup and creating a new
user with a unique email and username. This user is like any other human user, but will be
configured with a private profile and own no repositories.

When providing permissions for anything accessing the GitHub organization, the following are
required for HCP Terraform's VCS Provider:

- Commit statuses: Read and write
- Contents: Read-only
- Metadata: Read-only
- Webhooks: Read and write

##### Add the Service Account to the GitHub Organization

Once created, add the service account as a member of the GitHub organization being integrated
with HCP Terraform.

##### Create an OAuth App in the GitHub Organization

Navigate to GitHub organization settings -> Developer settings -> OAuth Apps to create a new
OAuth App for the _organization_ (not an individual user).

The Application name, Homepage URL, and Authorization callback URL fields will be populated
with information found in HCP Terraform. Device flow can be enabled if desired, but does
not affect the process either way.

Pause here and open a new window/tab with the HCP Terraform organization open and logged in
as a user with access to add a VCS Provider.

###### Add a VCS Provider

Navigate to HCP Terraform organization settings -> Version Control -> Providers to Add a VCS provider.
Select GitHub -> GitHub.com (Custom) to display the information needed to populate the OAuth application
registration form.

Back in GitHub, within the OAuth App registration window/tab, copy the Application name, Homepage URL,
and Authorization callback URL into the relevant fields in the OAuth App configuration.

Click Register application and copy the Client ID into the Add VCS Provider window in HCP Terraform and
give the VCS Provider the same name as the GitHub organization being configured.

Finally, in the OAuth App, Generate a new client secret, and copy the secret into the Add VCS Provider
window in HCP Terraform.

Click Connect and continue to begin the authorization workflow between HCP Terraform and GitHub. At this
point it is important to be logged into GitHub using your _service account_ created earlier, not your
user account. It is important to note that the email used for the GitHub _service account_ does not need
to be a member of the HCP Terraform organization.
