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

PROJECT="weight/user-server"
REMOTE_DIR="/home/rossini/deployment/${PROJECT}"


DEPLOY_ALL="\
./deploy-remote.sh \
--image-name user-server \
--pod-name 'weight-pod' \
--weight-host 'weight-host' \
--server-name 'user-server' \
--prefix-dir '../weight-user/' \
--dockerfile 'Dockerfile' \
--remote-dir $REMOTE_DIR \
$REMOVE_ALL"
echo "Deploying to prod as: $DEPLOY_ALL"
eval $DEPLOY_ALL