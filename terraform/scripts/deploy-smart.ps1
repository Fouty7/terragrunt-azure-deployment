# Smart Terragrunt Deployment Script
# Handles dependencies correctly for first-time and subsequent deployments
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("plan", "apply", "destroy")]
    [string]$Action,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("test", "dev", "prod")]
    [string]$Environment,
    
    [switch]$FirstDeploy = $false
)

$ErrorActionPreference = "Stop"

Write-Host "Starting smart Terragrunt $Action for $Environment environment..." -ForegroundColor Green

# Navigate to environment directory
$envPath = "live\$Environment"
if (!(Test-Path $envPath)) {
    Write-Error "Environment directory '$envPath' not found!"
    exit 1
}

Set-Location $envPath

if ($FirstDeploy -and $Action -eq "apply") {
    Write-Host "FIRST DEPLOYMENT: Running modules in dependency order..." -ForegroundColor Cyan
    
    # Step 1: Independent modules first
    $independentModules = @("monitoring", "keyvault", "sql")
    foreach ($module in $independentModules) {
        Write-Host "Applying $module..." -ForegroundColor Yellow
        terragrunt apply --auto-approve --terragrunt-working-dir $module
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to apply $module"
            exit 1
        }
    }
    
    # Step 2: Dependent modules
    Write-Host "Applying AKS (depends on monitoring)..." -ForegroundColor Yellow
    terragrunt apply --auto-approve --terragrunt-working-dir aks
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to apply AKS"
        exit 1
    }
    
    Write-Host "First deployment completed successfully!" -ForegroundColor Green
} else {
    # Normal run-all operation for subsequent deployments or plans
    Write-Host "Running terragrunt run-all $Action..." -ForegroundColor Yellow
    
    switch ($Action) {
        "plan" { terragrunt run-all plan --terragrunt-parallelism 1 }
        "apply" { terragrunt run-all apply --auto-approve --terragrunt-parallelism 1 }
        "destroy" { terragrunt run-all destroy --auto-approve --terragrunt-parallelism 1 }
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Operation completed successfully!" -ForegroundColor Green
    } else {
        Write-Error "Operation failed with exit code $LASTEXITCODE"
        exit 1
    }
}