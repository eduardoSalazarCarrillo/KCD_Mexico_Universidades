#!/bin/bash
# =============================================================================
# Lab 03: Cluster Exploration - Script de Solución Completa
# =============================================================================
# Este script ejecuta todos los comandos del laboratorio de forma secuencial.
# Úsalo como referencia o para verificar que completaste correctamente el lab.
#
# NOTA: Este script asume que Minikube está corriendo (Lab 02 completado).
# =============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

wait_for_user() {
    echo ""
    read -p "Presiona Enter para continuar..."
    echo ""
}

# =============================================================================
# Verificar que Minikube está corriendo
# =============================================================================
print_step "Verificación Inicial"

if ! command -v minikube &> /dev/null; then
    echo -e "${RED}Error: Minikube no está instalado.${NC}"
    echo "Por favor, completa el Lab 02 primero."
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl no está instalado.${NC}"
    echo "Por favor, completa el Lab 02 primero."
    exit 1
fi

print_command "minikube status"
if ! minikube status &> /dev/null; then
    echo -e "${YELLOW}Minikube no está corriendo. Iniciando...${NC}"
    minikube start --driver=docker
fi
minikube status

echo ""
echo -e "${GREEN}✓ Minikube está corriendo${NC}"

wait_for_user

# =============================================================================
# Paso 2: Explorar los Nodos del Clúster
# =============================================================================
print_step "Paso 2: Explorar los Nodos del Clúster"

print_command "kubectl get nodes"
kubectl get nodes

echo ""
print_command "kubectl get nodes -o wide"
kubectl get nodes -o wide

echo ""
echo -e "${GREEN}✓ Nodos listados correctamente${NC}"

wait_for_user

# =============================================================================
# Paso 3: Inspeccionar un Nodo en Detalle
# =============================================================================
print_step "Paso 3: Inspeccionar un Nodo en Detalle"

print_command "kubectl describe node minikube"
echo "(Mostrando extracto...)"
kubectl describe node minikube | head -80

echo ""
echo "..."
echo "(Salida truncada para brevedad)"

echo ""
echo -e "${GREEN}✓ Nodo inspeccionado${NC}"

wait_for_user

# =============================================================================
# Paso 4: Explorar los Namespaces
# =============================================================================
print_step "Paso 4: Explorar los Namespaces"

print_command "kubectl get namespaces"
kubectl get namespaces

echo ""
echo -e "${GREEN}✓ Namespaces listados${NC}"

wait_for_user

# =============================================================================
# Paso 5: Explorar el Namespace kube-system
# =============================================================================
print_step "Paso 5: Explorar el Namespace kube-system"

print_command "kubectl get pods -n kube-system"
kubectl get pods -n kube-system

echo ""
print_command "kubectl get pods -n kube-system -o wide"
kubectl get pods -n kube-system -o wide

echo ""
echo -e "${GREEN}✓ Pods del sistema listados${NC}"

wait_for_user

# =============================================================================
# Paso 6: Inspeccionar el API Server
# =============================================================================
print_step "Paso 6: Inspeccionar el API Server"

print_command "kubectl describe pod -n kube-system -l component=kube-apiserver"
echo "(Mostrando extracto...)"
kubectl describe pod -n kube-system -l component=kube-apiserver | head -50

echo ""
print_substep "Logs del API Server"
print_command "kubectl logs -n kube-system -l component=kube-apiserver --tail=10"
kubectl logs -n kube-system -l component=kube-apiserver --tail=10 2>/dev/null || echo "(Logs pueden estar vacíos o no disponibles)"

echo ""
echo -e "${GREEN}✓ API Server inspeccionado${NC}"

wait_for_user

# =============================================================================
# Paso 7: Inspeccionar etcd
# =============================================================================
print_step "Paso 7: Inspeccionar etcd"

print_command "kubectl describe pod -n kube-system -l component=etcd"
echo "(Mostrando extracto...)"
kubectl describe pod -n kube-system -l component=etcd | head -50

echo ""
print_substep "Logs de etcd"
print_command "kubectl logs -n kube-system -l component=etcd --tail=10"
kubectl logs -n kube-system -l component=etcd --tail=10 2>/dev/null || echo "(Logs pueden estar vacíos o no disponibles)"

echo ""
echo -e "${GREEN}✓ etcd inspeccionado${NC}"

wait_for_user

# =============================================================================
# Paso 8: Inspeccionar el Scheduler
# =============================================================================
print_step "Paso 8: Inspeccionar el Scheduler"

print_command "kubectl describe pod -n kube-system -l component=kube-scheduler"
echo "(Mostrando extracto...)"
kubectl describe pod -n kube-system -l component=kube-scheduler | head -40

echo ""
print_substep "Logs del Scheduler"
print_command "kubectl logs -n kube-system -l component=kube-scheduler --tail=10"
kubectl logs -n kube-system -l component=kube-scheduler --tail=10 2>/dev/null || echo "(Logs pueden estar vacíos o no disponibles)"

echo ""
echo -e "${GREEN}✓ Scheduler inspeccionado${NC}"

wait_for_user

# =============================================================================
# Paso 9: Inspeccionar el Controller Manager
# =============================================================================
print_step "Paso 9: Inspeccionar el Controller Manager"

print_command "kubectl describe pod -n kube-system -l component=kube-controller-manager"
echo "(Mostrando extracto...)"
kubectl describe pod -n kube-system -l component=kube-controller-manager | head -40

echo ""
print_substep "Logs del Controller Manager"
print_command "kubectl logs -n kube-system -l component=kube-controller-manager --tail=10"
kubectl logs -n kube-system -l component=kube-controller-manager --tail=10 2>/dev/null || echo "(Logs pueden estar vacíos o no disponibles)"

echo ""
echo -e "${GREEN}✓ Controller Manager inspeccionado${NC}"

wait_for_user

# =============================================================================
# Paso 10: Inspeccionar kube-proxy
# =============================================================================
print_step "Paso 10: Inspeccionar kube-proxy"

print_command "kubectl get daemonset -n kube-system kube-proxy"
kubectl get daemonset -n kube-system kube-proxy

echo ""
print_command "kubectl describe daemonset -n kube-system kube-proxy"
echo "(Mostrando extracto...)"
kubectl describe daemonset -n kube-system kube-proxy | head -40

echo ""
echo -e "${GREEN}✓ kube-proxy inspeccionado${NC}"

wait_for_user

# =============================================================================
# Paso 11: Inspeccionar CoreDNS
# =============================================================================
print_step "Paso 11: Inspeccionar CoreDNS"

print_command "kubectl get deployment -n kube-system coredns"
kubectl get deployment -n kube-system coredns

echo ""
print_substep "ConfigMap de CoreDNS"
print_command "kubectl get configmap -n kube-system coredns -o yaml"
echo "(Mostrando extracto...)"
kubectl get configmap -n kube-system coredns -o yaml | head -30

echo ""
echo -e "${GREEN}✓ CoreDNS inspeccionado${NC}"

wait_for_user

# =============================================================================
# Paso 12: Inspeccionar kubelet (dentro del nodo)
# =============================================================================
print_step "Paso 12: Inspeccionar kubelet"

echo "El kubelet corre como servicio del sistema, no como pod."
echo "Para inspeccionarlo, necesitas conectarte al nodo:"
echo ""
print_command "minikube ssh"
echo ""
echo "Ejecutando comandos dentro del nodo..."
echo ""

print_substep "Estado del kubelet"
minikube ssh -- systemctl status kubelet --no-pager | head -15

echo ""
print_substep "Contenedores corriendo (docker ps)"
minikube ssh -- docker ps --format "table {{.Names}}\t{{.Status}}" | head -15

echo ""
echo -e "${GREEN}✓ kubelet inspeccionado${NC}"

wait_for_user

# =============================================================================
# Paso 13: Explorar la API de Kubernetes
# =============================================================================
print_step "Paso 13: Explorar la API de Kubernetes"

print_command "kubectl api-resources | head -20"
kubectl api-resources | head -20
echo "..."
echo "(Lista truncada)"

echo ""
print_command "kubectl api-versions"
kubectl api-versions

echo ""
echo -e "${GREEN}✓ API explorada${NC}"

wait_for_user

# =============================================================================
# Paso 14: Acceder Directamente a la API
# =============================================================================
print_step "Paso 14: Acceder Directamente a la API"

echo "Iniciando proxy en segundo plano..."
print_command "kubectl proxy &"
kubectl proxy &
PROXY_PID=$!
sleep 2

echo ""
print_substep "Consultando /api"
print_command "curl -s http://localhost:8001/api"
curl -s http://localhost:8001/api | head -20

echo ""
print_substep "Consultando namespaces via API"
print_command "curl -s http://localhost:8001/api/v1/namespaces | head -30"
curl -s http://localhost:8001/api/v1/namespaces | head -30

echo ""
echo "Deteniendo proxy..."
kill $PROXY_PID 2>/dev/null || true

echo ""
echo -e "${GREEN}✓ API accedida directamente${NC}"

wait_for_user

# =============================================================================
# Ejercicios Adicionales
# =============================================================================
print_step "Ejercicios Adicionales"

print_substep "Ejercicio 1: Versión de etcd"
print_command "kubectl describe pod -n kube-system -l component=etcd | grep Image:"
kubectl describe pod -n kube-system -l component=etcd | grep Image:

echo ""
print_substep "Ejercicio 2: Réplicas de CoreDNS"
print_command "kubectl get deployment -n kube-system coredns"
kubectl get deployment -n kube-system coredns

echo ""
print_substep "Ejercicio 4: Eventos del clúster"
print_command "kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -10"
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -10

echo ""
print_substep "Ejercicio 5: Salud de los componentes"
print_command "kubectl get --raw='/readyz?verbose'"
kubectl get --raw='/readyz?verbose' 2>/dev/null | head -30 || echo "(Endpoint puede no estar disponible)"

echo ""
echo -e "${GREEN}✓ Ejercicios adicionales completados${NC}"

wait_for_user

# =============================================================================
# Resumen Final
# =============================================================================
print_step "Laboratorio Completado"

echo "Has completado exitosamente el Lab 03: Cluster Exploration"
echo ""
echo "Resumen de componentes explorados:"
echo ""
echo "  CONTROL PLANE:"
echo "    - kube-apiserver     : Punto de entrada de la API"
echo "    - etcd               : Base de datos del clúster"
echo "    - kube-scheduler     : Asigna pods a nodos"
echo "    - controller-manager : Ejecuta controladores"
echo ""
echo "  WORKER NODE:"
echo "    - kubelet            : Agente del nodo (servicio del sistema)"
echo "    - kube-proxy         : Maneja reglas de red (DaemonSet)"
echo ""
echo "  OTROS:"
echo "    - CoreDNS            : DNS interno del clúster"
echo ""
echo "Comandos principales aprendidos:"
echo "  - kubectl get nodes [-o wide]"
echo "  - kubectl describe node <nombre>"
echo "  - kubectl get namespaces"
echo "  - kubectl get pods -n kube-system"
echo "  - kubectl describe pod -n <ns> -l <label>"
echo "  - kubectl logs -n <ns> -l <label>"
echo "  - kubectl get daemonset/deployment -n kube-system"
echo "  - kubectl api-resources / api-versions"
echo "  - kubectl proxy"
echo "  - minikube ssh"
echo ""
echo -e "${GREEN}¡Felicitaciones! Estás listo para el Lab 04: Pods y Deployments${NC}"
