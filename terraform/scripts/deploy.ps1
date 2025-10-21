# Robust Terragrunt Deployment Script
# Usage: .\scripts\deploy.ps1 -Action plan|apply -Environment test|dev|prod

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("plan", "apply", "destroy")]
    [string]$Action,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("test", "dev", "prod")]
    [string]$Environment,
    
    [int]$MaxRetries = 3,
    [int]$RetryDelay = 30
)

$ErrorActionPreference = "Stop"

Write-Host "Starting Terragrunt $Action for $Environment environment..." -ForegroundColor Green

# Navigate to environment directory
$envPath = "live\$Environment"
if (!(Test-Path $envPath)) {
    Write-Error "Environment directory '$envPath' not found!"
    exit 1
}

Set-Location $envPath

# Function to retry Azure operations
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
                Write-Error "All attempts failed for $OperationName"
                throw
            }
        }
    }
}

# Main execution
try {
    # Step 1: Initialize if needed
    Invoke-WithRetry -OperationName "Terragrunt Init" -ScriptBlock {
        terragrunt run-all init --terragrunt-parallelism 1
    }
    
    # Step 2: Execute the requested action
    Invoke-WithRetry -OperationName "Terragrunt $Action" -ScriptBlock {
        switch ($Action) {
            "plan" { terragrunt run-all plan --terragrunt-parallelism 1 }
            "apply" { terragrunt run-all apply --terragrunt-parallelism 1 }
            "destroy" { terragrunt run-all destroy --terragrunt-parallelism 1 }
        }
    }
    
    Write-Host "Deployment completed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    exit 1
}
