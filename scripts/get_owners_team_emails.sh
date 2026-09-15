#!/bin/sh

# get_owners_team_emails - Get the set of emails associated with the owners
#                          team in HCP Terraform.
#
# This script queries the HCP Terraform API to retrieve the email addresses
# of the users in the owners team. It is expected to be used with the
# external data source and so the inputs and outputs obey a specific protocol
# as defined in the provider documentation.
#
# Usage:
# Ensure `TFE_TOKEN` is set to a "Team Token" for the _owners_ team before
# running:
# $ export TFE_TOKEN="your-token-here"
#
# Then add the following Terraform code to your root module:
# data "external" "owners_team_emails" {
#   program = ["sh", "${path.module}/scripts/get_owners_team_emails.sh"]
#
#   query = {
#     owners_team_id = data.tfe_team.owners.id
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

# main prints the emails of the owners team members that are not service
# accounts as an external data source result.
main() {
  owners_team_id="$(jq -r '.owners_team_id // empty')"
  : "${owners_team_id:?"<-- this required query argument is not set."}"

  owners_team_json="$(tfe_api_get "/teams/${owners_team_id}?include=organization-memberships,users")"

  # Service accounts are excluded to match the tfe_team_organization_members
  # resource, which ignores them when reading a team's members.
  printf '%s\n' "${owners_team_json}" |
    jq '
      (
        [.included[]? | select(.type == "users" and .attributes."is-service-account") | {key: .id, value: true}]
        | from_entries
      ) as $service_accounts
      | [
          .included[]? | select(.type == "organization-memberships")
          | select($service_accounts[.relationships.user.data.id // ""] | not)
          | .attributes.email
        ]
      | {emails: (unique | tojson)}
    '
}

main "$@"
