#! /bin/bash
# set -e 

# Color
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
DGRN=$(tput setaf 2)
GRN=$(tput setaf 10)
YELL=$(tput setaf 3)
NC=$(tput sgr0) #No color



uninstall_consul () {
  consul-k8s uninstall -wipe-data -auto-approve
}

uninstall_argo_rollouts () {
  kubectl delete -n $1 -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml || true
  kubectl delete namespace $1 || true
}

delete_apps () { 
  kubectl delete -f demoapp/permissions
  kubectl delete -f demoapp/dcanadillas
}

# Ask for confirmation
read -p "${YELL}Are you sure you want to delete all the resources? [y/N]: ${NC}" CONFIRMATION
if [ "$CONFIRMATION" != "y" ];then
  echo -e "${RED}Aborting...${NC}"
  exit 1
fi

# Cleaning apps
echo -e "${GRN}Deleting example applications and traffic permissions... ${NC}"
delete_apps
echo -e "\n\n"

# Uninstall ArgoRollouts
echo -e "${GRN}Uninstalling ArgoRollouts... ${NC}"
uninstall_argo_rollouts argo-rollouts
echo -e "\n\n"

# Uninstall Consul
echo -e "${GRN}Uninstalling Consul... ${NC}"
uninstall_consul
kubectl delete ns consul || true
echo -e "\n\n"




