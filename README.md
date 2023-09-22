#AWS_EKS

This repo contains config to create an EKS cluster in a network-defined VPC. The cluster is created with add-ons such as vpc-cni, core-dns and kube-proxy via terraform.

#Module
1. VPC
2. EKS

To create resources via Terraform:

```
terraform init
terraform plan
terraform apply
```

#EKSCTL

We can also create an EKS cluster with simple configuration via EKSCTL. The config can be found in `eksctl` folder.

To create cluster:
```
eksctl create cluster -f eksctl/cluster.yaml
```

To Create Nodegroups:
```
eksctl create nodegroup -f eksctl/cluster.yaml
```

To Crete Addon:
```
eksctl create addon -f eksctl/cluster.yaml
```

#Install Metrics-server on EKS using Helm
```
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm upgrade --install metrics-server --namespace metrics --create-namespace metrics-server/metrics-server
```

#Install Nginx-Ingress on EKS using Helm
```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install nginx --namespace kube-system ingress-nginx/ingress-nginx -f helm-values.yaml
```

#Install External-DNS
```
helm upgrade --install external-dns -n kube-system external-dns/external-dns
```

#Enable Cluster-Autoscaler
```
helm install cluster-autoscaler -n kube-system autoscaler/cluster-autoscaler --set 'autoDiscovery.clusterName'=basic-cluster --set awsRegion=eu-north-1
```

#Install Mimir using Helm
```
kubectl create namespace mimir
helm -n mimir install mimir grafana/mimir-distributed -f mimir/helm-values.yaml
```

#Install Prometheus using Helm
```
kubectl create namespace prometheus
helm install prom --namespace prometheus prometheus-community/prometheus -f prometheus/helm-values.yaml --set server.remoteWrite[0].url=http://mimir.coffee-bean.xyz/api/v1/push
```

#Install Grafana using Helm
```
kubectl create namespace grafana
helm install graf --namespace grafana grafana/grafana -f grafana/helm-values.yaml
```

#Install opensearch using Helm
```
kubectl create namespace opensearch
helm install opensearch -n opensearch  opensearch/opensearch -f opensearch/helm-values.yaml
helm install elk -n opensearch opensearch/opensearch-dashboards -f opensearch-dashboards/helm-values.yaml
```

#Install certificate manager using helm
```
kubectl create namespace cert-manager
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.7.2 --set installCRDs=true
```

#Install Loki-stack using Helm
```
kubectl create ns loki
helm install loki -n loki -f loki-stack .
```