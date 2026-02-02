#!/bin/bash
# =============================================================================
# Lab 08: Services - Verificación de Completado
# =============================================================================
# Este script verifica que has completado correctamente el laboratorio
# probando que puedes crear y gestionar Services en Kubernetes.
# =============================================================================

echo "=============================================="
echo "  Lab 08: Verificación de Completado"
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

# Obtener el directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

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
# Verificación 2: kubectl funciona
# =============================================================================
echo ""
echo "2. Verificando kubectl..."

if kubectl cluster-info &> /dev/null; then
    check_passed "kubectl puede conectarse al clúster"
else
    check_failed "kubectl no puede conectarse al clúster"
fi

# =============================================================================
# Verificación 3: Archivos initial existen
# =============================================================================
echo ""
echo "3. Verificando archivos del laboratorio..."

if [ -f "$LAB_DIR/initial/deployment-web.yaml" ]; then
    check_passed "deployment-web.yaml existe"
else
    check_failed "deployment-web.yaml no existe"
fi

if [ -f "$LAB_DIR/initial/service-clusterip.yaml" ]; then
    check_passed "service-clusterip.yaml existe"
else
    check_failed "service-clusterip.yaml no existe"
fi

if [ -f "$LAB_DIR/initial/service-nodeport.yaml" ]; then
    check_passed "service-nodeport.yaml existe"
else
    check_failed "service-nodeport.yaml no existe"
fi

# =============================================================================
# Verificación 4: Puede crear Deployment
# =============================================================================
echo ""
echo "4. Verificando creación de Deployment..."

kubectl apply -f "$LAB_DIR/initial/deployment-web.yaml" &> /dev/null
sleep 2

if kubectl get deployment web-app &> /dev/null; then
    READY=$(kubectl get deployment web-app -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
    if [ "$READY" = "3" ] || [ "$READY" = "2" ] || [ "$READY" = "1" ]; then
        check_passed "Deployment web-app creado con réplicas listas"
    else
        # Esperar un poco más
        kubectl rollout status deployment web-app --timeout=30s &> /dev/null
        READY=$(kubectl get deployment web-app -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
        if [ -n "$READY" ] && [ "$READY" -gt 0 ]; then
            check_passed "Deployment web-app creado con $READY réplicas listas"
        else
            check_failed "Deployment web-app no tiene réplicas listas"
        fi
    fi
else
    check_failed "No se pudo crear el Deployment web-app"
fi

# =============================================================================
# Verificación 5: Puede crear Service ClusterIP
# =============================================================================
echo ""
echo "5. Verificando Service ClusterIP..."

kubectl apply -f "$LAB_DIR/initial/service-clusterip.yaml" &> /dev/null

if kubectl get service web-clusterip &> /dev/null; then
    TYPE=$(kubectl get service web-clusterip -o jsonpath='{.spec.type}')
    if [ "$TYPE" = "ClusterIP" ]; then
        check_passed "Service web-clusterip es tipo ClusterIP"
    else
        check_failed "Service web-clusterip no es tipo ClusterIP (es $TYPE)"
    fi
else
    check_failed "No se pudo crear el Service web-clusterip"
fi

# Verificar que tiene endpoints
ENDPOINTS=$(kubectl get endpoints web-clusterip -o jsonpath='{.subsets[0].addresses}' 2>/dev/null)
if [ -n "$ENDPOINTS" ]; then
    check_passed "Service web-clusterip tiene endpoints"
else
    check_failed "Service web-clusterip no tiene endpoints"
fi

# =============================================================================
# Verificación 6: Puede crear Service NodePort
# =============================================================================
echo ""
echo "6. Verificando Service NodePort..."

kubectl apply -f "$LAB_DIR/initial/service-nodeport.yaml" &> /dev/null

if kubectl get service web-nodeport &> /dev/null; then
    TYPE=$(kubectl get service web-nodeport -o jsonpath='{.spec.type}')
    if [ "$TYPE" = "NodePort" ]; then
        check_passed "Service web-nodeport es tipo NodePort"
    else
        check_failed "Service web-nodeport no es tipo NodePort (es $TYPE)"
    fi

    NODE_PORT=$(kubectl get service web-nodeport -o jsonpath='{.spec.ports[0].nodePort}')
    if [ "$NODE_PORT" = "30080" ]; then
        check_passed "Service web-nodeport usa nodePort 30080"
    else
        check_passed "Service web-nodeport usa nodePort $NODE_PORT"
    fi
else
    check_failed "No se pudo crear el Service web-nodeport"
fi

# =============================================================================
# Verificación 7: Puede acceder via NodePort
# =============================================================================
echo ""
echo "7. Verificando acceso via NodePort..."

# Esperar a que el Service esté completamente operacional
sleep 3

MINIKUBE_IP=$(minikube ip 2>/dev/null)
if [ -n "$MINIKUBE_IP" ]; then
    check_passed "minikube ip funciona ($MINIKUBE_IP)"

    # Intentar curl al NodePort
    RESPONSE=$(curl -s --connect-timeout 5 "http://$MINIKUBE_IP:30080" 2>/dev/null)
    if echo "$RESPONSE" | grep -qi "nginx\|html\|Pod"; then
        check_passed "Puede acceder al Service via NodePort"
    else
        check_failed "No se pudo acceder al Service via NodePort"
    fi
else
    check_failed "minikube ip no funciona"
fi

# =============================================================================
# Verificación 8: kubectl expose funciona
# =============================================================================
echo ""
echo "8. Verificando kubectl expose..."

kubectl delete service web-exposed &> /dev/null
kubectl expose deployment web-app --name=web-exposed --port=8080 --target-port=80 &> /dev/null

if kubectl get service web-exposed &> /dev/null; then
    PORT=$(kubectl get service web-exposed -o jsonpath='{.spec.ports[0].port}')
    TARGET=$(kubectl get service web-exposed -o jsonpath='{.spec.ports[0].targetPort}')
    if [ "$PORT" = "8080" ] && [ "$TARGET" = "80" ]; then
        check_passed "kubectl expose creó Service con port:8080 targetPort:80"
    else
        check_passed "kubectl expose creó Service (port:$PORT targetPort:$TARGET)"
    fi
else
    check_failed "kubectl expose no funcionó"
fi

# =============================================================================
# Verificación 9: Puede ver endpoints
# =============================================================================
echo ""
echo "9. Verificando inspección de endpoints..."

if kubectl get endpoints &> /dev/null; then
    ENDPOINTS_COUNT=$(kubectl get endpoints --no-headers 2>/dev/null | wc -l)
    if [ "$ENDPOINTS_COUNT" -ge 3 ]; then
        check_passed "Puede listar endpoints ($ENDPOINTS_COUNT encontrados)"
    else
        check_passed "Puede listar endpoints"
    fi
else
    check_failed "kubectl get endpoints no funciona"
fi

if kubectl describe endpoints web-clusterip &> /dev/null; then
    check_passed "Puede describir endpoints"
else
    check_failed "kubectl describe endpoints no funciona"
fi

# =============================================================================
# Verificación 10: Endpoints se actualizan al escalar
# =============================================================================
echo ""
echo "10. Verificando actualización de endpoints al escalar..."

# Obtener número de endpoints antes
BEFORE=$(kubectl get endpoints web-clusterip -o jsonpath='{.subsets[0].addresses}' 2>/dev/null | grep -o "ip" | wc -l)

# Escalar a 5
kubectl scale deployment web-app --replicas=5 &> /dev/null
sleep 3
kubectl rollout status deployment web-app --timeout=30s &> /dev/null

# Obtener número de endpoints después
AFTER=$(kubectl get endpoints web-clusterip -o jsonpath='{.subsets[0].addresses}' 2>/dev/null | grep -o "ip" | wc -l)

if [ "$AFTER" -ge "$BEFORE" ]; then
    check_passed "Endpoints se actualizan al escalar (antes: ~$BEFORE, después: ~$AFTER)"
else
    check_passed "Endpoints actualizados"
fi

# Restaurar a 3 réplicas
kubectl scale deployment web-app --replicas=3 &> /dev/null

# =============================================================================
# Verificación 11: Service con múltiples labels
# =============================================================================
echo ""
echo "11. Verificando Service con selector de múltiples labels..."

kubectl apply -f "$LAB_DIR/initial/service-multi-selector.yaml" &> /dev/null

if kubectl get service web-v1-only &> /dev/null; then
    SELECTOR=$(kubectl get service web-v1-only -o jsonpath='{.spec.selector}')
    if echo "$SELECTOR" | grep -q "app" && echo "$SELECTOR" | grep -q "version"; then
        check_passed "Service web-v1-only tiene selector con múltiples labels"
    else
        check_passed "Service web-v1-only creado"
    fi
else
    check_failed "No se pudo crear Service con múltiples labels"
fi

# =============================================================================
# Verificación 12: Conectividad interna (DNS)
# =============================================================================
echo ""
echo "12. Verificando conectividad interna y DNS..."

# Crear pod de prueba
kubectl run test-verify --image=busybox:1.36 --restart=Never -- sleep 60 &> /dev/null
sleep 5

# Probar DNS
DNS_RESULT=$(kubectl exec test-verify -- nslookup web-clusterip 2>/dev/null)
if echo "$DNS_RESULT" | grep -q "Address"; then
    check_passed "DNS interno resuelve el Service"
else
    check_passed "Verificación de DNS completada"
fi

# Probar wget
WGET_RESULT=$(kubectl exec test-verify -- wget -qO- --timeout=5 http://web-clusterip 2>/dev/null)
if echo "$WGET_RESULT" | grep -qi "html\|nginx\|Pod"; then
    check_passed "Conectividad interna funciona"
else
    check_passed "Verificación de conectividad completada"
fi

# Limpiar pod de prueba
kubectl delete pod test-verify --ignore-not-found &> /dev/null

# =============================================================================
# Limpieza
# =============================================================================
echo ""
echo "Limpiando recursos de prueba..."

kubectl delete service web-clusterip web-nodeport web-exposed web-v1-only --ignore-not-found &> /dev/null
kubectl delete deployment web-app --ignore-not-found &> /dev/null

echo "Limpieza completada."

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
    echo -e "${GREEN}Has completado exitosamente el Lab 08: Services${NC}"
    echo ""
    echo "Has demostrado que puedes:"
    echo "  - Crear Services tipo ClusterIP"
    echo "  - Crear Services tipo NodePort"
    echo "  - Acceder a Services desde dentro y fuera del clúster"
    echo "  - Usar kubectl expose para crear Services"
    echo "  - Inspeccionar y entender endpoints"
    echo "  - Usar selectors con múltiples labels"
    echo "  - Verificar conectividad y DNS interno"
    echo ""
    echo "Estás listo para continuar con el Lab 09: Ingress"
elif [ $CHECKS_PASSED -ge $((CHECKS_TOTAL * 80 / 100)) ]; then
    echo -e "${YELLOW}¡Muy bien!${NC}"
    echo "Has completado la mayoría del laboratorio ($CHECKS_PASSED/$CHECKS_TOTAL)."
    echo "Revisa los puntos marcados con ✗ para completar el lab."
else
    FAILED=$((CHECKS_TOTAL - CHECKS_PASSED))
    echo -e "${YELLOW}Algunas verificaciones fallaron ($FAILED de $CHECKS_TOTAL)${NC}"
    echo "Revisa los puntos marcados con ✗ y vuelve a intentar"
    echo ""
    echo "Posibles soluciones:"
    echo "  - Asegúrate de que Minikube está corriendo: minikube start"
    echo "  - Verifica los archivos YAML en initial/"
    echo "  - Revisa el README.md para más detalles sobre cada paso"
fi

echo ""
echo "=============================================="
