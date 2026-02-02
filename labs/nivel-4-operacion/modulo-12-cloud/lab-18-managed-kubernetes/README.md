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
# ===========================================
# REQUISITOS PREVIOS
# ===========================================

# 1. Instalar gcloud CLI (si no está instalado)
# https://cloud.google.com/sdk/docs/install

# 2. Autenticarse en Google Cloud
gcloud auth login

# 3. Listar proyectos disponibles
gcloud projects list

# 4. Configurar proyecto (reemplazar YOUR_PROJECT_ID)
gcloud config set project YOUR_PROJECT_ID

# 5. Habilitar la API de Kubernetes Engine (requerido una sola vez por proyecto)
gcloud services enable container.googleapis.com

# ===========================================
# CREAR RECURSOS
# ===========================================

# Crear clúster GKE con Workload Identity habilitado
# (reemplazar YOUR_PROJECT_ID con tu Project ID)
gcloud container clusters create demo-cluster \
  --zone us-central1-a \
  --num-nodes 3 \
  --machine-type e2-medium \
  --workload-pool=YOUR_PROJECT_ID.svc.id.goog

# Obtener credenciales para kubectl
gcloud container clusters get-credentials demo-cluster --zone us-central1-a

# ===========================================
# VERIFICAR
# ===========================================

# Verificar conexión
kubectl get nodes

# Ver información del clúster
gcloud container clusters describe demo-cluster --zone us-central1-a

# ===========================================
# CONFIGURAR WORKLOAD IDENTITY (Opcional)
# ===========================================

# 1. Crear Service Account de GCP para Workload Identity
gcloud iam service-accounts create gke-workload-demo \
  --display-name="GKE Workload Identity Demo"

# 2. Dar permisos al Service Account (ejemplo: lectura de Storage)
# gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
#   --member="serviceAccount:gke-workload-demo@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
#   --role="roles/storage.objectViewer"

# 3. Vincular K8s ServiceAccount con GCP Service Account
gcloud iam service-accounts add-iam-policy-binding \
  gke-workload-demo@YOUR_PROJECT_ID.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:YOUR_PROJECT_ID.svc.id.goog[default/gcp-workload-identity-sa]"

# 4. Aplicar el ServiceAccount de Kubernetes (ver initial/gke-serviceaccount.yaml)
# kubectl apply -f initial/gke-serviceaccount.yaml

# 5. Verificar que Workload Identity funciona
# kubectl exec -it gcp-workload-identity-demo -- gcloud auth list
```

### Paso 3: Explorar EKS (AWS)

```bash
# ===========================================
# REQUISITOS PREVIOS
# ===========================================

# 1. Instalar AWS CLI (si no está instalado)
# https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

# 2. Instalar eksctl (si no está instalado)
# https://eksctl.io/installation/

# 3. Configurar credenciales de AWS
aws configure
# Ingresa: AWS Access Key ID, Secret Access Key, Region (us-east-1), Output format (json)

# 4. Verificar autenticación
aws sts get-caller-identity

# ===========================================
# CREAR RECURSOS
# ===========================================

# Crear clúster EKS (eksctl crea automáticamente: VPC, subnets, IAM roles, security groups)
eksctl create cluster \
  --name demo-cluster \
  --region us-east-1 \
  --nodegroup-name workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 1 \
  --nodes-max 5

# Nota: La creación tarda ~15-20 minutos

# ===========================================
# VERIFICAR
# ===========================================

# Verificar conexión
kubectl get nodes

# Ver información del clúster
eksctl get cluster --name demo-cluster --region us-east-1

# Ver nodegroups
eksctl get nodegroup --cluster demo-cluster --region us-east-1

# Ver recursos creados en AWS (VPC, subnets, etc.)
aws cloudformation list-stacks --query "StackSummaries[?contains(StackName, 'demo-cluster')]"
```

### Paso 4: Explorar AKS (Azure)

```bash
# ===========================================
# REQUISITOS PREVIOS
# ===========================================

# 1. Instalar Azure CLI (si no está instalado)
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

# 2. Autenticarse en Azure
az login

# 3. Verificar suscripción activa
az account show

# 4. Listar suscripciones disponibles (si tienes varias)
az account list --output table

# 5. Cambiar de suscripción (si es necesario)
# az account set --subscription "SUBSCRIPTION_NAME_OR_ID"

# ===========================================
# CREAR RECURSOS
# ===========================================

# Crear grupo de recursos (contenedor para todos los recursos de Azure)
az group create --name demo-rg --location eastus

# Crear clúster AKS con Workload Identity habilitado
az aks create \
  --resource-group demo-rg \
  --name demo-cluster \
  --node-count 3 \
  --node-vm-size Standard_B2s \
  --generate-ssh-keys \
  --enable-managed-identity \
  --enable-oidc-issuer \
  --enable-workload-identity

# Nota: La creación tarda ~8-15 minutos

# Obtener credenciales para kubectl
az aks get-credentials --resource-group demo-rg --name demo-cluster

# ===========================================
# VERIFICAR
# ===========================================

# Verificar conexión
kubectl get nodes

# Ver información del clúster
az aks show --resource-group demo-rg --name demo-cluster --output table

# Ver todos los recursos en el grupo de recursos
az resource list --resource-group demo-rg --output table

# Ver el grupo de recursos de nodos (MC_*) creado automáticamente
az group list --query "[?starts_with(name, 'MC_demo-rg')]" --output table
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

> **Nota**: Workload Identity requiere que el clúster GKE tenga habilitado `--workload-pool=PROJECT_ID.svc.id.goog` y que exista un IAM binding entre el ServiceAccount de Kubernetes y el Service Account de GCP con el rol `roles/iam.workloadIdentityUser`.

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
# Usar Azure Workload Identity para acceder a Azure APIs
apiVersion: v1
kind: ServiceAccount
metadata:
  name: azure-sa
  annotations:
    # Vincula el ServiceAccount de Kubernetes con un Azure Managed Identity
    azure.workload.identity/client-id: <MANAGED_IDENTITY_CLIENT_ID>
  labels:
    # Label requerido para que el webhook inyecte las variables
    azure.workload.identity/use: "true"
```

> **Nota**: Azure Workload Identity reemplaza al legacy Azure AD Pod Identity. Requiere que el clúster AKS tenga habilitados OIDC Issuer y Workload Identity.

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

> **IMPORTANTE**: Elimina los recursos cuando termines el laboratorio para evitar costos innecesarios.

#### GKE - Limpieza

```bash
# Eliminar el clúster GKE
gcloud container clusters delete demo-cluster --zone us-central1-a --quiet

# Verificar que el clúster fue eliminado
gcloud container clusters list

# (Opcional) Eliminar discos persistentes huérfanos
gcloud compute disks list --filter="name~^gke-demo-cluster"
# Si hay discos, eliminarlos con:
# gcloud compute disks delete DISK_NAME --zone us-central1-a --quiet
```

#### EKS - Limpieza

```bash
# Eliminar el clúster EKS (también elimina VPC, subnets, IAM roles creados por eksctl)
eksctl delete cluster --name demo-cluster --region us-east-1

# Nota: La eliminación tarda ~10-15 minutos

# Verificar que el clúster fue eliminado
eksctl get cluster --region us-east-1

# Verificar que los stacks de CloudFormation fueron eliminados
aws cloudformation list-stacks \
  --query "StackSummaries[?contains(StackName, 'demo-cluster') && StackStatus!='DELETE_COMPLETE']"
```

#### AKS - Limpieza

```bash
# Eliminar el grupo de recursos (elimina TODOS los recursos dentro, incluyendo el clúster)
az group delete --name demo-rg --yes --no-wait

# Verificar el estado de eliminación
az group show --name demo-rg --query "properties.provisioningState" 2>/dev/null || echo "Grupo eliminado"

# Nota: El grupo de recursos de nodos (MC_demo-rg_demo-cluster_eastus) se elimina automáticamente

# Verificar que no quedan grupos de recursos del lab
az group list --query "[?contains(name, 'demo')]" --output table
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
- [GKE Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [EKS Docs](https://docs.aws.amazon.com/eks/)
- [EKS IRSA](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [AKS Docs](https://docs.microsoft.com/azure/aks/)
- [AKS Workload Identity](https://learn.microsoft.com/azure/aks/workload-identity-overview)

## Solución

Consulta el directorio `solution/` para scripts de automatización.

---

## Navegación

- [← Anterior: Lab 17 - Prometheus y Grafana](../../modulo-11-monitoreo/lab-17-prometheus-grafana/README.md)
- [→ Siguiente: Proyecto Final](../../../proyecto-final/README.md)
