#!/bin/bash
# =============================================================================
# Lab 14: Rolling Updates y Rollbacks - Script de Solucion Completa
# =============================================================================
# Este script ejecuta todos los comandos del laboratorio de forma secuencial.
# Usalo como referencia o para verificar que completaste correctamente el lab.
#
# NOTA: Este script asume que Minikube esta corriendo (Labs anteriores completados).
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

cleanup() {
    echo "Limpiando recursos previos..."
    kubectl delete deployment web-app --ignore-not-found=true &> /dev/null
    kubectl delete deployment web-app-recreate --ignore-not-found=true &> /dev/null
}

# =============================================================================
# Verificacion Inicial
# =============================================================================
print_step "Verificacion Inicial"

if ! command -v minikube &> /dev/null; then
    echo -e "${RED}Error: Minikube no esta instalado.${NC}"
    echo "Por favor, completa los labs anteriores primero."
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl no esta instalado.${NC}"
    echo "Por favor, completa los labs anteriores primero."
    exit 1
fi

print_command "minikube status"
if ! minikube status &> /dev/null; then
    echo -e "${YELLOW}Minikube no esta corriendo. Iniciando...${NC}"
    minikube start --driver=docker
fi
minikube status

echo ""
echo -e "${GREEN}Minikube esta corriendo${NC}"

# Limpiar recursos previos
cleanup

wait_for_user

# =============================================================================
# Paso 1: Crear Deployment inicial
# =============================================================================
print_step "Paso 1: Crear Deployment inicial"

print_substep "Examinar el archivo app-rolling.yaml"
print_command "cat $LAB_DIR/initial/app-rolling.yaml"
cat "$LAB_DIR/initial/app-rolling.yaml"

echo ""
print_substep "Aplicar el deployment"
print_command "kubectl apply -f $LAB_DIR/initial/app-rolling.yaml"
kubectl apply -f "$LAB_DIR/initial/app-rolling.yaml"

echo ""
print_command "kubectl rollout status deployment/web-app"
kubectl rollout status deployment/web-app

echo ""
print_command "kubectl get deployment web-app"
kubectl get deployment web-app

echo ""
print_command "kubectl get pods -l app=web"
kubectl get pods -l app=web

echo ""
echo -e "${GREEN}Deployment v1 creado con 4 replicas${NC}"

wait_for_user

# =============================================================================
# Paso 2: Realizar rolling update
# =============================================================================
print_step "Paso 2: Realizar rolling update"

print_substep "Actualizar la imagen a nginx:1.21-alpine"
print_command "kubectl set image deployment/web-app nginx=nginx:1.21-alpine"
kubectl set image deployment/web-app nginx=nginx:1.21-alpine

echo ""
print_substep "Documentar el cambio"
print_command 'kubectl annotate deployment web-app kubernetes.io/change-cause="Update to nginx 1.21" --overwrite'
kubectl annotate deployment web-app kubernetes.io/change-cause="Update to nginx 1.21" --overwrite

echo ""
print_substep "Observar el rollout"
print_command "kubectl rollout status deployment web-app"
kubectl rollout status deployment web-app

echo ""
print_command "kubectl get pods -l app=web"
kubectl get pods -l app=web

echo ""
print_command "kubectl describe deployment web-app | grep -i image"
kubectl describe deployment web-app | grep -i image

echo ""
echo -e "${GREEN}Rolling update completado a nginx:1.21-alpine${NC}"

wait_for_user

# =============================================================================
# Paso 3: Verificar el historial
# =============================================================================
print_step "Paso 3: Verificar el historial de revisiones"

print_command "kubectl rollout history deployment web-app"
kubectl rollout history deployment web-app

echo ""
print_substep "Ver detalles de revision 1"
print_command "kubectl rollout history deployment web-app --revision=1"
kubectl rollout history deployment web-app --revision=1

echo ""
print_substep "Ver detalles de revision 2"
print_command "kubectl rollout history deployment web-app --revision=2"
kubectl rollout history deployment web-app --revision=2

echo ""
echo -e "${GREEN}Historial de revisiones visualizado${NC}"

wait_for_user

# =============================================================================
# Paso 4: Simular un deployment fallido
# =============================================================================
print_step "Paso 4: Simular un deployment fallido"

print_substep "Actualizar a una imagen que no existe"
print_command "kubectl set image deployment/web-app nginx=nginx:invalid-version"
kubectl set image deployment/web-app nginx=nginx:invalid-version

echo ""
print_command 'kubectl annotate deployment web-app kubernetes.io/change-cause="Bad update - invalid image" --overwrite'
kubectl annotate deployment web-app kubernetes.io/change-cause="Bad update - invalid image" --overwrite

echo ""
print_substep "Observar el fallo (timeout esperado)"
print_command "kubectl rollout status deployment web-app --timeout=30s"
kubectl rollout status deployment web-app --timeout=30s 2>&1 || true

echo ""
print_substep "Ver estado de los pods"
print_command "kubectl get pods -l app=web"
kubectl get pods -l app=web

echo ""
print_substep "Verificar que algunos pods siguen funcionando"
print_command "kubectl describe deployment web-app | grep -A 5 'Replicas:'"
kubectl describe deployment web-app | grep -A 5 "Replicas:" || true

echo ""
echo -e "${YELLOW}Nota: La imagen no existe. Algunos pods fallan pero otros siguen corriendo gracias a maxUnavailable${NC}"
echo -e "${GREEN}Deployment fallido simulado${NC}"

wait_for_user

# =============================================================================
# Paso 5: Ejecutar rollback
# =============================================================================
print_step "Paso 5: Ejecutar rollback"

print_substep "Rollback a la version anterior"
print_command "kubectl rollout undo deployment web-app"
kubectl rollout undo deployment web-app

echo ""
print_command "kubectl rollout status deployment web-app"
kubectl rollout status deployment web-app

echo ""
print_command "kubectl get pods -l app=web"
kubectl get pods -l app=web

echo ""
print_command "kubectl describe deployment web-app | grep -i image"
kubectl describe deployment web-app | grep -i image

echo ""
print_substep "Rollback a revision especifica (revision 1)"
print_command "kubectl rollout undo deployment web-app --to-revision=1"
kubectl rollout undo deployment web-app --to-revision=1

echo ""
print_command "kubectl rollout status deployment web-app"
kubectl rollout status deployment web-app

echo ""
print_command "kubectl describe deployment web-app | grep -i image"
kubectl describe deployment web-app | grep -i image

echo ""
echo -e "${GREEN}Rollback ejecutado exitosamente${NC}"

wait_for_user

# =============================================================================
# Paso 6: Pausar y reanudar rollouts
# =============================================================================
print_step "Paso 6: Pausar y reanudar rollouts"

print_substep "Actualizar imagen"
print_command "kubectl set image deployment/web-app nginx=nginx:1.22-alpine"
kubectl set image deployment/web-app nginx=nginx:1.22-alpine

echo ""
print_substep "Pausar inmediatamente"
print_command "kubectl rollout pause deployment web-app"
kubectl rollout pause deployment web-app

echo ""
print_substep "Ver estado parcialmente actualizado"
print_command "kubectl get pods -l app=web"
kubectl get pods -l app=web

echo ""
print_command "kubectl get deployment web-app"
kubectl get deployment web-app

echo ""
print_substep "Hacer mas cambios mientras esta pausado"
print_command "kubectl set resources deployment web-app -c nginx --limits=memory=128Mi"
kubectl set resources deployment web-app -c nginx --limits=memory=128Mi

echo ""
print_substep "Reanudar el rollout"
print_command "kubectl rollout resume deployment web-app"
kubectl rollout resume deployment web-app

echo ""
print_command "kubectl rollout status deployment web-app"
kubectl rollout status deployment web-app

echo ""
print_command "kubectl get pods -l app=web"
kubectl get pods -l app=web

echo ""
echo -e "${GREEN}Pause y Resume demostrados${NC}"

wait_for_user

# =============================================================================
# Paso 7: Estrategia Recreate (comparacion)
# =============================================================================
print_step "Paso 7: Estrategia Recreate (comparacion)"

print_substep "Examinar el archivo app-recreate.yaml"
print_command "cat $LAB_DIR/initial/app-recreate.yaml"
cat "$LAB_DIR/initial/app-recreate.yaml"

echo ""
print_substep "Aplicar deployment con estrategia Recreate"
print_command "kubectl apply -f $LAB_DIR/initial/app-recreate.yaml"
kubectl apply -f "$LAB_DIR/initial/app-recreate.yaml"

echo ""
print_command "kubectl rollout status deployment/web-app-recreate"
kubectl rollout status deployment/web-app-recreate

echo ""
print_command "kubectl get pods -l app=web-recreate"
kubectl get pods -l app=web-recreate

echo ""
print_substep "Actualizar imagen (observar que todos los pods se eliminan primero)"
echo -e "${YELLOW}NOTA: Con estrategia Recreate, hay downtime porque todos los pods se eliminan antes de crear los nuevos${NC}"
print_command "kubectl set image deployment/web-app-recreate nginx=nginx:1.21-alpine"
kubectl set image deployment/web-app-recreate nginx=nginx:1.21-alpine

echo ""
print_command "kubectl rollout status deployment/web-app-recreate"
kubectl rollout status deployment/web-app-recreate

echo ""
print_command "kubectl get pods -l app=web-recreate"
kubectl get pods -l app=web-recreate

echo ""
echo -e "${GREEN}Estrategia Recreate demostrada${NC}"

wait_for_user

# =============================================================================
# Limpieza
# =============================================================================
print_step "Limpieza de recursos"

print_command "kubectl delete deployment web-app"
kubectl delete deployment web-app

print_command "kubectl delete deployment web-app-recreate"
kubectl delete deployment web-app-recreate

echo ""
echo "Esperando a que los recursos se eliminen..."
sleep 3

print_command "kubectl get deployments"
kubectl get deployments 2>/dev/null || echo "No resources found in default namespace."

print_command "kubectl get pods -l app=web"
kubectl get pods -l app=web 2>/dev/null || echo "No resources found."

print_command "kubectl get pods -l app=web-recreate"
kubectl get pods -l app=web-recreate 2>/dev/null || echo "No resources found."

echo ""
echo -e "${GREEN}Recursos limpiados${NC}"

wait_for_user

# =============================================================================
# Resumen Final
# =============================================================================
print_step "Laboratorio Completado"

echo "Has completado exitosamente el Lab 14: Rolling Updates y Rollbacks"
echo ""
echo "Resumen de conceptos aprendidos:"
echo ""
echo "  ESTRATEGIAS DE ACTUALIZACION:"
echo "    - RollingUpdate: Actualiza pods gradualmente sin downtime"
echo "    - Recreate: Elimina todos los pods antes de crear nuevos (con downtime)"
echo ""
echo "  PARAMETROS DE ROLLINGUPDATE:"
echo "    - maxSurge: Numero maximo de pods adicionales durante la actualizacion"
echo "    - maxUnavailable: Numero maximo de pods no disponibles durante la actualizacion"
echo ""
echo "  COMANDOS DE ROLLOUT:"
echo "    - kubectl rollout status: Ver estado del despliegue"
echo "    - kubectl rollout history: Ver historial de revisiones"
echo "    - kubectl rollout undo: Rollback a version anterior"
echo "    - kubectl rollout undo --to-revision=N: Rollback a revision especifica"
echo "    - kubectl rollout pause: Pausar actualizacion"
echo "    - kubectl rollout resume: Reanudar actualizacion"
echo ""
echo "  BUENAS PRACTICAS:"
echo "    - Usar readinessProbe para asegurar que pods estan listos"
echo "    - Documentar cambios con kubernetes.io/change-cause"
echo "    - Configurar maxSurge y maxUnavailable segun necesidades"
echo "    - Monitorear rollouts con kubectl rollout status"
echo ""
echo "Comandos principales aprendidos:"
echo "  - kubectl set image deployment/<n> <c>=<img>"
echo "  - kubectl rollout status deployment/<nombre>"
echo "  - kubectl rollout history deployment/<nombre>"
echo "  - kubectl rollout undo deployment/<nombre>"
echo "  - kubectl rollout pause/resume deployment/<nombre>"
echo "  - kubectl annotate deployment <n> kubernetes.io/change-cause=\"...\" --overwrite"
echo ""
echo -e "${GREEN}Felicitaciones! Estas listo para el Lab 15: RBAC${NC}"
