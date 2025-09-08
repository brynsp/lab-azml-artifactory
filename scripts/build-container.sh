#!/bin/bash

# Build script for the Contoso Lab sample container
# This script builds the container image and optionally pushes it to a registry

set -e

# Default values
IMAGE_NAME="contoso-lab/sample-ml-model"
IMAGE_TAG="latest"
BUILD_CONTEXT="./examples/docker"
REGISTRY=""
PUSH=false

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Build and optionally push the Contoso Lab sample container image"
    echo ""
    echo "Options:"
    echo "  -n, --name          Image name (default: contoso-lab/sample-ml-model)"
    echo "  -t, --tag           Image tag (default: latest)"
    echo "  -r, --registry      Registry URL (e.g., localhost:8082 or myacr.azurecr.io)"
    echo "  -p, --push          Push image to registry after building"
    echo "  -c, --context       Build context directory (default: ./examples/docker)"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                           # Build image locally"
    echo "  $0 -r localhost:8082 -p                     # Build and push to Artifactory"
    echo "  $0 -r myacr.azurecr.io -p -t v1.0           # Build and push to ACR with tag"
    echo ""
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -p|--push)
            PUSH=true
            shift
            ;;
        -c|--context)
            BUILD_CONTEXT="$2"
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

# Construct full image name
if [[ -n "$REGISTRY" ]]; then
    FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
else
    FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"
fi

echo "=============================================="
echo "Contoso Lab Container Build Script"
echo "=============================================="
echo "Image Name: $FULL_IMAGE_NAME"
echo "Build Context: $BUILD_CONTEXT"
echo "Push to Registry: $PUSH"
echo "=============================================="
echo ""

# Check if Docker is available
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

# Check if build context exists
if [[ ! -d "$BUILD_CONTEXT" ]]; then
    echo "✗ Build context directory not found: $BUILD_CONTEXT"
    exit 1
fi

echo "✓ Build context exists: $BUILD_CONTEXT"

# Copy scoring script to build context if needed
if [[ -f "./examples/azure-ml/score.py" && ! -f "$BUILD_CONTEXT/score.py" ]]; then
    echo "Copying score.py to build context..."
    cp "./examples/azure-ml/score.py" "$BUILD_CONTEXT/"
    echo "✓ score.py copied"
fi

echo ""

# Build the container image
echo "Building container image..."
echo "docker build -t $FULL_IMAGE_NAME $BUILD_CONTEXT"
echo ""

if docker build -t "$FULL_IMAGE_NAME" "$BUILD_CONTEXT"; then
    echo ""
    echo "✓ Container image built successfully!"
    echo "Image: $FULL_IMAGE_NAME"
else
    echo "✗ Failed to build container image"
    exit 1
fi

echo ""

# Display image information
echo "Image details:"
docker images "$FULL_IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
echo ""

# Push to registry if requested
if [[ "$PUSH" == "true" ]]; then
    if [[ -z "$REGISTRY" ]]; then
        echo "✗ Cannot push: no registry specified"
        echo "Use -r/--registry to specify a registry URL"
        exit 1
    fi
    
    echo "Pushing image to registry..."
    echo "docker push $FULL_IMAGE_NAME"
    echo ""
    
    if docker push "$FULL_IMAGE_NAME"; then
        echo ""
        echo "✓ Image pushed successfully!"
        echo "Image available at: $FULL_IMAGE_NAME"
    else
        echo "✗ Failed to push image"
        echo "Please check:"
        echo "  1. Registry URL is correct: $REGISTRY"
        echo "  2. You are logged into the registry"
        echo "  3. You have push permissions"
        exit 1
    fi
fi

echo ""
echo "=============================================="
echo "Build completed successfully!"
echo ""
echo "Next steps:"
if [[ "$PUSH" != "true" ]]; then
    echo "1. Push to Artifactory:"
    echo "   docker push $FULL_IMAGE_NAME"
fi
echo "2. Sync from Artifactory to ACR using:"
echo "   ./scripts/sync-image-to-acr.sh -a <artifactory-ip> -r <acr-name> -i $IMAGE_NAME -t $IMAGE_TAG"
echo "3. Deploy to Azure ML using the ACR image"
echo "=============================================="