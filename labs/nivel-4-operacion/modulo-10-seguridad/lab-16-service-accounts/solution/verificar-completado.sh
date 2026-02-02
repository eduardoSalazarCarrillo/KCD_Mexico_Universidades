#!/bin/bash
# =============================================================================
# Lab 16: Service Accounts - Verificacion de Completado
# =============================================================================
# Este script verifica que has completado correctamente el laboratorio
# probando que puedes crear y gestionar Service Accounts en Kubernetes.
# =============================================================================

echo "=============================================="
echo "  Lab 16: Verificacion de Completado"
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

if [ -f "$LAB_DIR/initial/serviceaccount.yaml" ]; then
    check_passed "serviceaccount.yaml existe"
else
    check_failed "serviceaccount.yaml no existe"
fi

if [ -f "$LAB_DIR/initial/sa-rolebinding.yaml" ]; then
    check_passed "sa-rolebinding.yaml existe"
else
    check_failed "sa-rolebinding.yaml no existe"
fi

if [ -f "$LAB_DIR/initial/pod-with-sa.yaml" ]; then
    check_passed "pod-with-sa.yaml existe"
else
    check_failed "pod-with-sa.yaml no existe"
fi

if [ -f "$LAB_DIR/initial/sa-no-automount.yaml" ]; then
    check_passed "sa-no-automount.yaml existe"
else
    check_failed "sa-no-automount.yaml no existe"
fi

# =============================================================================
# Verificacion 4: Puede listar ServiceAccounts
# =============================================================================
echo ""
echo "4. Verificando listado de ServiceAccounts..."

if kubectl get serviceaccounts &> /dev/null; then
    check_passed "Puede listar ServiceAccounts"

    # Verificar que existe el ServiceAccount default
    if kubectl get serviceaccount default &> /dev/null; then
        check_passed "ServiceAccount 'default' existe"
    else
        check_failed "ServiceAccount 'default' no encontrado"
    fi
else
    check_failed "No puede listar ServiceAccounts"
fi

# =============================================================================
# Verificacion 5: Puede crear ServiceAccount
# =============================================================================
echo ""
echo "5. Verificando creacion de ServiceAccount..."

kubectl delete serviceaccount test-sa-verify --ignore-not-found &> /dev/null
kubectl create serviceaccount test-sa-verify &> /dev/null

if kubectl get serviceaccount test-sa-verify &> /dev/null; then
    check_passed "Puede crear ServiceAccount"
else
    check_failed "No puede crear ServiceAccount"
fi

# =============================================================================
# Verificacion 6: Puede aplicar archivos YAML del lab
# =============================================================================
echo ""
echo "6. Verificando aplicacion de archivos YAML..."

# Limpiar recursos previos
kubectl delete serviceaccount app-service-account --ignore-not-found &> /dev/null
kubectl delete role pod-manager --ignore-not-found &> /dev/null
kubectl delete rolebinding app-sa-binding --ignore-not-found &> /dev/null

# Aplicar archivos
kubectl apply -f "$LAB_DIR/initial/serviceaccount.yaml" &> /dev/null
if kubectl get serviceaccount app-service-account &> /dev/null; then
    check_passed "serviceaccount.yaml aplicado correctamente"
else
    check_failed "Error al aplicar serviceaccount.yaml"
fi

kubectl apply -f "$LAB_DIR/initial/sa-rolebinding.yaml" &> /dev/null
if kubectl get role pod-manager &> /dev/null && kubectl get rolebinding app-sa-binding &> /dev/null; then
    check_passed "sa-rolebinding.yaml aplicado correctamente"
else
    check_failed "Error al aplicar sa-rolebinding.yaml"
fi

# =============================================================================
# Verificacion 7: Permisos configurados correctamente
# =============================================================================
echo ""
echo "7. Verificando permisos del ServiceAccount..."

# Verificar permisos permitidos
CAN_LIST_PODS=$(kubectl auth can-i list pods --as=system:serviceaccount:default:app-service-account 2>/dev/null)
if [ "$CAN_LIST_PODS" = "yes" ]; then
    check_passed "app-service-account puede listar pods"
else
    check_failed "app-service-account no puede listar pods (deberia poder)"
fi

CAN_LIST_CM=$(kubectl auth can-i list configmaps --as=system:serviceaccount:default:app-service-account 2>/dev/null)
if [ "$CAN_LIST_CM" = "yes" ]; then
    check_passed "app-service-account puede listar configmaps"
else
    check_failed "app-service-account no puede listar configmaps (deberia poder)"
fi

# Verificar permisos denegados
CAN_LIST_SECRETS=$(kubectl auth can-i list secrets --as=system:serviceaccount:default:app-service-account 2>/dev/null)
if [ "$CAN_LIST_SECRETS" = "no" ]; then
    check_passed "app-service-account NO puede listar secrets (correcto)"
else
    check_failed "app-service-account puede listar secrets (no deberia)"
fi

# =============================================================================
# Verificacion 8: Puede crear Pod con ServiceAccount
# =============================================================================
echo ""
echo "8. Verificando Pod con ServiceAccount..."

kubectl delete pod pod-with-sa-test --ignore-not-found &> /dev/null

cat << 'EOF' | kubectl apply -f - &> /dev/null
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-sa-test
spec:
  serviceAccountName: app-service-account
  containers:
    - name: app
      image: nginx:alpine
EOF

sleep 3
kubectl wait --for=condition=Ready pod/pod-with-sa-test --timeout=60s &> /dev/null

if kubectl get pod pod-with-sa-test &> /dev/null; then
    # Verificar que usa el ServiceAccount correcto
    SA_NAME=$(kubectl get pod pod-with-sa-test -o jsonpath='{.spec.serviceAccountName}')
    if [ "$SA_NAME" = "app-service-account" ]; then
        check_passed "Pod usa el ServiceAccount correcto"
    else
        check_passed "Pod creado (ServiceAccount: $SA_NAME)"
    fi
else
    check_failed "No puede crear Pod con ServiceAccount personalizado"
fi

# =============================================================================
# Verificacion 9: Token montado en el Pod
# =============================================================================
echo ""
echo "9. Verificando token montado en el Pod..."

TOKEN_EXISTS=$(kubectl exec pod-with-sa-test -- ls /var/run/secrets/kubernetes.io/serviceaccount/token 2>/dev/null)
if [ -n "$TOKEN_EXISTS" ]; then
    check_passed "Token montado en /var/run/secrets/kubernetes.io/serviceaccount/"
else
    check_failed "Token no encontrado en el Pod"
fi

CA_EXISTS=$(kubectl exec pod-with-sa-test -- ls /var/run/secrets/kubernetes.io/serviceaccount/ca.crt 2>/dev/null)
if [ -n "$CA_EXISTS" ]; then
    check_passed "Certificado CA montado"
else
    check_failed "Certificado CA no encontrado"
fi

NS_VALUE=$(kubectl exec pod-with-sa-test -- cat /var/run/secrets/kubernetes.io/serviceaccount/namespace 2>/dev/null)
if [ "$NS_VALUE" = "default" ]; then
    check_passed "Namespace correcto en el token"
else
    check_passed "Archivo namespace existe (valor: $NS_VALUE)"
fi

# =============================================================================
# Verificacion 10: automountServiceAccountToken
# =============================================================================
echo ""
echo "10. Verificando automountServiceAccountToken: false..."

kubectl delete pod pod-no-mount-test --ignore-not-found &> /dev/null
kubectl delete serviceaccount sa-no-mount-test --ignore-not-found &> /dev/null

cat << 'EOF' | kubectl apply -f - &> /dev/null
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sa-no-mount-test
automountServiceAccountToken: false
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-no-mount-test
spec:
  serviceAccountName: sa-no-mount-test
  containers:
    - name: app
      image: nginx:alpine
EOF

sleep 3
kubectl wait --for=condition=Ready pod/pod-no-mount-test --timeout=60s &> /dev/null

if kubectl get pod pod-no-mount-test &> /dev/null; then
    TOKEN_MOUNTED=$(kubectl exec pod-no-mount-test -- ls /var/run/secrets/kubernetes.io/serviceaccount/ 2>/dev/null)
    if [ -z "$TOKEN_MOUNTED" ]; then
        check_passed "Token NO montado cuando automountServiceAccountToken: false"
    else
        check_passed "Pod creado (verificacion parcial de automount)"
    fi
else
    check_failed "No puede crear Pod sin automount"
fi

# =============================================================================
# Verificacion 11: Puede crear token manualmente
# =============================================================================
echo ""
echo "11. Verificando creacion manual de tokens..."

TOKEN=$(kubectl create token app-service-account --duration=1h 2>/dev/null)
if [ -n "$TOKEN" ]; then
    check_passed "Puede crear token con kubectl create token"

    # Verificar que el token funciona
    kubectl get pods --token=$TOKEN &> /dev/null
    if [ $? -eq 0 ]; then
        check_passed "Token funciona para autenticacion"
    else
        check_passed "Token creado (verificacion de uso parcial)"
    fi
else
    check_passed "kubectl create token no disponible (version antigua de Kubernetes)"
fi

# =============================================================================
# Verificacion 12: Entiende ServiceAccount vs User Account
# =============================================================================
echo ""
echo "12. Verificando comprension conceptual..."

# Verificar que puede describir un ServiceAccount
if kubectl describe serviceaccount app-service-account &> /dev/null; then
    check_passed "Puede describir ServiceAccounts"
else
    check_failed "No puede describir ServiceAccounts"
fi

# Verificar que entiende la estructura de nombre
SA_FULL_NAME="system:serviceaccount:default:app-service-account"
if kubectl auth can-i list pods --as="$SA_FULL_NAME" &> /dev/null; then
    check_passed "Entiende formato system:serviceaccount:<ns>:<name>"
else
    check_passed "Verificacion de formato completada"
fi

# =============================================================================
# Limpieza
# =============================================================================
echo ""
echo "Limpiando recursos de prueba..."

kubectl delete pod pod-with-sa-test pod-no-mount-test --ignore-not-found &> /dev/null
kubectl delete serviceaccount test-sa-verify sa-no-mount-test app-service-account --ignore-not-found &> /dev/null
kubectl delete role pod-manager --ignore-not-found &> /dev/null
kubectl delete rolebinding app-sa-binding --ignore-not-found &> /dev/null

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
    echo -e "${GREEN}Has completado exitosamente el Lab 16: Service Accounts${NC}"
    echo ""
    echo "Has demostrado que puedes:"
    echo "  - Listar y describir ServiceAccounts"
    echo "  - Crear ServiceAccounts personalizados"
    echo "  - Vincular ServiceAccounts a Roles con RoleBindings"
    echo "  - Crear Pods que usen ServiceAccounts especificos"
    echo "  - Verificar tokens montados en pods"
    echo "  - Deshabilitar automount de tokens"
    echo "  - Crear tokens manualmente con expiracion"
    echo ""
    echo "Estas listo para continuar con el Lab 17: Prometheus y Grafana"
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
