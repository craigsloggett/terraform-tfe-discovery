#!/bin/sh

# get_variable_set_names - Get the names of the variable sets configured in an
#                          HCP Terraform organization.
#
# This script queries the HCP Terraform API to retrieve the variable sets
# configured in an organization. It is expected to be used with the external
# data source and so the inputs and outputs obey a specific protocol as
# defined in the provider documentation.
#
# Usage:
# Ensure `TFE_TOKEN` is set to a "Team Token" for the _owners_ team before
# running:
# $ export TFE_TOKEN="your-token-here"
#
# Then add the following Terraform code to your root module:
# data "external" "variable_set_names" {
#   program = ["sh", "${path.module}/scripts/get_variable_sets.sh"]
#
#   query = {
#     organization_name = data.tfe_organization.this.name
#   }
# }
#
# Dependencies:
#   - jq (for JSON parsing)
#   - curl (for querying the API)
set -euf

# Ensure required environment variables have been set.
: "${TFE_TOKEN:?"<-- this required environment variable is not set."}"

# Check if the required utilities are installed.
for utility in jq curl; do
  if ! command -v "${utility}" >/dev/null 2>&1; then
    printf '%s\n' "Error: ${utility} is not installed." >&2
    exit 1
  fi
done

# tfe_api_get prints the body of a successful GET request to the HCP Terraform
# API and fails with the API's error response otherwise.
tfe_api_get() (
  path="${1:?path is required}"

  # A retried request appends its body to stdout, so the body goes to a file
  # that curl truncates on each attempt.
  body="$(mktemp)"
  trap 'rm -f "${body}"' EXIT INT TERM HUP

  # The tfe provider retries rate limited requests, but curl only does so when
  # asked, and a plan can exceed the API's rate limit on its own.
  status="$(
    curl --silent --show-error --retry 5 \
      --header "Authorization: Bearer ${TFE_TOKEN}" \
      --header "Content-Type: application/vnd.api+json" \
      --output "${body}" \
      --write-out '%{http_code}' \
      "https://app.terraform.io/api/v2${path}"
  )"

  case "${status}" in
    2??)
      cat "${body}"
      ;;
    *)
      printf '%s\n' "Error: GET ${path} returned HTTP ${status}: $(cat "${body}")" >&2
      return 1
      ;;
  esac
)

# main prints the names of the variable sets as an external data source result.
main() {
  organization_name="$(jq -r '.organization_name // empty')"
  : "${organization_name:?"<-- this required query argument is not set."}"

  variable_sets_json="$(tfe_api_get "/organizations/${organization_name}/varsets")"

  printf '%s\n' "${variable_sets_json}" |
    jq '{names: ([.data[].attributes.name] | unique | tojson)}'
}

main "$@"
