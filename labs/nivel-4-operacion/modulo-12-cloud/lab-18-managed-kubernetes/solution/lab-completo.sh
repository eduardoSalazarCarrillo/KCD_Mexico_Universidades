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

# =============================================================================
# Seleccion de plataforma cloud
# =============================================================================
print_step "Selecciona tu Plataforma Cloud"

echo "Por favor, selecciona la plataforma cloud que deseas utilizar:"
echo ""
echo "  1) GKE - Google Kubernetes Engine (Google Cloud)"
echo "  2) EKS - Amazon Elastic Kubernetes Service (AWS)"
echo "  3) AKS - Azure Kubernetes Service (Microsoft Azure)"
echo "  4) Solo exploratorio (sin crear cluster)"
echo ""

CLOUD_PLATFORM=""
while [[ -z "$CLOUD_PLATFORM" ]]; do
    read -p "Ingresa tu opcion (1-4): " PLATFORM_CHOICE
    case $PLATFORM_CHOICE in
        1)
            CLOUD_PLATFORM="GKE"
            print_info "Has seleccionado GKE (Google Kubernetes Engine)"
            ;;
        2)
            CLOUD_PLATFORM="EKS"
            print_info "Has seleccionado EKS (Amazon Elastic Kubernetes Service)"
            ;;
        3)
            CLOUD_PLATFORM="AKS"
            print_info "Has seleccionado AKS (Azure Kubernetes Service)"
            ;;
        4)
            CLOUD_PLATFORM="EXPLORATORY"
            print_info "Modo exploratorio: revisaremos los conceptos sin crear clusters"
            ;;
        *)
            print_warning "Opcion invalida. Por favor ingresa 1, 2, 3 o 4."
            ;;
    esac
done

wait_for_user

# =============================================================================
# Paso 1: Verificar herramientas disponibles
# =============================================================================
print_step "Paso 1: Verificar herramientas disponibles"

echo "Verificando las herramientas necesarias para tu plataforma seleccionada..."
echo ""

# Verificar herramientas segun la plataforma seleccionada
if [[ "$CLOUD_PLATFORM" == "GKE" || "$CLOUD_PLATFORM" == "EXPLORATORY" ]]; then
    print_substep "Google Cloud SDK (gcloud)"
    if command -v gcloud &> /dev/null; then
        print_command "gcloud version"
        gcloud version 2>/dev/null | head -5
        echo ""
        print_info "gcloud esta instalado. Puedes usar GKE."
    else
        print_warning "gcloud NO esta instalado."
        echo "  Instalar: https://cloud.google.com/sdk/docs/install"
        if [[ "$CLOUD_PLATFORM" == "GKE" ]]; then
            echo ""
            print_warning "Necesitas instalar gcloud para continuar con GKE."
        fi
    fi
    echo ""
fi

if [[ "$CLOUD_PLATFORM" == "EKS" || "$CLOUD_PLATFORM" == "EXPLORATORY" ]]; then
    print_substep "AWS CLI y eksctl"
    if command -v aws &> /dev/null; then
        print_command "aws --version"
        aws --version
        print_info "AWS CLI esta instalado."
    else
        print_warning "AWS CLI NO esta instalado."
        echo "  Instalar: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        if [[ "$CLOUD_PLATFORM" == "EKS" ]]; then
            echo ""
            print_warning "Necesitas instalar AWS CLI para continuar con EKS."
        fi
    fi

    if command -v eksctl &> /dev/null; then
        print_command "eksctl version"
        eksctl version
        print_info "eksctl esta instalado. Puedes usar EKS facilmente."
    else
        print_warning "eksctl NO esta instalado."
        echo "  Instalar: https://eksctl.io/installation/"
        if [[ "$CLOUD_PLATFORM" == "EKS" ]]; then
            echo ""
            print_warning "Se recomienda instalar eksctl para facilitar el uso de EKS."
        fi
    fi
    echo ""
fi

if [[ "$CLOUD_PLATFORM" == "AKS" || "$CLOUD_PLATFORM" == "EXPLORATORY" ]]; then
    print_substep "Azure CLI (az)"
    if command -v az &> /dev/null; then
        print_command "az version"
        az version 2>/dev/null | head -5
        echo ""
        print_info "Azure CLI esta instalado. Puedes usar AKS."
    else
        print_warning "Azure CLI NO esta instalado."
        echo "  Instalar: https://docs.microsoft.com/cli/azure/install-azure-cli"
        if [[ "$CLOUD_PLATFORM" == "AKS" ]]; then
            echo ""
            print_warning "Necesitas instalar az para continuar con AKS."
        fi
    fi
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
if [[ "$CLOUD_PLATFORM" == "GKE" || "$CLOUD_PLATFORM" == "EXPLORATORY" ]]; then
    print_step "Paso 3: Comandos de GKE (Google Kubernetes Engine)"

    if [[ "$CLOUD_PLATFORM" == "GKE" ]]; then
        echo "A continuacion ejecutaremos los comandos para GKE."
        echo ""
        print_warning "Asegurate de tener una cuenta de GCP activa con facturacion habilitada."
        print_warning "Crear un cluster puede generar costos."
        echo ""

        print_substep "Verificando credenciales existentes"
        GKE_AUTHENTICATED=false
        GKE_PROJECT_CONFIGURED=false

        # Verificar si ya hay una cuenta autenticada
        print_command "gcloud auth list --filter=status:ACTIVE --format='value(account)'"
        ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null)
        if [[ -n "$ACTIVE_ACCOUNT" ]]; then
            print_info "Ya estas autenticado como: $ACTIVE_ACCOUNT"
            GKE_AUTHENTICATED=true
        else
            print_warning "No hay una cuenta activa autenticada."
        fi

        # Verificar si hay un proyecto configurado
        print_command "gcloud config get-value project"
        CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
        if [[ -n "$CURRENT_PROJECT" && "$CURRENT_PROJECT" != "(unset)" ]]; then
            print_info "Proyecto actual configurado: $CURRENT_PROJECT"
            GKE_PROJECT_CONFIGURED=true
        else
            print_warning "No hay un proyecto configurado."
        fi
        echo ""

        print_substep "Autenticacion"
        if [[ "$GKE_AUTHENTICATED" == true ]]; then
            read -p "Ya estas autenticado. Deseas re-autenticarte con otra cuenta? (s/n): " AUTH_GKE
        else
            print_command "gcloud auth login"
            read -p "Deseas autenticarte ahora? (s/n): " AUTH_GKE
        fi
        if [[ "$AUTH_GKE" == "s" || "$AUTH_GKE" == "S" ]]; then
            gcloud auth login
        fi
        echo ""

        print_substep "Configurar proyecto"
        if [[ "$GKE_PROJECT_CONFIGURED" == true ]]; then
            read -p "Proyecto actual: $CURRENT_PROJECT. Deseas usar otro proyecto? (s/n): " CHANGE_PROJECT
            if [[ "$CHANGE_PROJECT" == "s" || "$CHANGE_PROJECT" == "S" ]]; then
                read -p "Ingresa tu Project ID de GCP: " GCP_PROJECT_ID
                if [[ -n "$GCP_PROJECT_ID" ]]; then
                    print_command "gcloud config set project $GCP_PROJECT_ID"
                    gcloud config set project "$GCP_PROJECT_ID"
                fi
            fi
        else
            read -p "Ingresa tu Project ID de GCP: " GCP_PROJECT_ID
            if [[ -n "$GCP_PROJECT_ID" ]]; then
                print_command "gcloud config set project $GCP_PROJECT_ID"
                gcloud config set project "$GCP_PROJECT_ID"
            fi
        fi
        echo ""

        print_substep "Habilitar API de Kubernetes Engine"
        print_command "gcloud services enable container.googleapis.com"
        echo "Habilitando la API (puede tardar unos segundos)..."
        gcloud services enable container.googleapis.com 2>/dev/null || print_warning "No se pudo habilitar la API (puede que ya este habilitada)"
        echo ""

        print_substep "Crear cluster GKE Standard con Workload Identity"
        # Obtener el Project ID actual
        GCP_PROJECT=$(gcloud config get-value project 2>/dev/null)
        echo "Comando que se ejecutara (usando proyecto: $GCP_PROJECT):"
        cat << EOF
gcloud container clusters create demo-cluster \\
  --zone us-central1-a \\
  --num-nodes 3 \\
  --machine-type e2-medium \\
  --enable-ip-alias \\
  --workload-pool=${GCP_PROJECT}.svc.id.goog
EOF
        echo ""
        read -p "Deseas crear el cluster ahora? (s/n): " CREATE_GKE
        if [[ "$CREATE_GKE" == "s" || "$CREATE_GKE" == "S" ]]; then
            gcloud container clusters create demo-cluster \
                --zone us-central1-a \
                --num-nodes 3 \
                --machine-type e2-medium \
                --enable-ip-alias \
                --workload-pool="${GCP_PROJECT}.svc.id.goog"

            echo ""
            print_substep "Obtener credenciales"
            print_command "gcloud container clusters get-credentials demo-cluster --zone us-central1-a"
            gcloud container clusters get-credentials demo-cluster --zone us-central1-a

            echo ""
            print_substep "Verificar conexion"
            print_command "kubectl get nodes"
            kubectl get nodes
        fi
    else
        echo "Los siguientes comandos son para referencia."
        echo "Solo ejecutalos si tienes una cuenta de GCP activa."
        echo ""

        print_substep "Autenticacion"
        print_command "gcloud auth login"
        echo "# Abre el navegador para autenticacion"
        echo ""

        print_substep "Listar proyectos disponibles"
        print_command "gcloud projects list"
        echo ""

        print_substep "Configurar proyecto"
        print_command "gcloud config set project YOUR_PROJECT_ID"
        echo ""

        print_substep "Habilitar API de Kubernetes Engine"
        print_command "gcloud services enable container.googleapis.com"
        echo "# Requerido una sola vez por proyecto"
        echo ""

        print_substep "Crear cluster GKE Standard con Workload Identity"
        cat << 'EOF'
gcloud container clusters create demo-cluster \
  --zone us-central1-a \
  --num-nodes 3 \
  --machine-type e2-medium \
  --enable-ip-alias \
  --workload-pool=YOUR_PROJECT_ID.svc.id.goog
EOF
        echo "# Nota: Reemplaza YOUR_PROJECT_ID con tu Project ID"
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
    fi

    wait_for_user
fi

# =============================================================================
# Paso 4: Explorar comandos de EKS
# =============================================================================
if [[ "$CLOUD_PLATFORM" == "EKS" || "$CLOUD_PLATFORM" == "EXPLORATORY" ]]; then
    print_step "Paso 4: Comandos de EKS (Amazon Elastic Kubernetes Service)"

    if [[ "$CLOUD_PLATFORM" == "EKS" ]]; then
        echo "A continuacion ejecutaremos los comandos para EKS."
        echo ""
        print_warning "Asegurate de tener una cuenta de AWS activa con facturacion habilitada."
        print_warning "Crear un cluster puede generar costos (~$0.10/hora solo por el control plane)."
        echo ""

        print_substep "Verificando credenciales existentes"
        EKS_AUTHENTICATED=false

        # Verificar si ya hay credenciales AWS configuradas
        print_command "aws sts get-caller-identity"
        if AWS_IDENTITY=$(aws sts get-caller-identity 2>/dev/null); then
            AWS_ACCOUNT=$(echo "$AWS_IDENTITY" | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
            AWS_ARN=$(echo "$AWS_IDENTITY" | grep -o '"Arn": "[^"]*"' | cut -d'"' -f4)
            print_info "Ya estas autenticado en AWS"
            print_info "  Cuenta: $AWS_ACCOUNT"
            print_info "  ARN: $AWS_ARN"
            EKS_AUTHENTICATED=true
        else
            print_warning "No hay credenciales AWS configuradas o son invalidas."
        fi

        # Verificar region configurada
        print_command "aws configure get region"
        AWS_REGION=$(aws configure get region 2>/dev/null)
        if [[ -n "$AWS_REGION" ]]; then
            print_info "Region configurada: $AWS_REGION"
        else
            print_warning "No hay una region configurada."
        fi
        echo ""

        print_substep "Configurar credenciales AWS"
        if [[ "$EKS_AUTHENTICATED" == true ]]; then
            read -p "Ya tienes credenciales configuradas. Deseas reconfigurar? (s/n): " AUTH_EKS
        else
            print_command "aws configure"
            read -p "Deseas configurar las credenciales ahora? (s/n): " AUTH_EKS
        fi
        if [[ "$AUTH_EKS" == "s" || "$AUTH_EKS" == "S" ]]; then
            aws configure
        fi
        echo ""

        print_substep "Crear cluster EKS con eksctl"
        echo "Comando que se ejecutara:"
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
        read -p "Deseas crear el cluster ahora? (s/n): " CREATE_EKS
        if [[ "$CREATE_EKS" == "s" || "$CREATE_EKS" == "S" ]]; then
            eksctl create cluster \
                --name demo-cluster \
                --region us-east-1 \
                --nodegroup-name workers \
                --node-type t3.medium \
                --nodes 3 \
                --nodes-min 1 \
                --nodes-max 5

            echo ""
            print_substep "Verificar conexion"
            print_command "kubectl get nodes"
            kubectl get nodes
            print_command "eksctl get cluster --name demo-cluster"
            eksctl get cluster --name demo-cluster
        fi
    else
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
    fi

    wait_for_user
fi

# =============================================================================
# Paso 5: Explorar comandos de AKS
# =============================================================================
if [[ "$CLOUD_PLATFORM" == "AKS" || "$CLOUD_PLATFORM" == "EXPLORATORY" ]]; then
    print_step "Paso 5: Comandos de AKS (Azure Kubernetes Service)"

    if [[ "$CLOUD_PLATFORM" == "AKS" ]]; then
        echo "A continuacion ejecutaremos los comandos para AKS."
        echo ""
        print_warning "Asegurate de tener una cuenta de Azure activa con facturacion habilitada."
        print_warning "Crear un cluster puede generar costos."
        echo ""

        print_substep "Verificando credenciales existentes"
        AKS_AUTHENTICATED=false

        # Verificar si ya hay una sesion activa de Azure
        print_command "az account show"
        if AZ_ACCOUNT=$(az account show 2>/dev/null); then
            AZ_USER=$(echo "$AZ_ACCOUNT" | grep -o '"name": "[^"]*"' | head -1 | cut -d'"' -f4)
            AZ_SUBSCRIPTION=$(echo "$AZ_ACCOUNT" | grep -o '"id": "[^"]*"' | head -1 | cut -d'"' -f4)
            AZ_TENANT=$(echo "$AZ_ACCOUNT" | grep -o '"tenantId": "[^"]*"' | cut -d'"' -f4)
            print_info "Ya estas autenticado en Azure"
            print_info "  Suscripcion: $AZ_USER"
            print_info "  ID: $AZ_SUBSCRIPTION"
            print_info "  Tenant: $AZ_TENANT"
            AKS_AUTHENTICATED=true
        else
            print_warning "No hay una sesion activa de Azure."
        fi
        echo ""

        print_substep "Autenticacion"
        if [[ "$AKS_AUTHENTICATED" == true ]]; then
            read -p "Ya estas autenticado. Deseas re-autenticarte con otra cuenta? (s/n): " AUTH_AKS
        else
            print_command "az login"
            read -p "Deseas autenticarte ahora? (s/n): " AUTH_AKS
        fi
        if [[ "$AUTH_AKS" == "s" || "$AUTH_AKS" == "S" ]]; then
            az login
        fi
        echo ""

        print_substep "Crear grupo de recursos"
        print_command "az group create --name demo-rg --location eastus"
        read -p "Deseas crear el grupo de recursos ahora? (s/n): " CREATE_RG
        if [[ "$CREATE_RG" == "s" || "$CREATE_RG" == "S" ]]; then
            az group create --name demo-rg --location eastus
        fi
        echo ""

        print_substep "Crear cluster AKS"
        echo "Comando que se ejecutara:"
        cat << 'EOF'
az aks create \
  --resource-group demo-rg \
  --name demo-cluster \
  --node-count 3 \
  --node-vm-size Standard_B2s \
  --generate-ssh-keys \
  --enable-managed-identity \
  --enable-oidc-issuer \
  --enable-workload-identity
EOF
        echo ""
        read -p "Deseas crear el cluster ahora? (s/n): " CREATE_AKS
        if [[ "$CREATE_AKS" == "s" || "$CREATE_AKS" == "S" ]]; then
            az aks create \
                --resource-group demo-rg \
                --name demo-cluster \
                --node-count 3 \
                --node-vm-size Standard_B2s \
                --generate-ssh-keys \
                --enable-managed-identity

            echo ""
            print_substep "Obtener credenciales"
            print_command "az aks get-credentials --resource-group demo-rg --name demo-cluster"
            az aks get-credentials --resource-group demo-rg --name demo-cluster

            echo ""
            print_substep "Verificar conexion"
            print_command "kubectl get nodes"
            kubectl get nodes
        fi
    else
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
  --enable-managed-identity \
  --enable-oidc-issuer \
  --enable-workload-identity
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
    fi

    wait_for_user
fi

# =============================================================================
# Paso 6: Integraciones con Identity
# =============================================================================
print_step "Paso 6: Integraciones con Identity"

echo "Cada proveedor tiene su forma de dar acceso a APIs cloud desde pods."
echo ""

if [[ "$CLOUD_PLATFORM" == "GKE" || "$CLOUD_PLATFORM" == "EXPLORATORY" ]]; then
    print_substep "GKE: Workload Identity"
    echo "Permite a pods asumir Google Service Accounts."
    print_command "cat $LAB_DIR/initial/gke-serviceaccount.yaml"
    cat "$LAB_DIR/initial/gke-serviceaccount.yaml" | head -30
    echo "..."
    echo ""
fi

if [[ "$CLOUD_PLATFORM" == "EKS" || "$CLOUD_PLATFORM" == "EXPLORATORY" ]]; then
    print_substep "EKS: IAM Roles for Service Accounts (IRSA)"
    echo "Permite a pods asumir AWS IAM Roles."
    print_command "cat $LAB_DIR/initial/eks-serviceaccount.yaml"
    cat "$LAB_DIR/initial/eks-serviceaccount.yaml" | head -30
    echo "..."
    echo ""
fi

if [[ "$CLOUD_PLATFORM" == "AKS" || "$CLOUD_PLATFORM" == "EXPLORATORY" ]]; then
    print_substep "AKS: Azure Workload Identity"
    echo "Permite a pods asumir Azure Managed Identities."
    print_command "cat $LAB_DIR/initial/aks-serviceaccount.yaml"
    cat "$LAB_DIR/initial/aks-serviceaccount.yaml" | head -30
    echo "..."
    echo ""
fi

wait_for_user

# =============================================================================
# Paso 7: Calculadoras de costos
# =============================================================================
print_step "Paso 7: Calculadoras de Costos"

echo "Es importante estimar costos antes de desplegar en produccion."
echo ""

print_substep "Calculadoras oficiales"
if [[ "$CLOUD_PLATFORM" == "GKE" ]]; then
    echo "GKE: https://cloud.google.com/products/calculator"
elif [[ "$CLOUD_PLATFORM" == "EKS" ]]; then
    echo "EKS: https://calculator.aws/"
elif [[ "$CLOUD_PLATFORM" == "AKS" ]]; then
    echo "AKS: https://azure.microsoft.com/pricing/calculator/"
else
    echo "GKE: https://cloud.google.com/products/calculator"
    echo "EKS: https://calculator.aws/"
    echo "AKS: https://azure.microsoft.com/pricing/calculator/"
fi
echo ""

print_substep "Estimacion rapida (3 nodos e2-medium / t3.medium / B2s)"
if [[ "$CLOUD_PLATFORM" == "GKE" ]]; then
    cat << 'EOF'
+------------------+--------+
| Componente       | GKE    |
+------------------+--------+
| Control Plane    | $0     |
| 3 nodos (compute)| ~$75   |
| Load Balancer    | ~$20   |
+------------------+--------+
| TOTAL (mes)      | ~$95   |
+------------------+--------+
EOF
elif [[ "$CLOUD_PLATFORM" == "EKS" ]]; then
    cat << 'EOF'
+------------------+--------+
| Componente       | EKS    |
+------------------+--------+
| Control Plane    | ~$73   |
| 3 nodos (compute)| ~$100  |
| Load Balancer    | ~$20   |
+------------------+--------+
| TOTAL (mes)      | ~$193  |
+------------------+--------+
EOF
elif [[ "$CLOUD_PLATFORM" == "AKS" ]]; then
    cat << 'EOF'
+------------------+--------+
| Componente       | AKS    |
+------------------+--------+
| Control Plane    | $0     |
| 3 nodos (compute)| ~$75   |
| Load Balancer    | ~$20   |
+------------------+--------+
| TOTAL (mes)      | ~$95   |
+------------------+--------+
EOF
else
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
fi
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

if [[ "$CLOUD_PLATFORM" == "GKE" || "$CLOUD_PLATFORM" == "EXPLORATORY" ]]; then
    print_substep "Elige GKE si:"
    echo "  - Ya usas Google Cloud"
    echo "  - Quieres la experiencia K8s mas nativa (Google creo K8s)"
    echo "  - Prefieres gestion automatizada (Autopilot)"
    echo "  - Multi-cloud es importante (Anthos)"
    echo ""
fi

if [[ "$CLOUD_PLATFORM" == "EKS" || "$CLOUD_PLATFORM" == "EXPLORATORY" ]]; then
    print_substep "Elige EKS si:"
    echo "  - Ya tienes infraestructura significativa en AWS"
    echo "  - Necesitas integracion profunda con servicios AWS"
    echo "  - Compliance es critico"
    echo "  - Necesitas Fargate para serverless"
    echo ""
fi

if [[ "$CLOUD_PLATFORM" == "AKS" || "$CLOUD_PLATFORM" == "EXPLORATORY" ]]; then
    print_substep "Elige AKS si:"
    echo "  - Ya usas Azure o Microsoft 365"
    echo "  - Necesitas integracion con Azure AD"
    echo "  - Windows containers son importantes"
    echo "  - Ya tienes licencias Enterprise de Microsoft"
    echo ""
fi

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
# Limpieza de recursos (si se creo un cluster)
# =============================================================================
if [[ "$CLOUD_PLATFORM" != "EXPLORATORY" ]]; then
    print_step "Limpieza de Recursos"

    print_warning "IMPORTANTE: Si creaste un cluster, recuerda eliminarlo para evitar costos."
    echo ""

    if [[ "$CLOUD_PLATFORM" == "GKE" ]]; then
        print_substep "Eliminar cluster GKE"
        print_command "gcloud container clusters delete demo-cluster --zone us-central1-a --quiet"
        echo ""
        read -p "Deseas eliminar el cluster GKE ahora? (s/n): " DELETE_GKE
        if [[ "$DELETE_GKE" == "s" || "$DELETE_GKE" == "S" ]]; then
            gcloud container clusters delete demo-cluster --zone us-central1-a --quiet
            print_info "Cluster GKE eliminado."
        fi
    elif [[ "$CLOUD_PLATFORM" == "EKS" ]]; then
        print_substep "Eliminar cluster EKS"
        print_command "eksctl delete cluster --name demo-cluster --region us-east-1"
        echo ""
        read -p "Deseas eliminar el cluster EKS ahora? (s/n): " DELETE_EKS
        if [[ "$DELETE_EKS" == "s" || "$DELETE_EKS" == "S" ]]; then
            eksctl delete cluster --name demo-cluster --region us-east-1
            print_info "Cluster EKS eliminado."
        fi
    elif [[ "$CLOUD_PLATFORM" == "AKS" ]]; then
        print_substep "Eliminar cluster AKS y grupo de recursos"
        print_command "az group delete --name demo-rg --yes --no-wait"
        echo ""
        read -p "Deseas eliminar el grupo de recursos (y el cluster) AKS ahora? (s/n): " DELETE_AKS
        if [[ "$DELETE_AKS" == "s" || "$DELETE_AKS" == "S" ]]; then
            az group delete --name demo-rg --yes --no-wait
            print_info "Eliminacion del grupo de recursos iniciada (puede tomar unos minutos)."
        fi
    fi

    wait_for_user
fi

# =============================================================================
# Resumen Final
# =============================================================================
print_step "Laboratorio Completado"

echo "Has completado exitosamente el Lab 18: Managed Kubernetes"
echo ""
echo "Plataforma seleccionada: $CLOUD_PLATFORM"
echo ""
echo "Resumen de conceptos aprendidos:"
echo ""

if [[ "$CLOUD_PLATFORM" == "EXPLORATORY" ]]; then
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
    echo "  HERRAMIENTAS CLI:"
    echo "    - GKE: gcloud"
    echo "    - EKS: eksctl, aws"
    echo "    - AKS: az"
elif [[ "$CLOUD_PLATFORM" == "GKE" ]]; then
    echo "  GKE (Google Kubernetes Engine):"
    echo "    - Control plane gratuito"
    echo "    - Experiencia K8s nativa (Google creo Kubernetes)"
    echo "    - Modos: Standard y Autopilot"
    echo "    - Integracion: Workload Identity"
    echo "    - CLI: gcloud"
elif [[ "$CLOUD_PLATFORM" == "EKS" ]]; then
    echo "  EKS (Amazon Elastic Kubernetes Service):"
    echo "    - Control plane: ~$0.10/hora (~$73/mes)"
    echo "    - Integracion profunda con servicios AWS"
    echo "    - Opciones: Managed Node Groups, Fargate (serverless)"
    echo "    - Integracion: IAM Roles for Service Accounts (IRSA)"
    echo "    - CLI: eksctl, aws"
elif [[ "$CLOUD_PLATFORM" == "AKS" ]]; then
    echo "  AKS (Azure Kubernetes Service):"
    echo "    - Control plane gratuito"
    echo "    - Integracion con Azure AD"
    echo "    - Soporte para Windows containers"
    echo "    - Integracion: Azure Workload Identity"
    echo "    - CLI: az"
fi
echo ""
echo "  CRITERIOS DE SELECCION:"
echo "    - Infraestructura existente"
echo "    - Experiencia del equipo"
echo "    - Requisitos de integracion"
echo "    - Presupuesto"
echo "    - Compliance y seguridad"
echo ""
echo "Archivos de referencia:"
echo "  - initial/comparativa-proveedores.md"
echo "  - initial/cuestionario-seleccion.md"
if [[ "$CLOUD_PLATFORM" == "GKE" || "$CLOUD_PLATFORM" == "EXPLORATORY" ]]; then
    echo "  - initial/gke-serviceaccount.yaml"
fi
if [[ "$CLOUD_PLATFORM" == "EKS" || "$CLOUD_PLATFORM" == "EXPLORATORY" ]]; then
    echo "  - initial/eks-serviceaccount.yaml"
fi
if [[ "$CLOUD_PLATFORM" == "AKS" || "$CLOUD_PLATFORM" == "EXPLORATORY" ]]; then
    echo "  - initial/aks-serviceaccount.yaml"
fi
echo ""
echo -e "${GREEN}Felicitaciones! Has completado todos los laboratorios del curso.${NC}"
echo -e "${GREEN}Ahora estas listo para el Proyecto Final.${NC}"
