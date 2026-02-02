#!/bin/bash
# =============================================================================
# Lab 04: Pods y Deployments - Script de Solución Completa
# =============================================================================
# Este script ejecuta todos los comandos del laboratorio de forma secuencial.
# Úsalo como referencia o para verificar que completaste correctamente el lab.
#
# NOTA: Este script asume que Minikube está corriendo (Lab 03 completado).
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

wait_for_user() {
    echo ""
    read -p "Presiona Enter para continuar..."
    echo ""
}

wait_for_pods() {
    local label=$1
    local expected=$2
    echo "Esperando a que los pods estén listos..."
    kubectl wait --for=condition=Ready pods -l "$label" --timeout=60s 2>/dev/null || true
}

# =============================================================================
# Verificación Inicial
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
# Paso 2: Crear un Pod Simple con kubectl run
# =============================================================================
print_step "Paso 2: Crear un Pod Simple con kubectl run"

# Limpiar pod si existe
kubectl delete pod mi-primer-pod --ignore-not-found=true 2>/dev/null

print_command "kubectl run mi-primer-pod --image=nginx:alpine"
kubectl run mi-primer-pod --image=nginx:alpine

echo ""
echo "Esperando a que el pod esté listo..."
kubectl wait --for=condition=Ready pod/mi-primer-pod --timeout=60s

echo ""
print_command "kubectl get pods"
kubectl get pods

echo ""
print_command "kubectl get pods -o wide"
kubectl get pods -o wide

echo ""
echo -e "${GREEN}✓ Pod creado exitosamente${NC}"

wait_for_user

# =============================================================================
# Paso 3: Inspeccionar el Pod
# =============================================================================
print_step "Paso 3: Inspeccionar el Pod"

print_command "kubectl describe pod mi-primer-pod"
echo "(Mostrando extracto...)"
kubectl describe pod mi-primer-pod | head -60

echo ""
echo "..."
echo "(Salida truncada para brevedad)"

echo ""
echo -e "${GREEN}✓ Pod inspeccionado${NC}"

wait_for_user

# =============================================================================
# Paso 4: Ver los Logs del Pod
# =============================================================================
print_step "Paso 4: Ver los Logs del Pod"

print_command "kubectl logs mi-primer-pod"
kubectl logs mi-primer-pod 2>/dev/null || echo "(Los logs pueden estar vacíos si no hay tráfico)"

echo ""
echo -e "${GREEN}✓ Logs revisados${NC}"

wait_for_user

# =============================================================================
# Paso 5: Ejecutar Comandos Dentro del Pod
# =============================================================================
print_step "Paso 5: Ejecutar Comandos Dentro del Pod"

print_command "kubectl exec mi-primer-pod -- nginx -v"
kubectl exec mi-primer-pod -- nginx -v

echo ""
print_substep "Ejecutando comandos dentro del pod"
print_command "kubectl exec mi-primer-pod -- hostname"
kubectl exec mi-primer-pod -- hostname

print_command "kubectl exec mi-primer-pod -- cat /etc/os-release | head -5"
kubectl exec mi-primer-pod -- cat /etc/os-release | head -5

print_command "kubectl exec mi-primer-pod -- ls /usr/share/nginx/html/"
kubectl exec mi-primer-pod -- ls /usr/share/nginx/html/

echo ""
echo -e "${GREEN}✓ Comandos ejecutados dentro del pod${NC}"

wait_for_user

# =============================================================================
# Paso 6: Eliminar el Pod y Observar que NO se Recrea
# =============================================================================
print_step "Paso 6: Eliminar el Pod (NO se recrea)"

print_command "kubectl delete pod mi-primer-pod"
kubectl delete pod mi-primer-pod

echo ""
print_command "kubectl get pods"
kubectl get pods 2>/dev/null || echo "No resources found in default namespace."

echo ""
echo -e "${YELLOW}Nota: El pod NO se recrea porque fue creado directamente, sin un controlador.${NC}"

echo ""
echo -e "${GREEN}✓ Pod eliminado (no se recrea)${NC}"

wait_for_user

# =============================================================================
# Paso 7: Crear un Pod usando un Archivo YAML
# =============================================================================
print_step "Paso 7: Crear un Pod usando un Archivo YAML"

print_command "cat $LAB_DIR/initial/pod-nginx.yaml"
cat "$LAB_DIR/initial/pod-nginx.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/pod-nginx.yaml"
kubectl apply -f "$LAB_DIR/initial/pod-nginx.yaml"

echo ""
echo "Esperando a que el pod esté listo..."
kubectl wait --for=condition=Ready pod/pod-nginx --timeout=60s

echo ""
print_command "kubectl get pods --show-labels"
kubectl get pods --show-labels

echo ""
echo -e "${GREEN}✓ Pod creado desde archivo YAML${NC}"

wait_for_user

# =============================================================================
# Paso 8: Crear un Deployment
# =============================================================================
print_step "Paso 8: Crear un Deployment"

print_command "cat $LAB_DIR/initial/deployment-nginx.yaml"
cat "$LAB_DIR/initial/deployment-nginx.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/deployment-nginx.yaml"
kubectl apply -f "$LAB_DIR/initial/deployment-nginx.yaml"

echo ""
echo "Esperando a que el deployment esté listo..."
kubectl rollout status deployment/nginx-deployment --timeout=60s

echo ""
echo -e "${GREEN}✓ Deployment creado${NC}"

wait_for_user

# =============================================================================
# Paso 9: Verificar el Deployment, ReplicaSet y Pods
# =============================================================================
print_step "Paso 9: Verificar el Deployment, ReplicaSet y Pods"

print_command "kubectl get deployments"
kubectl get deployments

echo ""
print_command "kubectl get replicasets"
kubectl get replicasets

echo ""
print_command "kubectl get pods --show-labels"
kubectl get pods --show-labels

echo ""
echo -e "${GREEN}✓ Deployment, ReplicaSet y Pods verificados${NC}"

wait_for_user

# =============================================================================
# Paso 10: Describir el Deployment
# =============================================================================
print_step "Paso 10: Describir el Deployment"

print_command "kubectl describe deployment nginx-deployment"
echo "(Mostrando extracto...)"
kubectl describe deployment nginx-deployment | head -50

echo ""
echo "..."
echo "(Salida truncada para brevedad)"

echo ""
echo -e "${GREEN}✓ Deployment descrito${NC}"

wait_for_user

# =============================================================================
# Paso 11: Probar el Self-Healing
# =============================================================================
print_step "Paso 11: Probar el Self-Healing"

print_substep "Obteniendo nombre de un pod del Deployment"
POD_NAME=$(kubectl get pods -l app=nginx-deploy -o jsonpath='{.items[0].metadata.name}')
echo "Pod a eliminar: $POD_NAME"

echo ""
print_command "kubectl delete pod $POD_NAME"
kubectl delete pod "$POD_NAME" &

# Pequeña pausa para que empiece la eliminación
sleep 1

echo ""
print_substep "Verificando pods (observa el pod nuevo creándose)"
print_command "kubectl get pods -l app=nginx-deploy"
kubectl get pods -l app=nginx-deploy

# Esperar a que se complete la eliminación en segundo plano
wait

echo ""
echo "Esperando a que todos los pods estén listos..."
sleep 3
kubectl wait --for=condition=Ready pods -l app=nginx-deploy --timeout=60s 2>/dev/null || true

echo ""
print_command "kubectl get pods -l app=nginx-deploy"
kubectl get pods -l app=nginx-deploy

echo ""
echo -e "${YELLOW}Observa: Kubernetes automáticamente creó un nuevo pod para mantener 3 réplicas${NC}"

echo ""
echo -e "${GREEN}✓ Self-healing verificado${NC}"

wait_for_user

# =============================================================================
# Paso 12: Filtrar Pods por Labels
# =============================================================================
print_step "Paso 12: Filtrar Pods por Labels"

print_command "kubectl get pods -l app=nginx-deploy"
kubectl get pods -l app=nginx-deploy

echo ""
print_command "kubectl get pods -l 'app!=nginx-deploy'"
kubectl get pods -l 'app!=nginx-deploy'

echo ""
print_command "kubectl get pods -l app=nginx,environment=lab"
kubectl get pods -l app=nginx,environment=lab

echo ""
echo -e "${GREEN}✓ Filtrado por labels funcionando${NC}"

wait_for_user

# =============================================================================
# Paso 13: Ver Todos los Recursos Relacionados
# =============================================================================
print_step "Paso 13: Ver Todos los Recursos Relacionados"

print_command "kubectl get all -l app=nginx-deploy"
kubectl get all -l app=nginx-deploy

echo ""
echo -e "${GREEN}✓ Recursos relacionados listados${NC}"

wait_for_user

# =============================================================================
# Paso 14: Limpiar los Recursos
# =============================================================================
print_step "Paso 14: Limpiar los Recursos"

print_command "kubectl delete pod pod-nginx"
kubectl delete pod pod-nginx

print_command "kubectl delete deployment nginx-deployment"
kubectl delete deployment nginx-deployment

echo ""
echo "Esperando a que los recursos se eliminen..."
sleep 3

print_command "kubectl get all"
kubectl get all

echo ""
echo -e "${GREEN}✓ Recursos limpiados${NC}"

wait_for_user

# =============================================================================
# Ejercicios Adicionales
# =============================================================================
print_step "Ejercicios Adicionales"

print_substep "Ejercicio 2: Crear un Deployment con kubectl create"
print_command "kubectl create deployment web-app --image=httpd:alpine --replicas=2"
kubectl create deployment web-app --image=httpd:alpine --replicas=2

echo ""
echo "Esperando a que el deployment esté listo..."
kubectl rollout status deployment/web-app --timeout=60s

echo ""
print_command "kubectl get deployment web-app"
kubectl get deployment web-app

print_command "kubectl get pods -l app=web-app"
kubectl get pods -l app=web-app

echo ""
print_command "kubectl delete deployment web-app"
kubectl delete deployment web-app

echo ""
print_substep "Ejercicio 3: Generar YAML con dry-run"
print_command "kubectl run test-pod --image=nginx:alpine --dry-run=client -o yaml"
kubectl run test-pod --image=nginx:alpine --dry-run=client -o yaml

echo ""
print_command "kubectl create deployment test-deploy --image=nginx:alpine --replicas=2 --dry-run=client -o yaml"
kubectl create deployment test-deploy --image=nginx:alpine --replicas=2 --dry-run=client -o yaml

echo ""
echo -e "${GREEN}✓ Ejercicios adicionales completados${NC}"

wait_for_user

# =============================================================================
# Resumen Final
# =============================================================================
print_step "Laboratorio Completado"

echo "Has completado exitosamente el Lab 04: Pods y Deployments"
echo ""
echo "Resumen de conceptos aprendidos:"
echo ""
echo "  PODS:"
echo "    - Unidad mínima de despliegue en Kubernetes"
echo "    - Se crean con 'kubectl run' o 'kubectl apply -f'"
echo "    - Un pod solo NO se recrea si se elimina"
echo ""
echo "  DEPLOYMENTS:"
echo "    - Gestiona pods de forma declarativa"
echo "    - Crea automáticamente un ReplicaSet"
echo "    - Proporciona self-healing (recreación automática)"
echo ""
echo "  REPLICASETS:"
echo "    - Mantiene N réplicas de pods"
echo "    - Creado automáticamente por Deployments"
echo "    - Raramente se usa directamente"
echo ""
echo "  LABELS Y SELECTORS:"
echo "    - Labels: metadatos clave-valor"
echo "    - Selectors: filtros para encontrar recursos"
echo ""
echo "Comandos principales aprendidos:"
echo "  - kubectl run <nombre> --image=<imagen>"
echo "  - kubectl apply -f <archivo.yaml>"
echo "  - kubectl get pods/deployments/replicasets"
echo "  - kubectl describe pod/deployment <nombre>"
echo "  - kubectl logs <pod>"
echo "  - kubectl exec <pod> -- <comando>"
echo "  - kubectl delete pod/deployment <nombre>"
echo "  - kubectl get pods -l <label>=<valor>"
echo ""
echo -e "${GREEN}¡Felicitaciones! Estás listo para el Lab 05: Scaling${NC}"
