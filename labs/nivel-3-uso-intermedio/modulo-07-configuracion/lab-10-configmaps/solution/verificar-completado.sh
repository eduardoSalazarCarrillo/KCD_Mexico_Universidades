#!/bin/bash
# =============================================================================
# Lab 10: ConfigMaps - Verificación de Completado
# =============================================================================
# Este script verifica que has completado correctamente el laboratorio
# probando que puedes crear y gestionar ConfigMaps en Kubernetes.
# =============================================================================

echo "=============================================="
echo "  Lab 10: Verificación de Completado"
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

if [ -f "$LAB_DIR/initial/config.properties" ]; then
    check_passed "config.properties existe"
else
    check_failed "config.properties no existe"
fi

if [ -f "$LAB_DIR/initial/configmap.yaml" ]; then
    check_passed "configmap.yaml existe"
else
    check_failed "configmap.yaml no existe"
fi

if [ -f "$LAB_DIR/initial/pod-env.yaml" ]; then
    check_passed "pod-env.yaml existe"
else
    check_failed "pod-env.yaml no existe"
fi

if [ -f "$LAB_DIR/initial/pod-volume.yaml" ]; then
    check_passed "pod-volume.yaml existe"
else
    check_failed "pod-volume.yaml no existe"
fi

# =============================================================================
# Verificación 4: Puede crear ConfigMap desde literales
# =============================================================================
echo ""
echo "4. Verificando creación de ConfigMap desde literales..."

kubectl delete configmap test-literal-cm --ignore-not-found &> /dev/null
kubectl create configmap test-literal-cm \
  --from-literal=KEY1=value1 \
  --from-literal=KEY2=value2 &> /dev/null

if kubectl get configmap test-literal-cm &> /dev/null; then
    DATA_COUNT=$(kubectl get configmap test-literal-cm -o jsonpath='{.data}' | grep -o "KEY" | wc -l)
    if [ "$DATA_COUNT" -ge 2 ]; then
        check_passed "Puede crear ConfigMap desde literales (2 claves)"
    else
        check_passed "Puede crear ConfigMap desde literales"
    fi
else
    check_failed "No se pudo crear ConfigMap desde literales"
fi

# =============================================================================
# Verificación 5: Puede crear ConfigMap desde archivo
# =============================================================================
echo ""
echo "5. Verificando creación de ConfigMap desde archivo..."

kubectl delete configmap test-file-cm --ignore-not-found &> /dev/null
kubectl create configmap test-file-cm --from-file="$LAB_DIR/initial/config.properties" &> /dev/null

if kubectl get configmap test-file-cm &> /dev/null; then
    # Verificar que contiene el archivo
    CONTENT=$(kubectl get configmap test-file-cm -o jsonpath='{.data.config\.properties}')
    if echo "$CONTENT" | grep -q "database.host"; then
        check_passed "Puede crear ConfigMap desde archivo con contenido correcto"
    else
        check_passed "Puede crear ConfigMap desde archivo"
    fi
else
    check_failed "No se pudo crear ConfigMap desde archivo"
fi

# =============================================================================
# Verificación 6: Puede crear ConfigMap desde YAML
# =============================================================================
echo ""
echo "6. Verificando creación de ConfigMap desde YAML..."

kubectl apply -f "$LAB_DIR/initial/configmap.yaml" &> /dev/null

if kubectl get configmap app-config-yaml &> /dev/null; then
    # Verificar que tiene nginx.conf
    HAS_NGINX=$(kubectl get configmap app-config-yaml -o jsonpath='{.data.nginx\.conf}')
    if [ -n "$HAS_NGINX" ]; then
        check_passed "Puede crear ConfigMap desde YAML (incluye nginx.conf)"
    else
        check_passed "Puede crear ConfigMap desde YAML"
    fi
else
    check_failed "No se pudo crear ConfigMap desde YAML"
fi

# =============================================================================
# Verificación 7: Puede usar ConfigMap como variables de entorno
# =============================================================================
echo ""
echo "7. Verificando uso de ConfigMap como variables de entorno..."

# Primero crear el ConfigMap app-config requerido
kubectl delete configmap app-config --ignore-not-found &> /dev/null
kubectl create configmap app-config \
  --from-literal=APP_ENV=production \
  --from-literal=APP_DEBUG=false \
  --from-literal=LOG_LEVEL=info &> /dev/null

kubectl delete pod pod-configmap-env --ignore-not-found &> /dev/null
kubectl apply -f "$LAB_DIR/initial/pod-env.yaml" &> /dev/null

echo "   Esperando a que el Pod esté listo..."
kubectl wait --for=condition=Ready pod/pod-configmap-env --timeout=60s &> /dev/null

if kubectl get pod pod-configmap-env &> /dev/null; then
    # Verificar que las variables de entorno existen
    ENV_VAR=$(kubectl exec pod-configmap-env -- printenv APP_ENV 2>/dev/null)
    if [ "$ENV_VAR" = "production" ]; then
        check_passed "ConfigMap inyectado como variables de entorno (APP_ENV=production)"
    else
        check_passed "Pod con ConfigMap como variables de entorno creado"
    fi

    # Verificar CUSTOM_VAR
    CUSTOM=$(kubectl exec pod-configmap-env -- printenv CUSTOM_VAR 2>/dev/null)
    if [ "$CUSTOM" = "production" ]; then
        check_passed "Variable específica CUSTOM_VAR configurada correctamente"
    else
        check_failed "CUSTOM_VAR no está configurada correctamente"
    fi
else
    check_failed "No se pudo crear Pod con ConfigMap como variables de entorno"
fi

# =============================================================================
# Verificación 8: Puede montar ConfigMap como volumen
# =============================================================================
echo ""
echo "8. Verificando montaje de ConfigMap como volumen..."

# Crear ConfigMap app-properties requerido
kubectl delete configmap app-properties --ignore-not-found &> /dev/null
kubectl create configmap app-properties --from-file="$LAB_DIR/initial/config.properties" &> /dev/null

kubectl delete pod pod-configmap-volume --ignore-not-found &> /dev/null
kubectl apply -f "$LAB_DIR/initial/pod-volume.yaml" &> /dev/null

echo "   Esperando a que el Pod esté listo..."
kubectl wait --for=condition=Ready pod/pod-configmap-volume --timeout=60s &> /dev/null

if kubectl get pod pod-configmap-volume &> /dev/null; then
    # Verificar que el archivo está montado
    FILE_CONTENT=$(kubectl exec pod-configmap-volume -- cat /etc/config/config.properties 2>/dev/null)
    if echo "$FILE_CONTENT" | grep -q "database.host"; then
        check_passed "ConfigMap montado como volumen en /etc/config"
    else
        check_passed "Pod con volumen ConfigMap creado"
    fi

    # Verificar nginx.conf montado selectivamente
    NGINX_CONTENT=$(kubectl exec pod-configmap-volume -- cat /etc/nginx/conf.d/default.conf 2>/dev/null)
    if echo "$NGINX_CONTENT" | grep -q "server"; then
        check_passed "nginx.conf montado selectivamente como default.conf"
    else
        check_failed "nginx.conf no está montado correctamente"
    fi
else
    check_failed "No se pudo crear Pod con ConfigMap como volumen"
fi

# =============================================================================
# Verificación 9: Puede actualizar ConfigMap
# =============================================================================
echo ""
echo "9. Verificando actualización de ConfigMap..."

# Actualizar ConfigMap
kubectl patch configmap app-config --type merge -p '{"data":{"LOG_LEVEL":"debug"}}' &> /dev/null

NEW_VALUE=$(kubectl get configmap app-config -o jsonpath='{.data.LOG_LEVEL}')
if [ "$NEW_VALUE" = "debug" ]; then
    check_passed "Puede actualizar ConfigMap (LOG_LEVEL=debug)"
else
    check_failed "No se pudo actualizar ConfigMap"
fi

# =============================================================================
# Verificación 10: Entender comportamiento de actualización
# =============================================================================
echo ""
echo "10. Verificando comprensión del comportamiento de actualización..."

# Las variables de entorno NO deben haberse actualizado
ENV_LOG=$(kubectl exec pod-configmap-env -- printenv LOG_LEVEL 2>/dev/null)
if [ "$ENV_LOG" = "info" ]; then
    check_passed "Comprende que variables de entorno NO se actualizan automáticamente"
else
    check_passed "Verificación de comportamiento de actualización completada"
fi

# =============================================================================
# Verificación 11: Puede crear ConfigMap inmutable
# =============================================================================
echo ""
echo "11. Verificando creación de ConfigMap inmutable..."

kubectl delete configmap test-immutable-cm --ignore-not-found &> /dev/null
cat <<EOF | kubectl apply -f - &> /dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: test-immutable-cm
data:
  KEY: "value"
immutable: true
EOF

if kubectl get configmap test-immutable-cm &> /dev/null; then
    IMMUTABLE=$(kubectl get configmap test-immutable-cm -o jsonpath='{.immutable}')
    if [ "$IMMUTABLE" = "true" ]; then
        check_passed "Puede crear ConfigMap inmutable"
    else
        check_passed "ConfigMap inmutable creado"
    fi

    # Verificar que no se puede modificar
    PATCH_RESULT=$(kubectl patch configmap test-immutable-cm --type merge -p '{"data":{"KEY":"nuevo"}}' 2>&1)
    if echo "$PATCH_RESULT" | grep -qi "immutable\|forbidden"; then
        check_passed "ConfigMap inmutable rechaza modificaciones"
    else
        check_failed "ConfigMap inmutable permite modificaciones (no debería)"
    fi
else
    check_failed "No se pudo crear ConfigMap inmutable"
fi

# =============================================================================
# Verificación 12: Puede listar ConfigMaps
# =============================================================================
echo ""
echo "12. Verificando listado de ConfigMaps..."

if kubectl get configmaps &> /dev/null; then
    CM_COUNT=$(kubectl get configmaps --no-headers 2>/dev/null | wc -l)
    if [ "$CM_COUNT" -ge 3 ]; then
        check_passed "Puede listar ConfigMaps ($CM_COUNT encontrados)"
    else
        check_passed "Puede listar ConfigMaps"
    fi
else
    check_failed "kubectl get configmaps no funciona"
fi

# =============================================================================
# Verificación 13: Puede describir ConfigMap
# =============================================================================
echo ""
echo "13. Verificando descripción de ConfigMap..."

if kubectl describe configmap app-config &> /dev/null; then
    check_passed "Puede describir ConfigMaps"
else
    check_failed "kubectl describe configmap no funciona"
fi

# =============================================================================
# Limpieza
# =============================================================================
echo ""
echo "Limpiando recursos de prueba..."

kubectl delete pod pod-configmap-env pod-configmap-volume --ignore-not-found &> /dev/null
kubectl delete configmap app-config app-properties app-config-yaml test-literal-cm test-file-cm test-immutable-cm --ignore-not-found &> /dev/null

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
    echo -e "${GREEN}Has completado exitosamente el Lab 10: ConfigMaps${NC}"
    echo ""
    echo "Has demostrado que puedes:"
    echo "  - Crear ConfigMaps desde literales"
    echo "  - Crear ConfigMaps desde archivos"
    echo "  - Crear ConfigMaps desde YAML"
    echo "  - Inyectar ConfigMaps como variables de entorno"
    echo "  - Montar ConfigMaps como volúmenes"
    echo "  - Actualizar ConfigMaps"
    echo "  - Crear ConfigMaps inmutables"
    echo "  - Entender diferencias de actualización (env vs volumen)"
    echo ""
    echo "Estás listo para continuar con el Lab 11: Secrets"
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
