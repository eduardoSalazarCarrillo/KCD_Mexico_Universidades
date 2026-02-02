#!/bin/bash
# =============================================================================
# Lab 13: Horizontal Pod Autoscaler (HPA) - Script de Solución Completa
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
kubectl delete hpa php-apache php-apache-hpa --ignore-not-found=true 2>/dev/null
kubectl delete deployment php-apache --ignore-not-found=true 2>/dev/null
kubectl delete service php-apache --ignore-not-found=true 2>/dev/null
kubectl delete pod load-generator --ignore-not-found=true 2>/dev/null
sleep 2

echo -e "${GREEN}✓ Limpieza completada${NC}"

wait_for_user

# =============================================================================
# Paso 1: Habilitar Metrics Server
# =============================================================================
print_step "Paso 1: Habilitar Metrics Server"

print_command "minikube addons enable metrics-server"
minikube addons enable metrics-server

echo ""
echo "Esperando a que Metrics Server esté listo..."
sleep 10

print_command "kubectl get pods -n kube-system | grep metrics-server"
kubectl get pods -n kube-system | grep metrics-server || echo "(Esperando que el pod inicie...)"

echo ""
echo -e "${YELLOW}Nota: Metrics Server puede tardar 1-2 minutos en estar completamente operativo.${NC}"
echo -e "${YELLOW}Si kubectl top falla, espera un poco más y vuelve a intentar.${NC}"

echo ""
echo "Verificando Metrics Server (puede tardar)..."
for i in {1..12}; do
    if kubectl top nodes &> /dev/null; then
        echo -e "${GREEN}✓ Metrics Server está funcionando${NC}"
        break
    fi
    echo "  Intento $i/12 - Esperando..."
    sleep 10
done

print_substep "Verificar métricas de nodos"
print_command "kubectl top nodes"
kubectl top nodes 2>/dev/null || echo "(Metrics Server aún iniciando...)"

echo ""
echo -e "${GREEN}✓ Metrics Server habilitado${NC}"

wait_for_user

# =============================================================================
# Paso 2: Crear Deployment con resource requests
# =============================================================================
print_step "Paso 2: Crear Deployment con Resource Requests"

print_command "cat $LAB_DIR/initial/app-hpa.yaml"
cat "$LAB_DIR/initial/app-hpa.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/app-hpa.yaml"
kubectl apply -f "$LAB_DIR/initial/app-hpa.yaml"

echo ""
echo "Esperando a que el deployment esté listo..."
kubectl rollout status deployment/php-apache --timeout=120s

echo ""
print_command "kubectl get deployment php-apache"
kubectl get deployment php-apache

echo ""
print_command "kubectl get pods -l app=php-apache"
kubectl get pods -l app=php-apache

echo ""
print_command "kubectl get service php-apache"
kubectl get service php-apache

echo ""
echo -e "${GREEN}✓ Deployment y Service creados${NC}"

wait_for_user

# =============================================================================
# Paso 3: Crear HPA con kubectl
# =============================================================================
print_step "Paso 3: Crear HPA con kubectl"

print_substep "Crear HPA usando comando imperativo"

print_command "kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10"
kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10

echo ""
print_command "kubectl get hpa"
kubectl get hpa

echo ""
print_command "kubectl describe hpa php-apache"
kubectl describe hpa php-apache

echo ""
echo -e "${YELLOW}Explicación de las columnas del HPA:${NC}"
echo "  - REFERENCE: Deployment que controla"
echo "  - TARGETS: Uso actual / objetivo (puede mostrar <unknown> inicialmente)"
echo "  - MINPODS/MAXPODS: Límites de escalamiento"
echo "  - REPLICAS: Número actual de réplicas"

echo ""
echo -e "${GREEN}✓ HPA creado con kubectl${NC}"

wait_for_user

# =============================================================================
# Paso 4: Crear HPA con YAML (más avanzado)
# =============================================================================
print_step "Paso 4: Crear HPA con YAML"

print_substep "Eliminar HPA anterior"
print_command "kubectl delete hpa php-apache"
kubectl delete hpa php-apache

echo ""
print_substep "Crear HPA con configuración avanzada"

print_command "cat $LAB_DIR/initial/hpa.yaml"
cat "$LAB_DIR/initial/hpa.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/hpa.yaml"
kubectl apply -f "$LAB_DIR/initial/hpa.yaml"

echo ""
print_command "kubectl get hpa php-apache-hpa"
kubectl get hpa php-apache-hpa

echo ""
print_command "kubectl describe hpa php-apache-hpa"
kubectl describe hpa php-apache-hpa

echo ""
echo -e "${YELLOW}Ventajas del HPA con YAML:${NC}"
echo "  - Múltiples métricas (CPU y memoria)"
echo "  - Control de comportamiento de escalamiento"
echo "  - Configuración de stabilizationWindow"
echo "  - Versionado en Git"

echo ""
echo -e "${GREEN}✓ HPA creado con YAML${NC}"

wait_for_user

# =============================================================================
# Paso 5: Observar el estado del HPA
# =============================================================================
print_step "Paso 5: Observar el Estado del HPA"

print_substep "Ver métricas actuales"

echo "Esperando a que las métricas estén disponibles..."
sleep 15

print_command "kubectl get hpa php-apache-hpa"
kubectl get hpa php-apache-hpa

echo ""
print_command "kubectl top pods -l app=php-apache"
kubectl top pods -l app=php-apache 2>/dev/null || echo "(Esperando métricas de pods...)"

echo ""
print_substep "Ver detalles del HPA"
print_command "kubectl get hpa php-apache-hpa -o yaml | head -50"
kubectl get hpa php-apache-hpa -o yaml | head -50

echo ""
echo -e "${GREEN}✓ Estado del HPA verificado${NC}"

wait_for_user

# =============================================================================
# Paso 6: Generar carga para probar escalamiento
# =============================================================================
print_step "Paso 6: Generar Carga para Probar Escalamiento"

echo -e "${YELLOW}IMPORTANTE: Este paso genera carga en el servicio para ver el escalamiento.${NC}"
echo ""
echo "Vamos a:"
echo "  1. Iniciar un generador de carga en segundo plano"
echo "  2. Observar cómo el HPA aumenta las réplicas"
echo "  3. Detener la carga y ver el scale-down"
echo ""

print_substep "Verificar estado inicial"
print_command "kubectl get hpa php-apache-hpa"
kubectl get hpa php-apache-hpa

print_command "kubectl get pods -l app=php-apache"
kubectl get pods -l app=php-apache

echo ""
print_substep "Iniciar generador de carga"
echo -e "${YELLOW}Iniciando generador de carga en segundo plano...${NC}"
echo ""

# Crear el generador de carga como un Job
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: load-generator
spec:
  template:
    spec:
      containers:
      - name: load-generator
        image: busybox:1.36
        command:
        - /bin/sh
        - -c
        - "while true; do wget -q -O- http://php-apache > /dev/null; done"
      restartPolicy: Never
  backoffLimit: 1
EOF

echo ""
echo "Generador de carga iniciado. Observando el escalamiento..."
echo ""

# Observar durante 2 minutos
for i in {1..12}; do
    echo ""
    echo "=== Observación $i/12 (cada 10 segundos) ==="
    print_command "kubectl get hpa php-apache-hpa"
    kubectl get hpa php-apache-hpa
    echo ""
    print_command "kubectl get pods -l app=php-apache"
    kubectl get pods -l app=php-apache
    echo ""
    print_command "kubectl top pods -l app=php-apache"
    kubectl top pods -l app=php-apache 2>/dev/null || echo "(Métricas no disponibles aún)"
    sleep 10
done

echo ""
echo -e "${GREEN}✓ Período de observación de carga completado${NC}"

wait_for_user

# =============================================================================
# Paso 7: Detener carga y observar scale-down
# =============================================================================
print_step "Paso 7: Detener Carga y Observar Scale-Down"

print_substep "Detener el generador de carga"
print_command "kubectl delete job load-generator"
kubectl delete job load-generator --ignore-not-found=true

echo ""
echo -e "${YELLOW}Nota: El scale-down toma tiempo debido al stabilizationWindowSeconds.${NC}"
echo "Observando durante 2 minutos..."
echo ""

# Observar durante 2 minutos
for i in {1..12}; do
    echo ""
    echo "=== Observación $i/12 (cada 10 segundos) ==="
    print_command "kubectl get hpa php-apache-hpa"
    kubectl get hpa php-apache-hpa
    echo ""
    print_command "kubectl get pods -l app=php-apache"
    kubectl get pods -l app=php-apache
    sleep 10
done

echo ""
print_substep "Ver eventos del HPA"
print_command "kubectl describe hpa php-apache-hpa | grep -A 20 'Events:'"
kubectl describe hpa php-apache-hpa | grep -A 20 "Events:" || echo "(Sin eventos recientes)"

echo ""
echo -e "${GREEN}✓ Observación de scale-down completada${NC}"

wait_for_user

# =============================================================================
# Ejercicios Adicionales
# =============================================================================
print_step "Ejercicios Adicionales"

print_substep "Ejercicio 1: Ver HPA en formato YAML"

print_command "kubectl get hpa php-apache-hpa -o yaml"
kubectl get hpa php-apache-hpa -o yaml

echo ""
print_substep "Ejercicio 2: Modificar límites del HPA"

echo "Cambiando minReplicas a 3 y maxReplicas a 15..."
print_command "kubectl patch hpa php-apache-hpa --patch '{\"spec\":{\"minReplicas\":3,\"maxReplicas\":15}}'"
kubectl patch hpa php-apache-hpa --patch '{"spec":{"minReplicas":3,"maxReplicas":15}}'

echo ""
print_command "kubectl get hpa php-apache-hpa"
kubectl get hpa php-apache-hpa

echo ""
print_substep "Ejercicio 3: Ver condiciones del HPA"

print_command "kubectl get hpa php-apache-hpa -o jsonpath='{.status.conditions[*].type}'"
echo ""
kubectl get hpa php-apache-hpa -o jsonpath='{.status.conditions[*].type}'
echo ""

echo ""
echo -e "${GREEN}✓ Ejercicios adicionales completados${NC}"

wait_for_user

# =============================================================================
# Limpieza Final
# =============================================================================
print_step "Limpieza Final"

echo "Eliminando recursos del laboratorio..."

print_command "kubectl delete hpa php-apache-hpa"
kubectl delete hpa php-apache-hpa --ignore-not-found=true

print_command "kubectl delete deployment php-apache"
kubectl delete deployment php-apache --ignore-not-found=true

print_command "kubectl delete service php-apache"
kubectl delete service php-apache --ignore-not-found=true

print_command "kubectl delete job load-generator"
kubectl delete job load-generator --ignore-not-found=true

echo ""
echo "Verificando limpieza..."
print_command "kubectl get all -l app=php-apache"
kubectl get all -l app=php-apache 2>/dev/null || echo "No resources found."

echo ""
echo -e "${GREEN}✓ Recursos limpiados${NC}"

wait_for_user

# =============================================================================
# Resumen Final
# =============================================================================
print_step "Laboratorio Completado"

echo "Has completado exitosamente el Lab 13: Horizontal Pod Autoscaler"
echo ""
echo "Resumen de conceptos aprendidos:"
echo ""
echo "  METRICS SERVER:"
echo "    - Necesario para que HPA funcione"
echo "    - Recolecta métricas de CPU y memoria de los pods"
echo "    - kubectl top nodes/pods para ver métricas"
echo ""
echo "  HORIZONTAL POD AUTOSCALER (HPA):"
echo "    - Escala automáticamente basado en métricas"
echo "    - Requiere resource requests en los pods"
echo "    - Configurable con kubectl autoscale o YAML"
echo ""
echo "  CONFIGURACIÓN AVANZADA:"
echo "    - Múltiples métricas (CPU, memoria, custom)"
echo "    - behavior: control de velocidad de escalamiento"
echo "    - stabilizationWindowSeconds: evita fluctuaciones"
echo "    - policies: reglas específicas de scale-up/down"
echo ""
echo "  BUENAS PRÁCTICAS:"
echo "    - Siempre definir resource requests"
echo "    - Establecer límites razonables de réplicas"
echo "    - Usar stabilizationWindow para estabilidad"
echo "    - Monitorear el comportamiento del HPA"
echo ""
echo "Comandos principales aprendidos:"
echo "  - minikube addons enable metrics-server"
echo "  - kubectl top nodes"
echo "  - kubectl top pods"
echo "  - kubectl autoscale deployment <nombre> --cpu-percent=<N> --min=<X> --max=<Y>"
echo "  - kubectl get hpa"
echo "  - kubectl describe hpa <nombre>"
echo ""
echo -e "${GREEN}¡Felicitaciones! Estás listo para el Lab 14: Rolling Updates y Rollbacks${NC}"
