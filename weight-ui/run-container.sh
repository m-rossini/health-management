#!/bin/bash

# Function to display help message
print_help() {
  echo "Usage: $0 <image_name>"
  echo "  image_name: The name of the container image to deploy."
}

# Parse arguments
if [[ $# -lt 1 ]]; then
  echo "Error: Missing image name argument."
  print_help
  exit 1
fi

IMAGE_NAME="$1"
POD_NAME="$2"
SERVER_NAME="$3"

RUN_CONTAINER_COMMAND="podman run -d --name $SERVER_NAME --user root:root --pod $POD_NAME $IMAGE_NAME"
echo "Running command: $RUN_CONTAINER_COMMAND"
eval $RUN_CONTAINER_COMMAND
