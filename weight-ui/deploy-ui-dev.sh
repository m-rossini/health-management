#!/usr/bin/zsh

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

# Define default values
REMOVE="false"
# Parse arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
  --remove)
    REMOVE=true
    shift # past argument
    ;;
  *) # Unknown option
    echo "Error: Unknown option $key" >&2
    exit 1
    ;;
  esac
done

if [[ $REMOVE = true ]]; then
  ./stop-container.sh 'ui-server'
  REMOVE="--remove"
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error: Failed to stop and remove container 'ui-server' on local server.${NC}"
    exit 1
  fi
fi

# Check if pod exists, create it if necessary
POD_EXISTS=$(podman pod ls --format "{{.Name}}" | grep -w "weight-pod" | wc -l)
if [[ $POD_EXISTS -eq 0 ]]; then
  echo -e "${YELLOW}Pod 'weight-pod' not found. Creating...${NC}"
  ./create-pod.sh "weight-host" "weight-pod" # Pass host_name and pod_name
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error: Failed to create pod 'weight-pod'.${NC}"
    exit 1
  fi
fi

# Deploy image with run-container.sh script
DEPLOY_ALL="\
./deploy-local.sh \
--image-name ui-server \
--pod-name 'weight-pod' \
--weight-host 'weight-host' \
--server-name 'ui-server' \
--prefix-dir '.' \
--dockerfile 'Dockerfile' \
$REMOVE"

echo "Deploying UI to dev as: $DEPLOY_ALL"
eval $DEPLOY_ALL

if [[ $? -ne 0 ]]; then
  echo -e "${RED}Error: Failed to deploy image 'ui-server'.${NC}"
  exit 1
fi

echo -e "${GREEN}Local Deployment successful!${NC}"
