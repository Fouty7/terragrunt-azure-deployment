# Terragrunt Destroy Script
# Handles state locks and provides clear feedback
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("test", "dev", "prod")]
    [string]$Environment,
    
    [switch]$AutoApprove = $false
)

$ErrorActionPreference = "Continue"  # Continue on errors to show more info

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

# Function to destroy a module with lock handling
function Destroy-Module {
    param(
        [string]$ModuleName,
        [string]$ModulePath = $ModuleName
    )
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Destroying $ModuleName" -ForegroundColor Cyan  
    Write-Host "========================================" -ForegroundColor Cyan
    
    try {
        Push-Location $ModulePath
        
        # First, try to break any existing locks
        Write-Host "Checking for and breaking any state locks..." -ForegroundColor Yellow
        $planOutput = terragrunt plan -detailed-exitcode 2>&1
        
        # Look for lock errors in the output
        $lockPattern = 'ID:\s+([a-f0-9\-]+)'
        if ($planOutput -match $lockPattern) {
            $lockId = $matches[1]
            Write-Host "Found lock ID: $lockId. Breaking lock..." -ForegroundColor Yellow
            echo "yes" | terragrunt force-unlock $lockId
            Write-Host "Lock broken." -ForegroundColor Green
        }
        
        # Now attempt destroy
        Write-Host "Starting destruction..." -ForegroundColor Yellow
        if ($AutoApprove) {
            terragrunt destroy --auto-approve
        } else {
            terragrunt destroy
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$ModuleName destroyed successfully!" -ForegroundColor Green
        } else {
            Write-Host "$ModuleName destruction failed with exit code $LASTEXITCODE" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Error destroying $ModuleName : $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        Pop-Location
    }
}

try {
    # Destroy in reverse dependency order
    Write-Host "DESTRUCTION ORDER: AKS -> KeyVault -> SQL -> Monitoring -> Root" -ForegroundColor Yellow
    
    # 1. AKS (depends on monitoring)
    if (Test-Path "aks") {
        Destroy-Module "AKS" "aks"
    }
    
    # 2. Independent modules
    if (Test-Path "keyvault") {
        Destroy-Module "KeyVault" "keyvault"
    }
    
    if (Test-Path "sql") {
        Destroy-Module "SQL Database" "sql"
    }
    
    if (Test-Path "monitoring") {
        Destroy-Module "Monitoring" "monitoring"
    }
    
    # 3. Root module
    Destroy-Module "Root Module" "."
    
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "DESTRUCTION PROCESS COMPLETED!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Check the output above for any failed modules." -ForegroundColor Yellow
    Write-Host "You may need to manually clean up resources that failed to destroy." -ForegroundColor Yellow
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}