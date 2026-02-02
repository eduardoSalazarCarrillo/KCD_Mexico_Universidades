#!/bin/bash
# =============================================================================
# Lab 18: Managed Kubernetes - Script de Solucion Completa
# =============================================================================
# Este script proporciona una guia interactiva para explorar y comparar
# servicios de Kubernetes administrado en la nube.
#
# NOTA: Este laboratorio es principalmente teorico/exploratorio.
# Los comandos de creacion de clusters requieren cuentas cloud activas
# y pueden generar costos.
# =============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

print_step() {
    echo ""
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo ""
}

print_substep() {
    echo ""
    echo -e "${CYAN}--- $1 ---${NC}"
    echo ""
}

print_command() {
    echo -e "${YELLOW}$ $1${NC}"
}

print_info() {
    echo -e "${GREEN}INFO:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}ADVERTENCIA:${NC} $1"
}

wait_for_user() {
    echo ""
    read -p "Presiona Enter para continuar..."
    echo ""
}

# =============================================================================
# Bienvenida
# =============================================================================
print_step "Lab 18: Managed Kubernetes"

echo "Bienvenido al laboratorio de Kubernetes administrado en la nube."
echo ""
echo "En este laboratorio exploraremos:"
echo "  - GKE (Google Kubernetes Engine)"
echo "  - EKS (Amazon Elastic Kubernetes Service)"
echo "  - AKS (Azure Kubernetes Service)"
echo ""
print_warning "Este laboratorio es principalmente exploratorio."
print_warning "Los comandos de creacion de clusters requieren cuentas cloud"
print_warning "y pueden generar costos si se ejecutan."
echo ""

wait_for_user

# =============================================================================
# Paso 1: Verificar herramientas disponibles
# =============================================================================
print_step "Paso 1: Verificar herramientas disponibles"

echo "Verificando que herramientas cloud tienes instaladas..."
echo ""

# Verificar gcloud (GKE)
print_substep "Google Cloud SDK (gcloud)"
if command -v gcloud &> /dev/null; then
    print_command "gcloud version"
    gcloud version 2>/dev/null | head -5
    echo ""
    print_info "gcloud esta instalado. Puedes usar GKE."
else
    print_warning "gcloud NO esta instalado."
    echo "  Instalar: https://cloud.google.com/sdk/docs/install"
fi

echo ""

# Verificar aws / eksctl (EKS)
print_substep "AWS CLI y eksctl"
if command -v aws &> /dev/null; then
    print_command "aws --version"
    aws --version
    print_info "AWS CLI esta instalado."
else
    print_warning "AWS CLI NO esta instalado."
    echo "  Instalar: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
fi

if command -v eksctl &> /dev/null; then
    print_command "eksctl version"
    eksctl version
    print_info "eksctl esta instalado. Puedes usar EKS facilmente."
else
    print_warning "eksctl NO esta instalado."
    echo "  Instalar: https://eksctl.io/installation/"
fi

echo ""

# Verificar az (AKS)
print_substep "Azure CLI (az)"
if command -v az &> /dev/null; then
    print_command "az version"
    az version 2>/dev/null | head -5
    echo ""
    print_info "Azure CLI esta instalado. Puedes usar AKS."
else
    print_warning "Azure CLI NO esta instalado."
    echo "  Instalar: https://docs.microsoft.com/cli/azure/install-azure-cli"
fi

wait_for_user

# =============================================================================
# Paso 2: Revisar comparativa de proveedores
# =============================================================================
print_step "Paso 2: Comparativa de Proveedores"

print_substep "Tabla comparativa general"
cat << 'EOF'
+---------------------+------------------------+------------------------+------------------------+
| Caracteristica      | GKE (Google)           | EKS (AWS)              | AKS (Azure)            |
+---------------------+------------------------+------------------------+------------------------+
| Control Plane       | Gratuito               | ~$0.10/hora (~$73/mes) | Gratuito               |
| Versiones K8s       | Ultimas                | Ultimas                | Ultimas                |
| Auto-upgrade        | Si                     | Parcial                | Si                     |
| Networking          | VPC-native             | VPC CNI                | Azure CNI              |
| Integracion IAM     | Google IAM             | AWS IAM                | Azure AD               |
| CLI                 | gcloud                 | eksctl/aws             | az                     |
| Tiempo de creacion  | ~5-10 min              | ~15-20 min             | ~8-15 min              |
+---------------------+------------------------+------------------------+------------------------+
EOF

echo ""
print_info "Documento completo en: initial/comparativa-proveedores.md"

wait_for_user

# =============================================================================
# Paso 3: Explorar comandos de GKE
# =============================================================================
print_step "Paso 3: Comandos de GKE (Google Kubernetes Engine)"

echo "Los siguientes comandos son para referencia."
echo "Solo ejecutalos si tienes una cuenta de GCP activa."
echo ""

print_substep "Autenticacion"
print_command "gcloud auth login"
echo "# Abre el navegador para autenticacion"
echo ""

print_substep "Configurar proyecto"
print_command "gcloud config set project YOUR_PROJECT_ID"
echo ""

print_substep "Crear cluster GKE Standard"
cat << 'EOF'
gcloud container clusters create demo-cluster \
  --zone us-central1-a \
  --num-nodes 3 \
  --machine-type e2-medium \
  --enable-ip-alias
EOF
echo ""

print_substep "Crear cluster GKE Autopilot (totalmente administrado)"
cat << 'EOF'
gcloud container clusters create-auto demo-autopilot \
  --region us-central1
EOF
echo ""

print_substep "Obtener credenciales"
print_command "gcloud container clusters get-credentials demo-cluster --zone us-central1-a"
echo ""

print_substep "Verificar conexion"
print_command "kubectl get nodes"
echo ""

print_substep "Eliminar cluster"
print_command "gcloud container clusters delete demo-cluster --zone us-central1-a --quiet"
echo ""

wait_for_user

# =============================================================================
# Paso 4: Explorar comandos de EKS
# =============================================================================
print_step "Paso 4: Comandos de EKS (Amazon Elastic Kubernetes Service)"

echo "Los siguientes comandos son para referencia."
echo "Solo ejecutalos si tienes una cuenta de AWS activa."
echo ""

print_substep "Configurar credenciales AWS"
print_command "aws configure"
echo "# Ingresa Access Key ID, Secret Access Key, Region"
echo ""

print_substep "Crear cluster EKS con eksctl"
cat << 'EOF'
eksctl create cluster \
  --name demo-cluster \
  --region us-east-1 \
  --nodegroup-name workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 1 \
  --nodes-max 5
EOF
echo ""

print_substep "Crear cluster EKS con Fargate (serverless)"
cat << 'EOF'
eksctl create cluster \
  --name demo-fargate \
  --region us-east-1 \
  --fargate
EOF
echo ""

print_substep "Obtener credenciales"
print_command "aws eks update-kubeconfig --name demo-cluster --region us-east-1"
echo ""

print_substep "Verificar conexion"
print_command "kubectl get nodes"
print_command "eksctl get cluster --name demo-cluster"
echo ""

print_substep "Eliminar cluster"
print_command "eksctl delete cluster --name demo-cluster --region us-east-1"
echo ""

wait_for_user

# =============================================================================
# Paso 5: Explorar comandos de AKS
# =============================================================================
print_step "Paso 5: Comandos de AKS (Azure Kubernetes Service)"

echo "Los siguientes comandos son para referencia."
echo "Solo ejecutalos si tienes una cuenta de Azure activa."
echo ""

print_substep "Autenticacion"
print_command "az login"
echo "# Abre el navegador para autenticacion"
echo ""

print_substep "Crear grupo de recursos"
print_command "az group create --name demo-rg --location eastus"
echo ""

print_substep "Crear cluster AKS"
cat << 'EOF'
az aks create \
  --resource-group demo-rg \
  --name demo-cluster \
  --node-count 3 \
  --node-vm-size Standard_B2s \
  --generate-ssh-keys \
  --enable-managed-identity
EOF
echo ""

print_substep "Obtener credenciales"
print_command "az aks get-credentials --resource-group demo-rg --name demo-cluster"
echo ""

print_substep "Verificar conexion"
print_command "kubectl get nodes"
print_command "az aks show --resource-group demo-rg --name demo-cluster"
echo ""

print_substep "Eliminar cluster y grupo de recursos"
print_command "az group delete --name demo-rg --yes --no-wait"
echo ""

wait_for_user

# =============================================================================
# Paso 6: Integraciones con Identity
# =============================================================================
print_step "Paso 6: Integraciones con Identity"

echo "Cada proveedor tiene su forma de dar acceso a APIs cloud desde pods."
echo ""

print_substep "GKE: Workload Identity"
echo "Permite a pods asumir Google Service Accounts."
print_command "cat $LAB_DIR/initial/gke-serviceaccount.yaml"
cat "$LAB_DIR/initial/gke-serviceaccount.yaml" | head -30
echo "..."
echo ""

print_substep "EKS: IAM Roles for Service Accounts (IRSA)"
echo "Permite a pods asumir AWS IAM Roles."
print_command "cat $LAB_DIR/initial/eks-serviceaccount.yaml"
cat "$LAB_DIR/initial/eks-serviceaccount.yaml" | head -30
echo "..."
echo ""

print_substep "AKS: Azure Workload Identity"
echo "Permite a pods asumir Azure Managed Identities."
print_command "cat $LAB_DIR/initial/aks-serviceaccount.yaml"
cat "$LAB_DIR/initial/aks-serviceaccount.yaml" | head -30
echo "..."
echo ""

wait_for_user

# =============================================================================
# Paso 7: Calculadoras de costos
# =============================================================================
print_step "Paso 7: Calculadoras de Costos"

echo "Es importante estimar costos antes de desplegar en produccion."
echo ""

print_substep "Calculadoras oficiales"
echo "GKE: https://cloud.google.com/products/calculator"
echo "EKS: https://calculator.aws/"
echo "AKS: https://azure.microsoft.com/pricing/calculator/"
echo ""

print_substep "Estimacion rapida (3 nodos e2-medium / t3.medium / B2s)"
cat << 'EOF'
+------------------+--------+--------+--------+
| Componente       | GKE    | EKS    | AKS    |
+------------------+--------+--------+--------+
| Control Plane    | $0     | ~$73   | $0     |
| 3 nodos (compute)| ~$75   | ~$100  | ~$75   |
| Load Balancer    | ~$20   | ~$20   | ~$20   |
+------------------+--------+--------+--------+
| TOTAL (mes)      | ~$95   | ~$193  | ~$95   |
+------------------+--------+--------+--------+
EOF
echo ""
print_warning "Estos son estimados. Los costos reales varian por region y uso."
echo ""

wait_for_user

# =============================================================================
# Paso 8: Criterios de seleccion
# =============================================================================
print_step "Paso 8: Criterios de Seleccion"

echo "No hay una respuesta correcta universal."
echo "La mejor opcion depende de tu contexto especifico."
echo ""

print_substep "Elige GKE si:"
echo "  - Ya usas Google Cloud"
echo "  - Quieres la experiencia K8s mas nativa (Google creo K8s)"
echo "  - Prefieres gestion automatizada (Autopilot)"
echo "  - Multi-cloud es importante (Anthos)"
echo ""

print_substep "Elige EKS si:"
echo "  - Ya tienes infraestructura significativa en AWS"
echo "  - Necesitas integracion profunda con servicios AWS"
echo "  - Compliance es critico"
echo "  - Necesitas Fargate para serverless"
echo ""

print_substep "Elige AKS si:"
echo "  - Ya usas Azure o Microsoft 365"
echo "  - Necesitas integracion con Azure AD"
echo "  - Windows containers son importantes"
echo "  - Ya tienes licencias Enterprise de Microsoft"
echo ""

print_info "Cuestionario de seleccion en: initial/cuestionario-seleccion.md"

wait_for_user

# =============================================================================
# Paso 9: Ejercicio practico con Minikube
# =============================================================================
print_step "Paso 9: Ejercicio Practico (Minikube)"

echo "Aunque no tengamos acceso a clusters cloud, podemos practicar"
echo "los conceptos usando Minikube."
echo ""

if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    print_info "Minikube esta corriendo. Ejecutando ejercicio practico..."
    echo ""

    print_substep "Simular acceso a API desde un pod"

    # Crear un ServiceAccount
    kubectl create serviceaccount cloud-demo-sa --dry-run=client -o yaml | kubectl apply -f -

    # Crear un pod que use el ServiceAccount
    cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: cloud-demo-pod
spec:
  serviceAccountName: cloud-demo-sa
  containers:
    - name: demo
      image: curlimages/curl:latest
      command: ["sleep", "300"]
EOF

    echo "Esperando a que el pod este listo..."
    kubectl wait --for=condition=Ready pod/cloud-demo-pod --timeout=60s 2>/dev/null || true

    echo ""
    print_substep "Verificar token montado en el pod"
    print_command "kubectl exec cloud-demo-pod -- ls -la /var/run/secrets/kubernetes.io/serviceaccount/"
    kubectl exec cloud-demo-pod -- ls -la /var/run/secrets/kubernetes.io/serviceaccount/ 2>/dev/null || echo "Pod no disponible"

    echo ""
    print_substep "Ver el token del ServiceAccount"
    print_command "kubectl exec cloud-demo-pod -- cat /var/run/secrets/kubernetes.io/serviceaccount/token | head -c 100"
    TOKEN=$(kubectl exec cloud-demo-pod -- cat /var/run/secrets/kubernetes.io/serviceaccount/token 2>/dev/null | head -c 100)
    echo "${TOKEN}..."

    echo ""
    print_substep "Limpiar recursos"
    kubectl delete pod cloud-demo-pod --ignore-not-found=true
    kubectl delete serviceaccount cloud-demo-sa --ignore-not-found=true

    print_info "En un cluster cloud, este token seria intercambiado"
    print_info "por credenciales del proveedor via Workload Identity/IRSA."
else
    print_warning "Minikube no esta corriendo."
    echo "Para ejecutar el ejercicio practico:"
    echo "  minikube start --driver=docker"
fi

wait_for_user

# =============================================================================
# Resumen Final
# =============================================================================
print_step "Laboratorio Completado"

echo "Has completado exitosamente el Lab 18: Managed Kubernetes"
echo ""
echo "Resumen de conceptos aprendidos:"
echo ""
echo "  PROVEEDORES DE KUBERNETES ADMINISTRADO:"
echo "    - GKE (Google): Experiencia nativa, Autopilot, control plane gratis"
echo "    - EKS (AWS): Integracion profunda con AWS, Fargate"
echo "    - AKS (Azure): Integracion con Azure AD, Windows containers"
echo ""
echo "  INTEGRACIONES CON IDENTITY:"
echo "    - GKE: Workload Identity"
echo "    - EKS: IAM Roles for Service Accounts (IRSA)"
echo "    - AKS: Azure Workload Identity"
echo ""
echo "  CRITERIOS DE SELECCION:"
echo "    - Infraestructura existente"
echo "    - Experiencia del equipo"
echo "    - Requisitos de integracion"
echo "    - Presupuesto"
echo "    - Compliance y seguridad"
echo ""
echo "  HERRAMIENTAS CLI:"
echo "    - GKE: gcloud"
echo "    - EKS: eksctl, aws"
echo "    - AKS: az"
echo ""
echo "Archivos de referencia:"
echo "  - initial/comparativa-proveedores.md"
echo "  - initial/cuestionario-seleccion.md"
echo "  - initial/gke-serviceaccount.yaml"
echo "  - initial/eks-serviceaccount.yaml"
echo "  - initial/aks-serviceaccount.yaml"
echo ""
echo -e "${GREEN}Felicitaciones! Has completado todos los laboratorios del curso.${NC}"
echo -e "${GREEN}Ahora estas listo para el Proyecto Final.${NC}"
