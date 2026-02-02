#!/bin/bash
# =============================================================================
# Lab 02: Minikube Setup - Verificación de Completado
# =============================================================================
# Este script verifica que has completado correctamente el laboratorio
# verificando que Minikube y kubectl funcionan correctamente.
# =============================================================================

set -e

echo "=============================================="
echo "  Lab 02: Verificación de Completado"
echo "=============================================="
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Contador de verificaciones
CHECKS_PASSED=0
CHECKS_TOTAL=0

check_passed() {
    echo -e "${GREEN}✓${NC} $1"
    ((++CHECKS_PASSED))
    ((++CHECKS_TOTAL))
}

check_failed() {
    echo -e "${RED}✗${NC} $1"
    ((++CHECKS_TOTAL))
}

# =============================================================================
# Verificación 1: Minikube instalado
# =============================================================================
echo "1. Verificando instalación de Minikube..."

if command -v minikube &> /dev/null; then
    VERSION=$(minikube version --short 2>/dev/null || minikube version | head -1)
    check_passed "Minikube está instalado ($VERSION)"
else
    check_failed "Minikube no está instalado"
    exit 1
fi

# =============================================================================
# Verificación 2: kubectl instalado
# =============================================================================
echo ""
echo "2. Verificando instalación de kubectl..."

if command -v kubectl &> /dev/null; then
    VERSION=$(kubectl version --client -o yaml 2>/dev/null | grep gitVersion | head -1 | awk '{print $2}' || echo "instalado")
    check_passed "kubectl está instalado ($VERSION)"
else
    check_failed "kubectl no está instalado"
fi

# =============================================================================
# Verificación 3: Clúster corriendo
# =============================================================================
echo ""
echo "3. Verificando estado del clúster..."

if minikube status &> /dev/null; then
    HOST_STATUS=$(minikube status --format='{{.Host}}' 2>/dev/null)
    KUBELET_STATUS=$(minikube status --format='{{.Kubelet}}' 2>/dev/null)
    APISERVER_STATUS=$(minikube status --format='{{.APIServer}}' 2>/dev/null)

    if [ "$HOST_STATUS" = "Running" ]; then
        check_passed "Host está corriendo"
    else
        check_failed "Host no está corriendo (estado: $HOST_STATUS)"
    fi

    if [ "$KUBELET_STATUS" = "Running" ]; then
        check_passed "Kubelet está corriendo"
    else
        check_failed "Kubelet no está corriendo (estado: $KUBELET_STATUS)"
    fi

    if [ "$APISERVER_STATUS" = "Running" ]; then
        check_passed "API Server está corriendo"
    else
        check_failed "API Server no está corriendo (estado: $APISERVER_STATUS)"
    fi
else
    check_failed "El clúster de Minikube no está corriendo"
    echo "   → Inicia el clúster con: minikube start"
fi

# =============================================================================
# Verificación 4: kubectl puede conectarse
# =============================================================================
echo ""
echo "4. Verificando conexión de kubectl..."

if kubectl cluster-info &> /dev/null; then
    check_passed "kubectl puede conectarse al clúster"
else
    check_failed "kubectl no puede conectarse al clúster"
fi

# =============================================================================
# Verificación 5: Nodos disponibles
# =============================================================================
echo ""
echo "5. Verificando nodos del clúster..."

if kubectl get nodes &> /dev/null; then
    NODE_STATUS=$(kubectl get nodes -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)

    if [ "$NODE_STATUS" = "True" ]; then
        check_passed "Nodo minikube está Ready"
    else
        check_failed "Nodo minikube no está Ready"
    fi
else
    check_failed "No se pueden obtener los nodos"
fi

# =============================================================================
# Verificación 6: Contexto configurado
# =============================================================================
echo ""
echo "6. Verificando contexto de Kubernetes..."

CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "ninguno")

if [ "$CURRENT_CONTEXT" = "minikube" ]; then
    check_passed "Contexto actual es 'minikube'"
else
    check_failed "Contexto actual no es 'minikube' (es: $CURRENT_CONTEXT)"
    echo "   → Cambia el contexto con: kubectl config use-context minikube"
fi

# =============================================================================
# Verificación 7: Pods del sistema corriendo
# =============================================================================
echo ""
echo "7. Verificando pods del sistema..."

SYSTEM_PODS=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | wc -l)

if [ "$SYSTEM_PODS" -gt 0 ]; then
    RUNNING_PODS=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -c "Running" || echo "0")
    check_passed "Hay $RUNNING_PODS pods del sistema corriendo"
else
    check_failed "No hay pods del sistema"
fi

# =============================================================================
# Verificación 8: Servicios del sistema
# =============================================================================
echo ""
echo "8. Verificando servicios del sistema..."

if kubectl get svc -n kube-system kubernetes &> /dev/null 2>&1 || kubectl get svc kubernetes &> /dev/null; then
    check_passed "Servicio de Kubernetes API disponible"
else
    check_failed "Servicio de Kubernetes API no encontrado"
fi

# =============================================================================
# Verificación 9: DNS del clúster
# =============================================================================
echo ""
echo "9. Verificando DNS del clúster..."

if kubectl get svc -n kube-system kube-dns &> /dev/null 2>&1; then
    check_passed "Servicio DNS (kube-dns) está disponible"
elif kubectl get svc -n kube-system coredns &> /dev/null 2>&1; then
    check_passed "Servicio DNS (CoreDNS) está disponible"
else
    check_failed "Servicio DNS no encontrado"
fi

# =============================================================================
# Verificación 10: Addons básicos
# =============================================================================
echo ""
echo "10. Verificando addons básicos..."

STORAGE_ADDON=$(minikube addons list 2>/dev/null | grep "storage-provisioner" | grep -c "enabled" || echo "0")
if [ "$STORAGE_ADDON" -gt 0 ]; then
    check_passed "Addon storage-provisioner está habilitado"
else
    check_failed "Addon storage-provisioner no está habilitado"
fi

# =============================================================================
# Resumen
# =============================================================================
echo ""
echo "=============================================="
echo "  Resumen de Verificación"
echo "=============================================="
echo ""
echo "Verificaciones pasadas: $CHECKS_PASSED/$CHECKS_TOTAL"
echo ""

if [ $CHECKS_PASSED -eq $CHECKS_TOTAL ]; then
    echo -e "${GREEN}¡FELICITACIONES!${NC}"
    echo -e "${GREEN}Has completado exitosamente el Lab 02: Minikube Setup${NC}"
    echo ""
    echo "Tu clúster de Kubernetes local está funcionando correctamente."
    echo ""
    echo "Información del clúster:"
    echo "  - IP: $(minikube ip 2>/dev/null || echo 'N/A')"
    echo "  - Kubernetes: $(kubectl version --short 2>/dev/null | grep Server | awk '{print $3}' || echo 'N/A')"
    echo ""
    echo "Estás listo para continuar con el Lab 03: Cluster Exploration"
    echo ""
    echo -e "${YELLOW}IMPORTANTE: Mantén el clúster corriendo para el siguiente laboratorio.${NC}"
else
    FAILED=$((CHECKS_TOTAL - CHECKS_PASSED))
    echo -e "${YELLOW}Algunas verificaciones fallaron ($FAILED de $CHECKS_TOTAL)${NC}"
    echo "Revisa los puntos marcados con ✗ y vuelve a intentar"
    echo ""
    echo "Sugerencias:"
    echo "  - Si el clúster no está corriendo: minikube start"
    echo "  - Si hay problemas de conexión: minikube delete && minikube start"
    echo "  - Si el contexto es incorrecto: kubectl config use-context minikube"
fi

echo ""
echo "=============================================="
