#!/bin/bash
# =============================================================================
# Lab 02: Minikube Setup - Script de Solución Completa
# =============================================================================
# Este script ejecuta todos los comandos del laboratorio de forma secuencial.
# Úsalo como referencia o para verificar que completaste correctamente el lab.
#
# NOTA: Este script asume que Docker ya está instalado (Lab 01 completado).
# =============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo ""
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo ""
}

print_command() {
    echo -e "${YELLOW}$ $1${NC}"
}

wait_for_user() {
    echo ""
    read -p "Presiona Enter para continuar..."
    echo ""
}

# =============================================================================
# Verificar Docker
# =============================================================================
print_step "Paso 1: Verificar Docker"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker no está instalado.${NC}"
    echo "Por favor, completa el Lab 01 primero."
    exit 1
fi

print_command "docker version"
docker version --format 'Cliente: {{.Client.Version}}, Servidor: {{.Server.Version}}'

echo ""
echo -e "${GREEN}✓ Docker está funcionando correctamente${NC}"

wait_for_user

# =============================================================================
# Verificar/Instalar Minikube
# =============================================================================
print_step "Pasos 2-3: Verificar Minikube"

if ! command -v minikube &> /dev/null; then
    echo "Minikube no está instalado."
    echo "Instalando Minikube..."

    # Detectar arquitectura
    ARCH=$(uname -m)
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')

    if [ "$OS" = "linux" ]; then
        if [ "$ARCH" = "x86_64" ]; then
            curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
            sudo install minikube-linux-amd64 /usr/local/bin/minikube
            rm minikube-linux-amd64
        elif [ "$ARCH" = "aarch64" ]; then
            curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-arm64
            sudo install minikube-linux-arm64 /usr/local/bin/minikube
            rm minikube-linux-arm64
        fi
    elif [ "$OS" = "darwin" ]; then
        if command -v brew &> /dev/null; then
            brew install minikube
        else
            echo "Por favor instala Minikube manualmente siguiendo el README.md"
            exit 1
        fi
    fi
fi

print_command "minikube version"
minikube version

echo ""
echo -e "${GREEN}✓ Minikube está instalado${NC}"

wait_for_user

# =============================================================================
# Verificar/Instalar kubectl
# =============================================================================
print_step "Pasos 4-5: Verificar kubectl"

if ! command -v kubectl &> /dev/null; then
    echo "kubectl no está instalado."
    echo "Instalando kubectl..."

    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)

    if [ "$OS" = "linux" ]; then
        if [ "$ARCH" = "x86_64" ]; then
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        elif [ "$ARCH" = "aarch64" ]; then
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"
        fi
        sudo install kubectl /usr/local/bin/kubectl
        rm kubectl
    elif [ "$OS" = "darwin" ]; then
        if command -v brew &> /dev/null; then
            brew install kubectl
        else
            echo "Por favor instala kubectl manualmente siguiendo el README.md"
            exit 1
        fi
    fi
fi

print_command "kubectl version --client"
kubectl version --client

echo ""
echo -e "${GREEN}✓ kubectl está instalado${NC}"

wait_for_user

# =============================================================================
# Iniciar Minikube
# =============================================================================
print_step "Paso 6: Iniciar el Clúster de Minikube"

# Verificar si ya existe un clúster
if minikube status &> /dev/null; then
    echo "Ya existe un clúster de Minikube ejecutándose."
    print_command "minikube status"
    minikube status
else
    echo "Iniciando nuevo clúster de Minikube..."
    print_command "minikube start --driver=docker"
    minikube start --driver=docker
fi

echo ""
echo -e "${GREEN}✓ Clúster de Minikube iniciado${NC}"

wait_for_user

# =============================================================================
# Verificar estado del clúster
# =============================================================================
print_step "Paso 7: Verificar Estado del Clúster"

print_command "minikube status"
minikube status

echo ""
echo -e "${GREEN}✓ El clúster está funcionando${NC}"

wait_for_user

# =============================================================================
# Verificar conexión con kubectl
# =============================================================================
print_step "Paso 8: Verificar Conexión con kubectl"

print_command "kubectl cluster-info"
kubectl cluster-info

echo ""
print_command "kubectl get nodes"
kubectl get nodes

echo ""
print_command "kubectl version"
kubectl version

echo ""
echo -e "${GREEN}✓ kubectl está conectado al clúster${NC}"

wait_for_user

# =============================================================================
# Dashboard (solo mostrar URL)
# =============================================================================
print_step "Paso 9: Dashboard de Kubernetes"

echo "El dashboard se puede abrir con: minikube dashboard"
echo "Para obtener solo la URL: minikube dashboard --url"
echo ""
echo "NOTA: No ejecutamos el dashboard automáticamente porque bloquea la terminal."

wait_for_user

# =============================================================================
# Comandos útiles
# =============================================================================
print_step "Paso 10: Comandos Útiles de Minikube"

print_command "minikube ip"
minikube ip

echo ""
print_command "minikube profile list"
minikube profile list

echo ""
print_command "minikube addons list | head -20"
minikube addons list | head -20
echo "... (lista truncada)"

wait_for_user

# =============================================================================
# Contextos de Kubernetes
# =============================================================================
print_step "Paso 11: Contextos de Kubernetes"

print_command "kubectl config current-context"
kubectl config current-context

echo ""
print_command "kubectl config get-contexts"
kubectl config get-contexts

echo ""
echo -e "${GREEN}✓ Contexto configurado correctamente${NC}"

wait_for_user

# =============================================================================
# Resumen Final
# =============================================================================
print_step "Laboratorio Completado"

echo "Has completado exitosamente el Lab 02: Minikube Setup"
echo ""
echo "Estado del clúster:"
minikube status
echo ""
echo "Comandos principales aprendidos:"
echo "  - minikube version      : Ver versión de Minikube"
echo "  - minikube start        : Iniciar el clúster"
echo "  - minikube status       : Ver estado del clúster"
echo "  - minikube stop         : Detener el clúster"
echo "  - minikube delete       : Eliminar el clúster"
echo "  - minikube dashboard    : Abrir dashboard web"
echo "  - kubectl cluster-info  : Información del clúster"
echo "  - kubectl get nodes     : Ver nodos del clúster"
echo "  - kubectl config        : Gestionar contextos"
echo ""
echo -e "${GREEN}¡Felicitaciones! Estás listo para el Lab 03: Cluster Exploration${NC}"
echo ""
echo -e "${YELLOW}IMPORTANTE: Mantén el clúster corriendo para el siguiente laboratorio.${NC}"
echo "Si necesitas pausarlo temporalmente, usa: minikube pause"
