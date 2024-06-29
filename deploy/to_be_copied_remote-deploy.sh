#!/usr/bin/zsh

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
WHITE='\033[0;37m'
NC='\033[0m'  # No Color

# Define default values
IMAGE_NAME=$1  # Image name passed as argument
PREFIX_DIR=$2  # Directory on remote machine
POD_NAME=$3  # Name of the pod
WEIGHT_HOST=$4
SERVER_NAME=$5

# Check if pod exists, create it if necessary
POD_EXISTS=$(podman pod ls --format "{{.Name}}" | grep -w "$POD_NAME" | wc -l)
echo -e "${WHITE}Checking if pod '$POD_NAME' exists... Found: $POD_EXISTS pods.${NC}"
if [[ $POD_EXISTS -eq 0 ]]; then
  echo -e "${YELLOW}Pod '$POD_NAME' not found. Creating...${NC}"
  $PREFIX_DIR/create-pod.sh "$WEIGHT_HOST" "$POD_NAME"  # Pass host_name and pod_name
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error: Failed to create pod '$POD_NAME'.${NC}"
    exit 1
  fi
fi

# Deploy image with run-container.sh script
echo -e "${WHITE}Deploying image '$IMAGE_NAME' to pod '$POD_NAME'...${NC}"
RUN_CONTAINER_COMMAND="$PREFIX_DIR/run-container.sh $IMAGE_NAME $POD_NAME $SERVER_NAME"
echo "Running ${RUN_CONTAINER_COMMAND}"
eval $RUN_CONTAINER_COMMAND

if [[ $? -ne 0 ]]; then
  echo -e "${RED}Error: Failed to deploy image '$IMAGE_NAME'.${NC}"
  exit 1
fi

echo -e "${GREEN}Deployment successful!${NC}"
