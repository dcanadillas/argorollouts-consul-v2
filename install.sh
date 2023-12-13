#! /bin/bash
# set -e 

CONSUL_K8S_VERSION="1.3.0"
CONSUL_VALUES="./consul.yaml"
CONSUL_VERSION="1.17.0-ent"
CHART_REPO="hashicorp/consul"
LICENSE_FILE="/Users/david/SynologyDrive/HashiCorp_Personal/Licenses/consul-202410.hclic"
CONSUL_LICENSE="$(cat $LICENSE_FILE)"
# CHART_REPO="hashicorp/consul"

# echo $CONSUL_LICENSE

# read -p "..."

# Color
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
DGRN=$(tput setaf 2)
GRN=$(tput setaf 10)
YELL=$(tput setaf 3)
NC=$(tput sgr0) #No color


consul_prep () {
  kubectl create ns consul || true
  kubectl create secret generic consul-ent-license -n consul --from-literal license="$CONSUL_LICENSE"
  kubectl create secret generic consul-bootstrap-token -n consul --from-literal token=ConsulR0cks
}

install_consul () {
  local values=$1
  local chart_version=$2
  if echo $3 | grep -q ".*-ent$";then
    local consul_version="$3-ent"
  else
    local consul_version="$3"
  fi

  # helm upgrade -i consul -n consul -f $values --version $chart_version $CHART_REPO --debug --wait
  helm upgrade -i consul -n consul -f $values \
  --set "image=hashicorp/consul-enterprise:$consul_version" \
  --set "imageK8s=hashicorp/consul-k8s-control-plane:$chart_version" \
  --set "imageConsulDataplane=hashicorp/consul-k8s-control-plane:$chart_version" \
  --version $chart_version \
  $CHART_REPO --debug
}


install_argo_rollouts () {
  kubectl create namespace argo-rollouts || true
  kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml || true
}

apps () {
  kubectl apply -f demoapp/dcanadillas 
  kubectl apply -f demoapp/permissions
}

# install_api_gw () {
#   # This deploys the pods, the services and the service-defaults
#   kubectl apply -f demoapp/dcanadillas
#   # # Ensure that API Gateways previously installed are deleted
#   # kubectl delete -f demoapp/api-gw
#   # Deploy the API GW 
#   kubectl apply -f $1
#   # This will wait for the api-gateway service to get an IP
#   # kubectl get service -w api-gateway -o 'go-template={{with .status.loadBalancer.ingress}}{{range .}}{{.ip}}{{"\n"}}{{end}}{{.err}}{{end}}' 2>/dev/null| head -n1
#   until kubectl get svc/api-gateway -o jsonpath='{.status.loadBalancer}' | grep "ingress"; do : ; done
  
#   # And now the HTTPRoute
#   sleep 10
#   kubectl apply -f demoapp/api-gw/httproute-front.yaml
# }

test_app () {
  kubectl wait --for=condition=Ready po -l app=proxy --timeout=60s
  sleep 5
  for i in {1..4};do
    kubectl exec -ti deploy/nginx -c nginx -- curl frontend:8080
    kubectl exec -ti deploy/nginx -c nginx -- curl frontend:8080/full
    # curl http://$(kubectl get gateway -o jsonpath='{.status.addresses[0].value}' api-gateway):9090
    echo -e "\n"
  done
}


# Checking secrets and installing them if not existing
if kubectl get secret consul-ent-license -n consul && kubectl get secret consul-bootstrap-token -n consul; then
  echo -e "Secrets are in place..."
else
  echo -e "${GRN}Creating required bootstrap and license secrets...${NC}"
  consul_prep
fi
echo -e "\n\n"


# Install Consul
echo -e "${GRN}Installing Consul 1.17 with API Gateway... ${NC}"
install_consul $CONSUL_VALUES $CONSUL_K8S_VERSION $CONSUL_VERSION
echo -e "\n\n"

# Install ArgoRollouts
echo -e "${GRN}Installing ArgoRollouts... ${NC}"
install_argo_rollouts
echo -e "\n\n"

# Deploying apps
echo -e "${GRN}Deploying example applications and traffic permissions... ${NC}"
apps
echo -e "\n\n"

# # Install a demo application and the API Gateway to route to it
# echo -e "${GRN}Deploying a demo app and API Gateway... ${NC}"
# install_api_gw demoapp/api-gw/api-gw-115.yaml
# echo -e "\n"

echo -e "${YELL}Testing app response from nginx deployment... ${NC}"
sleep 5
test_app
echo -e "\n\n"

# echo -e "${DGRN}Is the app working? ${NC}"
# read -p "${YELL}Press any key to continue to upgrade Consul (Ctrl-C to Cancel)...${NC}"
# echo -e "\n"


# echo -e "${YELL}Testing app response from new Gateway... ${NC}"
# test_app
# echo -e "\n\n"

