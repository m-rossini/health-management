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
  ./stop-pod.sh 'weight-pod'
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error: Failed to stop and remove pod '$POD_NAME' on local server.${NC}"
    exit 1
  fi
fi

DEPLOY_WEIGHT="./deploy-weight-dev.sh"
echo "Deploying weigth server to dev as: $DEPLOY_WEIGHT "
eval $DEPLOY_WEIGHT

DEPLOY_USER="./deploy-user-dev.sh"
echo "Deploying user server to dev as: $DEPLOY_USER "
eval $DEPLOY_USER
