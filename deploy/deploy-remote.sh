#!/usr/bin/zsh
# set -x
# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

# Define project directory prefix (adjust if needed)
PREFIX_DIR=".." # Points to the directory one level above the script

# Define default values
WEIGHT_HOST="weight-host"
SERVER_NAME="$2"
REMOTE_USER="rossini"
REMOTE_HOST="rossini"

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
  --remote-dir)
    REMOTE_DIR="$2"
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
if [[ -z "$IMAGE_NAME" || -z "$PREFIX_DIR" || -z "$POD_NAME" || -z "$WEIGHT_HOST" || -z "$SERVER_NAME" ]]; then
  echo -e "${RED}Error: Missing mandatory arguments.${NC}"
  echo -e "${WHITE}Usage: $0 --image-name <image_name> --remote-dir <remote_dir> --pod-name <pod_name> --weight-host <weight_host> --server-name <server_name> --prefix-dir <prefix_dir> --dockerfile <dockerfile> [--remove-all | --remove]${NC}"
  exit 1
fi

REQUIREMENTS_FILE="$PREFIX_DIR/requirements.txt"
DOCKERFILE_PATH="$PREFIX_DIR/$DOCKERFILE"
echo -e "${WHITE}Building image: $IMAGE_NAME (using $REQUIREMENTS_FILE and $DOCKERFILE)...${NC}"
podman build -t "$IMAGE_NAME" -f "$DOCKERFILE" $PREFIX_DIR

if [[ $? -ne 0 ]]; then
  echo -e "${RED}Error: Failed to build image '$IMAGE_NAME'.${NC}"
  exit 1
fi

# Use podman image scp to copy the image to the remote server
echo -e "${WHITE}Copying image to remote server...${NC}"
IMAGE_COPY_COMMAND="podman image scp $IMAGE_NAME ${REMOTE_USER}@${REMOTE_HOST}"

if [[ $? -ne 0 ]]; then
  echo -e "${RED}Error: Failed to copy image '$IMAGE_NAME' to remote server.${NC}"
  exit 1
fi

# Create remote directory if it doesn't exist
ssh "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p ${REMOTE_DIR}"

# Prefix the files to be copied
cp ./create-pod.sh ./to_be_copied_create-pod.sh
cp ./run-container.sh ./to_be_copied_run-container.sh

# Copy necessary files to remote server
echo -e "${WHITE}Copying deployment files to remote server...${NC}"
scp to_be_copied_* "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"

ssh "${REMOTE_USER}@${REMOTE_HOST}" <<EOF
  mv ${REMOTE_DIR}/to_be_copied_create-pod.sh ${REMOTE_DIR}/create-pod.sh
  mv ${REMOTE_DIR}/to_be_copied_run-container.sh ${REMOTE_DIR}/run-container.sh
  mv ${REMOTE_DIR}/to_be_copied_remote-deploy.sh ${REMOTE_DIR}/deploy-local.sh
EOF

ssh "${REMOTE_USER}@${REMOTE_HOST}" "chmod +x ${REMOTE_DIR}/*.sh"
if [[ "$REMOVE" = true ]]; then
  scp ./stop-container.sh $REMOTE_USER@$REMOTE_HOST:${REMOTE_DIR}/stop-container.sh
  ssh $REMOTE_USER@$REMOTE_HOST "chmod +x ${REMOTE_DIR}/stop-container.sh && ${REMOTE_DIR}/stop-container.sh $SERVER_NAME"
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error: Failed to stop and remove container '$SERVER_NAME' on remote server.${NC}"
    exit 1
  fi
fi

# Execute the remote deployment script
echo -e "${WHITE}Executing remote deployment script...${NC}"
ssh "${REMOTE_USER}@${REMOTE_HOST}" "${REMOTE_DIR}/deploy-local.sh ${IMAGE_NAME} ${REMOTE_DIR} ${POD_NAME} ${WEIGHT_HOST} ${SERVER_NAME}"
if [[ $? -ne 0 ]]; then
  echo -e "${RED}Error: Remote deployment failed.${NC}"
  exit 1
fi

echo -e "${GREEN}Remote deployment successful!${NC}"

# Clean up the local prefixed files
rm -f ./to_be_copied_create-pod.sh
rm -f ./to_be_copied_run-container.sh
