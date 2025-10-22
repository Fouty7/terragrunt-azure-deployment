#!/bin/bash

# Terragrunt Destroy Script (mac-linux/Linux)
# Handles state locks and provides clear feedback

set +e  # Continue on errors to show more info

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo "Usage: $0 -e <ENVIRONMENT> [--auto-approve]"
    echo ""
    echo "Options:"
    echo "  -e, --environment  Environment to destroy (test|dev|prod)"
    echo "  --auto-approve    Skip confirmation prompt (DANGEROUS!)"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -e test                    # Safe destroy with confirmation"
    echo "  $0 -e test --auto-approve     # Automated destroy (no confirmation)"
}

# Parse command line arguments
ENVIRONMENT=""
AUTO_APPROVE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --auto-approve)
            AUTO_APPROVE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown parameter: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$ENVIRONMENT" ]]; then
    echo -e "${RED}Error: Environment (-e) is required${NC}"
    usage
    exit 1
fi

# Validate environment
case $ENVIRONMENT in
    test|dev|prod)
        ;;
    *)
        echo -e "${RED}Error: Invalid environment '$ENVIRONMENT'. Must be test, dev, or prod${NC}"
        exit 1
        ;;
esac

echo -e "${RED}Starting Terragrunt DESTROY for $ENVIRONMENT environment...${NC}"
echo -e "${YELLOW}WARNING: This will destroy ALL infrastructure in the $ENVIRONMENT environment!${NC}"

# Confirm destruction unless auto-approve is set
if [[ "$AUTO_APPROVE" != true ]]; then
    echo ""
    read -p "Are you absolutely sure you want to destroy all resources? Type 'DESTROY' to confirm: " confirmation
    if [[ "$confirmation" != "DESTROY" ]]; then
        echo -e "${GREEN}Destruction cancelled.${NC}"
        exit 0
    fi
fi

# Navigate to environment directory
ENV_PATH="live/$ENVIRONMENT"
if [[ ! -d "$ENV_PATH" ]]; then
    echo -e "${RED}Error: Environment directory '$ENV_PATH' not found!${NC}"
    exit 1
fi

cd "$ENV_PATH"

# Function to destroy a module with lock handling
destroy_module() {
    local module_name="$1"
    local module_path="${2:-$module_name}"
    
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}Destroying $module_name${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    if [[ ! -d "$module_path" ]]; then
        echo -e "${YELLOW}Module directory '$module_path' not found, skipping...${NC}"
        return 0
    fi
    
    # Change to module directory
    pushd "$module_path" > /dev/null
    
    # First, try to break any existing locks
    echo -e "${YELLOW}Checking for and breaking any state locks...${NC}"
    plan_output=$(terragrunt plan -detailed-exitcode 2>&1 || true)
    
    # Look for lock errors in the output
    if echo "$plan_output" | grep -q "ID:"; then
        lock_id=$(echo "$plan_output" | grep -oE "ID:\s+[a-f0-9-]+" | head -1 | awk '{print $2}')
        if [[ -n "$lock_id" ]]; then
            echo -e "${YELLOW}Found lock ID: $lock_id. Breaking lock...${NC}"
            echo "yes" | terragrunt force-unlock "$lock_id" || true
            echo -e "${GREEN}Lock broken.${NC}"
        fi
    fi
    
    # Now attempt destroy
    echo -e "${YELLOW}Starting destruction...${NC}"
    if [[ "$AUTO_APPROVE" == true ]]; then
        terragrunt destroy --auto-approve
    else
        terragrunt destroy
    fi
    
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}$module_name destroyed successfully!${NC}"
    else
        echo -e "${RED}$module_name destruction failed with exit code $exit_code${NC}"
    fi
    
    # Return to previous directory
    popd > /dev/null
    
    return $exit_code
}

# Main execution
echo -e "${YELLOW}DESTRUCTION ORDER: AKS -> KeyVault -> SQL/Monitoring/Network -> Root${NC}"

# Destroy in reverse dependency order
# 1. AKS (depends on monitoring and network)
if [[ -d "aks" ]]; then
    destroy_module "AKS" "aks"
fi

# 2. KeyVault (depends on SQL and monitoring)
if [[ -d "keyvault" ]]; then
    destroy_module "KeyVault" "keyvault"
fi

# 3. Independent modules (can be destroyed in parallel conceptually)
if [[ -d "sql" ]]; then
    destroy_module "SQL Database" "sql"
fi

if [[ -d "monitoring" ]]; then
    destroy_module "Monitoring" "monitoring"
fi

if [[ -d "network" ]]; then
    destroy_module "Network" "network"
fi

# 3. Root module
destroy_module "Root Module" "."

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}DESTRUCTION PROCESS COMPLETED!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}Check the output above for any failed modules.${NC}"
echo -e "${YELLOW}You may need to manually clean up resources that failed to destroy.${NC}"