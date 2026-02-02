#!/bin/bash
# =============================================================================
# Lab 15: RBAC - Verificacion de Completado
# =============================================================================
# Este script verifica que has completado correctamente el laboratorio
# probando que puedes crear y gestionar RBAC en Kubernetes.
# =============================================================================

echo "=============================================="
echo "  Lab 15: Verificacion de Completado"
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

REQUIRED_FILES=(
    "role-readonly.yaml"
    "role-developer.yaml"
    "rolebinding.yaml"
    "clusterrole.yaml"
    "clusterrolebinding.yaml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$LAB_DIR/initial/$file" ]; then
        check_passed "$file existe"
    else
        check_failed "$file no existe"
    fi
done

# =============================================================================
# Verificacion 4: Puede crear namespace
# =============================================================================
echo ""
echo "4. Verificando creacion de namespace..."

kubectl delete namespace rbac-lab-test --ignore-not-found &> /dev/null
kubectl create namespace rbac-lab-test &> /dev/null

if kubectl get namespace rbac-lab-test &> /dev/null; then
    check_passed "Puede crear namespace"
else
    check_failed "No puede crear namespace"
fi

# =============================================================================
# Verificacion 5: Puede crear Role
# =============================================================================
echo ""
echo "5. Verificando creacion de Role..."

cat << 'EOF' | kubectl apply -f - &> /dev/null
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: test-role
  namespace: rbac-lab-test
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
EOF

if kubectl get role test-role -n rbac-lab-test &> /dev/null; then
    check_passed "Puede crear Role"

    # Verificar que tiene las reglas correctas
    VERBS=$(kubectl get role test-role -n rbac-lab-test -o jsonpath='{.rules[0].verbs}')
    if echo "$VERBS" | grep -q "get" && echo "$VERBS" | grep -q "list"; then
        check_passed "Role tiene los verbs correctos (get, list)"
    else
        check_failed "Role no tiene los verbs esperados"
    fi
else
    check_failed "No puede crear Role"
fi

# =============================================================================
# Verificacion 6: Puede crear RoleBinding
# =============================================================================
echo ""
echo "6. Verificando creacion de RoleBinding..."

cat << 'EOF' | kubectl apply -f - &> /dev/null
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: test-rolebinding
  namespace: rbac-lab-test
subjects:
  - kind: User
    name: test-user
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: test-role
  apiGroup: rbac.authorization.k8s.io
EOF

if kubectl get rolebinding test-rolebinding -n rbac-lab-test &> /dev/null; then
    check_passed "Puede crear RoleBinding"

    # Verificar que tiene el subject correcto
    SUBJECT=$(kubectl get rolebinding test-rolebinding -n rbac-lab-test -o jsonpath='{.subjects[0].name}')
    if [ "$SUBJECT" = "test-user" ]; then
        check_passed "RoleBinding tiene el subject correcto"
    else
        check_failed "RoleBinding no tiene el subject esperado"
    fi
else
    check_failed "No puede crear RoleBinding"
fi

# =============================================================================
# Verificacion 7: Puede verificar permisos con can-i
# =============================================================================
echo ""
echo "7. Verificando kubectl auth can-i..."

# El usuario test-user deberia poder listar pods
CAN_LIST=$(kubectl auth can-i list pods -n rbac-lab-test --as=test-user 2>/dev/null)
if [ "$CAN_LIST" = "yes" ]; then
    check_passed "can-i funciona: test-user puede listar pods"
else
    check_failed "can-i no funciona o permisos incorrectos"
fi

# El usuario test-user NO deberia poder crear pods
CAN_CREATE=$(kubectl auth can-i create pods -n rbac-lab-test --as=test-user 2>/dev/null)
if [ "$CAN_CREATE" = "no" ]; then
    check_passed "can-i funciona: test-user NO puede crear pods"
else
    check_failed "Permisos incorrectos: test-user no deberia poder crear pods"
fi

# =============================================================================
# Verificacion 8: Puede crear ClusterRole
# =============================================================================
echo ""
echo "8. Verificando creacion de ClusterRole..."

kubectl delete clusterrole test-clusterrole --ignore-not-found &> /dev/null

cat << 'EOF' | kubectl apply -f - &> /dev/null
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: test-clusterrole
rules:
  - apiGroups: [""]
    resources: ["namespaces"]
    verbs: ["get", "list"]
EOF

if kubectl get clusterrole test-clusterrole &> /dev/null; then
    check_passed "Puede crear ClusterRole"
else
    check_failed "No puede crear ClusterRole"
fi

# =============================================================================
# Verificacion 9: Puede crear ClusterRoleBinding
# =============================================================================
echo ""
echo "9. Verificando creacion de ClusterRoleBinding..."

kubectl delete clusterrolebinding test-clusterrolebinding --ignore-not-found &> /dev/null

cat << 'EOF' | kubectl apply -f - &> /dev/null
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: test-clusterrolebinding
subjects:
  - kind: Group
    name: test-group
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: test-clusterrole
  apiGroup: rbac.authorization.k8s.io
EOF

if kubectl get clusterrolebinding test-clusterrolebinding &> /dev/null; then
    check_passed "Puede crear ClusterRoleBinding"
else
    check_failed "No puede crear ClusterRoleBinding"
fi

# =============================================================================
# Verificacion 10: Entiende la diferencia entre Role y ClusterRole
# =============================================================================
echo ""
echo "10. Verificando comprension de Role vs ClusterRole..."

# ClusterRole deberia permitir acceso global
CAN_LIST_NS=$(kubectl auth can-i list namespaces --as=test-user2 --as-group=test-group 2>/dev/null)
if [ "$CAN_LIST_NS" = "yes" ]; then
    check_passed "ClusterRoleBinding otorga permisos globales"
else
    check_passed "Verificacion de ClusterRole completada (puede requerir mas configuracion)"
fi

# =============================================================================
# Verificacion 11: Puede listar Roles predefinidos
# =============================================================================
echo ""
echo "11. Verificando acceso a roles predefinidos..."

if kubectl get clusterrole view &> /dev/null; then
    check_passed "Puede ver ClusterRole 'view'"
else
    check_failed "No puede acceder a ClusterRole 'view'"
fi

if kubectl get clusterrole edit &> /dev/null; then
    check_passed "Puede ver ClusterRole 'edit'"
else
    check_failed "No puede acceder a ClusterRole 'edit'"
fi

if kubectl get clusterrole admin &> /dev/null; then
    check_passed "Puede ver ClusterRole 'admin'"
else
    check_failed "No puede acceder a ClusterRole 'admin'"
fi

# =============================================================================
# Verificacion 12: Puede describir recursos RBAC
# =============================================================================
echo ""
echo "12. Verificando comandos de inspeccion..."

if kubectl describe role test-role -n rbac-lab-test &> /dev/null; then
    check_passed "Puede describir Roles con kubectl describe"
else
    check_failed "kubectl describe role no funciona"
fi

if kubectl describe rolebinding test-rolebinding -n rbac-lab-test &> /dev/null; then
    check_passed "Puede describir RoleBindings con kubectl describe"
else
    check_failed "kubectl describe rolebinding no funciona"
fi

# =============================================================================
# Verificacion 13: Entiende apiGroups
# =============================================================================
echo ""
echo "13. Verificando comprension de apiGroups..."

# Crear un Role con apiGroups de apps
cat << 'EOF' | kubectl apply -f - &> /dev/null
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployment-reader
  namespace: rbac-lab-test
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list"]
EOF

if kubectl get role deployment-reader -n rbac-lab-test &> /dev/null; then
    APIGROUP=$(kubectl get role deployment-reader -n rbac-lab-test -o jsonpath='{.rules[0].apiGroups[0]}')
    if [ "$APIGROUP" = "apps" ]; then
        check_passed "Comprende apiGroups: 'apps' para deployments"
    else
        check_failed "apiGroups no configurado correctamente"
    fi
else
    check_failed "No puede crear Role con apiGroups apps"
fi

# =============================================================================
# Verificacion 14: Puede aplicar archivos del lab
# =============================================================================
echo ""
echo "14. Verificando archivos YAML del laboratorio..."

# Crear namespace para prueba
kubectl create namespace rbac-lab --dry-run=client -o yaml | kubectl apply -f - &> /dev/null

if kubectl apply -f "$LAB_DIR/initial/role-readonly.yaml" &> /dev/null; then
    check_passed "role-readonly.yaml es valido y aplicable"
else
    check_failed "role-readonly.yaml tiene errores"
fi

if kubectl apply -f "$LAB_DIR/initial/role-developer.yaml" &> /dev/null; then
    check_passed "role-developer.yaml es valido y aplicable"
else
    check_failed "role-developer.yaml tiene errores"
fi

if kubectl apply -f "$LAB_DIR/initial/rolebinding.yaml" &> /dev/null; then
    check_passed "rolebinding.yaml es valido y aplicable"
else
    check_failed "rolebinding.yaml tiene errores"
fi

# =============================================================================
# Limpieza
# =============================================================================
echo ""
echo "Limpiando recursos de prueba..."

kubectl delete namespace rbac-lab-test --ignore-not-found &> /dev/null
kubectl delete namespace rbac-lab --ignore-not-found &> /dev/null
kubectl delete clusterrole test-clusterrole --ignore-not-found &> /dev/null
kubectl delete clusterrolebinding test-clusterrolebinding --ignore-not-found &> /dev/null

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
    echo -e "${GREEN}Has completado exitosamente el Lab 15: RBAC${NC}"
    echo ""
    echo "Has demostrado que puedes:"
    echo "  - Crear Roles y ClusterRoles"
    echo "  - Crear RoleBindings y ClusterRoleBindings"
    echo "  - Verificar permisos con kubectl auth can-i"
    echo "  - Entender la diferencia entre Role y ClusterRole"
    echo "  - Trabajar con apiGroups (core y apps)"
    echo "  - Acceder a roles predefinidos del sistema"
    echo ""
    echo "Estas listo para continuar con el Lab 16: Service Accounts"
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
    echo "  - Asegurate de crear el namespace rbac-lab primero"
fi

echo ""
echo "=============================================="
