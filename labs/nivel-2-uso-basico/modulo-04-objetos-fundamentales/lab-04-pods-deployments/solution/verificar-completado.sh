#!/bin/bash
# =============================================================================
# Lab 04: Pods y Deployments - Verificación de Completado
# =============================================================================
# Este script verifica que has comprendido los conceptos del laboratorio
# probando la creación y gestión de Pods y Deployments.
# =============================================================================

echo "=============================================="
echo "  Lab 04: Verificación de Completado"
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
    kubectl delete pod test-pod-verify --ignore-not-found=true &> /dev/null
    kubectl delete deployment test-deployment-verify --ignore-not-found=true &> /dev/null
    kubectl delete pod pod-nginx --ignore-not-found=true &> /dev/null
    kubectl delete deployment nginx-deployment --ignore-not-found=true &> /dev/null
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
# Verificación 3: Crear un Pod con kubectl run
# =============================================================================
echo ""
echo "3. Verificando creación de Pod con kubectl run..."

if kubectl run test-pod-verify --image=nginx:alpine &> /dev/null; then
    sleep 2
    kubectl wait --for=condition=Ready pod/test-pod-verify --timeout=30s &> /dev/null
    if kubectl get pod test-pod-verify &> /dev/null; then
        check_passed "Puede crear un Pod con kubectl run"
    else
        check_failed "El Pod no se creó correctamente"
    fi
else
    check_failed "No pudo crear Pod con kubectl run"
fi

# =============================================================================
# Verificación 4: Ver logs de un Pod
# =============================================================================
echo ""
echo "4. Verificando acceso a logs de Pod..."

if kubectl logs test-pod-verify &> /dev/null; then
    check_passed "Puede ver logs de un Pod"
else
    check_failed "No puede ver logs del Pod"
fi

# =============================================================================
# Verificación 5: Ejecutar comando en un Pod
# =============================================================================
echo ""
echo "5. Verificando ejecución de comandos en Pod..."

if kubectl exec test-pod-verify -- nginx -v &> /dev/null; then
    check_passed "Puede ejecutar comandos dentro de un Pod"
else
    check_failed "No puede ejecutar comandos en el Pod"
fi

# =============================================================================
# Verificación 6: Describir un Pod
# =============================================================================
echo ""
echo "6. Verificando descripción de Pod..."

if kubectl describe pod test-pod-verify &> /dev/null; then
    OUTPUT=$(kubectl describe pod test-pod-verify 2>/dev/null)
    if echo "$OUTPUT" | grep -q "nginx:alpine"; then
        check_passed "Puede describir un Pod y ver detalles"
    else
        check_failed "La descripción del Pod no muestra la información esperada"
    fi
else
    check_failed "No puede describir el Pod"
fi

# =============================================================================
# Verificación 7: Eliminar un Pod
# =============================================================================
echo ""
echo "7. Verificando eliminación de Pod..."

if kubectl delete pod test-pod-verify &> /dev/null; then
    sleep 2
    if ! kubectl get pod test-pod-verify &> /dev/null; then
        check_passed "Puede eliminar un Pod (y el Pod no se recrea)"
    else
        check_failed "El Pod se recreó (no debería sin un controlador)"
    fi
else
    check_failed "No puede eliminar el Pod"
fi

# =============================================================================
# Verificación 8: Crear un Pod desde archivo YAML
# =============================================================================
echo ""
echo "8. Verificando creación de Pod desde archivo YAML..."

if [ -f "$LAB_DIR/initial/pod-nginx.yaml" ]; then
    if kubectl apply -f "$LAB_DIR/initial/pod-nginx.yaml" &> /dev/null; then
        sleep 2
        kubectl wait --for=condition=Ready pod/pod-nginx --timeout=30s &> /dev/null
        if kubectl get pod pod-nginx --show-labels 2>/dev/null | grep -q "app=nginx"; then
            check_passed "Puede crear Pod desde archivo YAML con labels"
        else
            check_failed "El Pod YAML no tiene los labels correctos"
        fi
    else
        check_failed "No pudo crear Pod desde archivo YAML"
    fi
else
    check_failed "Archivo pod-nginx.yaml no encontrado en initial/"
fi

# =============================================================================
# Verificación 9: Crear un Deployment
# =============================================================================
echo ""
echo "9. Verificando creación de Deployment..."

if [ -f "$LAB_DIR/initial/deployment-nginx.yaml" ]; then
    if kubectl apply -f "$LAB_DIR/initial/deployment-nginx.yaml" &> /dev/null; then
        sleep 3
        kubectl rollout status deployment/nginx-deployment --timeout=60s &> /dev/null
        if kubectl get deployment nginx-deployment &> /dev/null; then
            READY=$(kubectl get deployment nginx-deployment -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
            if [ "$READY" == "3" ]; then
                check_passed "Puede crear un Deployment con 3 réplicas"
            else
                check_failed "El Deployment no tiene 3 réplicas listas (tiene: $READY)"
            fi
        else
            check_failed "El Deployment no se creó"
        fi
    else
        check_failed "No pudo crear el Deployment"
    fi
else
    check_failed "Archivo deployment-nginx.yaml no encontrado en initial/"
fi

# =============================================================================
# Verificación 10: Verificar que se creó un ReplicaSet
# =============================================================================
echo ""
echo "10. Verificando creación automática de ReplicaSet..."

RS_COUNT=$(kubectl get replicasets -l app=nginx-deploy --no-headers 2>/dev/null | wc -l)
if [ "$RS_COUNT" -ge 1 ]; then
    check_passed "El Deployment creó automáticamente un ReplicaSet"
else
    check_failed "No se encontró el ReplicaSet del Deployment"
fi

# =============================================================================
# Verificación 11: Verificar que se crearon los Pods del Deployment
# =============================================================================
echo ""
echo "11. Verificando creación de Pods por el Deployment..."

POD_COUNT=$(kubectl get pods -l app=nginx-deploy --no-headers 2>/dev/null | grep -c "Running")
if [ "$POD_COUNT" -eq 3 ]; then
    check_passed "El Deployment tiene 3 Pods en estado Running"
else
    check_failed "El Deployment no tiene 3 Pods Running (tiene: $POD_COUNT)"
fi

# =============================================================================
# Verificación 12: Probar self-healing
# =============================================================================
echo ""
echo "12. Verificando self-healing del Deployment..."

# Obtener nombre de un pod
POD_TO_DELETE=$(kubectl get pods -l app=nginx-deploy -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -n "$POD_TO_DELETE" ]; then
    # Eliminar el pod
    kubectl delete pod "$POD_TO_DELETE" &> /dev/null &

    # Esperar un momento
    sleep 5

    # Verificar que hay 3 pods otra vez (o en proceso de creación)
    POD_COUNT=$(kubectl get pods -l app=nginx-deploy --no-headers 2>/dev/null | wc -l)

    # Esperar a que todos estén listos
    kubectl wait --for=condition=Ready pods -l app=nginx-deploy --timeout=30s &> /dev/null

    POD_READY=$(kubectl get pods -l app=nginx-deploy --no-headers 2>/dev/null | grep -c "Running")

    if [ "$POD_READY" -eq 3 ]; then
        check_passed "Self-healing funciona: el Pod eliminado fue reemplazado"
    else
        check_failed "Self-healing no funcionó correctamente (pods running: $POD_READY)"
    fi
else
    check_failed "No se pudo obtener un pod para probar self-healing"
fi

# =============================================================================
# Verificación 13: Filtrar por labels
# =============================================================================
echo ""
echo "13. Verificando filtrado por labels..."

DEPLOY_PODS=$(kubectl get pods -l app=nginx-deploy --no-headers 2>/dev/null | wc -l)
NGINX_POD=$(kubectl get pods -l app=nginx,environment=lab --no-headers 2>/dev/null | wc -l)

if [ "$DEPLOY_PODS" -eq 3 ] && [ "$NGINX_POD" -eq 1 ]; then
    check_passed "Puede filtrar pods usando labels correctamente"
else
    check_failed "El filtrado por labels no funciona como se esperaba"
fi

# =============================================================================
# Verificación 14: Describir Deployment
# =============================================================================
echo ""
echo "14. Verificando descripción de Deployment..."

DESCRIBE_OUTPUT=$(kubectl describe deployment nginx-deployment 2>/dev/null)
if echo "$DESCRIBE_OUTPUT" | grep -q "Replicas:.*3 desired"; then
    if echo "$DESCRIBE_OUTPUT" | grep -q "RollingUpdate"; then
        check_passed "Puede describir Deployment y ver estrategia"
    else
        check_failed "No se muestra la estrategia de actualización"
    fi
else
    check_failed "No puede describir el Deployment correctamente"
fi

# =============================================================================
# Verificación 15: Eliminar Deployment
# =============================================================================
echo ""
echo "15. Verificando eliminación de Deployment..."

if kubectl delete deployment nginx-deployment &> /dev/null; then
    sleep 3
    POD_COUNT=$(kubectl get pods -l app=nginx-deploy --no-headers 2>/dev/null | wc -l)
    if [ "$POD_COUNT" -eq 0 ]; then
        check_passed "Eliminar Deployment también elimina sus Pods"
    else
        check_failed "Los Pods del Deployment no fueron eliminados"
    fi
else
    check_failed "No puede eliminar el Deployment"
fi

# =============================================================================
# Limpieza Final
# =============================================================================
echo ""
echo "Limpiando recursos..."
cleanup &> /dev/null

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
    echo -e "${GREEN}Has completado exitosamente el Lab 04: Pods y Deployments${NC}"
    echo ""
    echo "Has demostrado que puedes:"
    echo "  - Crear Pods con kubectl run"
    echo "  - Crear Pods desde archivos YAML"
    echo "  - Inspeccionar Pods (describe, logs, exec)"
    echo "  - Crear Deployments desde archivos YAML"
    echo "  - Entender la relación Deployment → ReplicaSet → Pods"
    echo "  - Observar el self-healing de Kubernetes"
    echo "  - Filtrar recursos usando labels"
    echo "  - Eliminar Pods y Deployments"
    echo ""
    echo "Estás listo para continuar con el Lab 05: Scaling"
else
    FAILED=$((CHECKS_TOTAL - CHECKS_PASSED))
    echo -e "${YELLOW}Algunas verificaciones fallaron ($FAILED de $CHECKS_TOTAL)${NC}"
    echo "Revisa los puntos marcados con ✗ y vuelve a intentar"
    echo ""
    echo "Posibles soluciones:"
    echo "  - Asegúrate de que Minikube está corriendo: minikube start"
    echo "  - Verifica que los archivos YAML existen en initial/"
    echo "  - Revisa el README.md para más detalles sobre cada paso"
    echo "  - Espera unos segundos si los pods están en ContainerCreating"
fi

echo ""
echo "=============================================="
