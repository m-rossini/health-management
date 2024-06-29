#v!/bin/bash
# Function to display help message
print_help() {
  echo "Usage: $0 <pod_name>"
  echo "  pod_name: The name of the pod to be create."
}

# Parse arguments
if [[ $# -lt 1 ]]; then
  echo "Error: Missing image name argument."
  print_help
  exit 1
fi

HOST_NAME="$1"
POD_NAME="$2"
CREATE_COMMAND="podman pod create --hostname $HOST_NAME --memory 8G --userns=keep-id --network marcos-net -p8080:80 -p5000:5000 -p5001:5001 -p5002:5002 -p5003:5003 $POD_NAME"
echo $CREATE_COMMAND
eval $CREATE_COMMAND