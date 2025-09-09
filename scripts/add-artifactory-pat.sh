#!/usr/bin/env bash
set -euo pipefail

# Add (or update) an Artifactory PAT secret in a private Key Vault after Terraform deploy.
# This is required because a policy blocks public network access + shared key auth, so
# Terraform cannot create a placeholder secret during provisioning.
#
# Requirements:
#  - Run this from a host that can resolve & reach the Key Vault private endpoint (e.g. jumpbox)
#  - Azure CLI logged in (az login) with access to the subscription
#  - The user / MI has 'set' permission on secrets (already granted by the module's access policy)
#
# Usage examples:
#   ./scripts/add-artifactory-pat.sh -k $(terraform output -raw key_vault_name) -t <token>
#   ./scripts/add-artifactory-pat.sh -k my-kv-name -f pat.txt
#   ./scripts/add-artifactory-pat.sh -k my-kv-name (will prompt securely for value)
#
# Options:
#   -k  Key Vault name (required)
#   -n  Secret name (default: artifactory-pat)
#   -t  Secret value (PAT) provided inline
#   -f  File containing the secret value
#   -s  Azure subscription ID (optional; otherwise current context is used)
#   -h  Help

SECRET_NAME="artifactory-pat"
KV_NAME=""
VALUE=""
VALUE_FILE=""
SUBSCRIPTION_ID=""

usage() {
  grep '^#' "$0" | sed -e 's/^# //'
}

while getopts ":k:n:t:f:s:h" opt; do
  case $opt in
    k) KV_NAME="$OPTARG" ;;
    n) SECRET_NAME="$OPTARG" ;;
    t) VALUE="$OPTARG" ;;
    f) VALUE_FILE="$OPTARG" ;;
    s) SUBSCRIPTION_ID="$OPTARG" ;;
    h) usage; exit 0 ;;
    :) echo "Error: -$OPTARG requires an argument" >&2; exit 1 ;;
    \?) echo "Error: invalid option -$OPTARG" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$KV_NAME" ]]; then
  echo "Error: Key Vault name (-k) is required" >&2
  usage
  exit 1
fi

if [[ -n "$VALUE_FILE" && -n "$VALUE" ]]; then
  echo "Error: specify either -t or -f, not both" >&2
  exit 1
fi

if [[ -n "$VALUE_FILE" ]]; then
  if [[ ! -f "$VALUE_FILE" ]]; then
    echo "Error: file not found: $VALUE_FILE" >&2
    exit 1
  fi
  VALUE=$(<"$VALUE_FILE")
fi

if [[ -z "$VALUE" ]]; then
  # Prompt silently
  read -rsp "Enter secret value for $SECRET_NAME: " VALUE
  echo
  if [[ -z "$VALUE" ]]; then
    echo "Error: secret value cannot be empty" >&2
    exit 1
  fi
fi

# Optional subscription targeting
SUB_ARG=()
if [[ -n "$SUBSCRIPTION_ID" ]]; then
  SUB_ARG=(--subscription "$SUBSCRIPTION_ID")
fi

echo "Setting secret '$SECRET_NAME' in Key Vault '$KV_NAME'..."
set +e
OUTPUT=$(az keyvault secret set --vault-name "$KV_NAME" --name "$SECRET_NAME" --value "$VALUE" "${SUB_ARG[@]}" -o json 2>&1)
STATUS=$?
set -e

if [[ $STATUS -ne 0 ]]; then
  echo "$OUTPUT" >&2
  if grep -qi 'Public network access is disabled' <<< "$OUTPUT"; then
    echo "Hint: run this script from a host inside the VNet with private DNS resolution (e.g. the jumpbox)." >&2
  fi
  exit $STATUS
fi

echo "✅ Secret '$SECRET_NAME' stored successfully."
# Print short metadata (avoid echoing secret value back)
SECRET_ID=$(echo "$OUTPUT" | sed -n 's/.*"id": "\(https:[^"]*\)".*/\1/p')
if [[ -n "$SECRET_ID" ]]; then
  echo "Secret ID: $SECRET_ID"
fi
