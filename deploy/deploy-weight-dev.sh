#!/usr/bin/zsh
REMOVE=""
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
  --remove)
    REMOVE="--remove"
    shift # past argument
    ;;
  *) # Unknown option
    echo "Error: Unknown option $key" >&2
    exit 1
    ;;
  esac
done

DEPLOY_ALL="\
./deploy-local.sh \
--image-name weight-server-dev \
--pod-name 'weight-pod' \
--weight-host 'weight-host' \
--server-name 'weight-server-dev' \
--prefix-dir '../weight-backend/' \
--dockerfile 'Dockerfile-dev' \
$REMOVE"
echo "Deploying to dev as: $DEPLOY_ALL"
eval $DEPLOY_ALL
