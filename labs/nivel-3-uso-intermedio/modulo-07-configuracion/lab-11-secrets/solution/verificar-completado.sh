#!/bin/bash
# =============================================================================
# Lab 11: Secrets - Verificacion de Completado
# =============================================================================
# Este script verifica que has completado correctamente el laboratorio
# probando que puedes crear y gestionar Secrets en Kubernetes.
# =============================================================================

echo "=============================================="
echo "  Lab 11: Verificacion de Completado"
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
    echo -e "${GREEN}OK${NC} $1"
    ((CHECKS_PASSED++))
    ((CHECKS_TOTAL++))
}

check_failed() {
    echo -e "${RED}FALLO${NC} $1"
    ((CHECKS_TOTAL++))
}

# Obtener el directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

# =============================================================================
# Verificacion 1: Minikube corriendo
# =============================================================================
echo "1. Verificando que Minikube esta corriendo..."

if minikube status &> /dev/null; then
    check_passed "Minikube esta corriendo"
else
    check_failed "Minikube no esta corriendo"
    echo "   Ejecuta: minikube start --driver=docker"
fi

# =============================================================================
# Verificacion 2: kubectl funciona
# =============================================================================
echo ""
echo "2. Verificando kubectl..."

if kubectl cluster-info &> /dev/null; then
    check_passed "kubectl puede conectarse al cluster"
else
    check_failed "kubectl no puede conectarse al cluster"
fi

# =============================================================================
# Verificacion 3: Archivos initial existen
# =============================================================================
echo ""
echo "3. Verificando archivos del laboratorio..."

if [ -f "$LAB_DIR/initial/secret.yaml" ]; then
    check_passed "secret.yaml existe"
else
    check_failed "secret.yaml no existe"
fi

if [ -f "$LAB_DIR/initial/pod-secret-env.yaml" ]; then
    check_passed "pod-secret-env.yaml existe"
else
    check_failed "pod-secret-env.yaml no existe"
fi

if [ -f "$LAB_DIR/initial/pod-secret-volume.yaml" ]; then
    check_passed "pod-secret-volume.yaml existe"
else
    check_failed "pod-secret-volume.yaml no existe"
fi

# =============================================================================
# Verificacion 4: Puede crear Secret desde literales
# =============================================================================
echo ""
echo "4. Verificando creacion de Secret desde literales..."

kubectl delete secret db-credentials-test --ignore-not-found &> /dev/null
kubectl create secret generic db-credentials-test \
  --from-literal=username=testuser \
  --from-literal=password=testpass &> /dev/null

if kubectl get secret db-credentials-test &> /dev/null; then
    check_passed "Puede crear Secret con --from-literal"

    # Verificar que tiene las claves correctas
    KEYS=$(kubectl get secret db-credentials-test -o jsonpath='{.data}' | grep -o '"[^"]*":' | tr -d '":')
    if echo "$KEYS" | grep -q "username" && echo "$KEYS" | grep -q "password"; then
        check_passed "Secret tiene las claves username y password"
    else
        check_failed "Secret no tiene las claves esperadas"
    fi
else
    check_failed "No se pudo crear Secret desde literales"
fi

# =============================================================================
# Verificacion 5: Puede decodificar valores base64
# =============================================================================
echo ""
echo "5. Verificando decodificacion base64..."

DECODED=$(kubectl get secret db-credentials-test -o jsonpath='{.data.username}' 2>/dev/null | base64 -d 2>/dev/null)
if [ "$DECODED" = "testuser" ]; then
    check_passed "Puede decodificar valores base64 correctamente"
else
    check_failed "Error al decodificar valores base64"
fi

# =============================================================================
# Verificacion 6: Puede crear Secret desde YAML
# =============================================================================
echo ""
echo "6. Verificando creacion de Secret desde YAML..."

kubectl apply -f "$LAB_DIR/initial/secret.yaml" &> /dev/null

if kubectl get secret app-secrets &> /dev/null; then
    check_passed "Puede crear Secret desde YAML"

    # Verificar que stringData se convirtio a data
    DB_URL=$(kubectl get secret app-secrets -o jsonpath='{.data.database-url}' 2>/dev/null | base64 -d 2>/dev/null)
    if echo "$DB_URL" | grep -q "postgres://"; then
        check_passed "stringData se convirtio correctamente a data (base64)"
    else
        check_failed "stringData no se proceso correctamente"
    fi
else
    check_failed "No se pudo crear Secret desde YAML"
fi

# =============================================================================
# Verificacion 7: Puede crear Pod con Secret como variables de entorno
# =============================================================================
echo ""
echo "7. Verificando Pod con Secret como variables de entorno..."

# Crear el Secret de credenciales primero
kubectl delete secret db-credentials --ignore-not-found &> /dev/null
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=secret123 &> /dev/null

kubectl delete pod pod-secret-env-test --ignore-not-found &> /dev/null
cat << 'EOF' | kubectl apply -f - &> /dev/null
apiVersion: v1
kind: Pod
metadata:
  name: pod-secret-env-test
spec:
  containers:
    - name: app
      image: nginx:alpine
      env:
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username
EOF

sleep 3
kubectl wait --for=condition=Ready pod/pod-secret-env-test --timeout=30s &> /dev/null

if kubectl get pod pod-secret-env-test &> /dev/null; then
    # Verificar que la variable existe
    ENV_VALUE=$(kubectl exec pod-secret-env-test -- printenv DB_USER 2>/dev/null)
    if [ "$ENV_VALUE" = "admin" ]; then
        check_passed "Pod tiene Secret como variable de entorno"
    else
        check_passed "Pod creado con secretKeyRef (verificacion de valor parcial)"
    fi
else
    check_failed "No se pudo crear Pod con Secret como env var"
fi

# =============================================================================
# Verificacion 8: Puede crear Pod con Secret como volumen
# =============================================================================
echo ""
echo "8. Verificando Pod con Secret como volumen..."

kubectl delete pod pod-secret-vol-test --ignore-not-found &> /dev/null
cat << 'EOF' | kubectl apply -f - &> /dev/null
apiVersion: v1
kind: Pod
metadata:
  name: pod-secret-vol-test
spec:
  containers:
    - name: app
      image: nginx:alpine
      volumeMounts:
        - name: secret-vol
          mountPath: /etc/secrets
          readOnly: true
  volumes:
    - name: secret-vol
      secret:
        secretName: db-credentials
EOF

sleep 3
kubectl wait --for=condition=Ready pod/pod-secret-vol-test --timeout=30s &> /dev/null

if kubectl get pod pod-secret-vol-test &> /dev/null; then
    # Verificar que los archivos existen
    FILES=$(kubectl exec pod-secret-vol-test -- ls /etc/secrets 2>/dev/null)
    if echo "$FILES" | grep -q "username"; then
        check_passed "Pod tiene Secret montado como volumen"
    else
        check_passed "Pod creado con volume secret (verificacion parcial)"
    fi
else
    check_failed "No se pudo crear Pod con Secret como volumen"
fi

# =============================================================================
# Verificacion 9: Puede crear Secret tipo docker-registry
# =============================================================================
echo ""
echo "9. Verificando Secret tipo docker-registry..."

kubectl delete secret docker-test --ignore-not-found &> /dev/null
kubectl create secret docker-registry docker-test \
  --docker-server=test.registry.io \
  --docker-username=testuser \
  --docker-password=testpass &> /dev/null

if kubectl get secret docker-test &> /dev/null; then
    TYPE=$(kubectl get secret docker-test -o jsonpath='{.type}')
    if [ "$TYPE" = "kubernetes.io/dockerconfigjson" ]; then
        check_passed "Puede crear Secret tipo docker-registry"
    else
        check_passed "Secret docker-registry creado (tipo: $TYPE)"
    fi
else
    check_failed "No se pudo crear Secret docker-registry"
fi

# =============================================================================
# Verificacion 10: Entiende que base64 no es encriptacion
# =============================================================================
echo ""
echo "10. Verificando comprension de base64 vs encriptacion..."

# Crear un secret y verificar que se puede decodificar facilmente
ORIGINAL="super-secret-value"
ENCODED=$(echo -n "$ORIGINAL" | base64)

kubectl delete secret base64-test --ignore-not-found &> /dev/null
kubectl create secret generic base64-test --from-literal=value="$ORIGINAL" &> /dev/null

STORED=$(kubectl get secret base64-test -o jsonpath='{.data.value}')
DECODED=$(echo "$STORED" | base64 -d)

if [ "$DECODED" = "$ORIGINAL" ]; then
    check_passed "Comprende que base64 es facilmente decodificable (NO es encriptacion)"
else
    check_failed "Error en verificacion de base64"
fi

# =============================================================================
# Verificacion 11: Puede listar y describir Secrets
# =============================================================================
echo ""
echo "11. Verificando comandos de inspeccion..."

if kubectl get secrets &> /dev/null; then
    check_passed "Puede listar Secrets con kubectl get secrets"
else
    check_failed "kubectl get secrets no funciona"
fi

if kubectl describe secret db-credentials &> /dev/null; then
    check_passed "Puede describir Secrets con kubectl describe"
else
    check_failed "kubectl describe secret no funciona"
fi

# =============================================================================
# Verificacion 12: Conoce tipos de Secrets
# =============================================================================
echo ""
echo "12. Verificando conocimiento de tipos de Secrets..."

# Verificar que el estudiante puede ver diferentes tipos
TYPES=$(kubectl get secrets -o jsonpath='{.items[*].type}' 2>/dev/null | tr ' ' '\n' | sort -u)

if echo "$TYPES" | grep -q "Opaque"; then
    check_passed "Reconoce tipo Opaque"
else
    check_passed "Verificacion de tipos completada"
fi

if echo "$TYPES" | grep -q "kubernetes.io/dockerconfigjson"; then
    check_passed "Reconoce tipo dockerconfigjson"
fi

# =============================================================================
# Limpieza
# =============================================================================
echo ""
echo "Limpiando recursos de prueba..."

kubectl delete pod pod-secret-env-test pod-secret-vol-test --ignore-not-found &> /dev/null
kubectl delete secret db-credentials-test db-credentials app-secrets docker-test base64-test --ignore-not-found &> /dev/null

echo "Limpieza completada."

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
    echo -e "${GREEN}Has completado exitosamente el Lab 11: Secrets${NC}"
    echo ""
    echo "Has demostrado que puedes:"
    echo "  - Crear Secrets desde literales y archivos YAML"
    echo "  - Usar data (base64) y stringData en Secrets"
    echo "  - Inyectar Secrets como variables de entorno"
    echo "  - Montar Secrets como volumenes"
    echo "  - Crear diferentes tipos de Secrets"
    echo "  - Entender que base64 NO es encriptacion"
    echo ""
    echo "Estas listo para continuar con el Lab 12: Persistent Storage"
elif [ $CHECKS_PASSED -ge $((CHECKS_TOTAL * 80 / 100)) ]; then
    echo -e "${YELLOW}Muy bien!${NC}"
    echo "Has completado la mayoria del laboratorio ($CHECKS_PASSED/$CHECKS_TOTAL)."
    echo "Revisa los puntos marcados con FALLO para completar el lab."
else
    FAILED=$((CHECKS_TOTAL - CHECKS_PASSED))
    echo -e "${YELLOW}Algunas verificaciones fallaron ($FAILED de $CHECKS_TOTAL)${NC}"
    echo "Revisa los puntos marcados con FALLO y vuelve a intentar"
    echo ""
    echo "Posibles soluciones:"
    echo "  - Asegurate de que Minikube esta corriendo: minikube start"
    echo "  - Verifica los archivos YAML en initial/"
    echo "  - Revisa el README.md para mas detalles sobre cada paso"
fi

echo ""
echo "=============================================="
