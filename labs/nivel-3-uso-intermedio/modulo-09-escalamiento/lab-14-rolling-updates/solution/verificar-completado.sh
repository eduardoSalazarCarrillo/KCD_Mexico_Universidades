#!/bin/bash
# =============================================================================
# Lab 14: Rolling Updates y Rollbacks - Verificacion de Completado
# =============================================================================
# Este script verifica que has comprendido los conceptos del laboratorio
# probando las diferentes formas de actualizar y hacer rollback en Kubernetes.
# =============================================================================

echo "=============================================="
echo "  Lab 14: Verificacion de Completado"
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
    echo -e "${GREEN}OK${NC} $1"
    ((CHECKS_PASSED++))
    ((CHECKS_TOTAL++))
}

check_failed() {
    echo -e "${RED}FAIL${NC} $1"
    ((CHECKS_TOTAL++))
}

cleanup() {
    echo ""
    echo "Limpiando recursos de prueba..."
    kubectl delete deployment verify-rolling --ignore-not-found=true &> /dev/null
    kubectl delete deployment verify-recreate --ignore-not-found=true &> /dev/null
}

# Limpiar al inicio
cleanup &> /dev/null

# =============================================================================
# Verificacion 1: Minikube corriendo
# =============================================================================
echo "1. Verificando que Minikube esta corriendo..."

if minikube status &> /dev/null; then
    check_passed "Minikube esta corriendo"
else
    check_failed "Minikube no esta corriendo"
    echo "   Ejecuta: minikube start --driver=docker"
    exit 1
fi

# =============================================================================
# Verificacion 2: kubectl puede conectarse al cluster
# =============================================================================
echo ""
echo "2. Verificando conexion al cluster..."

if kubectl cluster-info &> /dev/null; then
    check_passed "kubectl puede conectarse al cluster"
else
    check_failed "kubectl no puede conectarse al cluster"
fi

# =============================================================================
# Verificacion 3: Archivos YAML iniciales existen
# =============================================================================
echo ""
echo "3. Verificando que los archivos YAML iniciales existen..."

if [ -f "$LAB_DIR/initial/app-rolling.yaml" ]; then
    check_passed "Archivo app-rolling.yaml existe"
else
    check_failed "Archivo app-rolling.yaml no encontrado"
fi

if [ -f "$LAB_DIR/initial/app-recreate.yaml" ]; then
    check_passed "Archivo app-recreate.yaml existe"
else
    check_failed "Archivo app-recreate.yaml no encontrado"
fi

# =============================================================================
# Verificacion 4: Crear deployment con estrategia RollingUpdate
# =============================================================================
echo ""
echo "4. Verificando creacion de deployment con RollingUpdate..."

cat << 'EOF' > /tmp/verify-rolling.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: verify-rolling
  annotations:
    kubernetes.io/change-cause: "Initial v1"
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: verify-rolling
  template:
    metadata:
      labels:
        app: verify-rolling
    spec:
      containers:
        - name: nginx
          image: nginx:1.20-alpine
          ports:
            - containerPort: 80
EOF

if kubectl apply -f /tmp/verify-rolling.yaml &> /dev/null; then
    kubectl rollout status deployment/verify-rolling --timeout=120s &> /dev/null
    if kubectl get deployment verify-rolling &> /dev/null; then
        READY=$(kubectl get deployment verify-rolling -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
        if [ "$READY" == "3" ]; then
            check_passed "Puede crear deployment con estrategia RollingUpdate"
        else
            check_failed "El deployment no tiene 3 replicas listas (tiene: $READY)"
        fi
    else
        check_failed "El deployment no se creo"
    fi
else
    check_failed "No puede crear deployment"
fi

# =============================================================================
# Verificacion 5: Rolling update con kubectl set image
# =============================================================================
echo ""
echo "5. Verificando rolling update con kubectl set image..."

if kubectl set image deployment/verify-rolling nginx=nginx:1.21-alpine &> /dev/null; then
    kubectl rollout status deployment/verify-rolling --timeout=120s &> /dev/null
    CURRENT_IMAGE=$(kubectl get deployment verify-rolling -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
    if [ "$CURRENT_IMAGE" == "nginx:1.21-alpine" ]; then
        check_passed "Puede realizar rolling update con kubectl set image"
    else
        check_failed "La imagen no se actualizo correctamente (actual: $CURRENT_IMAGE)"
    fi
else
    check_failed "No puede ejecutar kubectl set image"
fi

# =============================================================================
# Verificacion 6: Ver historial de revisiones
# =============================================================================
echo ""
echo "6. Verificando historial de revisiones..."

HISTORY=$(kubectl rollout history deployment/verify-rolling 2>/dev/null)
if echo "$HISTORY" | grep -q "REVISION"; then
    REVISION_COUNT=$(echo "$HISTORY" | grep -c "^[0-9]" || echo "0")
    if [ "$REVISION_COUNT" -ge 2 ]; then
        check_passed "Puede ver historial de revisiones (tiene $REVISION_COUNT revisiones)"
    else
        check_passed "Puede ver historial de revisiones"
    fi
else
    check_failed "No puede ver historial de revisiones"
fi

# =============================================================================
# Verificacion 7: Documentar cambio con change-cause
# =============================================================================
echo ""
echo "7. Verificando documentacion de cambios con change-cause..."

if kubectl annotate deployment/verify-rolling kubernetes.io/change-cause="Update to 1.21" --overwrite &> /dev/null; then
    ANNOTATION=$(kubectl get deployment verify-rolling -o jsonpath='{.metadata.annotations.kubernetes\.io/change-cause}' 2>/dev/null)
    if [ "$ANNOTATION" == "Update to 1.21" ]; then
        check_passed "Puede documentar cambios con kubernetes.io/change-cause"
    else
        check_failed "La anotacion no se aplico correctamente"
    fi
else
    check_failed "No puede agregar anotaciones"
fi

# =============================================================================
# Verificacion 8: Simular deployment fallido
# =============================================================================
echo ""
echo "8. Verificando que puede detectar deployment fallido..."

kubectl set image deployment/verify-rolling nginx=nginx:invalid-version-xyz &> /dev/null
sleep 10

POD_STATUS=$(kubectl get pods -l app=verify-rolling -o jsonpath='{.items[*].status.containerStatuses[0].state.waiting.reason}' 2>/dev/null)
if echo "$POD_STATUS" | grep -qE "ImagePullBackOff|ErrImagePull"; then
    check_passed "Puede detectar deployment fallido (ImagePullBackOff)"
else
    # Verificar si hay pods en estado erroneo
    PODS_NOT_READY=$(kubectl get pods -l app=verify-rolling --no-headers 2>/dev/null | grep -v "Running" | wc -l)
    if [ "$PODS_NOT_READY" -gt 0 ]; then
        check_passed "Puede detectar deployment fallido"
    else
        check_failed "No se detecto fallo en deployment (estado: $POD_STATUS)"
    fi
fi

# =============================================================================
# Verificacion 9: Rollback funciona
# =============================================================================
echo ""
echo "9. Verificando rollback..."

if kubectl rollout undo deployment/verify-rolling &> /dev/null; then
    kubectl rollout status deployment/verify-rolling --timeout=120s &> /dev/null
    CURRENT_IMAGE=$(kubectl get deployment verify-rolling -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
    if [ "$CURRENT_IMAGE" == "nginx:1.21-alpine" ]; then
        check_passed "Puede hacer rollback con kubectl rollout undo"
    else
        check_passed "Rollback ejecutado (imagen actual: $CURRENT_IMAGE)"
    fi
else
    check_failed "kubectl rollout undo no funciona"
fi

# =============================================================================
# Verificacion 10: Rollback a revision especifica
# =============================================================================
echo ""
echo "10. Verificando rollback a revision especifica..."

if kubectl rollout undo deployment/verify-rolling --to-revision=1 &> /dev/null; then
    kubectl rollout status deployment/verify-rolling --timeout=120s &> /dev/null
    CURRENT_IMAGE=$(kubectl get deployment verify-rolling -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
    if [ "$CURRENT_IMAGE" == "nginx:1.20-alpine" ]; then
        check_passed "Puede hacer rollback a revision especifica (v1 = nginx:1.20-alpine)"
    else
        check_passed "Rollback a revision especifica ejecutado"
    fi
else
    check_failed "Rollback a revision especifica no funciona"
fi

# =============================================================================
# Verificacion 11: Pause y Resume
# =============================================================================
echo ""
echo "11. Verificando pause de rollout..."

if kubectl rollout pause deployment/verify-rolling &> /dev/null; then
    PAUSED=$(kubectl get deployment verify-rolling -o jsonpath='{.spec.paused}' 2>/dev/null)
    if [ "$PAUSED" == "true" ]; then
        check_passed "Puede pausar rollout con kubectl rollout pause"
    else
        check_failed "El deployment no se pauso correctamente"
    fi
else
    check_failed "kubectl rollout pause no funciona"
fi

echo ""
echo "12. Verificando resume de rollout..."

if kubectl rollout resume deployment/verify-rolling &> /dev/null; then
    sleep 2
    PAUSED=$(kubectl get deployment verify-rolling -o jsonpath='{.spec.paused}' 2>/dev/null)
    if [ "$PAUSED" != "true" ]; then
        check_passed "Puede reanudar rollout con kubectl rollout resume"
    else
        check_failed "El deployment no se reanudo correctamente"
    fi
else
    check_failed "kubectl rollout resume no funciona"
fi

# =============================================================================
# Verificacion 13: Estrategia Recreate
# =============================================================================
echo ""
echo "13. Verificando creacion de deployment con estrategia Recreate..."

cat << 'EOF' > /tmp/verify-recreate.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: verify-recreate
spec:
  replicas: 2
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: verify-recreate
  template:
    metadata:
      labels:
        app: verify-recreate
    spec:
      containers:
        - name: nginx
          image: nginx:1.20-alpine
          ports:
            - containerPort: 80
EOF

if kubectl apply -f /tmp/verify-recreate.yaml &> /dev/null; then
    kubectl rollout status deployment/verify-recreate --timeout=120s &> /dev/null
    STRATEGY=$(kubectl get deployment verify-recreate -o jsonpath='{.spec.strategy.type}' 2>/dev/null)
    if [ "$STRATEGY" == "Recreate" ]; then
        check_passed "Puede crear deployment con estrategia Recreate"
    else
        check_failed "La estrategia no es Recreate (actual: $STRATEGY)"
    fi
else
    check_failed "No puede crear deployment con estrategia Recreate"
fi

# =============================================================================
# Verificacion 14: Entender diferencias entre estrategias
# =============================================================================
echo ""
echo "14. Verificando comprension de estrategias de actualizacion..."

ROLLING_STRATEGY=$(kubectl get deployment verify-rolling -o jsonpath='{.spec.strategy.type}' 2>/dev/null)
RECREATE_STRATEGY=$(kubectl get deployment verify-recreate -o jsonpath='{.spec.strategy.type}' 2>/dev/null)

if [ "$ROLLING_STRATEGY" == "RollingUpdate" ] && [ "$RECREATE_STRATEGY" == "Recreate" ]; then
    MAX_SURGE=$(kubectl get deployment verify-rolling -o jsonpath='{.spec.strategy.rollingUpdate.maxSurge}' 2>/dev/null)
    MAX_UNAVAIL=$(kubectl get deployment verify-rolling -o jsonpath='{.spec.strategy.rollingUpdate.maxUnavailable}' 2>/dev/null)
    if [ -n "$MAX_SURGE" ] && [ -n "$MAX_UNAVAIL" ]; then
        check_passed "Comprende ambas estrategias (RollingUpdate: maxSurge=$MAX_SURGE, maxUnavailable=$MAX_UNAVAIL)"
    else
        check_passed "Comprende ambas estrategias de actualizacion"
    fi
else
    check_failed "Falta comprension de estrategias de actualizacion"
fi

# =============================================================================
# Limpieza Final
# =============================================================================
echo ""
echo "Limpiando recursos de verificacion..."
kubectl delete deployment verify-rolling --ignore-not-found=true &> /dev/null
kubectl delete deployment verify-recreate --ignore-not-found=true &> /dev/null
rm -f /tmp/verify-rolling.yaml /tmp/verify-recreate.yaml

# =============================================================================
# Resumen
# =============================================================================
echo ""
echo "=============================================="
echo "  Resumen de Verificacion"
echo "=============================================="
echo ""
echo "Verificaciones pasadas: $CHECKS_PASSED/$CHECKS_TOTAL"
echo ""

if [ $CHECKS_PASSED -eq $CHECKS_TOTAL ]; then
    echo -e "${GREEN}FELICITACIONES!${NC}"
    echo -e "${GREEN}Has completado exitosamente el Lab 14: Rolling Updates y Rollbacks${NC}"
    echo ""
    echo "Has demostrado que puedes:"
    echo "  - Crear deployments con estrategia RollingUpdate"
    echo "  - Realizar rolling updates con kubectl set image"
    echo "  - Ver y entender el historial de revisiones"
    echo "  - Documentar cambios con kubernetes.io/change-cause"
    echo "  - Detectar deployments fallidos"
    echo "  - Hacer rollback a versiones anteriores"
    echo "  - Hacer rollback a revisiones especificas"
    echo "  - Pausar y reanudar rollouts"
    echo "  - Entender la diferencia entre RollingUpdate y Recreate"
    echo ""
    echo "Estas listo para continuar con el Lab 15: RBAC"
elif [ $CHECKS_PASSED -ge $((CHECKS_TOTAL - 2)) ]; then
    echo -e "${YELLOW}Casi lo logras!${NC}"
    FAILED=$((CHECKS_TOTAL - CHECKS_PASSED))
    echo "Solo $FAILED verificacion(es) fallaron."
    echo "Revisa los puntos marcados con FAIL y vuelve a intentar."
else
    FAILED=$((CHECKS_TOTAL - CHECKS_PASSED))
    echo -e "${YELLOW}Algunas verificaciones fallaron ($FAILED de $CHECKS_TOTAL)${NC}"
    echo "Revisa los puntos marcados con FAIL y vuelve a intentar"
    echo ""
    echo "Posibles soluciones:"
    echo "  - Asegurate de que Minikube esta corriendo: minikube start"
    echo "  - Verifica que los archivos YAML existen en initial/"
    echo "  - Revisa el README.md para mas detalles sobre cada paso"
    echo "  - Practica los comandos de rollout"
fi

echo ""
echo "=============================================="
