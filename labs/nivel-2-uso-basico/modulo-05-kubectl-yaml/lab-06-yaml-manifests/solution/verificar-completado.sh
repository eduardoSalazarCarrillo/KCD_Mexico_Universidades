#!/bin/bash
# =============================================================================
# Lab 06: YAML Manifests - Verificación de Completado
# =============================================================================
# Este script verifica que has comprendido los conceptos del laboratorio
# probando la creación de manifiestos YAML y el uso de labels.
# =============================================================================

echo "=============================================="
echo "  Lab 06: Verificación de Completado"
echo "=============================================="
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

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

cleanup() {
    echo ""
    echo "Limpiando recursos de prueba..."
    kubectl delete pod test-yaml-pod --ignore-not-found=true &> /dev/null
    kubectl delete deployment test-yaml-deployment --ignore-not-found=true &> /dev/null
    kubectl delete namespace verify-lab-06 --ignore-not-found=true &> /dev/null
}

# Limpiar al inicio
cleanup &> /dev/null

# =============================================================================
# Verificación 1: Minikube corriendo
# =============================================================================
echo "1. Verificando que Minikube está corriendo..."

if minikube status &> /dev/null; then
    check_passed "Minikube está corriendo"
else
    check_failed "Minikube no está corriendo"
    echo "   Ejecuta: minikube start --driver=docker"
    exit 1
fi

# =============================================================================
# Verificación 2: kubectl puede conectarse al clúster
# =============================================================================
echo ""
echo "2. Verificando conexión al clúster..."

if kubectl cluster-info &> /dev/null; then
    check_passed "kubectl puede conectarse al clúster"
else
    check_failed "kubectl no puede conectarse al clúster"
fi

# =============================================================================
# Verificación 3: Archivos YAML iniciales existen
# =============================================================================
echo ""
echo "3. Verificando que los archivos YAML iniciales existen..."

if [ -f "$LAB_DIR/initial/pod-ejemplo.yaml" ]; then
    check_passed "Archivo pod-ejemplo.yaml existe"
else
    check_failed "Archivo pod-ejemplo.yaml no encontrado"
fi

if [ -f "$LAB_DIR/initial/deployment-ejemplo.yaml" ]; then
    check_passed "Archivo deployment-ejemplo.yaml existe"
else
    check_failed "Archivo deployment-ejemplo.yaml no encontrado"
fi

# =============================================================================
# Verificación 4: Crear Pod desde archivo YAML
# =============================================================================
echo ""
echo "4. Verificando creación de Pod desde archivo YAML..."

if kubectl apply -f "$LAB_DIR/initial/pod-ejemplo.yaml" &> /dev/null; then
    sleep 2
    kubectl wait --for=condition=Ready pod/pod-ejemplo --timeout=60s &> /dev/null
    if kubectl get pod pod-ejemplo &> /dev/null; then
        # Verificar que tiene los labels correctos
        LABELS=$(kubectl get pod pod-ejemplo -o jsonpath='{.metadata.labels}')
        if echo "$LABELS" | grep -q "mi-aplicacion"; then
            check_passed "Puede crear Pod desde archivo YAML con labels correctos"
        else
            check_failed "El Pod no tiene los labels correctos"
        fi
    else
        check_failed "El Pod no se creó correctamente"
    fi
else
    check_failed "No pudo crear Pod desde archivo YAML"
fi

# =============================================================================
# Verificación 5: Crear Deployment desde archivo YAML
# =============================================================================
echo ""
echo "5. Verificando creación de Deployment desde archivo YAML..."

if kubectl apply -f "$LAB_DIR/initial/deployment-ejemplo.yaml" &> /dev/null; then
    kubectl rollout status deployment/web-deployment --timeout=120s &> /dev/null
    if kubectl get deployment web-deployment &> /dev/null; then
        READY=$(kubectl get deployment web-deployment -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
        if [ "$READY" == "3" ]; then
            check_passed "Puede crear Deployment desde archivo YAML con 3 réplicas"
        else
            check_failed "El Deployment no tiene 3 réplicas listas (tiene: $READY)"
        fi
    else
        check_failed "El Deployment no se creó"
    fi
else
    check_failed "No pudo crear el Deployment"
fi

# =============================================================================
# Verificación 6: Filtrar por labels
# =============================================================================
echo ""
echo "6. Verificando filtrado por labels..."

POD_COUNT=$(kubectl get pods -l app=web,tier=frontend --no-headers 2>/dev/null | wc -l)
if [ "$POD_COUNT" -eq 3 ]; then
    check_passed "Puede filtrar pods por múltiples labels"
else
    check_failed "Filtrado por labels no funciona (esperado 3, obtenido: $POD_COUNT)"
fi

# =============================================================================
# Verificación 7: Generar YAML con dry-run
# =============================================================================
echo ""
echo "7. Verificando generación de YAML con dry-run..."

DRYRUN_OUTPUT=$(kubectl run test-dryrun --image=nginx:alpine --dry-run=client -o yaml 2>/dev/null)
if echo "$DRYRUN_OUTPUT" | grep -q "apiVersion: v1" && echo "$DRYRUN_OUTPUT" | grep -q "kind: Pod"; then
    check_passed "Puede generar YAML de Pod con --dry-run=client -o yaml"
else
    check_failed "No se generó YAML correcto con dry-run"
fi

DEPLOY_DRYRUN=$(kubectl create deployment test-deploy-dryrun --image=nginx:alpine --dry-run=client -o yaml 2>/dev/null)
if echo "$DEPLOY_DRYRUN" | grep -q "apiVersion: apps/v1" && echo "$DEPLOY_DRYRUN" | grep -q "kind: Deployment"; then
    check_passed "Puede generar YAML de Deployment con --dry-run=client -o yaml"
else
    check_failed "No se generó YAML de Deployment correcto con dry-run"
fi

# =============================================================================
# Verificación 8: Agregar labels a recursos existentes
# =============================================================================
echo ""
echo "8. Verificando manejo de labels..."

# Agregar label
if kubectl label pod pod-ejemplo verificado=true &> /dev/null; then
    LABEL_VALUE=$(kubectl get pod pod-ejemplo -o jsonpath='{.metadata.labels.verificado}' 2>/dev/null)
    if [ "$LABEL_VALUE" == "true" ]; then
        check_passed "Puede agregar labels a recursos existentes"
    else
        check_failed "El label no se agregó correctamente"
    fi
else
    check_failed "No puede agregar labels"
fi

# Modificar label
if kubectl label pod pod-ejemplo verificado=actualizado --overwrite &> /dev/null; then
    LABEL_VALUE=$(kubectl get pod pod-ejemplo -o jsonpath='{.metadata.labels.verificado}' 2>/dev/null)
    if [ "$LABEL_VALUE" == "actualizado" ]; then
        check_passed "Puede modificar labels existentes con --overwrite"
    else
        check_failed "El label no se modificó correctamente"
    fi
else
    check_failed "No puede modificar labels"
fi

# Eliminar label
if kubectl label pod pod-ejemplo verificado- &> /dev/null; then
    LABEL_VALUE=$(kubectl get pod pod-ejemplo -o jsonpath='{.metadata.labels.verificado}' 2>/dev/null)
    if [ -z "$LABEL_VALUE" ]; then
        check_passed "Puede eliminar labels con el sufijo -"
    else
        check_failed "El label no se eliminó correctamente"
    fi
else
    check_failed "No puede eliminar labels"
fi

# =============================================================================
# Verificación 9: Exportar recurso a YAML
# =============================================================================
echo ""
echo "9. Verificando exportación de recursos a YAML..."

EXPORT_YAML=$(kubectl get pod pod-ejemplo -o yaml 2>/dev/null)
if echo "$EXPORT_YAML" | grep -q "apiVersion:" && \
   echo "$EXPORT_YAML" | grep -q "kind: Pod" && \
   echo "$EXPORT_YAML" | grep -q "metadata:" && \
   echo "$EXPORT_YAML" | grep -q "spec:"; then
    check_passed "Puede exportar recursos existentes a formato YAML"
else
    check_failed "No puede exportar recursos a YAML correctamente"
fi

# =============================================================================
# Verificación 10: Crear recursos multi-documento
# =============================================================================
echo ""
echo "10. Verificando creación de recursos multi-documento..."

cat << 'EOF' > /tmp/verify-multi.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: verify-lab-06
---
apiVersion: v1
kind: Pod
metadata:
  name: verify-pod
  namespace: verify-lab-06
spec:
  containers:
    - name: nginx
      image: nginx:alpine
EOF

if kubectl apply -f /tmp/verify-multi.yaml &> /dev/null; then
    sleep 3
    if kubectl get namespace verify-lab-06 &> /dev/null && \
       kubectl get pod verify-pod -n verify-lab-06 &> /dev/null; then
        check_passed "Puede crear múltiples recursos desde un archivo YAML"
    else
        check_failed "Los recursos multi-documento no se crearon correctamente"
    fi
else
    check_failed "No puede aplicar archivos multi-documento"
fi

# =============================================================================
# Verificación 11: kubectl explain funciona
# =============================================================================
echo ""
echo "11. Verificando kubectl explain..."

EXPLAIN_OUTPUT=$(kubectl explain pod.spec.containers 2>/dev/null)
if echo "$EXPLAIN_OUTPUT" | grep -qi "container"; then
    check_passed "Puede usar kubectl explain para documentación de campos"
else
    check_failed "kubectl explain no funciona correctamente"
fi

# =============================================================================
# Verificación 12: kubectl api-resources funciona
# =============================================================================
echo ""
echo "12. Verificando kubectl api-resources..."

API_RESOURCES=$(kubectl api-resources 2>/dev/null)
if echo "$API_RESOURCES" | grep -q "pods" && \
   echo "$API_RESOURCES" | grep -q "deployments"; then
    check_passed "Puede listar recursos de la API con kubectl api-resources"
else
    check_failed "kubectl api-resources no funciona correctamente"
fi

# =============================================================================
# Verificación 13: Visualizar labels como columnas
# =============================================================================
echo ""
echo "13. Verificando visualización de labels como columnas..."

LABEL_COLUMNS=$(kubectl get pods -L app,environment 2>/dev/null)
if echo "$LABEL_COLUMNS" | grep -q "APP"; then
    check_passed "Puede mostrar labels como columnas con -L"
else
    check_failed "No puede mostrar labels como columnas"
fi

# =============================================================================
# Limpieza Final
# =============================================================================
echo ""
echo "Limpiando recursos de verificación..."
kubectl delete pod pod-ejemplo --ignore-not-found=true &> /dev/null
kubectl delete deployment web-deployment --ignore-not-found=true &> /dev/null
kubectl delete namespace verify-lab-06 --ignore-not-found=true &> /dev/null
rm -f /tmp/verify-multi.yaml &> /dev/null

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
    echo -e "${GREEN}Has completado exitosamente el Lab 06: YAML Manifests${NC}"
    echo ""
    echo "Has demostrado que puedes:"
    echo "  - Crear Pods y Deployments desde archivos YAML"
    echo "  - Entender la estructura de manifiestos (apiVersion, kind, metadata, spec)"
    echo "  - Generar YAML con --dry-run=client -o yaml"
    echo "  - Exportar recursos existentes a formato YAML"
    echo "  - Filtrar recursos usando labels y selectors"
    echo "  - Agregar, modificar y eliminar labels"
    echo "  - Crear múltiples recursos desde un archivo multi-documento"
    echo "  - Usar kubectl explain para consultar documentación"
    echo "  - Usar kubectl api-resources para explorar la API"
    echo ""
    echo "Estás listo para continuar con el Lab 07: Resource Updates"
else
    FAILED=$((CHECKS_TOTAL - CHECKS_PASSED))
    echo -e "${YELLOW}Algunas verificaciones fallaron ($FAILED de $CHECKS_TOTAL)${NC}"
    echo "Revisa los puntos marcados con ✗ y vuelve a intentar"
    echo ""
    echo "Posibles soluciones:"
    echo "  - Asegúrate de que Minikube está corriendo: minikube start"
    echo "  - Verifica que los archivos YAML existen en initial/"
    echo "  - Revisa el README.md para más detalles sobre cada paso"
    echo "  - Practica los comandos de dry-run y labels"
fi

echo ""
echo "=============================================="
