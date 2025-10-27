# Azure DevOps Migration Guide

This guide explains how to migrate your Terraform/Terragrunt CI/CD pipelines from GitHub Actions to Azure DevOps.

## Overview

The project includes two Azure Pipelines:
1. **azure-pipelines-plan.yml** - PR validation (runs terragrunt plan)
2. **azure-pipelines-apply.yml** - Deployment (runs terragrunt apply on merge or manual trigger)

---

## Prerequisites

- Azure DevOps organization and project
- Azure Repos repository (migrate from GitHub)
- Azure subscription with appropriate permissions
- Service Principal for Terraform authentication
- **Agent Setup**: Choose between Microsoft-hosted or self-hosted agents (see Step 1A below)

---

## Step 1A: Choose Your Agent Type

Azure Pipelines require compute resources (agents) to run your pipelines. You have two options:

### Option 1: Microsoft-Hosted Agents (Recommended for Getting Started)

**Pros:**
- No setup or maintenance required
- Pre-configured with common tools
- Automatic updates
- Clean environment for each run

**Cons:**
- Requires parallelism grant (free for public projects, paid for private)
- Limited to 60 minutes per job (free tier)
- Less control over environment

#### Setup Microsoft-Hosted Agents:

1. **Request Free Parallelism** (if you don't have it):
   - Fill out the form: https://aka.ms/azpipelines-parallelism-request
   - Wait 2-3 business days for approval
   - You'll receive 1 free parallel job

2. **Verify Parallelism is Enabled**:
   - Go to **Organization Settings** → **Pipelines** → **Parallel jobs**
   - Under **Microsoft-hosted**, ensure you see at least "1" available
   - If it shows "0", your request is still pending or was denied

3. **Your pipelines are already configured** to use Microsoft-hosted agents:
   ```yaml
   pool:
     name: 'Azure Pipelines'
     vmImage: 'ubuntu-latest'
   ```

4. **No additional setup needed!** Skip to Step 1B (Service Principal).

---

### Option 2: Self-Hosted Agents (Recommended for Production)

**Pros:**
- Free - no parallelism limits
- Full control over environment
- Can run on-premises or in your cloud
- Faster for large dependencies (cached)
- Can access private networks

**Cons:**
- Requires setup and maintenance
- You manage security and updates
- Need a dedicated machine or VM

#### Setup Self-Hosted Agent:

**Step 1: Create Agent Pool**

1. Go to **Organization Settings** → **Agent pools**
2. Click **Add pool**
3. Select **Self-hosted**
4. Name: `Default` (or custom name like `terraform-agents`)
5. ✅ Check **Grant access permission to all pipelines**
6. Click **Create**

**Step 2: Install Agent on Your Machine**

##### On Windows (PowerShell as Administrator):

```powershell
# Create agent directory
mkdir C:\agent ; cd C:\agent

# Download agent
$AgentZip = "vsts-agent-win-x64-3.236.1.zip"
Invoke-WebRequest -Uri "https://vstsagentpackage.azureedge.net/agent/3.236.1/$AgentZip" -OutFile $AgentZip

# Extract
Expand-Archive -Path $AgentZip -DestinationPath $PWD

# Configure agent
.\config.cmd
```

##### On Linux/Mac:

```bash
# Create agent directory
mkdir ~/agent && cd ~/agent

# Download agent (check latest version at: https://github.com/microsoft/azure-pipelines-agent/releases)
wget https://vstsagentpackage.azureedge.net/agent/3.236.1/vsts-agent-linux-x64-3.236.1.tar.gz

# Extract
tar zxvf vsts-agent-linux-x64-3.236.1.tar.gz

# Configure agent
./config.sh
```

**Step 3: Configuration Prompts**

During configuration, you'll be prompted for:

1. **Server URL**: `https://dev.azure.com/{YOUR_ORGANIZATION}`
2. **Authentication type**: Press Enter (PAT)
3. **Personal Access Token**: Create one:
   - Azure DevOps → User Settings → Personal access tokens
   - Click **New Token**
   - Name: `agent-setup`
   - Scopes: **Agent Pools (read, manage)**
   - Create and copy the token
4. **Agent pool**: Enter the pool name from Step 1 (e.g., `Default`)
5. **Agent name**: Press Enter (uses hostname) or provide custom name
6. **Work folder**: Press Enter (default: `_work`)
7. **Run as service**: `Y` (recommended) or `N` for interactive

**Step 4: Start the Agent**

##### Windows (if installed as service):
```powershell
# Service starts automatically
# Or manually start:
Start-Service vstsagent.*
```

##### Windows (interactive mode):
```powershell
.\run.cmd
```

##### Linux/Mac (as service):
```bash
sudo ./svc.sh install
sudo ./svc.sh start
```

##### Linux/Mac (interactive):
```bash
./run.sh
```

**Step 5: Install Required Tools on Agent**

Your self-hosted agent needs these tools installed:

```bash
# Install unzip (for Terraform download)
# Ubuntu/Debian:
sudo apt-get update && sudo apt-get install -y unzip curl jq

# RHEL/CentOS:
sudo yum install -y unzip curl jq

# Windows (using Chocolatey):
choco install unzip curl jq -y
```

**Azure CLI** (required for authentication):
```bash
# Linux:
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Windows:
choco install azure-cli -y

# Mac:
brew install azure-cli
```

**Step 6: Update Pipeline Configuration**

If you used a custom pool name (not `Default`), update your pipeline files:

**In `azure-pipelines-plan.yml` and `azure-pipelines-apply.yml`**, change:

```yaml
pool:
  name: 'Azure Pipelines'  # ← Change this
  vmImage: 'ubuntu-latest'  # ← Remove this line
```

To:

```yaml
pool:
  name: 'Default'  # ← Your self-hosted pool name
```

**Step 7: Verify Agent is Online**

1. Go to **Organization Settings** → **Agent pools**
2. Click on your pool (`Default` or custom name)
3. Go to **Agents** tab
4. Verify your agent shows **Online** status with a green check ✅

---

### Comparison: Microsoft-Hosted vs Self-Hosted

| Feature | Microsoft-Hosted | Self-Hosted |
|---------|-----------------|-------------|
| **Setup Time** | None | 15-30 minutes |
| **Cost** | Free tier limited, then paid | Free (your infrastructure cost) |
| **Parallelism** | Requires grant/payment | Unlimited |
| **Maintenance** | Microsoft manages | You manage |
| **Performance** | Standard | Depends on your hardware |
| **Network Access** | Public internet only | Can access private networks |
| **Tool Installation** | Pre-installed | You install |
| **Job Duration** | 60 min (free), 360 min (paid) | Unlimited |
| **Best For** | Testing, small projects | Production, private networks |

---

## Step 1B: Create Service Principal (You can skip if you already have a service principal)

Create a Service Principal for Terraform to authenticate with Azure:

```bash
# Login to Azure
az login

# Create Service Principal with Contributor role
az ad sp create-for-rbac --name "terraform-sp" \
  --role Contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>
```

**Save the output:**
```json
{
  "appId": "<CLIENT_ID>",
  "displayName": "terraform-sp",
  "password": "<CLIENT_SECRET>",
  "tenant": "<TENANT_ID>"
}
```

---

## Step 2: Create Azure Service Connection

1. Navigate to **Project Settings** → **Service connections**
2. Click **New service connection** → Select **Azure Resource Manager**
3. Choose **Service principal (manual)**
4. Fill in the details:
   - **Service connection name**: `Azure-Terraform-ServiceConnection`
   - **Subscription ID**: Your Azure subscription ID
   - **Subscription Name**: Your Azure subscription name
   - **Service Principal Id**: `<CLIENT_ID>` from Step 1
   - **Service Principal Key**: `<CLIENT_SECRET>` from Step 1
   - **Tenant ID**: `<TENANT_ID>` from Step 1
5. Click **Verify** to test the connection
6. Check **Grant access permission to all pipelines**
7. Click **Save**

> **Important**: The service connection name `Azure-Terraform-ServiceConnection` is referenced in the pipeline templates. If you use a different name, update the templates accordingly.

---

## Step 3: Create Variable Group

Variable groups store secrets and configuration used by pipelines:

1. Navigate to **Pipelines** → **Library**
2. Click **+ Variable group**
3. Name it: `terraform-secrets`
4. Add the following variables:

| Variable Name | Value | Secret |
|--------------|-------|--------|
| `ARM_SUBSCRIPTION_ID` | Your Azure subscription ID | No |
| `ARM_CLIENT_ID` | Service Principal App ID | No |
| `ARM_CLIENT_SECRET` | Service Principal Password | **Yes** ✓ |
| `ARM_TENANT_ID` | Your Azure AD Tenant ID | No |
| `SQL_ADMIN_PASSWORD` | SQL Server admin password | **Yes** ✓ |
| `TF_VERSION` | `1.3.0` | No |
| `TG_VERSION` | `0.55.0` | No |

5. Click **Save**

> **Note**: Mark `ARM_CLIENT_SECRET` and `SQL_ADMIN_PASSWORD` as secret by clicking the lock icon.

---

## Step 4: Create Environments

Environments enable deployment approvals and history tracking:

1. Navigate to **Pipelines** → **Environments**
2. Create three environments:
   - `test`
   - `dev`
   - `prod`

### Optional: Add Approvals for Production

1. Click on the `prod` environment
2. Click **•••** (More actions) → **Approvals and checks**
3. Add **Approvals** check
4. Select approvers (users/groups who must approve prod deployments)
5. Click **Create**

---

## Step 5: Configure Repository

### Migrate from GitHub to Azure Repos

1. Navigate to **Repos** → **Files**
2. Click **Import repository**
3. Select **Git** as clone type
4. Enter GitHub repository URL: `https://github.com/<YOUR_ORG>/Azure-Environment-Terraform`
5. If private, provide credentials
6. Click **Import**

### Set up Branch Policies

Enforce PR reviews and pipeline validation on `main` branch:

1. Navigate to **Repos** → **Branches**
2. Find `main` branch → Click **•••** → **Branch policies**
3. Configure:
   - ✓ **Require a minimum number of reviewers**: Set to 1 (or more)
   - ✓ **Check for linked work items**: Optional
   - ✓ **Check for comment resolution**: Recommended
   - ✓ **Build Validation**:
     - Click **+** to add build policy
     - Select `azure-pipelines-plan` pipeline
     - Set **Trigger**: Automatic
     - Set **Policy requirement**: Required
     - Click **Save**

This ensures the plan pipeline runs on every PR to `main`.

---

## Step 6: Create Pipelines

### Create Plan Pipeline (PR Validation)

1. Navigate to **Pipelines** → **Pipelines**
2. Click **New pipeline**
3. Select **Azure Repos Git**
4. Select your repository
5. Select **Existing Azure Pipelines YAML file**
6. Choose `/azure-pipelines-plan.yml`
7. Click **Continue** → **Save** (don't run yet)
8. Rename pipeline (optional):
   - Click **•••** → **Rename/move**
   - Name: `Terragrunt Plan (PR Validation)`

### Create Apply Pipeline (Deployment)

1. Navigate to **Pipelines** → **Pipelines**
2. Click **New pipeline**
3. Select **Azure Repos Git**
4. Select your repository
5. Select **Existing Azure Pipelines YAML file**
6. Choose `/azure-pipelines-apply.yml`
7. Click **Continue** → **Save** (don't run yet)
8. Rename pipeline (optional):
   - Click **•••** → **Rename/move**
   - Name: `Terragrunt Apply (Deployment)`

---

## Step 7: Link Variable Group to Pipelines

Both pipelines need access to the variable group:

1. Navigate to **Pipelines** → **Pipelines**
2. Click on **Terragrunt Plan (PR Validation)** pipeline
3. Click **Edit**
4. Click **•••** → **Triggers**
5. Go to **Variables** tab
6. Click **Variable groups** → **Link variable group**
7. Select `terraform-secrets`
8. Click **Save**
9. Repeat for **Terragrunt Apply (Deployment)** pipeline

---

## Step 8: Grant Pipeline Permissions

Pipelines need permission to post comments and access resources:

### Enable System.AccessToken for PR Comments

1. Navigate to **Project Settings** → **Pipelines** → **Settings**
2. Enable **Limit job authorization scope to current project**
3. For each pipeline:
   - Open pipeline → **Edit** → **•••** → **Settings**
   - Under **Advanced**, enable **Allow scripts to access the OAuth token**

### Grant Environment Access

1. Navigate to **Pipelines** → **Environments**
2. For each environment (`test`, `dev`, `prod`):
   - Click environment → **•••** → **Security**
   - Add your pipelines with **Creator** or **Administrator** role

---

## Step 9: Test the Pipelines

### Test PR Pipeline

1. Create a new branch:
   ```bash
   git checkout -b test/pipeline-setup
   ```

2. Make a small change to a test environment file:
   ```bash
   echo "# Test change" >> terraform/live/test/terragrunt.hcl
   git add .
   git commit -m "test: pipeline setup"
   git push origin test/pipeline-setup
   ```

3. Create a Pull Request in Azure Repos
4. Verify the `Terragrunt Plan` pipeline runs automatically
5. Check PR comments for plan output

### Test Apply Pipeline (Manual Trigger)

1. Navigate to **Pipelines** → **Terragrunt Apply (Deployment)**
2. Click **Run pipeline**
3. Select parameters:
   - **Environment**: `test`
   - **First deployment**: `true` (if this is your first run)
4. Click **Run**
5. Verify deployment succeeds
6. Check artifacts for kubeconfig file

### Test Apply Pipeline (CI Trigger)

1. Merge your test PR to `main`
2. Verify the `Terragrunt Apply` pipeline runs automatically
3. Check that it applies only to the `test` environment (if you changed test files)

---

## Differences from GitHub Actions

| Feature | GitHub Actions | Azure DevOps Pipelines |
|---------|---------------|------------------------|
| **Secrets** | Repository Secrets | Variable Groups (linked to pipelines) |
| **Environments** | Repository Environments | Project Environments |
| **Service Connection** | Stored in secrets | Service Connection with RBAC |
| **PR Comments** | `actions/github-script` | REST API with `System.AccessToken` |
| **Manual Trigger** | `workflow_dispatch` | Pipeline parameters |
| **Conditional Stages** | `if` conditions | `condition` expressions |
| **Matrix Strategy** | `strategy.matrix` | Separate jobs with conditions |

---

## Workflow Comparison

### Pull Request Flow

**GitHub Actions:**
```
PR created → Plan workflow triggers → Plan runs for changed envs → Results posted to PR
```

**Azure DevOps:**
```
PR created → Branch policy triggers plan pipeline → Plan runs for changed envs → Results posted to PR
```

### Merge/Deploy Flow

**GitHub Actions:**
```
Merge to main → Apply workflow triggers → Detects changes → Applies to affected envs
OR
Manual trigger → Select env → Apply to selected env
```

**Azure DevOps:**
```
Merge to main → CI trigger on apply pipeline → Detects changes → Applies to affected envs
OR
Manual run → Select environment parameter → Apply to selected env with optional approval
```

---

## Common Issues and Solutions

### Issue: Pipeline fails with "Service connection not found"

**Solution**: 
- Verify the service connection name in templates matches the one created (`Azure-Terraform-ServiceConnection`)
- Grant pipeline permission to use the service connection

### Issue: Cannot post comments to PR

**Solution**:
- Enable "Allow scripts to access the OAuth token" in pipeline settings
- Grant "Contribute to pull requests" permission to Build Service account

### Issue: Variable group variables not available

**Solution**:
- Link variable group to the pipeline
- Verify variable group is not empty
- Check variable names match exactly (case-sensitive)

### Issue: Environment approval blocks deployment

**Solution**:
- Check environment approvals configuration
- Approve pending deployments in **Pipelines** → **Environments** → Click environment → **Approvals**

---

## Manual Promotion to Higher Environments

After merging changes that auto-deploy to `test`:

1. Verify `test` environment works correctly
2. Navigate to **Pipelines** → **Terragrunt Apply**
3. Click **Run pipeline**
4. Select:
   - **Environment**: `dev` (or `prod`)
   - **First deployment**: `false` (unless it's truly the first deploy)
5. Click **Run**
6. If approval is required for `prod`, approvers will receive notification

---

## Next Steps

1. ✅ Complete all setup steps above
2. ✅ Test both pipelines with a test PR
3. ✅ Configure production approval gates
4. ✅ Document your team's deployment process
5. Consider adding:
   - Plan artifact persistence for "apply what was planned"
   - Slack/Teams notifications for deployments
   - Cost estimation using Infracost
   - Security scanning with tfsec or Checkov

---

## Support and Resources

- [Azure Pipelines Documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

For project-specific questions, refer to:
- `README.md` - CI/CD pipeline setup
- `README-DEV-TEAM.md` - Local development setup
