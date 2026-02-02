#!/bin/bash
# =============================================================================
# Lab 05: Scaling - Verificación de Completado
# =============================================================================
# Este script verifica que has completado correctamente el laboratorio
# probando tus conocimientos de escalamiento en Kubernetes.
# =============================================================================

echo "=============================================="
echo "  Lab 05: Verificación de Completado"
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
# Verificación 3: Crear un deployment de prueba
# =============================================================================
echo ""
echo "3. Verificando capacidad de crear deployments..."

# Limpiar si existe
kubectl delete deployment scaling-test --ignore-not-found=true &> /dev/null
sleep 2

if kubectl create deployment scaling-test --image=nginx:alpine --replicas=1 &> /dev/null; then
    kubectl rollout status deployment/scaling-test --timeout=60s &> /dev/null
    check_passed "Puede crear deployments"
else
    check_failed "No puede crear deployments"
fi

# =============================================================================
# Verificación 4: Escalar con kubectl scale
# =============================================================================
echo ""
echo "4. Verificando escalamiento con kubectl scale..."

if kubectl scale deployment scaling-test --replicas=3 &> /dev/null; then
    sleep 3
    REPLICAS=$(kubectl get deployment scaling-test -o jsonpath='{.spec.replicas}' 2>/dev/null)
    if [ "$REPLICAS" = "3" ]; then
        check_passed "kubectl scale funciona correctamente (escaló a 3 réplicas)"
    else
        check_failed "kubectl scale no cambió las réplicas correctamente"
    fi
else
    check_failed "kubectl scale falló"
fi

# =============================================================================
# Verificación 5: Verificar pods creados
# =============================================================================
echo ""
echo "5. Verificando que los pods se crearon..."

sleep 5
POD_COUNT=$(kubectl get pods -l app=scaling-test --no-headers 2>/dev/null | wc -l)
if [ "$POD_COUNT" = "3" ]; then
    check_passed "Se crearon 3 pods correctamente"
else
    check_failed "Número incorrecto de pods: $POD_COUNT (esperado: 3)"
fi

# =============================================================================
# Verificación 6: Reducir réplicas
# =============================================================================
echo ""
echo "6. Verificando reducción de réplicas (scale down)..."

if kubectl scale deployment scaling-test --replicas=1 &> /dev/null; then
    sleep 5
    REPLICAS=$(kubectl get deployment scaling-test -o jsonpath='{.spec.replicas}' 2>/dev/null)
    if [ "$REPLICAS" = "1" ]; then
        check_passed "Scale down funciona correctamente (redujo a 1 réplica)"
    else
        check_failed "Scale down no funcionó correctamente"
    fi
else
    check_failed "kubectl scale (down) falló"
fi

# =============================================================================
# Verificación 7: Escalar con patch
# =============================================================================
echo ""
echo "7. Verificando escalamiento con kubectl patch..."

if kubectl patch deployment scaling-test -p '{"spec":{"replicas":4}}' &> /dev/null; then
    sleep 3
    REPLICAS=$(kubectl get deployment scaling-test -o jsonpath='{.spec.replicas}' 2>/dev/null)
    if [ "$REPLICAS" = "4" ]; then
        check_passed "kubectl patch funciona correctamente (escaló a 4 réplicas)"
    else
        check_failed "kubectl patch no cambió las réplicas correctamente"
    fi
else
    check_failed "kubectl patch falló"
fi

# =============================================================================
# Verificación 8: Escalar a 0 réplicas
# =============================================================================
echo ""
echo "8. Verificando escalamiento a 0 réplicas..."

if kubectl scale deployment scaling-test --replicas=0 &> /dev/null; then
    sleep 5
    POD_COUNT=$(kubectl get pods -l app=scaling-test --no-headers 2>/dev/null | grep -v "Terminating" | wc -l)
    DEPLOYMENT_EXISTS=$(kubectl get deployment scaling-test --no-headers 2>/dev/null | wc -l)

    if [ "$POD_COUNT" = "0" ] && [ "$DEPLOYMENT_EXISTS" = "1" ]; then
        check_passed "Scale a 0 funciona (deployment existe, sin pods)"
    else
        check_failed "Scale a 0 no funcionó correctamente"
    fi
else
    check_failed "kubectl scale a 0 falló"
fi

# =============================================================================
# Verificación 9: Ver información del deployment
# =============================================================================
echo ""
echo "9. Verificando que puede obtener información de réplicas..."

REPLICAS_INFO=$(kubectl get deployment scaling-test -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ -n "$REPLICAS_INFO" ]; then
    check_passed "Puede obtener información de réplicas con jsonpath"
else
    check_failed "No puede obtener información de réplicas"
fi

# =============================================================================
# Verificación 10: Ver pods en formato wide
# =============================================================================
echo ""
echo "10. Verificando vista extendida de pods..."

# Restaurar réplicas para esta prueba
kubectl scale deployment scaling-test --replicas=2 &> /dev/null
sleep 5

if kubectl get pods -l app=scaling-test -o wide &> /dev/null; then
    WIDE_OUTPUT=$(kubectl get pods -l app=scaling-test -o wide 2>/dev/null)
    if echo "$WIDE_OUTPUT" | grep -q "NODE"; then
        check_passed "kubectl get pods -o wide funciona"
    else
        check_failed "kubectl get pods -o wide no muestra información esperada"
    fi
else
    check_failed "kubectl get pods -o wide falló"
fi

# =============================================================================
# Verificación 11: Ver eventos de escalamiento
# =============================================================================
echo ""
echo "11. Verificando acceso a eventos de escalamiento..."

if kubectl describe deployment scaling-test 2>/dev/null | grep -q "ScalingReplicaSet"; then
    check_passed "Puede ver eventos de escalamiento"
else
    # Puede que no haya eventos recientes, verificar que describe funciona
    if kubectl describe deployment scaling-test &> /dev/null; then
        check_passed "Puede acceder a información del deployment (sin eventos recientes)"
    else
        check_failed "No puede acceder a eventos del deployment"
    fi
fi

# =============================================================================
# Verificación 12: Limpiar recursos
# =============================================================================
echo ""
echo "12. Verificando limpieza de recursos..."

if kubectl delete deployment scaling-test &> /dev/null; then
    sleep 3
    if ! kubectl get deployment scaling-test &> /dev/null; then
        check_passed "Puede eliminar deployments correctamente"
    else
        check_failed "El deployment no fue eliminado completamente"
    fi
else
    check_failed "kubectl delete deployment falló"
fi

# =============================================================================
# Verificación 13: Conocimiento de conceptos (verificación de archivos)
# =============================================================================
echo ""
echo "13. Verificando archivos del laboratorio..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

if [ -f "$LAB_DIR/initial/deployment-scaling.yaml" ]; then
    check_passed "Archivo deployment-scaling.yaml existe"
else
    check_failed "Archivo deployment-scaling.yaml no encontrado"
fi

if [ -f "$LAB_DIR/initial/deployment-scaled.yaml" ]; then
    check_passed "Archivo deployment-scaled.yaml existe"
else
    check_failed "Archivo deployment-scaled.yaml no encontrado"
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
    echo -e "${GREEN}Has completado exitosamente el Lab 05: Scaling${NC}"
    echo ""
    echo "Has demostrado que puedes:"
    echo "  - Crear deployments en Kubernetes"
    echo "  - Escalar aplicaciones usando kubectl scale"
    echo "  - Reducir el número de réplicas (scale down)"
    echo "  - Usar kubectl patch para modificar réplicas"
    echo "  - Escalar a 0 réplicas sin eliminar el deployment"
    echo "  - Obtener información de réplicas con jsonpath"
    echo "  - Ver pods en formato extendido"
    echo "  - Acceder a eventos de escalamiento"
    echo "  - Limpiar recursos correctamente"
    echo ""
    echo "Estás listo para continuar con el Lab 06: YAML Manifests"
else
    FAILED=$((CHECKS_TOTAL - CHECKS_PASSED))
    echo -e "${YELLOW}Algunas verificaciones fallaron ($FAILED de $CHECKS_TOTAL)${NC}"
    echo "Revisa los puntos marcados con ✗ y vuelve a intentar"
    echo ""
    echo "Posibles soluciones:"
    echo "  - Asegúrate de que Minikube está corriendo: minikube start"
    echo "  - Verifica tu conexión al clúster: kubectl cluster-info"
    echo "  - Revisa el README.md para más detalles sobre cada paso"
    echo "  - Asegúrate de que los archivos YAML existen en initial/"
fi

echo ""
echo "=============================================="
