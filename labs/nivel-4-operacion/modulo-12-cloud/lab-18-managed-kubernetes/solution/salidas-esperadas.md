# Lab 18: Managed Kubernetes - Salidas Esperadas

Este documento muestra las salidas esperadas de los comandos del laboratorio. Dado que este laboratorio es principalmente exploratorio y requiere cuentas cloud para ejecutar los comandos reales, las salidas mostradas aqui son ejemplos representativos.

## Paso 1: Verificar herramientas disponibles

### gcloud version (si esta instalado)

```
$ gcloud version
Google Cloud SDK 458.0.1
bq 2.0.101
core 2024.01.26
gcloud-crc32c 1.0.0
gsutil 5.27
```

### aws --version (si esta instalado)

```
$ aws --version
aws-cli/2.15.10 Python/3.11.6 Linux/6.1.0 exe/x86_64.ubuntu.22
```

### eksctl version (si esta instalado)

```
$ eksctl version
0.169.0
```

### az version (si esta instalado)

```
$ az version
{
  "azure-cli": "2.56.0",
  "azure-cli-core": "2.56.0",
  "azure-cli-telemetry": "1.1.0",
  "extensions": {}
}
```

## Paso 3: Comandos de GKE

### gcloud container clusters create (ejemplo de salida)

```
$ gcloud container clusters create demo-cluster \
  --zone us-central1-a \
  --num-nodes 3 \
  --machine-type e2-medium

Creating cluster demo-cluster in us-central1-a... Cluster is being health-checked (master is healthy)...done.
Created [https://container.googleapis.com/v1/projects/my-project/zones/us-central1-a/clusters/demo-cluster].
To inspect the contents of your cluster, go to: https://console.cloud.google.com/kubernetes/workload_/gcloud/us-central1-a/demo-cluster?project=my-project
kubeconfig entry generated for demo-cluster.
NAME          LOCATION       MASTER_VERSION   MASTER_IP      MACHINE_TYPE  NODE_VERSION     NUM_NODES  STATUS
demo-cluster  us-central1-a  1.28.5-gke.1200  34.123.45.67   e2-medium     1.28.5-gke.1200  3          RUNNING
```

### gcloud container clusters get-credentials

```
$ gcloud container clusters get-credentials demo-cluster --zone us-central1-a
Fetching cluster endpoint and auth data.
kubeconfig entry generated for demo-cluster.
```

### kubectl get nodes (GKE)

```
$ kubectl get nodes
NAME                                          STATUS   ROLES    AGE   VERSION
gke-demo-cluster-default-pool-a1b2c3d4-abcd   Ready    <none>   5m    v1.28.5-gke.1200
gke-demo-cluster-default-pool-a1b2c3d4-efgh   Ready    <none>   5m    v1.28.5-gke.1200
gke-demo-cluster-default-pool-a1b2c3d4-ijkl   Ready    <none>   5m    v1.28.5-gke.1200
```

## Paso 4: Comandos de EKS

### eksctl create cluster (ejemplo de salida)

```
$ eksctl create cluster \
  --name demo-cluster \
  --region us-east-1 \
  --nodegroup-name workers \
  --node-type t3.medium \
  --nodes 3

2024-01-26 10:00:00 [i]  eksctl version 0.169.0
2024-01-26 10:00:00 [i]  using region us-east-1
2024-01-26 10:00:01 [i]  setting availability zones to [us-east-1a us-east-1b]
2024-01-26 10:00:01 [i]  subnets for us-east-1a - public:192.168.0.0/19 private:192.168.64.0/19
2024-01-26 10:00:01 [i]  subnets for us-east-1b - public:192.168.32.0/19 private:192.168.96.0/19
2024-01-26 10:00:01 [i]  using Kubernetes version 1.28
2024-01-26 10:00:01 [i]  creating EKS cluster "demo-cluster" in "us-east-1" region with managed nodes
...
2024-01-26 10:15:00 [✔]  EKS cluster "demo-cluster" in "us-east-1" region is ready
```

### kubectl get nodes (EKS)

```
$ kubectl get nodes
NAME                             STATUS   ROLES    AGE   VERSION
ip-192-168-10-100.ec2.internal   Ready    <none>   5m    v1.28.5-eks-5e0fdde
ip-192-168-20-200.ec2.internal   Ready    <none>   5m    v1.28.5-eks-5e0fdde
ip-192-168-30-150.ec2.internal   Ready    <none>   5m    v1.28.5-eks-5e0fdde
```

### eksctl get cluster

```
$ eksctl get cluster --name demo-cluster
NAME           REGION      EKSCTL CREATED
demo-cluster   us-east-1   True
```

## Paso 5: Comandos de AKS

### az aks create (ejemplo de salida)

```
$ az aks create \
  --resource-group demo-rg \
  --name demo-cluster \
  --node-count 3 \
  --node-vm-size Standard_B2s \
  --generate-ssh-keys

{
  "aadProfile": null,
  "addonProfiles": null,
  "agentPoolProfiles": [
    {
      "count": 3,
      "name": "nodepool1",
      "osDiskSizeGb": 128,
      "osType": "Linux",
      "vmSize": "Standard_B2s",
      ...
    }
  ],
  "dnsPrefix": "demo-cluster-demo-rg-abc123",
  "fqdn": "demo-cluster-demo-rg-abc123.hcp.eastus.azmk8s.io",
  "id": "/subscriptions/.../resourceGroups/demo-rg/providers/Microsoft.ContainerService/managedClusters/demo-cluster",
  "kubernetesVersion": "1.28.5",
  "location": "eastus",
  "name": "demo-cluster",
  "nodeResourceGroup": "MC_demo-rg_demo-cluster_eastus",
  "provisioningState": "Succeeded",
  ...
}
```

### az aks get-credentials

```
$ az aks get-credentials --resource-group demo-rg --name demo-cluster
Merged "demo-cluster" as current context in /home/user/.kube/config
```

### kubectl get nodes (AKS)

```
$ kubectl get nodes
NAME                                STATUS   ROLES   AGE   VERSION
aks-nodepool1-12345678-vmss000000   Ready    agent   5m    v1.28.5
aks-nodepool1-12345678-vmss000001   Ready    agent   5m    v1.28.5
aks-nodepool1-12345678-vmss000002   Ready    agent   5m    v1.28.5
```

## Paso 9: Ejercicio Practico con Minikube

### Crear ServiceAccount

```
$ kubectl create serviceaccount cloud-demo-sa --dry-run=client -o yaml | kubectl apply -f -
serviceaccount/cloud-demo-sa created
```

### Crear Pod

```
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
...
EOF
pod/cloud-demo-pod created
```

### Verificar token montado

```
$ kubectl exec cloud-demo-pod -- ls -la /var/run/secrets/kubernetes.io/serviceaccount/
total 4
drwxrwxrwt 3 root root  140 Jan 26 10:00 .
drwxr-xr-x 3 root root 4096 Jan 26 10:00 ..
drwxr-xr-x 2 root root  100 Jan 26 10:00 ..2024_01_26_10_00_00.123456789
lrwxrwxrwx 1 root root   31 Jan 26 10:00 ..data -> ..2024_01_26_10_00_00.123456789
lrwxrwxrwx 1 root root   13 Jan 26 10:00 ca.crt -> ..data/ca.crt
lrwxrwxrwx 1 root root   16 Jan 26 10:00 namespace -> ..data/namespace
lrwxrwxrwx 1 root root   12 Jan 26 10:00 token -> ..data/token
```

### Ver token del ServiceAccount

```
$ kubectl exec cloud-demo-pod -- cat /var/run/secrets/kubernetes.io/serviceaccount/token | head -c 100
eyJhbGciOiJSUzI1NiIsImtpZCI6IjEyMzQ1Njc4OTAifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRl...
```

## Limpieza

### GKE

```
$ gcloud container clusters delete demo-cluster --zone us-central1-a --quiet
Deleting cluster demo-cluster...done.
Deleted [https://container.googleapis.com/v1/projects/my-project/zones/us-central1-a/clusters/demo-cluster].
```

### EKS

```
$ eksctl delete cluster --name demo-cluster --region us-east-1
2024-01-26 11:00:00 [i]  deleting EKS cluster "demo-cluster"
2024-01-26 11:00:01 [i]  will drain 1 nodegroup(s) in cluster "demo-cluster"
...
2024-01-26 11:15:00 [✔]  all cluster resources were deleted
```

### AKS

```
$ az group delete --name demo-rg --yes --no-wait
```

## Notas Importantes

### Diferencias en nombres de nodos

| Proveedor | Formato del nombre de nodo        |
| --------- | --------------------------------- |
| GKE       | gke-{cluster}-{pool}-{hash}-{id}  |
| EKS       | ip-{ip}.{region}.compute.internal |
| AKS       | aks-{pool}-{vmss-id}-vmss{number} |

### Tiempos de creacion tipicos

| Proveedor | Tiempo aproximado |
| --------- | ----------------- |
| GKE       | 5-10 minutos      |
| EKS       | 15-20 minutos     |
| AKS       | 8-15 minutos      |

### Costos mensuales estimados (3 nodos pequenos)

| Proveedor | Control Plane | Compute (3 nodos) | Total     |
| --------- | ------------- | ----------------- | --------- |
| GKE       | $0            | ~$75-100          | ~$75-100  |
| EKS       | ~$73          | ~$100-150         | ~$173-223 |
| AKS       | $0            | ~$75-100          | ~$75-100  |

> **Importante**: Estos son estimados. Consulta las calculadoras oficiales para precios actuales.
