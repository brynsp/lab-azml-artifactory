# Terraform IaC for AML + Artifactory Lab

This Terraform configuration provisions:

- Resource group, VNets/subnets, peering
- Storage accounts (ML, ADLS Gen2, Artifactory) and Azure Files share
- Key Vault
- Private DNS zones + VNet links
- Private Endpoints + DNS zone groups (storage, KV, AML)
- NAT Gateway + Public IP for ACI outbound
- ACI for Artifactory with Azure Files mount
- Bastion (Basic) + small Linux jumpbox VM
- Azure ML Workspace (private access, managed network)

Deterministic naming is derived from subscriptionId + resource group, keeping names stable across runs.

## Quick start

Authentication and subscription/tenant

- The provider will use your Azure CLI login by default. If you need to pin a specific subscription/tenant, export these before running Terraform:

```bash
export TF_VAR_subscription_id="<your-subscription-guid>"
export TF_VAR_tenant_id="<your-tenant-guid>"
```

Safe command sequence (won't kill the shell on an error):

```bash
cd infra/terraform
terraform init -upgrade || true
terraform validate || true
terraform plan -out tfplan || true
```

Apply when ready:

```bash
terraform apply tfplan
```
