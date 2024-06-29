#!/usr/bin/zsh
REMOVE_ALL=""
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
  --remove-all)
    REMOVE_ALL="--remove-all"
    shift # past argument
    ;;
  --remove)
    REMOVE_ALL="--remove"
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
--image-name user-server-dev \
--pod-name 'weight-pod' \
--weight-host 'weight-host' \
--server-name 'user-server-dev' \
--prefix-dir '../weight-user/' \
--dockerfile 'Dockerfile-dev' \
$REMOVE_ALL"
echo "Deploying to dev as: $DEPLOY_ALL"
eval $DEPLOY_ALL
