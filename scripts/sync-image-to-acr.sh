#!/bin/bash

# Sync container images from Artifactory to Azure Container Registry (ACR)
# This script automates the process of pulling images from Artifactory and pushing to ACR

set -e

# Default values
ARTIFACTORY_PORT="8082"
IMAGE_TAG="latest"

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Sync container images from Artifactory to Azure Container Registry"
    echo ""
    echo "Required Options:"
    echo "  -a, --artifactory   Artifactory host IP address or hostname"
    echo "  -r, --acr          Azure Container Registry name (without .azurecr.io)"
    echo "  -i, --image        Image name/path in Artifactory"
    echo ""
    echo "Optional:"
    echo "  -t, --tag          Image tag (default: latest)"
    echo "  -p, --port         Artifactory port (default: 8082)"
    echo "  --username         Artifactory username for authentication"
    echo "  --password         Artifactory password for authentication"
    echo "  --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -a 10.1.1.4 -r myacr -i contoso-lab/sample-ml-model"
    echo "  $0 -a 10.1.1.4 -r myacr -i contoso-lab/sample-ml-model -t v1.0"
    echo "  $0 -a artifactory.contoso.com -r myacr -i ml-models/pytorch-model --username admin --password mypass"
    echo ""
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--artifactory)
            ARTIFACTORY_HOST="$2"
            shift 2
            ;;
        -r|--acr)
            ACR_NAME="$2"
            shift 2
            ;;
        -i|--image)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -p|--port)
            ARTIFACTORY_PORT="$2"
            shift 2
            ;;
        --username)
            ARTIFACTORY_USERNAME="$2"
            shift 2
            ;;
        --password)
            ARTIFACTORY_PASSWORD="$2"
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
if [[ -z "$ARTIFACTORY_HOST" || -z "$ACR_NAME" || -z "$IMAGE_NAME" ]]; then
    echo "Error: Missing required parameters"
    echo ""
    usage
fi

# Construct image URLs
ARTIFACTORY_IMAGE="${ARTIFACTORY_HOST}:${ARTIFACTORY_PORT}/${IMAGE_NAME}:${IMAGE_TAG}"
ACR_IMAGE="${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}"

echo "=============================================="
echo "Container Image Sync Script"
echo "=============================================="
echo "Source (Artifactory): $ARTIFACTORY_IMAGE"
echo "Target (ACR):         $ACR_IMAGE"
echo "=============================================="
echo ""

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    echo "✗ Docker is not installed or not in PATH"
    echo "Please install Docker and ensure it's running"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "✗ Docker daemon is not running"
    echo "Please start Docker daemon"
    exit 1
fi

echo "✓ Docker is available"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "✗ Azure CLI is not installed or not in PATH"
    echo "Please install Azure CLI"
    exit 1
fi

echo "✓ Azure CLI is available"
echo ""

# Check Azure login status
echo "Checking Azure authentication..."
if ! az account show &> /dev/null; then
    echo "Not logged into Azure. Please log in:"
    az login
    echo ""
fi

CURRENT_SUBSCRIPTION=$(az account show --query "name" -o tsv)
echo "✓ Logged into Azure (Subscription: $CURRENT_SUBSCRIPTION)"
echo ""

# Login to ACR
echo "Logging into Azure Container Registry..."
if az acr login --name "$ACR_NAME"; then
    echo "✓ Successfully logged into ACR: $ACR_NAME"
else
    echo "✗ Failed to login to ACR: $ACR_NAME"
    echo "Please check:"
    echo "  1. ACR name is correct"
    echo "  2. You have permissions to access the ACR"
    echo "  3. The ACR exists in your current subscription"
    exit 1
fi
echo ""

# Docker login to Artifactory if credentials provided
if [[ -n "$ARTIFACTORY_USERNAME" && -n "$ARTIFACTORY_PASSWORD" ]]; then
    echo "Logging into Artifactory Docker registry..."
    if echo "$ARTIFACTORY_PASSWORD" | docker login "${ARTIFACTORY_HOST}:${ARTIFACTORY_PORT}" --username "$ARTIFACTORY_USERNAME" --password-stdin; then
        echo "✓ Successfully logged into Artifactory"
    else
        echo "✗ Failed to login to Artifactory"
        echo "Please check your credentials"
        exit 1
    fi
    echo ""
fi

# Pull image from Artifactory
echo "Pulling image from Artifactory..."
echo "docker pull $ARTIFACTORY_IMAGE"
if docker pull "$ARTIFACTORY_IMAGE"; then
    echo "✓ Successfully pulled image from Artifactory"
else
    echo "✗ Failed to pull image from Artifactory"
    echo "Please check:"
    echo "  1. Image exists in Artifactory"
    echo "  2. Image name and tag are correct"
    echo "  3. Network connectivity to Artifactory"
    echo "  4. Authentication credentials (if required)"
    exit 1
fi
echo ""

# Tag image for ACR
echo "Tagging image for ACR..."
echo "docker tag $ARTIFACTORY_IMAGE $ACR_IMAGE"
if docker tag "$ARTIFACTORY_IMAGE" "$ACR_IMAGE"; then
    echo "✓ Successfully tagged image"
else
    echo "✗ Failed to tag image"
    exit 1
fi
echo ""

# Push image to ACR
echo "Pushing image to ACR..."
echo "docker push $ACR_IMAGE"
if docker push "$ACR_IMAGE"; then
    echo "✓ Successfully pushed image to ACR"
else
    echo "✗ Failed to push image to ACR"
    echo "Please check your ACR permissions"
    exit 1
fi
echo ""

# Clean up local images (optional)
read -p "Remove local images to save disk space? (y/N): " cleanup
if [[ "$cleanup" == "y" || "$cleanup" == "Y" ]]; then
    echo "Removing local images..."
    docker rmi "$ARTIFACTORY_IMAGE" "$ACR_IMAGE" || true
    echo "✓ Local images removed"
    echo ""
fi

echo "=============================================="
echo "✓ Image sync completed successfully!"
echo ""
echo "Image Details:"
echo "  Source: $ARTIFACTORY_IMAGE"
echo "  Target: $ACR_IMAGE"
echo ""
echo "Next Steps:"
echo "1. The image is now available in your ACR"
echo "2. Configure Azure ML to use this image"
echo "3. Create an Azure ML environment referencing: $ACR_IMAGE"
echo "=============================================="