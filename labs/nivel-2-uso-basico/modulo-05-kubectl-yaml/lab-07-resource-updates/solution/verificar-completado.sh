#!/bin/bash
# =============================================================================
# Lab 07: Resource Updates - Verificación de Completado
# =============================================================================
# Este script verifica que has comprendido los conceptos del laboratorio
# probando las diferentes formas de actualizar recursos en Kubernetes.
# =============================================================================

echo "=============================================="
echo "  Lab 07: Verificación de Completado"
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
    kubectl delete deployment verify-webapp --ignore-not-found=true &> /dev/null
    kubectl delete deployment test-rollback --ignore-not-found=true &> /dev/null
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

if [ -f "$LAB_DIR/initial/app-deployment-v1.yaml" ]; then
    check_passed "Archivo app-deployment-v1.yaml existe"
else
    check_failed "Archivo app-deployment-v1.yaml no encontrado"
fi

if [ -f "$LAB_DIR/initial/app-deployment-v2.yaml" ]; then
    check_passed "Archivo app-deployment-v2.yaml existe"
else
    check_failed "Archivo app-deployment-v2.yaml no encontrado"
fi

# =============================================================================
# Verificación 4: Crear deployment con kubectl apply
# =============================================================================
echo ""
echo "4. Verificando creación de deployment con kubectl apply..."

if kubectl apply -f "$LAB_DIR/initial/app-deployment-v1.yaml" &> /dev/null; then
    kubectl rollout status deployment/webapp --timeout=120s &> /dev/null
    if kubectl get deployment webapp &> /dev/null; then
        READY=$(kubectl get deployment webapp -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
        if [ "$READY" == "3" ]; then
            check_passed "Puede crear deployment con kubectl apply"
        else
            check_failed "El deployment no tiene 3 réplicas listas (tiene: $READY)"
        fi
    else
        check_failed "El deployment no se creó"
    fi
else
    check_failed "No puede crear deployment con kubectl apply"
fi

# =============================================================================
# Verificación 5: Ver historial de revisiones
# =============================================================================
echo ""
echo "5. Verificando historial de revisiones..."

HISTORY=$(kubectl rollout history deployment/webapp 2>/dev/null)
if echo "$HISTORY" | grep -q "REVISION"; then
    check_passed "Puede ver historial de revisiones con kubectl rollout history"
else
    check_failed "No puede ver historial de revisiones"
fi

# =============================================================================
# Verificación 6: Actualizar imagen con kubectl set image
# =============================================================================
echo ""
echo "6. Verificando actualización de imagen con kubectl set image..."

if kubectl set image deployment/webapp nginx=nginx:1.25-alpine &> /dev/null; then
    kubectl rollout status deployment/webapp --timeout=120s &> /dev/null
    CURRENT_IMAGE=$(kubectl get deployment webapp -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
    if [ "$CURRENT_IMAGE" == "nginx:1.25-alpine" ]; then
        check_passed "Puede actualizar imagen con kubectl set image"
    else
        check_failed "La imagen no se actualizó correctamente (actual: $CURRENT_IMAGE)"
    fi
else
    check_failed "No puede actualizar imagen con kubectl set image"
fi

# =============================================================================
# Verificación 7: Documentar cambio con change-cause
# =============================================================================
echo ""
echo "7. Verificando documentación de cambios con change-cause..."

if kubectl annotate deployment/webapp kubernetes.io/change-cause="Prueba de verificación" --overwrite &> /dev/null; then
    ANNOTATION=$(kubectl get deployment webapp -o jsonpath='{.metadata.annotations.kubernetes\.io/change-cause}' 2>/dev/null)
    if [ "$ANNOTATION" == "Prueba de verificación" ]; then
        check_passed "Puede documentar cambios con kubernetes.io/change-cause"
    else
        check_failed "La anotación no se aplicó correctamente"
    fi
else
    check_failed "No puede agregar anotaciones"
fi

# =============================================================================
# Verificación 8: Actualizar con kubectl apply
# =============================================================================
echo ""
echo "8. Verificando actualización con kubectl apply..."

if kubectl apply -f "$LAB_DIR/initial/app-deployment-v2.yaml" &> /dev/null; then
    kubectl rollout status deployment/webapp --timeout=120s &> /dev/null
    REPLICAS=$(kubectl get deployment webapp -o jsonpath='{.spec.replicas}' 2>/dev/null)
    if [ "$REPLICAS" == "4" ]; then
        check_passed "Puede actualizar deployment con kubectl apply"
    else
        check_failed "El deployment no se actualizó a 4 réplicas (tiene: $REPLICAS)"
    fi
else
    check_failed "No puede actualizar con kubectl apply"
fi

# =============================================================================
# Verificación 9: kubectl diff funciona
# =============================================================================
echo ""
echo "9. Verificando kubectl diff..."

DIFF_OUTPUT=$(kubectl diff -f "$LAB_DIR/initial/app-deployment-v1.yaml" 2>&1)
DIFF_EXIT=$?
# diff returns 0 if no changes, 1 if changes exist, >1 if error
if [ $DIFF_EXIT -le 1 ]; then
    check_passed "Puede usar kubectl diff para ver cambios"
else
    check_failed "kubectl diff no funciona correctamente"
fi

# =============================================================================
# Verificación 10: kubectl patch funciona
# =============================================================================
echo ""
echo "10. Verificando kubectl patch..."

if kubectl patch deployment webapp -p '{"spec":{"replicas":5}}' &> /dev/null; then
    sleep 2
    REPLICAS=$(kubectl get deployment webapp -o jsonpath='{.spec.replicas}' 2>/dev/null)
    if [ "$REPLICAS" == "5" ]; then
        check_passed "Puede usar kubectl patch para cambios parciales"
    else
        check_failed "kubectl patch no aplicó los cambios correctamente"
    fi
else
    check_failed "kubectl patch no funciona"
fi

# =============================================================================
# Verificación 11: Rollback funciona
# =============================================================================
echo ""
echo "11. Verificando rollback..."

# Primero, hacer un cambio con imagen inválida para tener algo de qué hacer rollback
kubectl set image deployment/webapp nginx=nginx:1.24-alpine &> /dev/null
kubectl rollout status deployment/webapp --timeout=60s &> /dev/null

REVISION_BEFORE=$(kubectl rollout history deployment/webapp 2>/dev/null | tail -n 2 | head -n 1 | awk '{print $1}')

if kubectl rollout undo deployment/webapp &> /dev/null; then
    kubectl rollout status deployment/webapp --timeout=60s &> /dev/null
    check_passed "Puede hacer rollback con kubectl rollout undo"
else
    check_failed "kubectl rollout undo no funciona"
fi

# =============================================================================
# Verificación 12: Rollback a revisión específica
# =============================================================================
echo ""
echo "12. Verificando rollback a revisión específica..."

# Obtener la revisión 1
if kubectl rollout undo deployment/webapp --to-revision=1 &> /dev/null; then
    kubectl rollout status deployment/webapp --timeout=60s &> /dev/null
    check_passed "Puede hacer rollback a revisión específica"
else
    check_failed "Rollback a revisión específica no funciona"
fi

# =============================================================================
# Verificación 13: Pause y Resume
# =============================================================================
echo ""
echo "13. Verificando pause y resume..."

if kubectl rollout pause deployment/webapp &> /dev/null; then
    # Verificar que está pausado
    PAUSED=$(kubectl get deployment webapp -o jsonpath='{.spec.paused}' 2>/dev/null)
    if [ "$PAUSED" == "true" ]; then
        check_passed "Puede pausar rollout con kubectl rollout pause"
    else
        check_failed "El deployment no se pausó correctamente"
    fi
else
    check_failed "kubectl rollout pause no funciona"
fi

if kubectl rollout resume deployment/webapp &> /dev/null; then
    sleep 2
    PAUSED=$(kubectl get deployment webapp -o jsonpath='{.spec.paused}' 2>/dev/null)
    if [ "$PAUSED" != "true" ]; then
        check_passed "Puede reanudar rollout con kubectl rollout resume"
    else
        check_failed "El deployment no se reanudó correctamente"
    fi
else
    check_failed "kubectl rollout resume no funciona"
fi

# =============================================================================
# Verificación 14: kubectl create falla si recurso existe
# =============================================================================
echo ""
echo "14. Verificando comportamiento de kubectl create cuando recurso existe..."

CREATE_OUTPUT=$(kubectl create -f "$LAB_DIR/initial/app-deployment-v1.yaml" 2>&1)
if echo "$CREATE_OUTPUT" | grep -q "AlreadyExists"; then
    check_passed "kubectl create falla correctamente cuando el recurso existe"
else
    check_failed "kubectl create debería fallar cuando el recurso existe"
fi

# =============================================================================
# Verificación 15: kubectl replace funciona
# =============================================================================
echo ""
echo "15. Verificando kubectl replace..."

if kubectl replace -f "$LAB_DIR/initial/app-deployment-v1.yaml" &> /dev/null; then
    kubectl rollout status deployment/webapp --timeout=60s &> /dev/null
    check_passed "Puede reemplazar recursos con kubectl replace"
else
    check_failed "kubectl replace no funciona"
fi

# =============================================================================
# Limpieza Final
# =============================================================================
echo ""
echo "Limpiando recursos de verificación..."
kubectl delete deployment webapp --ignore-not-found=true &> /dev/null

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
    echo -e "${GREEN}Has completado exitosamente el Lab 07: Resource Updates${NC}"
    echo ""
    echo "Has demostrado que puedes:"
    echo "  - Crear y actualizar deployments con kubectl apply"
    echo "  - Actualizar imágenes con kubectl set image"
    echo "  - Documentar cambios con kubernetes.io/change-cause"
    echo "  - Ver el historial de revisiones"
    echo "  - Usar kubectl diff para ver cambios antes de aplicar"
    echo "  - Usar kubectl patch para cambios parciales"
    echo "  - Hacer rollback a versiones anteriores"
    echo "  - Hacer rollback a revisiones específicas"
    echo "  - Pausar y reanudar rollouts"
    echo "  - Entender la diferencia entre apply, create y replace"
    echo ""
    echo "Estás listo para continuar con el Lab 08: Services"
else
    FAILED=$((CHECKS_TOTAL - CHECKS_PASSED))
    echo -e "${YELLOW}Algunas verificaciones fallaron ($FAILED de $CHECKS_TOTAL)${NC}"
    echo "Revisa los puntos marcados con ✗ y vuelve a intentar"
    echo ""
    echo "Posibles soluciones:"
    echo "  - Asegúrate de que Minikube está corriendo: minikube start"
    echo "  - Verifica que los archivos YAML existen en initial/"
    echo "  - Revisa el README.md para más detalles sobre cada paso"
    echo "  - Practica los comandos de rollout y actualización"
fi

echo ""
echo "=============================================="
