#!/usr/bin/zsh
# set -x
# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

stop_and_remove_container() {
  # Check if required argument is provided
  if [ $# -eq 0 ]; then
    echo "${RED}Error: Please provide a string to match container names.${NC}"
    exit 1
  fi
  local CONTAINER_NAME=$1
  containers=$(podman ps -a --filter name="$CONTAINER_NAME" --format "{{.ID}}")
  if [[ -z "$containers" ]]; then
    echo "${YELLOW}No container found with a name matching '$search_string'${NC}"
    exit 0
  fi

  container_id=$(echo "$containers" | cut -d ' ' -f 1)
  echo "${WHITE}Stopping container: (ID: $container_id)${NC}"
  podman rm -f $container_id
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error: Failed to remove pod $CONTAINER_NAME.${NC}"
    return 1
  fi

  echo -e "${GREEN}Container '$CONTAINER_NAME' was successfully stopped and removed.${NC}"
}

# Execute the function
stop_and_remove_container "$1"
