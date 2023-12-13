# Consul test with Argo Rollouts and Catalog v2

## Requirements

* Kubernetes cluster deployed (use Minikube, Kind or MicroK8s for quick deployment)
* kubectl CLI installed
* Helm installed
* Linux or MacOS terminal

## Installing Environment

You can install install the environment using the provided dummy script:
```
./install.sh
```

> NOTE: Change the variable `LICENSE_FILE` definition in the script `install.sh` to point your license file to use Consul Enterprise. If you want to use Consul Community you need to change the variable at the beginning of the script with `CONSUL_VERSION=1.17.0`

For the demo application manifests at `demoapp/dcanadillas`  there are two services that points to the same pods that will be part of the canary and stable versions:
* service `canary-front` will be for canary deployments
* service `frontend` will be for stable ones


## Canary deployment

Apply the argo object:
```
kubectl apply -f demoapp/argorollouts/rollouts.yaml
```

Wait till the first rollout is healthy:
```
kubectl argo rollouts get rollouts frontend-rollout -w 
```

Then you should see two different pods with `frontend-rollout-*`. At first they are same replicas from the stable version. So `canary-front` and `frontend` service should load balance to those two pods.


Let's do the rollout with a new version for the frontend application:
```
kubectl argo rollouts set image frontend-rollout frontend=hcdcanadillas/pydemo-front:v1.7
```

Check the progress of the rollout status of `revision:2`:
```
kubectl argo rollouts get rollouts frontend-rollout -w 
```

Now Argo Rollouts should have created the new pod and changed the endpoint of the `canary-front` service to point out
```
kubectl exec -ti deploy/nginx -c nginx -- curl frontend:8080
```
```
kubectl exec -ti deploy/nginx -c nginx -- curl canary-front:8080
```

## Consul v2 API
Here there are some of the commands to use the v2 API to get information about Consul Catalog (services, worloads and endpoints)

Get services from API:
```
consul resource list catalog.v2beta1.Service

consul resource list catalog.v2beta1.Service | jq -r .resources[].id.name
```


```
curl -k https://localhost:8501/api/catalog/v2beta1/serviceendpoints | jq -r .resources[].data.endpoints[]

curl -k https://localhost:8501/api/catalog/v2beta1/workload | jq .resources[].id

curl -k https://localhost:8501/api/catalog/v2beta1/service | jq -r .resources[].id
```