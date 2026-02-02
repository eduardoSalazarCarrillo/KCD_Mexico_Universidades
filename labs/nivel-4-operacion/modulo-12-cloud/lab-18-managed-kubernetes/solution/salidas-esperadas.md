# Lab 18: Managed Kubernetes - Salidas Esperadas

Este documento muestra las salidas esperadas de los comandos del laboratorio. El script ahora permite seleccionar una plataforma cloud especifica (GKE, EKS, o AKS) para evitar crear multiples clusters innecesarios.

## Seleccion de Plataforma

Al iniciar el script, se presenta un menu de seleccion:

```
==============================================
  Selecciona tu Plataforma Cloud
==============================================

Por favor, selecciona la plataforma cloud que deseas utilizar:

  1) GKE - Google Kubernetes Engine (Google Cloud)
  2) EKS - Amazon Elastic Kubernetes Service (AWS)
  3) AKS - Azure Kubernetes Service (Microsoft Azure)
  4) Solo exploratorio (sin crear cluster)

Ingresa tu opcion (1-4):
```

## Paso 1: Verificar herramientas disponibles

El script solo verifica las herramientas de la plataforma seleccionada.

### Para GKE (opcion 1)

```
--- Google Cloud SDK (gcloud) ---

$ gcloud version
Google Cloud SDK 458.0.1
bq 2.0.101
core 2024.01.26
gcloud-crc32c 1.0.0
gsutil 5.27

INFO: gcloud esta instalado. Puedes usar GKE.

--- Verificando credenciales existentes ---

$ gcloud auth list --filter=status:ACTIVE --format='value(account)'
usuario@gmail.com
INFO: Ya estas autenticado como: usuario@gmail.com

$ gcloud config get-value project
mi-proyecto-gcp
INFO: Proyecto actual configurado: mi-proyecto-gcp

--- Habilitar API de Kubernetes Engine ---

$ gcloud services enable container.googleapis.com
Habilitando la API (puede tardar unos segundos)...
Operation "operations/..." finished successfully.
```

### Para EKS (opcion 2)

```
--- AWS CLI y eksctl ---

$ aws --version
aws-cli/2.15.10 Python/3.11.6 Linux/6.1.0 exe/x86_64.ubuntu.22
INFO: AWS CLI esta instalado.

$ eksctl version
0.169.0
INFO: eksctl esta instalado. Puedes usar EKS facilmente.
```

### Para AKS (opcion 3)

```
--- Azure CLI (az) ---

$ az version
{
  "azure-cli": "2.56.0",
  "azure-cli-core": "2.56.0",
  "azure-cli-telemetry": "1.1.0",
  "extensions": {}
}

INFO: Azure CLI esta instalado. Puedes usar AKS.
```

## Verificacion de Credenciales Existentes

Antes de solicitar autenticacion, el script verifica si ya existen credenciales configuradas.

### EKS - Verificacion de credenciales

```
--- Verificando credenciales existentes ---

$ aws sts get-caller-identity
INFO: Ya estas autenticado en AWS
INFO:   Cuenta: 123456789012
INFO:   ARN: arn:aws:iam::123456789012:user/mi-usuario

$ aws configure get region
us-east-1
INFO: Region configurada: us-east-1

--- Configurar credenciales AWS ---
Ya tienes credenciales configuradas. Deseas reconfigurar? (s/n):
```

### AKS - Verificacion de credenciales

```
--- Verificando credenciales existentes ---

$ az account show
INFO: Ya estas autenticado en Azure
INFO:   Suscripcion: Mi Suscripcion Azure
INFO:   ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
INFO:   Tenant: yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy

--- Autenticacion ---
Ya estas autenticado. Deseas re-autenticarte con otra cuenta? (s/n):
```

## Creacion de Cluster (Solo plataforma seleccionada)

### GKE - Crear cluster

```
--- Crear cluster GKE Standard con Workload Identity ---

Comando que se ejecutara (usando proyecto: my-project):
gcloud container clusters create demo-cluster \
  --zone us-central1-a \
  --num-nodes 3 \
  --machine-type e2-medium \
  --enable-ip-alias \
  --workload-pool=my-project.svc.id.goog

Deseas crear el cluster ahora? (s/n): s

Creating cluster demo-cluster in us-central1-a... Cluster is being health-checked (master is healthy)...done.
Created [https://container.googleapis.com/v1/projects/my-project/zones/us-central1-a/clusters/demo-cluster].
kubeconfig entry generated for demo-cluster.
NAME          LOCATION       MASTER_VERSION      MASTER_IP      MACHINE_TYPE  NODE_VERSION        NUM_NODES  STATUS
demo-cluster  us-central1-a  1.33.5-gke.2118001  34.123.45.67   e2-medium     1.33.5-gke.2118001  3          RUNNING

--- Verificar conexion ---

$ kubectl get nodes
NAME                                          STATUS   ROLES    AGE   VERSION
gke-demo-cluster-default-pool-a1b2c3d4-abcd   Ready    <none>   5m    v1.33.5-gke.2118001
gke-demo-cluster-default-pool-a1b2c3d4-efgh   Ready    <none>   5m    v1.33.5-gke.2118001
gke-demo-cluster-default-pool-a1b2c3d4-ijkl   Ready    <none>   5m    v1.33.5-gke.2118001
```

### GKE - Verificar Workload Identity

```
--- Crear GCP Service Account ---

$ gcloud iam service-accounts create gke-workload-demo --display-name="GKE Workload Identity Demo"
Created service account [gke-workload-demo].

--- Configurar IAM binding ---

$ gcloud iam service-accounts add-iam-policy-binding \
  gke-workload-demo@my-project.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:my-project.svc.id.goog[default/gcp-workload-identity-sa]"
Updated IAM policy for serviceAccount [gke-workload-demo@my-project.iam.gserviceaccount.com].
bindings:
- members:
  - serviceAccount:my-project.svc.id.goog[default/gcp-workload-identity-sa]
  role: roles/iam.workloadIdentityUser
etag: BwZJ2c_-nD4=
version: 1

--- Aplicar ServiceAccount y Pod ---

$ kubectl apply -f initial/gke-serviceaccount.yaml
serviceaccount/gcp-workload-identity-sa created
pod/gcp-workload-identity-demo created

--- Verificar autenticacion desde el pod ---

$ kubectl exec gcp-workload-identity-demo -- gcloud auth list
                      Credentialed Accounts
ACTIVE  ACCOUNT
*       gke-workload-demo@my-project.iam.gserviceaccount.com

To set the active account, run:
    $ gcloud config set account `ACCOUNT`
```

### EKS - Crear cluster

```
--- Crear cluster EKS con eksctl ---

Comando que se ejecutara:
eksctl create cluster \
  --name demo-cluster \
  --region us-east-1 \
  --nodegroup-name workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 1 \
  --nodes-max 5

Deseas crear el cluster ahora? (s/n): s

2024-01-26 10:00:00 [i]  eksctl version 0.169.0
2024-01-26 10:00:00 [i]  using region us-east-1
2024-01-26 10:00:01 [i]  setting availability zones to [us-east-1a us-east-1b]
2024-01-26 10:00:01 [i]  creating EKS cluster "demo-cluster" in "us-east-1" region with managed nodes
...
2024-01-26 10:15:00 [✔]  EKS cluster "demo-cluster" in "us-east-1" region is ready

--- Verificar conexion ---

$ kubectl get nodes
NAME                             STATUS   ROLES    AGE   VERSION
ip-192-168-10-100.ec2.internal   Ready    <none>   5m    v1.28.5-eks-5e0fdde
ip-192-168-20-200.ec2.internal   Ready    <none>   5m    v1.28.5-eks-5e0fdde
ip-192-168-30-150.ec2.internal   Ready    <none>   5m    v1.28.5-eks-5e0fdde
```

### AKS - Crear cluster

```
--- Crear grupo de recursos ---

$ az group create --name demo-rg --location eastus
{
  "id": "/subscriptions/.../resourceGroups/demo-rg",
  "location": "eastus",
  "name": "demo-rg",
  "properties": {
    "provisioningState": "Succeeded"
  }
}

--- Crear cluster AKS ---

Comando que se ejecutara:
az aks create \
  --resource-group demo-rg \
  --name demo-cluster \
  --node-count 3 \
  --node-vm-size Standard_B2s \
  --generate-ssh-keys \
  --enable-managed-identity \
  --enable-oidc-issuer \
  --enable-workload-identity

Deseas crear el cluster ahora? (s/n): s

{
  "agentPoolProfiles": [...],
  "dnsPrefix": "demo-cluster-demo-rg-abc123",
  "fqdn": "demo-cluster-demo-rg-abc123.hcp.eastus.azmk8s.io",
  "kubernetesVersion": "1.33.6",
  "location": "eastus",
  "name": "demo-cluster",
  "oidcIssuerProfile": {
    "enabled": true,
    "issuerUrl": "https://eastus.oic.prod-aks.azure.com/..."
  },
  "securityProfile": {
    "workloadIdentity": {
      "enabled": true
    }
  },
  "provisioningState": "Succeeded",
  ...
}

--- Verificar conexion ---

$ kubectl get nodes
NAME                                STATUS   ROLES   AGE   VERSION
aks-nodepool1-12345678-vmss000000   Ready    <none>  5m    v1.33.6
aks-nodepool1-12345678-vmss000001   Ready    <none>  5m    v1.33.6
aks-nodepool1-12345678-vmss000002   Ready    <none>  5m    v1.33.6
```

### AKS - Verificar Azure Workload Identity

```
--- Crear Managed Identity ---

$ az identity create --name demo-workload-identity --resource-group demo-rg
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "id": "/subscriptions/.../resourcegroups/demo-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/demo-workload-identity",
  "name": "demo-workload-identity",
  "principalId": "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy",
  ...
}

--- Crear federated credential ---

$ az identity federated-credential create \
  --name demo-federated-cred \
  --identity-name demo-workload-identity \
  --resource-group demo-rg \
  --issuer "https://eastus.oic.prod-aks.azure.com/..." \
  --subject "system:serviceaccount:default:azure-workload-identity-sa" \
  --audiences "api://AzureADTokenExchange"
{
  "audiences": ["api://AzureADTokenExchange"],
  "issuer": "https://eastus.oic.prod-aks.azure.com/...",
  "name": "demo-federated-cred",
  "subject": "system:serviceaccount:default:azure-workload-identity-sa",
  ...
}

--- Verificar variables de entorno en el pod ---

$ kubectl exec azure-workload-identity-demo -- env | grep AZURE_
AZURE_AUTHORITY_HOST=https://login.microsoftonline.com/
AZURE_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AZURE_FEDERATED_TOKEN_FILE=/var/run/secrets/azure/tokens/azure-identity-token
AZURE_TENANT_ID=yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy

--- Verificar token montado ---

$ kubectl exec azure-workload-identity-demo -- ls -la /var/run/secrets/azure/tokens/
total 4
drwxrwxrwt 3 root root  100 ...
lrwxrwxrwx 1 root root   27 ... azure-identity-token -> ..data/azure-identity-token
```

## Limpieza de Recursos

Al final del laboratorio, se ofrece eliminar los recursos creados.

### GKE - Eliminar cluster

```
==============================================
  Limpieza de Recursos
==============================================

ADVERTENCIA: IMPORTANTE: Si creaste un cluster, recuerda eliminarlo para evitar costos.

--- Eliminar cluster GKE ---

$ gcloud container clusters delete demo-cluster --zone us-central1-a --quiet
Deseas eliminar el cluster GKE ahora? (s/n): s

Deleting cluster demo-cluster...done.
INFO: Cluster GKE eliminado.
```

### EKS - Eliminar cluster

```
--- Eliminar cluster EKS ---

$ eksctl delete cluster --name demo-cluster --region us-east-1
Deseas eliminar el cluster EKS ahora? (s/n): s

2024-01-26 11:00:00 [i]  deleting EKS cluster "demo-cluster"
...
2024-01-26 11:15:00 [✔]  all cluster resources were deleted
INFO: Cluster EKS eliminado.
```

### AKS - Eliminar cluster

```
--- Eliminar cluster AKS y grupo de recursos ---

$ az group delete --name demo-rg --yes --no-wait
Deseas eliminar el grupo de recursos (y el cluster) AKS ahora? (s/n): s

INFO: Eliminacion del grupo de recursos iniciada (puede tomar unos minutos).
```

## Resumen Final

```
==============================================
  Laboratorio Completado
==============================================

Has completado exitosamente el Lab 18: Managed Kubernetes

Plataforma seleccionada: GKE

Resumen de conceptos aprendidos:

  GKE (Google Kubernetes Engine):
    - Control plane gratuito
    - Experiencia K8s nativa (Google creo Kubernetes)
    - Modos: Standard y Autopilot
    - Integracion: Workload Identity
    - CLI: gcloud

  CRITERIOS DE SELECCION:
    - Infraestructura existente
    - Experiencia del equipo
    - Requisitos de integracion
    - Presupuesto
    - Compliance y seguridad

Archivos de referencia:
  - initial/comparativa-proveedores.md
  - initial/cuestionario-seleccion.md
  - initial/gke-serviceaccount.yaml

Felicitaciones! Has completado todos los laboratorios del curso.
Ahora estas listo para el Proyecto Final.
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

### Ventajas de seleccionar una sola plataforma

1. **Ahorro de costos**: Solo se crea un cluster en lugar de tres
2. **Menor tiempo**: No necesitas autenticarte en multiples proveedores
3. **Enfoque**: Puedes profundizar mas en la plataforma que realmente usaras
4. **Evita errores**: Menor riesgo de dejar clusters activos por accidente
