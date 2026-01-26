# Lab 18: Managed Kubernetes

## Objetivo

Comparar y explorar servicios de Kubernetes administrado en la nube.

## Prerrequisitos

- Lab 17 completado
- Cuenta en al menos un proveedor cloud (opcional para demo)

## Duración

60 minutos

## Instrucciones

### Paso 1: Comparar servicios administrados

| Característica  | GKE (Google) | EKS (AWS)   | AKS (Azure) |
| --------------- | ------------ | ----------- | ----------- |
| Control Plane   | Gratuito     | ~$0.10/hora | Gratuito    |
| Versiones K8s   | Últimas      | Últimas     | Últimas     |
| Auto-upgrade    | Sí           | Parcial     | Sí          |
| Networking      | VPC-native   | VPC CNI     | Azure CNI   |
| Integración IAM | Google IAM   | AWS IAM     | Azure AD    |
| CLI             | gcloud       | eksctl/aws  | az          |

### Paso 2: Explorar GKE (Google Cloud)

```bash
# Instalar gcloud CLI (si no está instalado)
# https://cloud.google.com/sdk/docs/install

# Configurar proyecto
gcloud config set project YOUR_PROJECT_ID

# Crear clúster GKE
gcloud container clusters create demo-cluster \
  --zone us-central1-a \
  --num-nodes 3 \
  --machine-type e2-medium

# Obtener credenciales
gcloud container clusters get-credentials demo-cluster --zone us-central1-a

# Verificar conexión
kubectl get nodes
```

### Paso 3: Explorar EKS (AWS)

```bash
# Instalar eksctl
# https://eksctl.io/installation/

# Crear clúster EKS
eksctl create cluster \
  --name demo-cluster \
  --region us-east-1 \
  --nodegroup-name workers \
  --node-type t3.medium \
  --nodes 3

# Verificar conexión
kubectl get nodes

# Ver información del clúster
eksctl get cluster --name demo-cluster
```

### Paso 4: Explorar AKS (Azure)

```bash
# Instalar Azure CLI
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

# Login
az login

# Crear grupo de recursos
az group create --name demo-rg --location eastus

# Crear clúster AKS
az aks create \
  --resource-group demo-rg \
  --name demo-cluster \
  --node-count 3 \
  --node-vm-size Standard_B2s \
  --generate-ssh-keys

# Obtener credenciales
az aks get-credentials --resource-group demo-rg --name demo-cluster

# Verificar conexión
kubectl get nodes
```

### Paso 5: Integraciones con servicios cloud

#### GKE - Integración con GCP

```yaml
# Usar Workload Identity para acceder a GCP APIs
apiVersion: v1
kind: ServiceAccount
metadata:
  name: gcp-sa
  annotations:
    iam.gke.io/gcp-service-account: my-sa@project.iam.gserviceaccount.com
```

#### EKS - Integración con AWS

```yaml
# Usar IRSA para acceder a AWS APIs
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aws-sa
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/my-role
```

#### AKS - Integración con Azure

```yaml
# Usar Azure AD Pod Identity
apiVersion: aadpodidentity.k8s.io/v1
kind: AzureIdentity
metadata:
  name: azure-identity
spec:
  type: 0
  resourceID: /subscriptions/.../resourcegroups/.../providers/Microsoft.ManagedIdentity/...
  clientID: <client-id>
```

### Paso 6: Consideraciones de costos

```bash
# GKE - Calculadora
# https://cloud.google.com/products/calculator

# AWS - Calculadora
# https://calculator.aws/

# Azure - Calculadora
# https://azure.microsoft.com/pricing/calculator/

# Costos típicos (aproximados, varían por región):
# - Control Plane: $0-73/mes
# - Nodos: $30-100/nodo/mes (depende del tipo)
# - Load Balancers: $15-25/mes
# - Storage: Variable
```

### Paso 7: Criterios de selección

| Criterio                 | GKE    | EKS   | AKS   |
| ------------------------ | ------ | ----- | ----- |
| Ya usa el cloud provider | ✓      | ✓     | ✓     |
| Experiencia con K8s      | Alta   | Media | Media |
| Costo inicial            | Bajo   | Medio | Bajo  |
| Integraciones nativas    | GCP    | AWS   | Azure |
| Multi-cloud              | Anthos | -     | Arc   |

### Paso 8: Limpieza (importante para evitar costos)

```bash
# GKE
gcloud container clusters delete demo-cluster --zone us-central1-a

# EKS
eksctl delete cluster --name demo-cluster

# AKS
az group delete --name demo-rg --yes
```

## Ejercicios Adicionales

1. Compara tiempos de creación de clúster entre proveedores
2. Investiga opciones de clústeres privados
3. Explora herramientas multi-cloud como Rancher o Lens

## Verificación

- [ ] Entiendo las diferencias entre proveedores
- [ ] Puedo crear clústeres en al menos un proveedor
- [ ] Conozco las integraciones con servicios cloud
- [ ] Entiendo las implicaciones de costos

## Recursos

- [GKE Docs](https://cloud.google.com/kubernetes-engine/docs)
- [EKS Docs](https://docs.aws.amazon.com/eks/)
- [AKS Docs](https://docs.microsoft.com/azure/aks/)

## Solución

Consulta el directorio `solution/` para scripts de automatización.
