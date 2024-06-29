#!/usr/bin/zsh

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

# Define default values
REMOVE=false
# Parse arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
  --remove)
    REMOVE=true
    shift # past argument
    ;;
  --image-name)
    IMAGE_NAME="$2"
    shift # past argument
    shift # past value
    ;;
  --pod-name)
    POD_NAME="$2"
    shift # past argument
    shift # past value
    ;;
  --weight-host)
    WEIGHT_HOST="$2"
    shift # past argument
    shift # past value
    ;;
  --server-name)
    SERVER_NAME="$2"
    shift # past argument
    shift # past value
    ;;
  --prefix-dir)
    PREFIX_DIR="$2"
    shift # past argument
    shift # past value
    ;;
  --dockerfile)
    DOCKERFILE="$2"
    shift # past argument
    shift # past value
    ;;
  *)
    echo -e "${RED}Unknown option: $key${NC}"
    exit 1
    ;;
  esac
done

# Validate mandatory arguments
if [[ -z "$IMAGE_NAME" || -z "$POD_NAME" || -z "$WEIGHT_HOST" || -z "$SERVER_NAME" ]]; then
  echo -e "${RED}Error: Missing mandatory arguments.${NC}"
  echo -e "${WHITE}Usage: $0 --image-name <image_name> --pod-name <pod_name> --weight-host <weight_host> --server-name <server_name> --prefix-dir <prefix_dir> --dockerfile <dockerfile> [--remove-all | --remove]${NC}"
  exit 1
fi

REQUIREMENTS_FILE="$PREFIX_DIR/requirements-dev.txt"
DOCKERFILE_PATH="$PREFIX_DIR/$DOCKERFILE"
echo -e "${WHITE}Building image: $IMAGE_NAME (using $REQUIREMENTS_FILE and $DOCKERFILE_PATH)...${NC}"
podman build -t "$IMAGE_NAME" -f "$DOCKERFILE" $PREFIX_DIR
if [[ $? -ne 0 ]]; then
  echo -e "${RED}Error: Failed to build image '$IMAGE_NAME'.${NC}"
  exit 1
fi

if [[ "$REMOVE" = true ]]; then
  ./stop-container.sh $SERVER_NAME
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error: Failed to stop and remove container '$SERVER_NAME' on local server.${NC}"
    exit 1
  fi
fi

# Check if pod exists, create it if necessary
POD_EXISTS=$(podman pod ls --format "{{.Name}}" | grep -w "$POD_NAME" | wc -l)
if [[ $POD_EXISTS -eq 0 ]]; then
  echo -e "${YELLOW}Pod '$POD_NAME' not found. Creating...${NC}"
  ./create-pod.sh "$WEIGHT_HOST" "$POD_NAME" # Pass host_name and pod_name
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error: Failed to create pod '$POD_NAME'.${NC}"
    exit 1
  fi
fi

# Deploy image with run-container.sh script
echo -e "${WHITE}Deploying image '$IMAGE_NAME' to pod '$POD_NAME'...${NC}"
./run-container.sh "$IMAGE_NAME" "$POD_NAME" "$SERVER_NAME"

if [[ $? -ne 0 ]]; then
  echo -e "${RED}Error: Failed to deploy image '$IMAGE_NAME'.${NC}"
  exit 1
fi

echo -e "${GREEN}Local Deployment successful!${NC}"
