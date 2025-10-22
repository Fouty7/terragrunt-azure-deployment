#!/bin/bash

# Terragrunt Deployment Script (mac-linux/Linux)
# Handles dependencies correctly for first-time and subsequent deployments

set -e  # Exit on any error

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
MAX_RETRIES=3
RETRY_DELAY=30

# Function to display usage
usage() {
    echo "Usage: $0 -a <ACTION> -e <ENVIRONMENT> [-f]"
    echo ""
    echo "Options:"
    echo "  -a, --action       Action to perform (plan|apply|destroy)"
    echo "  -e, --environment  Environment (test|dev|prod)"
    echo "  -f, --first-deploy First time deployment (handles dependencies)"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -a plan -e test"
    echo "  $0 -a apply -e test -f"
    echo "  $0 --action apply --environment prod"
}

# Parse command line arguments
ACTION=""
ENVIRONMENT=""
FIRST_DEPLOY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -f|--first-deploy)
            FIRST_DEPLOY=true
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
if [[ -z "$ACTION" ]]; then
    echo -e "${RED}Error: Action (-a) is required${NC}"
    usage
    exit 1
fi

if [[ -z "$ENVIRONMENT" ]]; then
    echo -e "${RED}Error: Environment (-e) is required${NC}"
    usage
    exit 1
fi

# Validate action
case $ACTION in
    plan|apply|destroy)
        ;;
    *)
        echo -e "${RED}Error: Invalid action '$ACTION'. Must be plan, apply, or destroy${NC}"
        exit 1
        ;;
esac

# Validate environment
case $ENVIRONMENT in
    test|dev|prod)
        ;;
    *)
        echo -e "${RED}Error: Invalid environment '$ENVIRONMENT'. Must be test, dev, or prod${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}Starting Terragrunt $ACTION for $ENVIRONMENT environment...${NC}"

# Navigate to environment directory
ENV_PATH="live/$ENVIRONMENT"
if [[ ! -d "$ENV_PATH" ]]; then
    echo -e "${RED}Error: Environment directory '$ENV_PATH' not found!${NC}"
    exit 1
fi

cd "$ENV_PATH"

# Function to execute with retry logic
retry_with_backoff() {
    local operation_name="$1"
    local command="$2"
    local attempt=1
    
    while [[ $attempt -le $MAX_RETRIES ]]; do
        echo -e "${YELLOW}Attempt $attempt/$MAX_RETRIES for $operation_name...${NC}"
        
        # Refresh Azure auth before each retry (except first)
        if [[ $attempt -gt 1 ]]; then
            echo -e "${CYAN}Refreshing Azure authentication...${NC}"
            az account get-access-token --output none || true
        fi
        
        # Execute the command
        if eval "$command"; then
            echo -e "${GREEN}$operation_name completed successfully!${NC}"
            return 0
        else
            local exit_code=$?
            echo -e "${RED}Attempt $attempt failed with exit code $exit_code${NC}"
            
            if [[ $attempt -lt $MAX_RETRIES ]]; then
                echo -e "${YELLOW}Waiting $RETRY_DELAY seconds before retry...${NC}"
                sleep $RETRY_DELAY
            else
                echo -e "${RED}All attempts failed for $operation_name${NC}"
                return $exit_code
            fi
        fi
        
        ((attempt++))
    done
}

# Main execution logic
if [[ "$FIRST_DEPLOY" == true && "$ACTION" == "apply" ]]; then
    echo -e "${CYAN}FIRST DEPLOYMENT: Running modules in dependency order...${NC}"
    
    # Step 1: Independent modules first
    independent_modules=("monitoring" "network" "sql")
    for module in "${independent_modules[@]}"; do
        echo -e "${YELLOW}Applying $module...${NC}"
        if ! retry_with_backoff "$module Apply" "terragrunt apply --auto-approve --terragrunt-working-dir $module"; then
            echo -e "${RED}Failed to apply $module${NC}"
            exit 1
        fi
    done
    
    # Step 2: KeyVault (depends on SQL and monitoring)
    echo -e "${YELLOW}Applying KeyVault (depends on SQL and monitoring)...${NC}"
    if ! retry_with_backoff "KeyVault Apply" "terragrunt apply --auto-approve --terragrunt-working-dir keyvault"; then
        echo -e "${RED}Failed to apply KeyVault${NC}"
        exit 1
    fi
    
    # Step 3: AKS (depends on monitoring and network)
    echo -e "${YELLOW}Applying AKS (depends on monitoring and network)...${NC}"
    if ! retry_with_backoff "AKS Apply" "terragrunt apply --auto-approve --terragrunt-working-dir aks"; then
        echo -e "${RED}Failed to apply AKS${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}First deployment completed successfully!${NC}"
else
    # Normal run-all operation for subsequent deployments or plans
    echo -e "${YELLOW}Running terragrunt run-all $ACTION...${NC}"
    
    case $ACTION in
        plan)
            command="terragrunt run-all plan --terragrunt-parallelism 1"
            ;;
        apply)
            command="terragrunt run-all apply --auto-approve --terragrunt-parallelism 1"
            ;;
        destroy)
            command="terragrunt run-all destroy --auto-approve --terragrunt-parallelism 1"
            ;;
    esac
    
    if retry_with_backoff "Terragrunt $ACTION" "$command"; then
        echo -e "${GREEN}Operation completed successfully!${NC}"
    else
        echo -e "${RED}Operation failed with exit code $?${NC}"
        exit 1
    fi
fi