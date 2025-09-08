#!/bin/bash

# Quick setup script for the Azure ML + Artifactory Lab Environment
# This script helps users get started with the lab deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}=============================================="
    echo -e "$1"
    echo -e "==============================================${NC}"
    echo ""
}

# Function to check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local all_good=true
    
    # Check Terraform
    if command -v terraform &> /dev/null; then
        local tf_version=$(terraform version | head -n1 | cut -d' ' -f2)
        print_status "Terraform installed: $tf_version"
    else
        print_error "Terraform not found. Please install Terraform 1.3 or later."
        echo "  Download from: https://www.terraform.io/downloads.html"
        all_good=false
    fi
    
    # Check Azure CLI
    if command -v az &> /dev/null; then
        local az_version=$(az version --output tsv --query '"azure-cli"')
        print_status "Azure CLI installed: $az_version"
        
        # Check if logged in
        if az account show &> /dev/null; then
            local subscription=$(az account show --query name -o tsv)
            print_status "Logged into Azure: $subscription"
        else
            print_warning "Not logged into Azure. Run 'az login' before deployment."
        fi
    else
        print_error "Azure CLI not found. Please install Azure CLI."
        echo "  Install guide: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        all_good=false
    fi
    
    # Check Docker (optional but recommended)
    if command -v docker &> /dev/null; then
        print_status "Docker installed"
    else
        print_warning "Docker not found. Recommended for building and testing containers."
    fi
    
    return $all_good
}

# Function to initialize Terraform
setup_terraform() {
    print_header "Setting up Terraform"
    
    if [[ ! -f "terraform.tfvars" ]]; then
        print_info "Creating terraform.tfvars from example..."
        cp terraform.tfvars.example terraform.tfvars
        print_status "terraform.tfvars created"
        print_warning "Please edit terraform.tfvars to customize your deployment"
        echo "  Key variables to update:"
        echo "  - admin_password (set a secure password)"
        echo "  - location (choose your preferred Azure region)"
        echo "  - tags (update with your organization info)"
    else
        print_status "terraform.tfvars already exists"
    fi
    
    print_info "Initializing Terraform..."
    if terraform init; then
        print_status "Terraform initialized successfully"
    else
        print_error "Terraform initialization failed"
        return 1
    fi
    
    print_info "Validating Terraform configuration..."
    if terraform validate; then
        print_status "Terraform configuration is valid"
    else
        print_error "Terraform configuration validation failed"
        return 1
    fi
}

# Function to plan deployment
plan_deployment() {
    print_header "Planning Deployment"
    
    print_info "Running terraform plan..."
    if terraform plan -out=tfplan; then
        print_status "Terraform plan completed successfully"
        echo ""
        print_info "Review the plan above. If everything looks good, run:"
        echo -e "${YELLOW}  terraform apply tfplan${NC}"
    else
        print_error "Terraform plan failed"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "Azure ML + Artifactory Lab Setup Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  check      Check prerequisites only"
    echo "  init       Initialize Terraform only"
    echo "  plan       Run terraform plan"
    echo "  all        Run all setup steps (default)"
    echo "  help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                 # Full setup (check, init, plan)"
    echo "  $0 check           # Check prerequisites only"
    echo "  $0 init            # Initialize Terraform only"
    echo ""
}

# Function to show deployment instructions
show_deployment_instructions() {
    print_header "Deployment Instructions"
    
    echo "To deploy the lab environment:"
    echo ""
    echo -e "${YELLOW}1. Review and customize terraform.tfvars:${NC}"
    echo "   nano terraform.tfvars"
    echo ""
    echo -e "${YELLOW}2. Deploy the infrastructure:${NC}"
    echo "   terraform apply tfplan"
    echo "   # Or run: terraform apply"
    echo ""
    echo -e "${YELLOW}3. Get deployment outputs:${NC}"
    echo "   terraform output"
    echo ""
    echo -e "${YELLOW}4. Access your lab:${NC}"
    echo "   - Connect to Windows jumpbox via Azure Bastion"
    echo "   - Use the Artifactory IP from outputs to access Artifactory"
    echo "   - Follow the README.md workflow guide"
    echo ""
    echo -e "${YELLOW}5. Build and test containers:${NC}"
    echo "   ./scripts/build-container.sh -r localhost:8082 -p"
    echo "   ./scripts/generate-artifactory-pat.sh -h <artifactory-ip>"
    echo "   ./scripts/sync-image-to-acr.sh -a <artifactory-ip> -r <acr-name> -i contoso-lab/sample-ml-model"
    echo ""
}

# Main execution
main() {
    local mode="${1:-all}"
    
    case $mode in
        "check")
            check_prerequisites
            ;;
        "init")
            if check_prerequisites; then
                setup_terraform
            fi
            ;;
        "plan")
            if check_prerequisites && setup_terraform; then
                plan_deployment
            fi
            ;;
        "all")
            if check_prerequisites && setup_terraform; then
                plan_deployment
                show_deployment_instructions
            fi
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            echo "Unknown option: $mode"
            show_usage
            exit 1
            ;;
    esac
}

print_header "Azure ML + Artifactory Lab Environment Setup"
echo "This script helps you set up the lab infrastructure using Terraform."
echo ""

main "$@"