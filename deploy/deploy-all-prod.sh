#!/usr/bin/zsh
REMOVE_ALL=false
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
  --remove-all)
    REMOVE_ALL=true
    shift # past argument
    ;;
  *) # Unknown option
    echo "Error: Unknown option $key" >&2
    exit 1
    ;;
  esac
done

if [[ "$REMOVE_ALL" = true ]]; then
  REMOTE_USER='rossini'
  REMOTE_HOST='rossini'
  REMOTE_DIR='/home/rossini/deployment/weight'
  POD_NAME='weight-pod'
  scp ./stop-pod.sh $REMOTE_USER@$REMOTE_HOST:${REMOTE_DIR}/stop-pod.sh
  ssh $REMOTE_USER@$REMOTE_HOST "chmod +x ${REMOTE_DIR}/stop-pod.sh && ${REMOTE_DIR}/stop-pod.sh $POD_NAME"
  ./stop-pod.sh 'weight-pod'
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error: Failed to stop and remove pod '$POD_NAME' on remote server.${NC}"
    exit 1
  fi
fi

DEPLOY_WEIGHT="./deploy-weight-prod.sh"
echo "Deploying weigth server to prod as: $DEPLOY_WEIGHT "
eval $DEPLOY_WEIGHT

DEPLOY_USER="./deploy-user-prod.sh"
echo "Deploying user server to prod as: $DEPLOY_USER "
eval $DEPLOY_USER
