#!/usr/bin/zsh

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
WHITE='\033[0;37m'
NC='\033[0m'  # No Color

# Function to stop all containers in a pod and remove the pod
stop_and_remove_pod() {
  local POD_NAME=$1
  POD_EXISTS=$(podman pod ls --format "{{.Name}}" | grep -w "$POD_NAME" | wc -l)
  if [[ $POD_EXISTS -eq 0 ]]; then
    echo -e "${YELLOW}Pod '$POD_NAME' does not exist. No action taken.${NC}"
    return 0
  fi

  # Get list of containers in the pod
  CONTAINER_IDS=$(podman ps -a --filter="pod=$POD_NAME" --format="{{.ID}}")

  # Iterate through each container ID
  echo "$CONTAINER_IDS" | while IFS= read -r CONTAINER_ID; do
    IS_INFRA=$(podman inspect --format="{{.IsInfra}}" $CONTAINER_ID)
    if [[ "$IS_INFRA" == "true" ]]; then
      echo -e "${YELLOW}Skipping removal of infrastructure container $CONTAINER_ID.${NC}"
      continue
    fi

    echo -e "${WHITE}Stopping container $CONTAINER_ID...${NC}"
    podman stop $CONTAINER_ID
    if [[ $? -ne 0 ]]; then
      echo -e "${RED}Error: Failed to stop container $CONTAINER_ID.${NC}"
      return 1
    fi

    echo -e "${WHITE}Removing container $CONTAINER_ID...${NC}"
    podman rm $CONTAINER_ID
    if [[ $? -ne 0 ]]; then
      echo -e "${RED}Error: Failed to remove container $CONTAINER_ID.${NC}"
      return 1
    fi
  done

  # Remove the pod
  echo -e "${WHITE}Removing pod $POD_NAME...${NC}"
  podman pod rm "$POD_NAME"
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error: Failed to remove pod $POD_NAME.${NC}"
    return 1
  fi

  echo -e "${GREEN}Pod '$POD_NAME' and its containers were successfully stopped and removed.${NC}"
}

# Execute the function
stop_and_remove_pod "$1"
