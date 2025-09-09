# Azure ML + Artifactory Lab Environment

A Terraform-based Azure lab environment for testing secure container image deployment from a simulated JFrog Artifactory registry to an Azure Machine Learning (Azure ML) workspace. This lab reproduces and helps resolve authentication and connectivity issues encountered when using third-party container registries with private endpoints and strict security controls.

## Overview

This lab environment provides a minimal, cost-effective simulation of a real enterprise setup, suitable for validating solutions before customer rollout. It models Contoso's enterprise requirements for private networking, authentication, and secure container deployment workflows.

## Architecture

### Network Segmentation

- **ML VNet** (`10.0.0.0/16`): Hosts Azure ML workspace and related private endpoints
- **Compute VNet** (`10.1.0.0/16`): Hosts Artifactory VM, jumpbox, and compute private endpoints
- **VNet Peering**: Enables communication between ML and Compute VNets
- **Private Endpoints**: All Azure services (ACR, Storage, Key Vault, ML workspace) use private endpoints
- **Azure Private DNS Zones**: Provides name resolution for private endpoints

### Resources

| Resource Type | Name Pattern | Purpose |
|---------------|--------------|---------|
| Resource Group | `rg-lab-azml-artifactory` | Contains all lab resources |
| ML VNet | `lab-azml-artifactory-ml-vnet` | Network for ML workspace |
| Compute VNet | `lab-azml-artifactory-compute-vnet` | Network for VMs and compute |
| Ubuntu VM | `lab-azml-artifactory-artifactory-vm` | Hosts JFrog Artifactory OSS |
| Windows VM | `lab-azml-artifactory-jumpbox-vm` | Management jumpbox |
| Azure Bastion | `lab-azml-artifactory-bastion` | Secure VM access |
| Azure ML Workspace | `lab-azml-artifactory-ml-workspace` | ML workspace with private endpoints |
| ACR | `labazmlartifactory<random>` | Azure Container Registry |
| Key Vault | `lab-azml-artifactory-kv-<random>` | Stores PAT and secrets |
| Storage Account | `labazmlartifactorysk<random>` | ML workspace storage |

### Authentication Model

- **Azure Resources**: Managed identities where possible
- **Artifactory**: Personal Access Token (PAT) authentication
- **ACR Integration**: ML workspace has AcrPull role assignment

## Prerequisites

- **Azure CLI**: Latest version installed and authenticated
- **Terraform**: Version 1.3 or later
- **Azure Subscription**: With Owner or Contributor permissions
- **Resource Quota**: Ensure sufficient quota for VMs, Bastion, and ACR Premium

## Quick Start

### 1. Clone and Initialize

```bash
git clone https://github.com/brynsp/lab-azml-artifactory.git
cd lab-azml-artifactory

# Initialize Terraform
terraform init
```

### 2. Deploy Infrastructure

```bash
# Plan the deployment
terraform plan

# Apply the configuration (takes 15-20 minutes)
terraform apply
```

### 3. Access the Lab

After deployment, note the output values:

```bash
terraform output
```

### 4. (Post-Deploy) Add Artifactory PAT Secret to Key Vault

The Key Vault is deployed with public network access disabled. A placeholder secret is NOT created during `terraform apply` to avoid policy blocks. After deployment, add the PAT from a host with private network access (e.g. the jumpbox) using the helper script:

```bash
# On the jumpbox or any machine resolving the Key Vault private endpoint
./scripts/add-artifactory-pat.sh -k $(terraform output -raw key_vault_name) -t <your_pat>
```

Alternative (prompt for value):

```bash
./scripts/add-artifactory-pat.sh -k $(terraform output -raw key_vault_name)
```

From a different subscription context:

```bash
./scripts/add-artifactory-pat.sh -k <kv-name> -s <subscription-id> -f pat.txt
```

If you see an error mentioning `Public network access is disabled`, ensure you're running inside the VNet (the Windows jumpbox) or have proper private DNS resolution on your host.

## Workflow Guide

### Step 1: Access Jumpbox

1. In Azure Portal, navigate to your resource group
2. Find the Azure Bastion resource
3. Connect to the Windows jumpbox VM using Bastion
4. Credentials: Use the admin_username/admin_password from your variables

### Step 2: Build and Push Sample Image to Artifactory

1. On the jumpbox, open Command Prompt or PowerShell
2. Connect to the Artifactory VM (use private IP from Terraform output):

   ```bash
   ssh ubuntu@<artifactory-vm-private-ip>
   ```

3. Build the sample container image:

   ```bash
   /home/ubuntu/build-sample-image.sh
   ```

4. Configure Docker to use Artifactory:

   ```bash
   # Create local repository in Artifactory (via web UI at http://localhost:8082)
   # Default credentials: admin/password
   
   # Login to local Artifactory Docker registry
   docker login localhost:8082
   
   # Push the sample image
   docker push localhost:8082/contoso-lab/sample-ml-model:latest
   ```

### Step 3: Generate Artifactory PAT

Use the provided script to generate a Personal Access Token:

```bash
# From the repository root
./scripts/generate-artifactory-pat.sh -h <artifactory-vm-private-ip> -u admin -p password
```

**Sample Script Output:**

```bash
✓ PAT generated successfully!

Response:
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...",
  "expires_in": 3600,
  "scope": "member-of-groups:readers",
  "token_type": "Bearer"
}

==============================================
ACCESS TOKEN (save this for Azure ML config):
eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...
==============================================
```

Store this token securely in Azure Key Vault or as a secret in your ML workspace.

To store it in Key Vault (private access):

```bash
./scripts/add-artifactory-pat.sh -k $(terraform output -raw key_vault_name) -t <access-token>
```

### Step 4: Sync Image from Artifactory to ACR

```bash
# Use the sync script to move images from Artifactory to ACR
./scripts/sync-image-to-acr.sh \
  -a <artifactory-vm-private-ip> \
  -r <acr-name> \
  -i contoso-lab/sample-ml-model \
  -t latest
```

### Step 5: Configure Azure ML Environment

1. Access Azure ML Studio through the private endpoint
2. Create a new environment referencing the ACR image:

   ```yaml
   name: contoso-artifactory-env
   image: <acr-name>.azurecr.io/contoso-lab/sample-ml-model:latest
   description: "Test environment from Artifactory"
   ```

### Step 6: Deploy and Test

1. Create a simple scoring script
2. Deploy to a managed online endpoint
3. Test image pull and deployment functionality

## PAT Generation Details

### Using JFrog REST API

```bash
curl -u <USERNAME>:<PASSWORD> -X POST "<ARTIFACTORY_URL>/artifactory/api/security/token" \
  -d "username=<USERNAME>" \
  -d "scope=member-of-groups:readers"
```

### Response Format

```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...",
  "expires_in": 3600,
  "scope": "member-of-groups:readers",
  "token_type": "Bearer"
}
```

### Secure Storage Options

1. **Azure Key Vault** (Recommended):

   ```bash
   az keyvault secret set \
     --vault-name <key-vault-name> \
     --name "artifactory-pat" \
     --value "<access-token>"
   ```

2. **Azure ML Workspace Secret**:

   ```python
   from azure.ai.ml import MLClient
   client = MLClient.from_config()
   client.connections.create_or_update(
       name="artifactory-connection",
       credentials={"pat": "<access-token>"}
   )
   ```

## Testing and Validation

### Verify Artifactory Access

```bash
# Test Artifactory API
curl -H "Authorization: Bearer <PAT>" \
  http://<artifactory-ip>:8082/artifactory/api/system/ping

# Test Docker registry
docker login <artifactory-ip>:8082 -u <username> -p <PAT>
```

### Verify ACR Integration

```bash
# Test ACR login with ML workspace managed identity
az acr login --name <acr-name>

# Pull image from ACR
docker pull <acr-name>.azurecr.io/contoso-lab/sample-ml-model:latest
```

### Common Error Resolution

| Error | Cause | Resolution |
|-------|-------|------------|
| `401 Unauthorized` | Invalid PAT or expired token | Regenerate PAT using script |
| `Empty directory tree` | Network connectivity issue | Check private endpoint configuration |
| `Image pull failed` | Missing AcrPull permissions | Verify ML workspace role assignment |
| `Connection timeout` | Private endpoint not resolved | Check DNS zone configuration |

## Customization

### Variables

Customize the deployment by modifying `terraform.tfvars`:

```hcl
# terraform.tfvars
location = "canadacentral"
resource_group_name = "rg-lab-azml-artifactory"
admin_username = "labadmin"
admin_password = "YourSecurePassword123!"
enable_bastion = true

tags = {
  Environment = "Lab"
  Project     = "AzureML-Artifactory"
  Owner       = "Contoso"
}
```

### Network Configuration

Modify network ranges in `locals.tf`:

```hcl
ml_vnet_address_space      = ["10.0.0.0/16"]
compute_vnet_address_space = ["10.1.0.0/16"]
```

## Cost Optimization

- **VM Sizes**: Default to `Standard_D2s_v3` (adjust based on needs)
- **ACR SKU**: Uses Premium (required for private endpoints)
- **Storage**: Standard LRS for cost efficiency
- **Auto-shutdown**: Configure VM auto-shutdown schedules

Estimated monthly cost: ~$300-400 USD (varies by region and usage)

## Security Considerations

- All Azure services use private endpoints
- Public network access disabled where possible
- VM access only through Azure Bastion
- Managed identities preferred over service principals
- Secrets stored in Azure Key Vault
- Network security groups restrict traffic

## Troubleshooting

### Deployment Issues

1. **Resource naming conflicts**: Random suffixes prevent conflicts
2. **Quota limits**: Check regional VM and ACR quotas
3. **Permission errors**: Ensure account has Owner/Contributor role

### Runtime Issues

1. **Artifactory not accessible**:
   - Wait 2-3 minutes after VM deployment
   - Check NSG rules and VM status

2. **Private endpoint resolution**:
   - Verify DNS zone links
   - Test nslookup from VMs

3. **Image pull failures**:
   - Check managed identity roles
   - Verify ACR permissions

### Useful Commands

```bash
# Check VM status
az vm list --resource-group rg-lab-azml-artifactory --output table

# Test private endpoint connectivity
az network private-endpoint list --resource-group rg-lab-azml-artifactory

# View ACR repositories
az acr repository list --name <acr-name>

# Check ML workspace endpoints
az ml workspace show --name <workspace-name> --resource-group rg-lab-azml-artifactory
```

## Teardown

### Complete Environment Cleanup

```bash
# Destroy all resources
terraform destroy

# Or delete the entire resource group
az group delete --name rg-lab-azml-artifactory --yes --no-wait
```

### Selective Cleanup

```bash
# Stop VMs to save costs
az vm deallocate --resource-group rg-lab-azml-artifactory --name lab-azml-artifactory-artifactory-vm
az vm deallocate --resource-group rg-lab-azml-artifactory --name lab-azml-artifactory-jumpbox-vm
```

## Support

For issues and questions:

1. Check the troubleshooting section above
2. Review Azure Activity Logs for deployment errors
3. Validate Terraform configuration with `terraform validate`
4. Check resource logs in Azure Portal

## References

- [JFrog Artifactory REST API Documentation](https://jfrog.com/help/r/jfrog-rest-apis/token-management-rest-api)
- [Azure ML Private Endpoints](https://docs.microsoft.com/en-us/azure/machine-learning/how-to-configure-private-link)
- [Azure Container Registry with Private Endpoints](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-private-link)
- [Azure Verified Modules (AVM)](https://azure.github.io/Azure-Verified-Modules/)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
