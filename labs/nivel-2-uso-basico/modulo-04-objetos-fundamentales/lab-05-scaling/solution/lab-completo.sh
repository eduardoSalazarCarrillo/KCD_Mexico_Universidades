#!/bin/bash
# =============================================================================
# Lab 05: Scaling - Script de Solución Completa
# =============================================================================
# Este script ejecuta todos los comandos del laboratorio de forma secuencial.
# Úsalo como referencia o para verificar que completaste correctamente el lab.
#
# NOTA: Este script asume que Minikube está corriendo (Lab 04 completado).
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
# Limpieza previa
# =============================================================================
print_step "Limpieza Previa"

echo "Eliminando recursos existentes si los hay..."
kubectl delete deployment web-app --ignore-not-found=true 2>/dev/null
sleep 2

echo -e "${GREEN}✓ Limpieza completada${NC}"

wait_for_user

# =============================================================================
# Paso 2: Crear un Deployment con 1 Réplica
# =============================================================================
print_step "Paso 2: Crear un Deployment con 1 Réplica"

print_command "cat $LAB_DIR/initial/deployment-scaling.yaml"
cat "$LAB_DIR/initial/deployment-scaling.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/deployment-scaling.yaml"
kubectl apply -f "$LAB_DIR/initial/deployment-scaling.yaml"

echo ""
echo "Esperando a que el deployment esté listo..."
kubectl rollout status deployment/web-app --timeout=60s

echo ""
print_command "kubectl get deployment web-app"
kubectl get deployment web-app

echo ""
print_command "kubectl get pods -l app=web-app"
kubectl get pods -l app=web-app

echo ""
echo -e "${GREEN}✓ Deployment creado con 1 réplica${NC}"

wait_for_user

# =============================================================================
# Paso 3: Verificar el Número Actual de Réplicas
# =============================================================================
print_step "Paso 3: Verificar el Número Actual de Réplicas"

print_substep "Forma 1: kubectl get deployment"
print_command "kubectl get deployment web-app"
kubectl get deployment web-app

echo ""
print_substep "Forma 2: Usando jsonpath"
print_command "kubectl get deployment web-app -o jsonpath='{.spec.replicas}'"
kubectl get deployment web-app -o jsonpath='{.spec.replicas}'
echo ""

echo ""
print_substep "Forma 3: Usando describe"
print_command "kubectl describe deployment web-app | grep -E 'Replicas:'"
kubectl describe deployment web-app | grep -E "Replicas:"

echo ""
echo -e "${GREEN}✓ Réplicas verificadas${NC}"

wait_for_user

# =============================================================================
# Paso 4: Escalar a 5 Réplicas con kubectl scale
# =============================================================================
print_step "Paso 4: Escalar a 5 Réplicas"

print_command "kubectl scale deployment web-app --replicas=5"
kubectl scale deployment web-app --replicas=5

echo ""
echo "Esperando a que los pods estén listos..."
kubectl wait --for=condition=Ready pods -l app=web-app --timeout=60s 2>/dev/null || true
sleep 2

echo ""
print_command "kubectl get deployment web-app"
kubectl get deployment web-app

echo ""
print_command "kubectl get pods -l app=web-app"
kubectl get pods -l app=web-app

echo ""
echo -e "${GREEN}✓ Escalado a 5 réplicas${NC}"

wait_for_user

# =============================================================================
# Paso 5: Verificar Distribución de Pods
# =============================================================================
print_step "Paso 5: Verificar Distribución de Pods"

print_command "kubectl get pods -l app=web-app -o wide"
kubectl get pods -l app=web-app -o wide

echo ""
echo -e "${YELLOW}Nota: En Minikube, todos los pods están en el mismo nodo.${NC}"
echo -e "${YELLOW}En un clúster multi-nodo, verías diferentes nodos.${NC}"

echo ""
echo -e "${GREEN}✓ Distribución verificada${NC}"

wait_for_user

# =============================================================================
# Paso 6: Reducir a 2 Réplicas
# =============================================================================
print_step "Paso 6: Reducir a 2 Réplicas"

print_command "kubectl scale deployment web-app --replicas=2"
kubectl scale deployment web-app --replicas=2

echo ""
echo "Esperando a que el escalamiento se complete..."
sleep 5

echo ""
print_command "kubectl get deployment web-app"
kubectl get deployment web-app

echo ""
print_command "kubectl get pods -l app=web-app"
kubectl get pods -l app=web-app

echo ""
echo -e "${GREEN}✓ Reducido a 2 réplicas${NC}"

wait_for_user

# =============================================================================
# Paso 7: Escalar Usando kubectl patch
# =============================================================================
print_step "Paso 7: Escalar Usando kubectl patch"

print_command "kubectl patch deployment web-app -p '{\"spec\":{\"replicas\":4}}'"
kubectl patch deployment web-app -p '{"spec":{"replicas":4}}'

echo ""
echo "Esperando a que los pods estén listos..."
kubectl wait --for=condition=Ready pods -l app=web-app --timeout=60s 2>/dev/null || true

echo ""
print_command "kubectl get deployment web-app"
kubectl get deployment web-app

echo ""
print_command "kubectl get pods -l app=web-app"
kubectl get pods -l app=web-app

echo ""
echo -e "${GREEN}✓ Escalado con patch a 4 réplicas${NC}"

wait_for_user

# =============================================================================
# Paso 8: Escalar Modificando el YAML y Aplicando
# =============================================================================
print_step "Paso 8: Escalar Modificando el YAML"

print_command "cat $LAB_DIR/initial/deployment-scaled.yaml"
cat "$LAB_DIR/initial/deployment-scaled.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/deployment-scaled.yaml"
kubectl apply -f "$LAB_DIR/initial/deployment-scaled.yaml"

echo ""
echo "Esperando a que los pods estén listos..."
kubectl wait --for=condition=Ready pods -l app=web-app --timeout=60s 2>/dev/null || true

echo ""
print_command "kubectl get deployment web-app"
kubectl get deployment web-app

echo ""
print_command "kubectl get pods -l app=web-app"
kubectl get pods -l app=web-app

echo ""
echo -e "${GREEN}✓ Escalado a 6 réplicas usando YAML${NC}"

wait_for_user

# =============================================================================
# Paso 9: Escalar a 0 Réplicas
# =============================================================================
print_step "Paso 9: Escalar a 0 Réplicas"

print_command "kubectl scale deployment web-app --replicas=0"
kubectl scale deployment web-app --replicas=0

echo ""
echo "Esperando a que los pods se terminen..."
sleep 5

echo ""
print_command "kubectl get deployment web-app"
kubectl get deployment web-app

echo ""
print_command "kubectl get pods -l app=web-app"
kubectl get pods -l app=web-app 2>/dev/null || echo "No resources found in default namespace."

echo ""
print_substep "Verificar que el Deployment y ReplicaSet siguen existiendo"
print_command "kubectl get deployment,replicaset -l app=web-app"
kubectl get deployment,replicaset -l app=web-app

echo ""
echo -e "${YELLOW}Nota: El Deployment existe pero sin Pods corriendo.${NC}"

echo ""
echo -e "${GREEN}✓ Escalado a 0 réplicas${NC}"

wait_for_user

# =============================================================================
# Paso 10: Restaurar las Réplicas
# =============================================================================
print_step "Paso 10: Restaurar las Réplicas"

print_command "kubectl scale deployment web-app --replicas=3"
kubectl scale deployment web-app --replicas=3

echo ""
echo "Esperando a que los pods estén listos..."
kubectl wait --for=condition=Ready pods -l app=web-app --timeout=60s 2>/dev/null || true

echo ""
print_command "kubectl get pods -l app=web-app"
kubectl get pods -l app=web-app

echo ""
echo -e "${GREEN}✓ Réplicas restauradas${NC}"

wait_for_user

# =============================================================================
# Paso 11: Ver el Historial de Eventos de Escalamiento
# =============================================================================
print_step "Paso 11: Ver el Historial de Eventos"

print_command "kubectl describe deployment web-app | grep -A 15 'Events:'"
kubectl describe deployment web-app | grep -A 15 "Events:" || echo "(Sin eventos recientes)"

echo ""
echo -e "${GREEN}✓ Eventos revisados${NC}"

wait_for_user

# =============================================================================
# Paso 12: Limpiar los Recursos
# =============================================================================
print_step "Paso 12: Limpiar los Recursos"

print_command "kubectl delete deployment web-app"
kubectl delete deployment web-app

echo ""
echo "Esperando a que los recursos se eliminen..."
sleep 3

print_command "kubectl get all -l app=web-app"
kubectl get all -l app=web-app 2>/dev/null || echo "No resources found in default namespace."

echo ""
echo -e "${GREEN}✓ Recursos limpiados${NC}"

wait_for_user

# =============================================================================
# Ejercicios Adicionales
# =============================================================================
print_step "Ejercicios Adicionales"

print_substep "Ejercicio 1: Escalamiento Condicional"

echo "Creando deployment con 2 réplicas..."
kubectl create deployment test-app --image=nginx:alpine --replicas=2
kubectl rollout status deployment/test-app --timeout=60s

echo ""
print_command "kubectl scale deployment test-app --current-replicas=2 --replicas=4"
kubectl scale deployment test-app --current-replicas=2 --replicas=4 && echo "Escalamiento exitoso" || echo "Escalamiento falló"

echo ""
echo "Intentando escalar con current-replicas incorrecto..."
print_command "kubectl scale deployment test-app --current-replicas=2 --replicas=6"
kubectl scale deployment test-app --current-replicas=2 --replicas=6 2>&1 || echo "(Esperado: falla porque ahora tiene 4 réplicas)"

echo ""
print_command "kubectl get deployment test-app"
kubectl get deployment test-app

echo ""
kubectl delete deployment test-app

echo ""
print_substep "Ejercicio 2: Escalar Múltiples Deployments"

echo "Creando dos deployments..."
kubectl create deployment app-a --image=nginx:alpine --replicas=1
kubectl create deployment app-b --image=httpd:alpine --replicas=1
kubectl rollout status deployment/app-a --timeout=60s
kubectl rollout status deployment/app-b --timeout=60s

echo ""
kubectl label deployment app-a tier=frontend
kubectl label deployment app-b tier=frontend

print_command "kubectl get deployments -l tier=frontend"
kubectl get deployments -l tier=frontend

echo ""
echo "Escalando todos los deployments con label tier=frontend..."
for deploy in $(kubectl get deployments -l tier=frontend -o name); do
  echo "Escalando $deploy a 3 réplicas..."
  kubectl scale $deploy --replicas=3
done

echo ""
print_command "kubectl get deployments -l tier=frontend"
kubectl get deployments -l tier=frontend

echo ""
kubectl delete deployment app-a app-b

echo ""
echo -e "${GREEN}✓ Ejercicios adicionales completados${NC}"

wait_for_user

# =============================================================================
# Resumen Final
# =============================================================================
print_step "Laboratorio Completado"

echo "Has completado exitosamente el Lab 05: Scaling"
echo ""
echo "Resumen de conceptos aprendidos:"
echo ""
echo "  ESCALAMIENTO HORIZONTAL:"
echo "    - Aumentar/disminuir el número de réplicas"
echo "    - Sin downtime durante el escalamiento"
echo "    - Alta disponibilidad con múltiples réplicas"
echo ""
echo "  FORMAS DE ESCALAR:"
echo "    - kubectl scale: Comando imperativo rápido"
echo "    - kubectl patch: JSON patch para modificar campos"
echo "    - kubectl apply: Aplicar archivo YAML (declarativo)"
echo "    - kubectl edit: Editar recurso directamente"
echo ""
echo "  CARACTERÍSTICAS:"
echo "    - Escalar a 0: Pausa la aplicación sin eliminarla"
echo "    - --current-replicas: Escalamiento condicional"
echo "    - Eventos: Kubernetes registra todos los cambios"
echo ""
echo "Comandos principales aprendidos:"
echo "  - kubectl scale deployment <nombre> --replicas=<N>"
echo "  - kubectl get deployment <nombre>"
echo "  - kubectl get pods -l <label>=<valor> -w"
echo "  - kubectl patch deployment <nombre> -p '{...}'"
echo "  - kubectl describe deployment <nombre>"
echo ""
echo -e "${GREEN}¡Felicitaciones! Estás listo para el Lab 06: YAML Manifests${NC}"
