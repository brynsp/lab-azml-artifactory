# Troubleshooting Guide for Azure ML + Artifactory Lab

This guide helps resolve common issues encountered during lab deployment and usage.

## Deployment Issues

### Terraform Errors

**Problem:** Resource naming conflicts
```
Error: A resource with the ID already exists
```
**Solution:**
- Random suffixes are used to prevent conflicts
- If still encountering issues, change the `name_prefix` in variables
- Clean up any partially created resources: `terraform destroy`

**Problem:** Insufficient quotas
```
Error: Quota exceeded for resource type
```
**Solution:**
- Check regional quotas in Azure Portal
- Request quota increases for:
  - Standard_D2s_v3 VMs (need 2)
  - Premium Container Registry
  - Azure Bastion
- Consider using different VM sizes or regions

**Problem:** Permission denied
```
Error: Authorization failed
```
**Solution:**
- Ensure your account has Owner or Contributor role
- Check if subscription is active
- Re-run `az login` to refresh credentials

### Resource Creation Timeouts

**Problem:** Bastion deployment takes too long
**Solution:**
- Bastion can take 10-15 minutes to deploy
- Increase timeout if using custom Terraform
- Check Azure Portal for deployment status

**Problem:** Private endpoints not resolving
**Solution:**
- DNS zones need 5-10 minutes to propagate
- Test resolution from VMs: `nslookup <service>.privatelink.domain`
- Verify VNet links to private DNS zones

## Runtime Issues

### VM Access Problems

**Problem:** Cannot connect to jumpbox via Bastion
**Solution:**
- Ensure Azure Bastion deployment completed
- Check NSG rules allow RDP (port 3389)
- VM may still be starting (wait 2-3 minutes)
- Verify correct username/password

**Problem:** SSH to Ubuntu VM fails
**Solution:**
- Connect from Windows jumpbox, not directly
- Use private IP address of Ubuntu VM
- Check NSG allows SSH (port 22) from VNet
- Verify VM is running: `az vm list --resource-group rg-lab-azml-artifactory`

### Artifactory Issues

**Problem:** Artifactory web UI not accessible
```
Connection refused or timeout
```
**Solution:**
1. Check if container is running:
   ```bash
   ssh ubuntu@<vm-ip>
   docker ps
   ```

2. If not running, restart:
   ```bash
   cd /opt/artifactory
   docker-compose up -d
   ```

3. Check container logs:
   ```bash
   docker logs artifactory
   ```

4. Verify NSG allows port 8082

**Problem:** Artifactory authentication fails
**Solution:**
- Default credentials: `admin/password`
- Wait 2-3 minutes after container start for initialization
- Check browser console for errors
- Try incognito/private browsing mode

**Problem:** Cannot push images to Artifactory
```
unauthorized: authentication required
```
**Solution:**
1. Create local Docker repository in Artifactory UI
2. Enable Docker access in repository settings
3. Configure Docker daemon with insecure registry:
   ```bash
   sudo nano /etc/docker/daemon.json
   {
     "insecure-registries": ["<artifactory-ip>:8082"]
   }
   sudo systemctl restart docker
   ```

### Azure ML Issues

**Problem:** ML workspace not accessible
**Solution:**
- Check if private endpoints are created
- Verify DNS resolution from client network
- Use Azure ML Studio via public internet initially
- Check firewall settings if accessing from corporate network

**Problem:** ACR authentication fails
```
Error: failed to authorize: failed to fetch anonymous token
```
**Solution:**
1. Login to ACR:
   ```bash
   az acr login --name <acr-name>
   ```

2. Check managed identity permissions:
   ```bash
   az role assignment list --scope /subscriptions/.../resourceGroups/.../providers/Microsoft.ContainerRegistry/registries/<acr-name>
   ```

3. Verify AcrPull role is assigned to ML workspace identity

**Problem:** Container image pull fails in ML deployment
**Solution:**
- Verify image exists in ACR: `az acr repository list --name <acr-name>`
- Check image tag is correct
- Ensure ML workspace has AcrPull permissions
- Test image pull manually: `docker pull <acr-name>.azurecr.io/<image>`

### Network Connectivity Issues

**Problem:** Private endpoints not resolving
**Solution:**
1. Check DNS zones are linked to VNets:
   ```bash
   az network private-dns link vnet list --resource-group rg-lab-azml-artifactory --zone-name privatelink.azurecr.io
   ```

2. Test DNS resolution from VM:
   ```bash
   nslookup <acr-name>.azurecr.io
   ```

3. Verify private endpoint exists:
   ```bash
   az network private-endpoint list --resource-group rg-lab-azml-artifactory
   ```

**Problem:** Inter-VNet communication fails
**Solution:**
- Check VNet peering is established and enabled
- Verify route tables don't block traffic
- Test connectivity: `ping <private-ip>` or `telnet <private-ip> <port>`

## Authentication Issues

### PAT Generation Problems

**Problem:** PAT generation script fails
```
Error: Cannot connect to Artifactory
```
**Solution:**
1. Verify Artifactory is accessible:
   ```bash
   curl -f http://<artifactory-ip>:8082/artifactory/api/system/ping
   ```

2. Check credentials are correct
3. Ensure Artifactory is fully initialized (wait 2-3 minutes)

**Problem:** Generated PAT doesn't work
**Solution:**
- Check token expiration (default 1 hour)
- Regenerate token with correct scopes
- Verify token format (should start with `eyJ`)
- Test token manually:
  ```bash
  curl -H "Authorization: Bearer <token>" http://<artifactory-ip>:8082/artifactory/api/system/ping
  ```

### Azure Authentication Issues

**Problem:** `az login` required repeatedly
**Solution:**
- Check subscription status
- Use service principal for automation:
  ```bash
  az login --service-principal --username <sp-id> --password <sp-secret> --tenant <tenant-id>
  ```

## Performance Issues

### Slow Deployment

**Problem:** Terraform apply takes very long
**Solution:**
- Azure Bastion can take 10-15 minutes alone
- Run deployment during off-peak hours
- Use smaller VM sizes for testing
- Consider disabling Bastion temporarily: `enable_bastion = false`

**Problem:** VM startup slow
**Solution:**
- VMs need 2-3 minutes to boot and run cloud-init
- Check VM status: `az vm get-instance-view --name <vm-name> --resource-group <rg-name>`
- Monitor boot diagnostics in Azure Portal

### Container Operations Slow

**Problem:** Docker image pulls/pushes are slow
**Solution:**
- Check network bandwidth
- Use smaller base images
- Consider using Azure Container Registry tasks for builds
- Monitor disk space on VMs

## Useful Diagnostic Commands

### Azure Resources
```bash
# List all resources
az resource list --resource-group rg-lab-azml-artifactory --output table

# Check VM status
az vm list --resource-group rg-lab-azml-artifactory --show-details --output table

# Verify private endpoints
az network private-endpoint list --resource-group rg-lab-azml-artifactory --output table

# Check role assignments
az role assignment list --resource-group rg-lab-azml-artifactory --output table
```

### VM Diagnostics
```bash
# Check VM boot diagnostics
az vm boot-diagnostics get-boot-log --name <vm-name> --resource-group rg-lab-azml-artifactory

# VM instance view
az vm get-instance-view --name <vm-name> --resource-group rg-lab-azml-artifactory
```

### Container Diagnostics
```bash
# Check container status
docker ps -a

# View container logs
docker logs artifactory

# Check disk usage
df -h

# Network connectivity
curl -v http://localhost:8082/artifactory/api/system/ping
```

### Network Diagnostics
```bash
# DNS resolution
nslookup <service>.privatelink.domain

# Port connectivity
telnet <ip> <port>

# Route testing
traceroute <destination>
```

## Getting Help

If you're still experiencing issues:

1. **Check Azure Activity Log** for deployment errors
2. **Review VM boot diagnostics** for startup issues  
3. **Examine container logs** for service problems
4. **Test network connectivity** between components
5. **Verify permissions** and role assignments

## Common Success Indicators

✅ **Everything is working when:**
- Terraform apply completes without errors
- All VMs show "Running" status
- Artifactory UI loads at http://<vm-ip>:8082
- ACR login succeeds: `az acr login --name <acr-name>`
- Private endpoint DNS resolves correctly
- Container images can be pushed to Artifactory
- Images can be synced from Artifactory to ACR
- Azure ML workspace can access ACR images