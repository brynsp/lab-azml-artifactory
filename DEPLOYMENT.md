# Deployment Checklist for Azure ML + Artifactory Lab

This checklist helps ensure a successful deployment of the lab environment.

## Pre-Deployment

- [ ] **Prerequisites Installed**
  - [ ] Terraform 1.3 or later
  - [ ] Azure CLI latest version
  - [ ] Docker (optional, for local testing)
  
- [ ] **Azure Setup**
  - [ ] Azure subscription with Owner or Contributor access
  - [ ] Sufficient resource quotas:
    - [ ] 2 x Standard_D2s_v3 VMs
    - [ ] 1 x Azure Container Registry (Premium SKU)
    - [ ] 1 x Azure Bastion
    - [ ] Virtual Networks and subnets
  
- [ ] **Configuration**
  - [ ] Copy `terraform.tfvars.example` to `terraform.tfvars`
  - [ ] Update variables in `terraform.tfvars`:
    - [ ] Set secure `admin_password`
    - [ ] Choose appropriate `location`
    - [ ] Update `tags` with your organization info
  
## Deployment Steps

- [ ] **Initialize Terraform**
  ```bash
  terraform init
  ```
  
- [ ] **Validate Configuration**
  ```bash
  terraform validate
  ```
  
- [ ] **Plan Deployment**
  ```bash
  terraform plan -out=tfplan
  ```
  
- [ ] **Review Plan Output**
  - [ ] Verify resource names and counts
  - [ ] Check network configuration
  - [ ] Confirm resource locations
  
- [ ] **Deploy Infrastructure** (15-20 minutes)
  ```bash
  terraform apply tfplan
  ```
  
- [ ] **Capture Outputs**
  ```bash
  terraform output > deployment-info.txt
  ```

## Post-Deployment Verification

- [ ] **Access Validation**
  - [ ] Connect to Windows jumpbox via Azure Bastion
  - [ ] SSH to Ubuntu VM from jumpbox
  - [ ] Access Artifactory at http://<vm-ip>:8082 (admin/password)
  
- [ ] **Service Health**
  - [ ] Artifactory container running (`docker ps`)
  - [ ] Azure ML workspace accessible
  - [ ] ACR login successful (`az acr login --name <acr-name>`)
  - [ ] Key Vault accessible

## Lab Workflow Testing

- [ ] **Container Image Workflow**
  - [ ] Build sample container image
  ```bash
  ./scripts/build-container.sh -r localhost:8082 -p
  ```
  
  - [ ] Generate Artifactory PAT
  ```bash
  ./scripts/generate-artifactory-pat.sh -h <artifactory-ip>
  ```
  
  - [ ] Sync image to ACR
  ```bash
  ./scripts/sync-image-to-acr.sh -a <artifactory-ip> -r <acr-name> -i contoso-lab/sample-ml-model
  ```
  
  - [ ] Deploy in Azure ML
    - [ ] Create environment from ACR image
    - [ ] Deploy to managed endpoint
    - [ ] Test inference

## Troubleshooting

- [ ] **Common Issues Resolved**
  - [ ] VM startup delays (wait 2-3 minutes)
  - [ ] Artifactory container initialization (check logs)
  - [ ] Private endpoint DNS resolution
  - [ ] Network security group rules
  - [ ] Managed identity permissions

## Cleanup

- [ ] **Save Important Data**
  - [ ] Export any custom images from ACR
  - [ ] Save PAT tokens if needed for other environments
  
- [ ] **Destroy Infrastructure**
  ```bash
  terraform destroy
  # OR
  az group delete --name rg-lab-azml-artifactory
  ```

## Success Criteria

✅ **Lab is successfully deployed when:**
- All Azure resources are created and healthy
- Windows jumpbox accessible via Bastion
- Artifactory accessible and functional
- Sample container can be built and pushed to Artifactory
- Container can be synced from Artifactory to ACR
- Azure ML workspace can deploy the ACR image
- End-to-end workflow completes successfully

---

**Estimated Total Time:** 30-45 minutes
**Estimated Cost:** $300-400 USD/month (varies by region and usage)