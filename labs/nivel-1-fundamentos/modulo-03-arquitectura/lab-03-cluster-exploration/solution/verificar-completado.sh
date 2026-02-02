#!/bin/bash
# =============================================================================
# Lab 03: Cluster Exploration - Verificación de Completado
# =============================================================================
# Este script verifica que has completado correctamente el laboratorio
# verificando que puedes ejecutar los comandos principales y entiendes
# los componentes del clúster.
# =============================================================================

echo "=============================================="
echo "  Lab 03: Verificación de Completado"
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
    ((CHECKS_PASSED++))
    ((CHECKS_TOTAL++))
}

check_failed() {
    echo -e "${RED}✗${NC} $1"
    ((CHECKS_TOTAL++))
}

# =============================================================================
# Verificación 1: Minikube corriendo
# =============================================================================
echo "1. Verificando que Minikube está corriendo..."

if minikube status &> /dev/null; then
    check_passed "Minikube está corriendo"
else
    check_failed "Minikube no está corriendo"
    echo "   Ejecuta: minikube start --driver=docker"
fi

# =============================================================================
# Verificación 2: kubectl puede listar nodos
# =============================================================================
echo ""
echo "2. Verificando listado de nodos..."

if kubectl get nodes &> /dev/null; then
    check_passed "kubectl get nodes funciona"
else
    check_failed "kubectl get nodes falló"
fi

# =============================================================================
# Verificación 3: Puede ver nodos con formato wide
# =============================================================================
echo ""
echo "3. Verificando información extendida de nodos..."

if kubectl get nodes -o wide &> /dev/null; then
    NODE_INFO=$(kubectl get nodes -o wide 2>/dev/null)
    if echo "$NODE_INFO" | grep -q "minikube"; then
        check_passed "kubectl get nodes -o wide muestra el nodo minikube"
    else
        check_failed "No se encontró el nodo minikube"
    fi
else
    check_failed "kubectl get nodes -o wide falló"
fi

# =============================================================================
# Verificación 4: Puede describir nodo
# =============================================================================
echo ""
echo "4. Verificando descripción de nodo..."

if kubectl describe node minikube &> /dev/null; then
    check_passed "kubectl describe node minikube funciona"
else
    check_failed "kubectl describe node minikube falló"
fi

# =============================================================================
# Verificación 5: Puede listar namespaces
# =============================================================================
echo ""
echo "5. Verificando listado de namespaces..."

if kubectl get namespaces &> /dev/null; then
    NS_OUTPUT=$(kubectl get namespaces 2>/dev/null)
    if echo "$NS_OUTPUT" | grep -q "kube-system"; then
        check_passed "kubectl get namespaces muestra kube-system"
    else
        check_failed "No se encontró el namespace kube-system"
    fi
else
    check_failed "kubectl get namespaces falló"
fi

# =============================================================================
# Verificación 6: Puede listar pods en kube-system
# =============================================================================
echo ""
echo "6. Verificando pods en kube-system..."

if kubectl get pods -n kube-system &> /dev/null; then
    PODS_OUTPUT=$(kubectl get pods -n kube-system 2>/dev/null)
    check_passed "kubectl get pods -n kube-system funciona"
else
    check_failed "kubectl get pods -n kube-system falló"
fi

# =============================================================================
# Verificación 7: API Server está corriendo
# =============================================================================
echo ""
echo "7. Verificando componentes del Control Plane..."

# API Server
if kubectl get pods -n kube-system -l component=kube-apiserver 2>/dev/null | grep -q "Running"; then
    check_passed "kube-apiserver está corriendo"
else
    check_failed "kube-apiserver no está corriendo"
fi

# etcd
if kubectl get pods -n kube-system -l component=etcd 2>/dev/null | grep -q "Running"; then
    check_passed "etcd está corriendo"
else
    check_failed "etcd no está corriendo"
fi

# Scheduler
if kubectl get pods -n kube-system -l component=kube-scheduler 2>/dev/null | grep -q "Running"; then
    check_passed "kube-scheduler está corriendo"
else
    check_failed "kube-scheduler no está corriendo"
fi

# Controller Manager
if kubectl get pods -n kube-system -l component=kube-controller-manager 2>/dev/null | grep -q "Running"; then
    check_passed "kube-controller-manager está corriendo"
else
    check_failed "kube-controller-manager no está corriendo"
fi

# =============================================================================
# Verificación 8: kube-proxy DaemonSet
# =============================================================================
echo ""
echo "8. Verificando kube-proxy DaemonSet..."

if kubectl get daemonset -n kube-system kube-proxy &> /dev/null; then
    DS_OUTPUT=$(kubectl get daemonset -n kube-system kube-proxy 2>/dev/null)
    if echo "$DS_OUTPUT" | grep -q "1.*1.*1"; then
        check_passed "kube-proxy DaemonSet está corriendo (1/1)"
    else
        check_failed "kube-proxy DaemonSet no tiene todas las réplicas listas"
    fi
else
    check_failed "kubectl get daemonset kube-proxy falló"
fi

# =============================================================================
# Verificación 9: CoreDNS Deployment
# =============================================================================
echo ""
echo "9. Verificando CoreDNS Deployment..."

if kubectl get deployment -n kube-system coredns &> /dev/null; then
    check_passed "CoreDNS deployment existe"
else
    check_failed "CoreDNS deployment no encontrado"
fi

# =============================================================================
# Verificación 10: Puede ver logs de componentes
# =============================================================================
echo ""
echo "10. Verificando acceso a logs de componentes..."

if kubectl logs -n kube-system -l component=kube-apiserver --tail=1 &> /dev/null; then
    check_passed "Puede acceder a logs del API Server"
else
    # Algunos clústeres no tienen logs disponibles inmediatamente
    if kubectl logs -n kube-system -l component=etcd --tail=1 &> /dev/null; then
        check_passed "Puede acceder a logs de etcd"
    else
        check_failed "No puede acceder a logs de componentes del sistema"
    fi
fi

# =============================================================================
# Verificación 11: kubectl api-resources
# =============================================================================
echo ""
echo "11. Verificando exploración de API..."

if kubectl api-resources &> /dev/null; then
    API_OUTPUT=$(kubectl api-resources 2>/dev/null)
    if echo "$API_OUTPUT" | grep -q "pods"; then
        check_passed "kubectl api-resources funciona y muestra pods"
    else
        check_failed "kubectl api-resources no muestra pods"
    fi
else
    check_failed "kubectl api-resources falló"
fi

# =============================================================================
# Verificación 12: kubectl api-versions
# =============================================================================
echo ""
echo "12. Verificando versiones de API..."

if kubectl api-versions &> /dev/null; then
    API_VERSIONS=$(kubectl api-versions 2>/dev/null)
    if echo "$API_VERSIONS" | grep -q "apps/v1"; then
        check_passed "kubectl api-versions funciona y muestra apps/v1"
    else
        check_failed "kubectl api-versions no muestra apps/v1"
    fi
else
    check_failed "kubectl api-versions falló"
fi

# =============================================================================
# Verificación 13: minikube ssh funciona
# =============================================================================
echo ""
echo "13. Verificando acceso SSH al nodo..."

if minikube ssh -- echo "test" &> /dev/null; then
    check_passed "minikube ssh funciona"
else
    check_failed "minikube ssh falló"
fi

# =============================================================================
# Verificación 14: Puede ver kubelet dentro del nodo
# =============================================================================
echo ""
echo "14. Verificando kubelet dentro del nodo..."

if minikube ssh -- systemctl is-active kubelet &> /dev/null; then
    KUBELET_STATUS=$(minikube ssh -- systemctl is-active kubelet 2>/dev/null | tr -d '\r')
    if [ "$KUBELET_STATUS" = "active" ]; then
        check_passed "kubelet está activo en el nodo"
    else
        check_failed "kubelet no está activo"
    fi
else
    check_failed "No se pudo verificar kubelet en el nodo"
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
    echo -e "${GREEN}Has completado exitosamente el Lab 03: Cluster Exploration${NC}"
    echo ""
    echo "Has demostrado que puedes:"
    echo "  - Listar y describir nodos del clúster"
    echo "  - Explorar namespaces del sistema"
    echo "  - Identificar los componentes del Control Plane"
    echo "  - Ver logs de componentes críticos"
    echo "  - Explorar la API de Kubernetes"
    echo "  - Acceder al nodo via SSH y verificar kubelet"
    echo ""
    echo "Estás listo para continuar con el Lab 04: Pods y Deployments"
else
    FAILED=$((CHECKS_TOTAL - CHECKS_PASSED))
    echo -e "${YELLOW}Algunas verificaciones fallaron ($FAILED de $CHECKS_TOTAL)${NC}"
    echo "Revisa los puntos marcados con ✗ y vuelve a intentar"
    echo ""
    echo "Posibles soluciones:"
    echo "  - Asegúrate de que Minikube está corriendo: minikube start"
    echo "  - Verifica tu conexión al clúster: kubectl cluster-info"
    echo "  - Revisa el README.md para más detalles sobre cada paso"
fi

echo ""
echo "=============================================="
