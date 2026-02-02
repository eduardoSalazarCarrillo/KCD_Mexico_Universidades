#!/bin/bash
# =============================================================================
# Lab 07: Resource Updates - Script de Solución Completa
# =============================================================================
# Este script ejecuta todos los comandos del laboratorio de forma secuencial.
# Úsalo como referencia o para verificar que completaste correctamente el lab.
#
# NOTA: Este script asume que Minikube está corriendo (Labs anteriores completados).
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
    kubectl delete deployment webapp --ignore-not-found=true &> /dev/null
    kubectl delete deployment app-recreate --ignore-not-found=true &> /dev/null
    kubectl delete deployment custom-rolling --ignore-not-found=true &> /dev/null
    kubectl delete deployment test-set --ignore-not-found=true &> /dev/null
}

# =============================================================================
# Verificación Inicial
# =============================================================================
print_step "Verificación Inicial"

if ! command -v minikube &> /dev/null; then
    echo -e "${RED}Error: Minikube no está instalado.${NC}"
    echo "Por favor, completa los labs anteriores primero."
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl no está instalado.${NC}"
    echo "Por favor, completa los labs anteriores primero."
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

# Limpiar recursos previos
cleanup

wait_for_user

# =============================================================================
# Paso 2: Desplegar la Aplicación Inicial (v1)
# =============================================================================
print_step "Paso 2: Desplegar la Aplicación Inicial (v1)"

print_command "cat $LAB_DIR/initial/app-deployment-v1.yaml"
cat "$LAB_DIR/initial/app-deployment-v1.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/app-deployment-v1.yaml"
kubectl apply -f "$LAB_DIR/initial/app-deployment-v1.yaml"

echo ""
print_command "kubectl rollout status deployment/webapp"
kubectl rollout status deployment/webapp

echo ""
print_command "kubectl get pods -l app=webapp -L version"
kubectl get pods -l app=webapp -L version

echo ""
echo -e "${GREEN}✓ Deployment v1 creado${NC}"

wait_for_user

# =============================================================================
# Paso 3: Ver el Historial de Revisiones
# =============================================================================
print_step "Paso 3: Ver el Historial de Revisiones"

print_command "kubectl rollout history deployment/webapp"
kubectl rollout history deployment/webapp

echo ""
print_command "kubectl rollout history deployment/webapp --revision=1"
kubectl rollout history deployment/webapp --revision=1

echo ""
echo -e "${GREEN}✓ Historial de revisiones visualizado${NC}"

wait_for_user

# =============================================================================
# Paso 4: Actualizar la Imagen Usando kubectl set image
# =============================================================================
print_step "Paso 4: Actualizar la Imagen Usando kubectl set image"

print_command "kubectl set image deployment/webapp nginx=nginx:1.25-alpine"
kubectl set image deployment/webapp nginx=nginx:1.25-alpine

echo ""
print_command "kubectl rollout status deployment/webapp"
kubectl rollout status deployment/webapp

echo ""
print_command "kubectl describe deployment webapp | grep -i image"
kubectl describe deployment webapp | grep -i image

echo ""
echo -e "${GREEN}✓ Imagen actualizada a nginx:1.25-alpine${NC}"

wait_for_user

# =============================================================================
# Paso 5: Documentar el Cambio con change-cause
# =============================================================================
print_step "Paso 5: Documentar el Cambio con change-cause"

print_command 'kubectl annotate deployment/webapp kubernetes.io/change-cause="Actualización a nginx:1.25-alpine para parches de seguridad" --overwrite'
kubectl annotate deployment/webapp kubernetes.io/change-cause="Actualización a nginx:1.25-alpine para parches de seguridad" --overwrite

echo ""
print_command "kubectl rollout history deployment/webapp"
kubectl rollout history deployment/webapp

echo ""
echo -e "${GREEN}✓ Cambio documentado en el historial${NC}"

wait_for_user

# =============================================================================
# Paso 6: Actualizar Usando kubectl apply
# =============================================================================
print_step "Paso 6: Actualizar Usando kubectl apply"

print_substep "Examinando el archivo v2"
print_command "cat $LAB_DIR/initial/app-deployment-v2.yaml"
cat "$LAB_DIR/initial/app-deployment-v2.yaml"

echo ""
print_substep "Viendo diferencias con kubectl diff"
print_command "kubectl diff -f $LAB_DIR/initial/app-deployment-v2.yaml"
kubectl diff -f "$LAB_DIR/initial/app-deployment-v2.yaml" 2>/dev/null || echo "(Las diferencias se muestran arriba)"

echo ""
print_substep "Aplicando cambios"
print_command "kubectl apply -f $LAB_DIR/initial/app-deployment-v2.yaml"
kubectl apply -f "$LAB_DIR/initial/app-deployment-v2.yaml"

echo ""
print_command "kubectl rollout status deployment/webapp"
kubectl rollout status deployment/webapp

echo ""
print_command "kubectl get pods -l app=webapp -L version"
kubectl get pods -l app=webapp -L version

echo ""
echo -e "${GREEN}✓ Deployment actualizado a v2${NC}"

wait_for_user

# =============================================================================
# Paso 7: Ver el Historial Completo
# =============================================================================
print_step "Paso 7: Ver el Historial Completo"

print_command "kubectl rollout history deployment/webapp"
kubectl rollout history deployment/webapp

echo ""
echo -e "${GREEN}✓ Historial completo visualizado${NC}"

wait_for_user

# =============================================================================
# Paso 8: Usar kubectl patch para Cambios Específicos
# =============================================================================
print_step "Paso 8: Usar kubectl patch para Cambios Específicos"

print_substep "Cambiar réplicas a 5 con patch"
print_command 'kubectl patch deployment webapp -p '\''{"spec":{"replicas":5}}'\'''
kubectl patch deployment webapp -p '{"spec":{"replicas":5}}'

echo ""
print_command "kubectl get deployment webapp"
kubectl get deployment webapp

echo ""
kubectl annotate deployment/webapp kubernetes.io/change-cause="Escalar a 5 réplicas usando kubectl patch" --overwrite

print_substep "Cambiar réplicas a 3 con patch"
print_command 'kubectl patch deployment webapp -p '\''{"spec":{"replicas":3}}'\'''
kubectl patch deployment webapp -p '{"spec":{"replicas":3}}'

echo ""
print_command "kubectl get deployment webapp"
kubectl get deployment webapp

echo ""
echo -e "${GREEN}✓ kubectl patch utilizado${NC}"

wait_for_user

# =============================================================================
# Paso 9: Diferencia entre create, apply y replace
# =============================================================================
print_step "Paso 9: Diferencia entre create, apply y replace"

print_substep "Intentar create cuando el recurso existe (fallará)"
print_command "kubectl create -f $LAB_DIR/initial/app-deployment-v1.yaml"
kubectl create -f "$LAB_DIR/initial/app-deployment-v1.yaml" 2>&1 || true

echo ""
print_substep "Usar apply cuando el recurso existe (funciona)"
print_command "kubectl apply -f $LAB_DIR/initial/app-deployment-v1.yaml"
kubectl apply -f "$LAB_DIR/initial/app-deployment-v1.yaml"

echo ""
print_substep "Usar replace para reemplazar completamente"
print_command "kubectl replace -f $LAB_DIR/initial/app-deployment-v1.yaml"
kubectl replace -f "$LAB_DIR/initial/app-deployment-v1.yaml"

echo ""
kubectl rollout status deployment/webapp

echo ""
echo -e "${GREEN}✓ Diferencias entre create, apply y replace demostradas${NC}"

wait_for_user

# =============================================================================
# Paso 10: Simular un Deployment Fallido
# =============================================================================
print_step "Paso 10: Simular un Deployment Fallido"

print_command "kubectl set image deployment/webapp nginx=nginx:version-inexistente"
kubectl set image deployment/webapp nginx=nginx:version-inexistente

echo ""
print_command "kubectl rollout status deployment/webapp --timeout=20s"
kubectl rollout status deployment/webapp --timeout=20s 2>&1 || true

echo ""
print_command "kubectl get pods -l app=webapp"
kubectl get pods -l app=webapp

echo ""
echo -e "${YELLOW}Nota: La imagen no existe, el rollout falla pero los pods anteriores siguen corriendo${NC}"
echo -e "${GREEN}✓ Deployment fallido simulado${NC}"

wait_for_user

# =============================================================================
# Paso 11: Ejecutar Rollback
# =============================================================================
print_step "Paso 11: Ejecutar Rollback"

print_command "kubectl rollout history deployment/webapp"
kubectl rollout history deployment/webapp

echo ""
print_command "kubectl rollout undo deployment/webapp"
kubectl rollout undo deployment/webapp

echo ""
print_command "kubectl rollout status deployment/webapp"
kubectl rollout status deployment/webapp

echo ""
print_command "kubectl get pods -l app=webapp"
kubectl get pods -l app=webapp

echo ""
echo -e "${GREEN}✓ Rollback ejecutado exitosamente${NC}"

wait_for_user

# =============================================================================
# Paso 12: Rollback a una Revisión Específica
# =============================================================================
print_step "Paso 12: Rollback a una Revisión Específica"

print_command "kubectl rollout history deployment/webapp"
kubectl rollout history deployment/webapp

echo ""
# Obtener la primera revisión disponible en el historial
FIRST_REVISION=$(kubectl rollout history deployment/webapp | grep -E "^[0-9]+" | head -1 | awk '{print $1}')
echo -e "${CYAN}Nota: Haciendo rollback a la primera revisión disponible: $FIRST_REVISION${NC}"
print_command "kubectl rollout undo deployment/webapp --to-revision=$FIRST_REVISION"
kubectl rollout undo deployment/webapp --to-revision=$FIRST_REVISION

echo ""
print_command "kubectl rollout status deployment/webapp"
kubectl rollout status deployment/webapp

echo ""
print_command "kubectl describe deployment webapp | grep -i image"
kubectl describe deployment webapp | grep -i image

echo ""
echo -e "${GREEN}✓ Rollback a revisión específica ejecutado${NC}"

wait_for_user

# =============================================================================
# Paso 13: Pausar y Reanudar Rollouts
# =============================================================================
print_step "Paso 13: Pausar y Reanudar Rollouts"

print_substep "Pausar el deployment"
print_command "kubectl rollout pause deployment/webapp"
kubectl rollout pause deployment/webapp

echo ""
print_substep "Hacer múltiples cambios mientras está pausado"
print_command "kubectl set image deployment/webapp nginx=nginx:1.25-alpine"
kubectl set image deployment/webapp nginx=nginx:1.25-alpine

print_command "kubectl set resources deployment/webapp -c nginx --limits=memory=256Mi,cpu=300m"
kubectl set resources deployment/webapp -c nginx --limits=memory=256Mi,cpu=300m

print_command "kubectl scale deployment/webapp --replicas=4"
kubectl scale deployment/webapp --replicas=4

echo ""
print_command "kubectl get deployment webapp"
kubectl get deployment webapp

echo ""
print_substep "Reanudar el rollout"
print_command "kubectl rollout resume deployment/webapp"
kubectl rollout resume deployment/webapp

echo ""
print_command "kubectl rollout status deployment/webapp"
kubectl rollout status deployment/webapp

echo ""
print_command "kubectl get pods -l app=webapp"
kubectl get pods -l app=webapp

echo ""
echo -e "${GREEN}✓ Pause y Resume demostrados${NC}"

wait_for_user

# =============================================================================
# Paso 14: Limpiar los Recursos
# =============================================================================
print_step "Paso 14: Limpiar los Recursos"

print_command "kubectl delete deployment webapp"
kubectl delete deployment webapp

echo ""
echo "Esperando a que los recursos se eliminen..."
sleep 3

print_command "kubectl get deployments"
kubectl get deployments 2>/dev/null || echo "No resources found in default namespace."

print_command "kubectl get pods -l app=webapp"
kubectl get pods -l app=webapp 2>/dev/null || echo "No resources found in default namespace."

echo ""
echo -e "${GREEN}✓ Recursos limpiados${NC}"

wait_for_user

# =============================================================================
# Ejercicios Adicionales (Opcional)
# =============================================================================
print_step "Ejercicios Adicionales (Opcional)"

echo "¿Deseas ejecutar los ejercicios adicionales? (s/n)"
read -r respuesta

if [[ "$respuesta" =~ ^[Ss]$ ]]; then
    print_substep "Ejercicio 1: Estrategia Recreate"

    cat << 'EOF' > /tmp/recreate-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-recreate
  annotations:
    kubernetes.io/change-cause: "Deployment con estrategia Recreate"
spec:
  replicas: 3
  selector:
    matchLabels:
      app: app-recreate
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: app-recreate
    spec:
      containers:
        - name: nginx
          image: nginx:1.24-alpine
          ports:
            - containerPort: 80
EOF

    kubectl apply -f /tmp/recreate-deployment.yaml
    kubectl rollout status deployment/app-recreate

    echo ""
    echo "Actualizando imagen (observa que todos los pods se eliminan primero)..."
    kubectl set image deployment/app-recreate nginx=nginx:1.25-alpine
    kubectl rollout status deployment/app-recreate

    echo ""
    kubectl get pods -l app=app-recreate

    echo ""
    kubectl delete deployment app-recreate
    echo -e "${GREEN}✓ Ejercicio 1 completado${NC}"

    wait_for_user

    print_substep "Ejercicio 2: kubectl set env"

    kubectl create deployment test-set --image=nginx:alpine --replicas=2
    kubectl rollout status deployment/test-set

    echo ""
    kubectl set env deployment/test-set ENVIRONMENT=production DEBUG=false

    echo ""
    echo "Variables de entorno configuradas:"
    kubectl describe deployment test-set | grep -A 10 "Environment:" || echo "  Revisando pods..."

    echo ""
    kubectl delete deployment test-set
    echo -e "${GREEN}✓ Ejercicio 2 completado${NC}"
fi

# =============================================================================
# Resumen Final
# =============================================================================
print_step "Laboratorio Completado"

echo "Has completado exitosamente el Lab 07: Resource Updates"
echo ""
echo "Resumen de conceptos aprendidos:"
echo ""
echo "  COMANDOS DE ACTUALIZACIÓN:"
echo "    - kubectl apply: Crear o actualizar declarativamente"
echo "    - kubectl create: Crear (falla si existe)"
echo "    - kubectl replace: Reemplazar completamente"
echo "    - kubectl set image: Cambiar imagen de contenedor"
echo "    - kubectl set resources: Cambiar recursos"
echo "    - kubectl set env: Establecer variables de entorno"
echo "    - kubectl edit: Editar en editor"
echo "    - kubectl patch: Cambios parciales con JSON"
echo ""
echo "  ROLLOUT Y HISTORIAL:"
echo "    - kubectl rollout status: Estado del despliegue"
echo "    - kubectl rollout history: Historial de revisiones"
echo "    - kubectl rollout undo: Rollback"
echo "    - kubectl rollout pause/resume: Control de actualizaciones"
echo ""
echo "  ESTRATEGIAS DE ACTUALIZACIÓN:"
echo "    - RollingUpdate: Sin downtime, gradual"
echo "    - Recreate: Con downtime, más rápido"
echo "    - maxSurge: Pods extra durante update"
echo "    - maxUnavailable: Pods no disponibles permitidos"
echo ""
echo "  DOCUMENTACIÓN DE CAMBIOS:"
echo "    - kubernetes.io/change-cause: Anotar razón del cambio"
echo ""
echo "Comandos principales aprendidos:"
echo "  - kubectl apply -f <archivo.yaml>"
echo "  - kubectl set image deployment/<n> <c>=<img>"
echo "  - kubectl rollout status deployment/<nombre>"
echo "  - kubectl rollout history deployment/<nombre>"
echo "  - kubectl rollout undo deployment/<nombre>"
echo "  - kubectl patch deployment/<n> -p '<json>'"
echo "  - kubectl diff -f <archivo.yaml>"
echo ""
echo -e "${GREEN}¡Felicitaciones! Estás listo para el Lab 08: Services${NC}"
