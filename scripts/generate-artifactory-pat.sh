#!/bin/bash

# Generate Artifactory Personal Access Token (PAT)
# This script creates an access token for authenticating with Artifactory

set -e

# Default values
ARTIFACTORY_USERNAME="admin"
ARTIFACTORY_PASSWORD="password"
ARTIFACTORY_URL=""

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Generate a Personal Access Token (PAT) for JFrog Artifactory authentication"
    echo ""
    echo "Options:"
    echo "  -u, --username      Artifactory username (default: admin)"
    echo "  -p, --password      Artifactory password (default: password)"
    echo "  -h, --host          Artifactory host IP address or hostname"
    echo "  --port              Artifactory port (default: 8082)"
    echo "  --help              Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 -h 10.1.1.4 -u admin -p mypassword"
    echo ""
    exit 1
}

# Parse command line arguments
ARTIFACTORY_PORT="8082"
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--username)
            ARTIFACTORY_USERNAME="$2"
            shift 2
            ;;
        -p|--password)
            ARTIFACTORY_PASSWORD="$2"
            shift 2
            ;;
        -h|--host)
            ARTIFACTORY_HOST="$2"
            shift 2
            ;;
        --port)
            ARTIFACTORY_PORT="$2"
            shift 2
            ;;
        --help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [[ -z "$ARTIFACTORY_HOST" ]]; then
    echo "Error: Artifactory host is required"
    echo "Use -h or --host to specify the Artifactory host IP address"
    echo ""
    usage
fi

ARTIFACTORY_URL="http://${ARTIFACTORY_HOST}:${ARTIFACTORY_PORT}"

echo "=============================================="
echo "Artifactory PAT Generation Script"
echo "=============================================="
echo "Artifactory URL: $ARTIFACTORY_URL"
echo "Username: $ARTIFACTORY_USERNAME"
echo "=============================================="
echo ""

# Check if Artifactory is accessible
echo "Checking Artifactory accessibility..."
if ! curl -f -s --connect-timeout 10 "$ARTIFACTORY_URL/artifactory/api/system/ping" > /dev/null; then
    echo "Error: Cannot connect to Artifactory at $ARTIFACTORY_URL"
    echo "Please ensure:"
    echo "  1. Artifactory is running"
    echo "  2. The host IP address is correct"
    echo "  3. Network connectivity is available"
    exit 1
fi

echo "✓ Artifactory is accessible"
echo ""

# Generate PAT using JFrog REST API
echo "Generating Personal Access Token..."
echo ""

RESPONSE=$(curl -s -u "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" \
    -X POST "${ARTIFACTORY_URL}/artifactory/api/security/token" \
    -d "username=${ARTIFACTORY_USERNAME}" \
    -d "scope=member-of-groups:readers" \
    -w "\nHTTP_CODE:%{http_code}")

# Extract HTTP status code
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | sed 's/.*HTTP_CODE://')
RESPONSE_BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE:/d')

if [[ "$HTTP_CODE" -eq 200 ]]; then
    echo "✓ PAT generated successfully!"
    echo ""
    echo "Response:"
    echo "$RESPONSE_BODY" | jq '.' 2>/dev/null || echo "$RESPONSE_BODY"
    echo ""
    
    # Extract access token if jq is available
    if command -v jq &> /dev/null; then
        ACCESS_TOKEN=$(echo "$RESPONSE_BODY" | jq -r '.access_token' 2>/dev/null)
        if [[ "$ACCESS_TOKEN" != "null" && -n "$ACCESS_TOKEN" ]]; then
            echo "=============================================="
            echo "ACCESS TOKEN (save this for Azure ML config):"
            echo "$ACCESS_TOKEN"
            echo "=============================================="
            echo ""
            
            # Optionally save to file
            read -p "Save token to file? (y/N): " save_to_file
            if [[ "$save_to_file" == "y" || "$save_to_file" == "Y" ]]; then
                TOKEN_FILE="artifactory-pat-$(date +%Y%m%d-%H%M%S).txt"
                echo "$ACCESS_TOKEN" > "$TOKEN_FILE"
                echo "✓ Token saved to: $TOKEN_FILE"
                echo ""
            fi
        fi
    fi
    
    echo "Next Steps:"
    echo "1. Copy the access_token value from above"
    echo "2. Store this token securely in Azure Key Vault or as a secret in your ML workspace"
    echo "3. Use this token for authenticating Azure ML to Artifactory"
    echo ""
    
else
    echo "✗ Failed to generate PAT"
    echo "HTTP Status Code: $HTTP_CODE"
    echo "Response: $RESPONSE_BODY"
    echo ""
    echo "Common issues:"
    echo "  - Incorrect username/password"
    echo "  - Artifactory not fully initialized (wait a few minutes after startup)"
    echo "  - Network connectivity issues"
    exit 1
fi