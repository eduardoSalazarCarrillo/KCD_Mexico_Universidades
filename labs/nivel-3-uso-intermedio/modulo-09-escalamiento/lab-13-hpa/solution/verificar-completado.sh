#!/bin/bash
# =============================================================================
# Lab 13: Horizontal Pod Autoscaler - Verificación de Completado
# =============================================================================
# Este script verifica que has completado correctamente el laboratorio
# probando tus conocimientos de HPA en Kubernetes.
# =============================================================================

echo "=============================================="
echo "  Lab 13: Verificación de Completado"
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

check_warning() {
    echo -e "${YELLOW}!${NC} $1"
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
# Verificación 2: kubectl disponible
# =============================================================================
echo ""
echo "2. Verificando kubectl..."

if kubectl version --client &> /dev/null; then
    check_passed "kubectl está disponible"
else
    check_failed "kubectl no está disponible"
fi

# =============================================================================
# Verificación 3: Metrics Server habilitado
# =============================================================================
echo ""
echo "3. Verificando Metrics Server..."

METRICS_SERVER=$(kubectl get pods -n kube-system -l k8s-app=metrics-server --no-headers 2>/dev/null | wc -l)
if [ "$METRICS_SERVER" -gt 0 ]; then
    check_passed "Metrics Server está instalado"
else
    check_failed "Metrics Server no está instalado"
    echo "   Ejecuta: minikube addons enable metrics-server"
fi

# Verificar que metrics-server está funcionando
if kubectl top nodes &> /dev/null; then
    check_passed "Metrics Server está funcionando (kubectl top nodes)"
else
    check_warning "Metrics Server puede no estar listo todavía"
    echo "   Espera unos minutos y vuelve a intentar"
    ((CHECKS_TOTAL++))
fi

# =============================================================================
# Verificación 4: Crear deployment de prueba con resource requests
# =============================================================================
echo ""
echo "4. Verificando capacidad de crear deployments con resource requests..."

# Limpiar si existe
kubectl delete deployment hpa-test --ignore-not-found=true &> /dev/null
kubectl delete hpa hpa-test --ignore-not-found=true &> /dev/null
kubectl delete service hpa-test --ignore-not-found=true &> /dev/null
sleep 2

# Crear deployment con resource requests
cat <<EOF | kubectl apply -f - &> /dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hpa-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hpa-test
  template:
    metadata:
      labels:
        app: hpa-test
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        resources:
          requests:
            cpu: 100m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 128Mi
EOF

if kubectl rollout status deployment/hpa-test --timeout=60s &> /dev/null; then
    check_passed "Puede crear deployments con resource requests"
else
    check_failed "No puede crear deployments con resource requests"
fi

# Verificar que el deployment tiene resource requests
REQUESTS=$(kubectl get deployment hpa-test -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null)
if [ "$REQUESTS" = "100m" ]; then
    check_passed "Resource requests están configurados correctamente"
else
    check_failed "Resource requests no están configurados"
fi

# =============================================================================
# Verificación 5: Crear HPA con kubectl autoscale
# =============================================================================
echo ""
echo "5. Verificando creación de HPA con kubectl autoscale..."

if kubectl autoscale deployment hpa-test --cpu-percent=50 --min=1 --max=5 &> /dev/null; then
    check_passed "Puede crear HPA con kubectl autoscale"
else
    check_failed "No puede crear HPA con kubectl autoscale"
fi

# Verificar que el HPA existe
if kubectl get hpa hpa-test &> /dev/null; then
    check_passed "HPA fue creado correctamente"
else
    check_failed "HPA no fue creado"
fi

# =============================================================================
# Verificación 6: Ver información del HPA
# =============================================================================
echo ""
echo "6. Verificando acceso a información del HPA..."

if kubectl get hpa hpa-test &> /dev/null; then
    check_passed "Puede obtener información del HPA"
else
    check_failed "No puede obtener información del HPA"
fi

if kubectl describe hpa hpa-test &> /dev/null; then
    check_passed "Puede describir el HPA"
else
    check_failed "No puede describir el HPA"
fi

# =============================================================================
# Verificación 7: Verificar campos del HPA
# =============================================================================
echo ""
echo "7. Verificando configuración del HPA..."

MIN_REPLICAS=$(kubectl get hpa hpa-test -o jsonpath='{.spec.minReplicas}' 2>/dev/null)
MAX_REPLICAS=$(kubectl get hpa hpa-test -o jsonpath='{.spec.maxReplicas}' 2>/dev/null)
TARGET_CPU=$(kubectl get hpa hpa-test -o jsonpath='{.spec.metrics[0].resource.target.averageUtilization}' 2>/dev/null)

if [ "$MIN_REPLICAS" = "1" ]; then
    check_passed "minReplicas configurado correctamente: $MIN_REPLICAS"
else
    check_failed "minReplicas incorrecto (esperado: 1, actual: $MIN_REPLICAS)"
fi

if [ "$MAX_REPLICAS" = "5" ]; then
    check_passed "maxReplicas configurado correctamente: $MAX_REPLICAS"
else
    check_failed "maxReplicas incorrecto (esperado: 5, actual: $MAX_REPLICAS)"
fi

if [ "$TARGET_CPU" = "50" ]; then
    check_passed "Target CPU configurado correctamente: ${TARGET_CPU}%"
else
    check_failed "Target CPU incorrecto (esperado: 50, actual: $TARGET_CPU)"
fi

# =============================================================================
# Verificación 8: Eliminar y recrear HPA con YAML
# =============================================================================
echo ""
echo "8. Verificando creación de HPA con YAML..."

# Eliminar HPA existente
kubectl delete hpa hpa-test &> /dev/null
sleep 2

# Crear HPA con YAML
cat <<EOF | kubectl apply -f - &> /dev/null
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: hpa-test
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: hpa-test
  minReplicas: 2
  maxReplicas: 8
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
EOF

if kubectl get hpa hpa-test &> /dev/null; then
    check_passed "Puede crear HPA desde YAML"
else
    check_failed "No puede crear HPA desde YAML"
fi

# Verificar nueva configuración
NEW_MIN=$(kubectl get hpa hpa-test -o jsonpath='{.spec.minReplicas}' 2>/dev/null)
if [ "$NEW_MIN" = "2" ]; then
    check_passed "HPA actualizado correctamente desde YAML"
else
    check_failed "HPA no fue actualizado desde YAML"
fi

# =============================================================================
# Verificación 9: Verificar HPA con autoscaling/v2
# =============================================================================
echo ""
echo "9. Verificando API version del HPA..."

API_VERSION=$(kubectl get hpa hpa-test -o jsonpath='{.apiVersion}' 2>/dev/null)
if [[ "$API_VERSION" == "autoscaling/v2"* ]]; then
    check_passed "HPA usa API version correcta: $API_VERSION"
else
    check_warning "HPA usa API version: $API_VERSION (recomendado: autoscaling/v2)"
    ((CHECKS_TOTAL++))
fi

# =============================================================================
# Verificación 10: Modificar HPA con patch
# =============================================================================
echo ""
echo "10. Verificando modificación de HPA con patch..."

if kubectl patch hpa hpa-test --patch '{"spec":{"maxReplicas":10}}' &> /dev/null; then
    check_passed "Puede modificar HPA con kubectl patch"
else
    check_failed "No puede modificar HPA con kubectl patch"
fi

NEW_MAX=$(kubectl get hpa hpa-test -o jsonpath='{.spec.maxReplicas}' 2>/dev/null)
if [ "$NEW_MAX" = "10" ]; then
    check_passed "HPA patch aplicado correctamente (maxReplicas: $NEW_MAX)"
else
    check_failed "HPA patch no se aplicó correctamente"
fi

# =============================================================================
# Verificación 11: kubectl top pods
# =============================================================================
echo ""
echo "11. Verificando kubectl top pods..."

# Esperar a que las métricas estén disponibles para los pods recién creados
# Metrics Server puede tardar hasta 60 segundos en recopilar métricas de pods nuevos
METRICS_READY=false
for i in {1..4}; do
    echo "   Intento $i/4 - Esperando métricas de pods..."
    sleep 15
    if kubectl top pods -l app=hpa-test &> /dev/null; then
        METRICS_READY=true
        break
    fi
done

if [ "$METRICS_READY" = true ]; then
    check_passed "Puede obtener métricas de pods"
else
    check_warning "No puede obtener métricas de pods (Metrics Server puede no estar listo)"
    ((CHECKS_TOTAL++))
fi

# =============================================================================
# Verificación 12: Verificar archivos del laboratorio
# =============================================================================
echo ""
echo "12. Verificando archivos del laboratorio..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

if [ -f "$LAB_DIR/initial/app-hpa.yaml" ]; then
    check_passed "Archivo app-hpa.yaml existe en initial/"
else
    check_failed "Archivo app-hpa.yaml no encontrado en initial/"
fi

if [ -f "$LAB_DIR/initial/hpa.yaml" ]; then
    check_passed "Archivo hpa.yaml existe en initial/"
else
    check_failed "Archivo hpa.yaml no encontrado en initial/"
fi

# =============================================================================
# Limpieza
# =============================================================================
echo ""
echo "13. Limpiando recursos de prueba..."

kubectl delete hpa hpa-test --ignore-not-found=true &> /dev/null
kubectl delete deployment hpa-test --ignore-not-found=true &> /dev/null
kubectl delete service hpa-test --ignore-not-found=true &> /dev/null

check_passed "Recursos de prueba limpiados"

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
    echo -e "${GREEN}Has completado exitosamente el Lab 13: Horizontal Pod Autoscaler${NC}"
    echo ""
    echo "Has demostrado que puedes:"
    echo "  - Habilitar y verificar Metrics Server"
    echo "  - Crear deployments con resource requests"
    echo "  - Crear HPA con kubectl autoscale"
    echo "  - Crear HPA con manifiestos YAML"
    echo "  - Verificar y modificar la configuración del HPA"
    echo "  - Usar kubectl top para ver métricas"
    echo ""
    echo "Estás listo para continuar con el Lab 14: Rolling Updates y Rollbacks"
else
    FAILED=$((CHECKS_TOTAL - CHECKS_PASSED))
    echo -e "${YELLOW}Algunas verificaciones fallaron ($FAILED de $CHECKS_TOTAL)${NC}"
    echo "Revisa los puntos marcados con ✗ y vuelve a intentar"
    echo ""
    echo "Posibles soluciones:"
    echo "  - Asegúrate de que Minikube está corriendo: minikube start"
    echo "  - Habilita Metrics Server: minikube addons enable metrics-server"
    echo "  - Espera a que Metrics Server esté listo (1-2 minutos)"
    echo "  - Verifica los archivos YAML en initial/"
    echo "  - Revisa el README.md para más detalles"
fi

echo ""
echo "=============================================="
