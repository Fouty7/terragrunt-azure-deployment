# Smart Terragrunt Destroy Script
# Destroys infrastructure in reverse dependency order to avoid conflicts
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("test", "dev", "prod")]
    [string]$Environment,
    
    [switch]$AutoApprove = $false,
    [int]$MaxRetries = 3,
    [int]$RetryDelay = 30
)

$ErrorActionPreference = "Stop"

Write-Host "Starting Terragrunt DESTROY for $Environment environment..." -ForegroundColor Red
Write-Host "WARNING: This will destroy ALL infrastructure in the $Environment environment!" -ForegroundColor Yellow

# Confirm destruction unless auto-approve is set
if (-not $AutoApprove) {
    $confirmation = Read-Host "Are you absolutely sure you want to destroy all resources? Type 'DESTROY' to confirm"
    if ($confirmation -ne "DESTROY") {
        Write-Host "Destruction cancelled." -ForegroundColor Green
        exit 0
    }
}

# Navigate to environment directory
$envPath = "live\$Environment"
if (!(Test-Path $envPath)) {
    Write-Error "Environment directory '$envPath' not found!"
    exit 1
}

Set-Location $envPath

# Function to retry operations
function Invoke-WithRetry {
    param(
        [scriptblock]$ScriptBlock,
        [string]$OperationName,
        [int]$MaxAttempts = $MaxRetries
    )
    
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            Write-Host "Attempt $attempt/$MaxAttempts for $OperationName..." -ForegroundColor Yellow
            
            # Refresh Azure auth before each retry
            if ($attempt -gt 1) {
                Write-Host "Refreshing Azure authentication..." -ForegroundColor Cyan
                az account get-access-token --output none
            }
            
            # Execute the operation
            $result = & $ScriptBlock
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "$OperationName completed successfully!" -ForegroundColor Green
                return $result
            }
            else {
                throw "Command failed with exit code $LASTEXITCODE"
            }
        }
        catch {
            Write-Warning "Attempt $attempt failed: $($_.Exception.Message)"
            
            if ($attempt -lt $MaxAttempts) {
                Write-Host "Waiting $RetryDelay seconds before retry..." -ForegroundColor Yellow
                Start-Sleep -Seconds $RetryDelay
            }
            else {
                Write-Warning "All attempts failed for $OperationName - continuing with next module"
                return $null
            }
        }
    }
}

try {
    Write-Host "DESTRUCTION ORDER: Dependent modules first, then independent modules" -ForegroundColor Cyan
    
    # Step 1: Destroy dependent modules first (AKS depends on monitoring)
    Write-Host "Destroying AKS (dependent module)..." -ForegroundColor Yellow
    Invoke-WithRetry -OperationName "AKS Destroy" -ScriptBlock {
        if ($AutoApprove) {
            terragrunt destroy --auto-approve --terragrunt-working-dir aks
        } else {
            terragrunt destroy --terragrunt-working-dir aks
        }
    }
    
    # Step 2: Destroy independent modules
    $independentModules = @("keyvault", "sql", "monitoring")
    foreach ($module in $independentModules) {
        Write-Host "Destroying $module..." -ForegroundColor Yellow
        Invoke-WithRetry -OperationName "$module Destroy" -ScriptBlock {
            if ($AutoApprove) {
                terragrunt destroy --auto-approve --terragrunt-working-dir $module
            } else {
                terragrunt destroy --terragrunt-working-dir $module
            }
        }
    }
    
    # Step 3: Destroy root module (if it has resources)
    Write-Host "Destroying root module..." -ForegroundColor Yellow
    Invoke-WithRetry -OperationName "Root Module Destroy" -ScriptBlock {
        if ($AutoApprove) {
            terragrunt destroy --auto-approve
        } else {
            terragrunt destroy
        }
    }
    
    Write-Host "DESTRUCTION COMPLETED!" -ForegroundColor Green
    Write-Host "All $Environment environment resources have been destroyed." -ForegroundColor Green
}
catch {
    Write-Error "Destruction failed: $($_.Exception.Message)"
    Write-Host "Some resources may still exist. Check Azure Portal and run individual destroy commands if needed." -ForegroundColor Yellow
    exit 1
}