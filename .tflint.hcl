config {
  format              = "default"
  call_module_type    = "all"
  force               = false
  disabled_by_default = false
}

# Disallow specifying a git repository as a module source without pinning to a version.
rule "terraform_module_pinned_source" {
  enabled = true
  style   = "semver"
}

# Checks that Terraform modules sourced from a registry specify a version.
rule "terraform_module_version" {
  enabled = true
  exact   = true
}

# Enforces naming conventions for resources, data sources, etc.
rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

plugin "terraform" {
  enabled = true
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
  version = "0.13.0"
  preset  = "all"
}
