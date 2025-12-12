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
