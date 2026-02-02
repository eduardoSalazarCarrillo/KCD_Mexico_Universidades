#!/bin/bash
# =============================================================================
# Lab 09: Ingress - Verificación de Completado
# =============================================================================
# Este script verifica que has comprendido los conceptos del laboratorio
# probando la configuración y funcionamiento de Ingress.
# =============================================================================

echo "=============================================="
echo "  Lab 09: Verificación de Completado"
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
    kubectl delete ingress app-ingress app-ingress-host --ignore-not-found=true &> /dev/null
    kubectl delete -f "$LAB_DIR/initial/apps.yaml" --ignore-not-found=true &> /dev/null
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
# Verificación 3: Ingress addon está habilitado
# =============================================================================
echo ""
echo "3. Verificando que el addon de Ingress está habilitado..."

if minikube addons list 2>/dev/null | grep -q "ingress.*enabled"; then
    check_passed "Addon de Ingress está habilitado"
else
    check_failed "Addon de Ingress no está habilitado"
    echo "   Ejecuta: minikube addons enable ingress"
fi

# =============================================================================
# Verificación 4: Ingress Controller está corriendo
# =============================================================================
echo ""
echo "4. Verificando que el Ingress Controller está corriendo..."

CONTROLLER_RUNNING=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller --no-headers 2>/dev/null | grep -c "Running")
if [ "$CONTROLLER_RUNNING" -ge 1 ]; then
    check_passed "Ingress Controller está corriendo"
else
    check_failed "Ingress Controller no está corriendo"
    echo "   Espera a que el controller inicie o ejecuta: minikube addons enable ingress"
fi

# =============================================================================
# Verificación 5: Archivos YAML existen
# =============================================================================
echo ""
echo "5. Verificando que los archivos YAML existen..."

if [ -f "$LAB_DIR/initial/apps.yaml" ] && [ -f "$LAB_DIR/initial/ingress-path.yaml" ] && [ -f "$LAB_DIR/initial/ingress-host.yaml" ]; then
    check_passed "Archivos YAML del laboratorio existen"
else
    check_failed "Faltan archivos YAML en initial/"
fi

# =============================================================================
# Verificación 6: Desplegar aplicaciones
# =============================================================================
echo ""
echo "6. Verificando despliegue de aplicaciones..."

# Limpiar primero
kubectl delete -f "$LAB_DIR/initial/apps.yaml" --ignore-not-found=true &> /dev/null

if kubectl apply -f "$LAB_DIR/initial/apps.yaml" &> /dev/null; then
    sleep 3
    kubectl rollout status deployment/app-frontend --timeout=60s &> /dev/null
    kubectl rollout status deployment/app-backend --timeout=60s &> /dev/null

    FRONTEND_READY=$(kubectl get deployment app-frontend -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
    BACKEND_READY=$(kubectl get deployment app-backend -o jsonpath='{.status.readyReplicas}' 2>/dev/null)

    if [ "$FRONTEND_READY" == "2" ] && [ "$BACKEND_READY" == "2" ]; then
        check_passed "Aplicaciones desplegadas (frontend: $FRONTEND_READY, backend: $BACKEND_READY réplicas)"
    else
        check_failed "Las aplicaciones no tienen todas las réplicas listas"
    fi
else
    check_failed "No se pudieron desplegar las aplicaciones"
fi

# =============================================================================
# Verificación 7: Services creados
# =============================================================================
echo ""
echo "7. Verificando que los Services existen..."

FRONTEND_SVC=$(kubectl get service frontend-svc --no-headers 2>/dev/null | wc -l)
BACKEND_SVC=$(kubectl get service backend-svc --no-headers 2>/dev/null | wc -l)

if [ "$FRONTEND_SVC" -eq 1 ] && [ "$BACKEND_SVC" -eq 1 ]; then
    check_passed "Services frontend-svc y backend-svc existen"
else
    check_failed "Faltan Services"
fi

# =============================================================================
# Verificación 8: Crear Ingress basado en path
# =============================================================================
echo ""
echo "8. Verificando creación de Ingress basado en path..."

kubectl delete ingress app-ingress --ignore-not-found=true &> /dev/null

if kubectl apply -f "$LAB_DIR/initial/ingress-path.yaml" &> /dev/null; then
    sleep 5

    INGRESS_EXISTS=$(kubectl get ingress app-ingress --no-headers 2>/dev/null | wc -l)

    if [ "$INGRESS_EXISTS" -eq 1 ]; then
        # Verificar que tiene las reglas correctas
        RULES=$(kubectl describe ingress app-ingress 2>/dev/null)
        if echo "$RULES" | grep -q "/frontend" && echo "$RULES" | grep -q "/backend"; then
            check_passed "Ingress basado en path creado con reglas correctas"
        else
            check_failed "Ingress existe pero las reglas no son correctas"
        fi
    else
        check_failed "Ingress basado en path no se creó"
    fi
else
    check_failed "No se pudo crear el Ingress basado en path"
fi

# =============================================================================
# Verificación 9: Crear Ingress basado en host
# =============================================================================
echo ""
echo "9. Verificando creación de Ingress basado en host..."

kubectl delete ingress app-ingress-host --ignore-not-found=true &> /dev/null

if kubectl apply -f "$LAB_DIR/initial/ingress-host.yaml" &> /dev/null; then
    sleep 3

    INGRESS_EXISTS=$(kubectl get ingress app-ingress-host --no-headers 2>/dev/null | wc -l)

    if [ "$INGRESS_EXISTS" -eq 1 ]; then
        # Verificar que tiene los hosts correctos
        HOSTS=$(kubectl get ingress app-ingress-host -o jsonpath='{.spec.rules[*].host}' 2>/dev/null)
        if echo "$HOSTS" | grep -q "frontend.local" && echo "$HOSTS" | grep -q "backend.local"; then
            check_passed "Ingress basado en host creado con hosts correctos"
        else
            check_failed "Ingress existe pero los hosts no son correctos"
        fi
    else
        check_failed "Ingress basado en host no se creó"
    fi
else
    check_failed "No se pudo crear el Ingress basado en host"
fi

# =============================================================================
# Verificación 10: Probar enrutamiento por path
# =============================================================================
echo ""
echo "10. Verificando enrutamiento por path..."

MINIKUBE_IP=$(minikube ip 2>/dev/null)

if [ -n "$MINIKUBE_IP" ]; then
    # Dar tiempo al Ingress para configurarse
    sleep 5

    FRONTEND_RESPONSE=$(curl -s --connect-timeout 5 "http://$MINIKUBE_IP/frontend" 2>/dev/null)
    BACKEND_RESPONSE=$(curl -s --connect-timeout 5 "http://$MINIKUBE_IP/backend" 2>/dev/null)

    FRONTEND_OK=false
    BACKEND_OK=false

    if echo "$FRONTEND_RESPONSE" | grep -q "Frontend"; then
        FRONTEND_OK=true
    fi

    if echo "$BACKEND_RESPONSE" | grep -q "Backend"; then
        BACKEND_OK=true
    fi

    if $FRONTEND_OK && $BACKEND_OK; then
        check_passed "Enrutamiento por path funciona (/frontend y /backend)"
    elif $FRONTEND_OK || $BACKEND_OK; then
        check_failed "Solo uno de los paths funciona (puede necesitar más tiempo)"
    else
        check_failed "Enrutamiento por path no funciona (verifica el Ingress Controller)"
        echo "   Tip: Prueba ejecutar 'minikube tunnel' en otra terminal"
    fi
else
    check_failed "No se pudo obtener la IP de Minikube"
fi

# =============================================================================
# Verificación 11: Probar enrutamiento por host
# =============================================================================
echo ""
echo "11. Verificando enrutamiento por host (usando header Host)..."

if [ -n "$MINIKUBE_IP" ]; then
    FRONTEND_HOST_RESPONSE=$(curl -s --connect-timeout 5 -H "Host: frontend.local" "http://$MINIKUBE_IP" 2>/dev/null)
    BACKEND_HOST_RESPONSE=$(curl -s --connect-timeout 5 -H "Host: backend.local" "http://$MINIKUBE_IP" 2>/dev/null)

    FRONTEND_HOST_OK=false
    BACKEND_HOST_OK=false

    if echo "$FRONTEND_HOST_RESPONSE" | grep -q "Frontend"; then
        FRONTEND_HOST_OK=true
    fi

    if echo "$BACKEND_HOST_RESPONSE" | grep -q "Backend"; then
        BACKEND_HOST_OK=true
    fi

    if $FRONTEND_HOST_OK && $BACKEND_HOST_OK; then
        check_passed "Enrutamiento por host funciona (frontend.local y backend.local)"
    elif $FRONTEND_HOST_OK || $BACKEND_HOST_OK; then
        check_failed "Solo uno de los hosts funciona"
    else
        check_failed "Enrutamiento por host no funciona"
    fi
else
    check_failed "No se pudo probar enrutamiento por host"
fi

# =============================================================================
# Verificación 12: Verificar anotaciones del Ingress
# =============================================================================
echo ""
echo "12. Verificando anotaciones del Ingress..."

ANNOTATIONS=$(kubectl get ingress app-ingress -o jsonpath='{.metadata.annotations}' 2>/dev/null)

if echo "$ANNOTATIONS" | grep -q "rewrite-target"; then
    check_passed "Ingress tiene la anotación rewrite-target"
else
    check_failed "Ingress no tiene la anotación rewrite-target"
fi

# =============================================================================
# Verificación 13: Ver logs del Ingress Controller
# =============================================================================
echo ""
echo "13. Verificando acceso a logs del Ingress Controller..."

if kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=1 &> /dev/null; then
    check_passed "Puede acceder a logs del Ingress Controller"
else
    check_failed "No puede acceder a logs del Ingress Controller"
fi

# =============================================================================
# Verificación 14: IngressClass configurado
# =============================================================================
echo ""
echo "14. Verificando IngressClass..."

INGRESS_CLASS=$(kubectl get ingress app-ingress -o jsonpath='{.spec.ingressClassName}' 2>/dev/null)

if [ "$INGRESS_CLASS" == "nginx" ]; then
    check_passed "IngressClass está configurado correctamente (nginx)"
else
    check_failed "IngressClass no está configurado correctamente"
fi

# =============================================================================
# Verificación 15: Limpiar recursos
# =============================================================================
echo ""
echo "15. Verificando limpieza de recursos..."

kubectl delete ingress app-ingress app-ingress-host --ignore-not-found=true &> /dev/null
kubectl delete -f "$LAB_DIR/initial/apps.yaml" --ignore-not-found=true &> /dev/null

sleep 3

INGRESS_COUNT=$(kubectl get ingress --no-headers 2>/dev/null | wc -l)
DEPLOY_COUNT=$(kubectl get deployment -l 'app in (frontend, backend)' --no-headers 2>/dev/null | wc -l)

if [ "$INGRESS_COUNT" -eq 0 ] && [ "$DEPLOY_COUNT" -eq 0 ]; then
    check_passed "Recursos limpiados correctamente"
else
    check_failed "Algunos recursos no se eliminaron"
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
    echo -e "${GREEN}Has completado exitosamente el Lab 09: Ingress${NC}"
    echo ""
    echo "Has demostrado que puedes:"
    echo "  - Habilitar el Ingress Controller en Minikube"
    echo "  - Crear Ingress con enrutamiento basado en path"
    echo "  - Crear Ingress con enrutamiento basado en host"
    echo "  - Usar la anotación rewrite-target"
    echo "  - Verificar el funcionamiento del Ingress con curl"
    echo "  - Acceder a los logs del Ingress Controller"
    echo "  - Configurar IngressClass"
    echo "  - Limpiar recursos de Ingress"
    echo ""
    echo "Estás listo para continuar con el Lab 10: ConfigMaps"
else
    FAILED=$((CHECKS_TOTAL - CHECKS_PASSED))
    echo -e "${YELLOW}Algunas verificaciones fallaron ($FAILED de $CHECKS_TOTAL)${NC}"
    echo "Revisa los puntos marcados con ✗ y vuelve a intentar"
    echo ""
    echo "Posibles soluciones:"
    echo "  - Asegúrate de que Minikube está corriendo: minikube start"
    echo "  - Habilita el addon de Ingress: minikube addons enable ingress"
    echo "  - Espera a que el Ingress Controller esté Running"
    echo "  - Si curl falla, prueba: minikube tunnel (en otra terminal)"
    echo "  - Verifica que los archivos YAML existen en initial/"
    echo "  - Revisa el README.md para más detalles sobre cada paso"
fi

echo ""
echo "=============================================="
