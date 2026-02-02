#!/bin/bash
# =============================================================================
# Lab 16: Service Accounts - Script de Solucion Completa
# =============================================================================
# Este script ejecuta todos los comandos del laboratorio de forma secuencial.
# Usalo como referencia o para verificar que completaste correctamente el lab.
#
# NOTA: Este script asume que Minikube esta corriendo (Labs anteriores completados).
# =============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_step() {
    echo ""
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo ""
}

print_substep() {
    echo ""
    echo -e "${CYAN}--- $1 ---${NC}"
    echo ""
}

print_command() {
    echo -e "${YELLOW}$ $1${NC}"
}

print_warning() {
    echo -e "${RED}[ADVERTENCIA] $1${NC}"
}

wait_for_user() {
    echo ""
    read -p "Presiona Enter para continuar..."
    echo ""
}

# Obtener el directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

# =============================================================================
# Verificacion Inicial
# =============================================================================
print_step "Verificacion Inicial"

if ! command -v minikube &> /dev/null; then
    echo -e "${RED}Error: Minikube no esta instalado.${NC}"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl no esta instalado.${NC}"
    exit 1
fi

print_command "minikube status"
if ! minikube status &> /dev/null; then
    echo -e "${YELLOW}Minikube no esta corriendo. Iniciando...${NC}"
    minikube start --driver=docker
fi
minikube status

echo ""
echo -e "${GREEN}OK Minikube esta corriendo${NC}"

wait_for_user

# =============================================================================
# Paso 1: Explorar ServiceAccount por defecto
# =============================================================================
print_step "Paso 1: Explorar ServiceAccount por defecto"

print_substep "Ver ServiceAccounts en el namespace actual"
print_command "kubectl get serviceaccounts"
kubectl get serviceaccounts

echo ""
print_substep "Describir el ServiceAccount default"
print_command "kubectl describe serviceaccount default"
kubectl describe serviceaccount default

echo ""
print_substep "Ver Secrets en el namespace"
print_command "kubectl get secrets"
kubectl get secrets

echo ""
echo -e "${GREEN}OK ServiceAccount por defecto explorado${NC}"
echo ""
echo "Nota: En Kubernetes 1.24+, los tokens de ServiceAccount ya no se crean"
echo "automaticamente como Secrets. Se usan Bound Service Account Tokens."

wait_for_user

# =============================================================================
# Paso 2: Crear ServiceAccount personalizado
# =============================================================================
print_step "Paso 2: Crear ServiceAccount personalizado"

print_substep "Ver contenido del archivo serviceaccount.yaml"
print_command "cat $LAB_DIR/initial/serviceaccount.yaml"
cat "$LAB_DIR/initial/serviceaccount.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/serviceaccount.yaml"
kubectl apply -f "$LAB_DIR/initial/serviceaccount.yaml"

echo ""
print_command "kubectl describe serviceaccount app-service-account"
kubectl describe serviceaccount app-service-account

echo ""
print_substep "Listar todos los ServiceAccounts"
print_command "kubectl get serviceaccounts"
kubectl get serviceaccounts

echo ""
echo -e "${GREEN}OK ServiceAccount app-service-account creado${NC}"

wait_for_user

# =============================================================================
# Paso 3: Vincular ServiceAccount a un Role
# =============================================================================
print_step "Paso 3: Vincular ServiceAccount a un Role"

print_substep "Ver contenido del archivo sa-rolebinding.yaml"
print_command "cat $LAB_DIR/initial/sa-rolebinding.yaml"
cat "$LAB_DIR/initial/sa-rolebinding.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/sa-rolebinding.yaml"
kubectl apply -f "$LAB_DIR/initial/sa-rolebinding.yaml"

echo ""
print_substep "Verificar el Role creado"
print_command "kubectl describe role pod-manager"
kubectl describe role pod-manager

echo ""
print_substep "Verificar el RoleBinding creado"
print_command "kubectl describe rolebinding app-sa-binding"
kubectl describe rolebinding app-sa-binding

echo ""
print_substep "Verificar permisos del ServiceAccount"
print_command "kubectl auth can-i list pods --as=system:serviceaccount:default:app-service-account"
kubectl auth can-i list pods --as=system:serviceaccount:default:app-service-account

print_command "kubectl auth can-i list configmaps --as=system:serviceaccount:default:app-service-account"
kubectl auth can-i list configmaps --as=system:serviceaccount:default:app-service-account

print_command "kubectl auth can-i list secrets --as=system:serviceaccount:default:app-service-account"
kubectl auth can-i list secrets --as=system:serviceaccount:default:app-service-account || echo "(Esperado: no)"

echo ""
echo -e "${GREEN}OK ServiceAccount vinculado al Role pod-manager${NC}"

wait_for_user

# =============================================================================
# Paso 4: Crear Pod con ServiceAccount
# =============================================================================
print_step "Paso 4: Crear Pod con ServiceAccount"

print_substep "Ver contenido del archivo pod-with-sa.yaml"
print_command "cat $LAB_DIR/initial/pod-with-sa.yaml"
cat "$LAB_DIR/initial/pod-with-sa.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/pod-with-sa.yaml"
kubectl delete pod pod-with-sa --ignore-not-found &> /dev/null
kubectl apply -f "$LAB_DIR/initial/pod-with-sa.yaml"

echo ""
echo "Esperando a que el pod este listo..."
kubectl wait --for=condition=Ready pod/pod-with-sa --timeout=120s

echo ""
print_substep "Verificar el ServiceAccount asignado al Pod"
print_command "kubectl describe pod pod-with-sa | grep -A5 'Service Account'"
kubectl describe pod pod-with-sa | grep -A5 "Service Account" || kubectl get pod pod-with-sa -o jsonpath='{.spec.serviceAccountName}{"\n"}'

echo ""
print_command "kubectl get pod pod-with-sa -o yaml | grep serviceAccountName"
kubectl get pod pod-with-sa -o yaml | grep serviceAccountName

echo ""
echo -e "${GREEN}OK Pod pod-with-sa creado con app-service-account${NC}"

wait_for_user

# =============================================================================
# Paso 5: Verificar token montado en el pod
# =============================================================================
print_step "Paso 5: Verificar token montado en el pod"

print_substep "Ver archivos montados en el directorio de secrets"
print_command "kubectl exec pod-with-sa -- ls -la /var/run/secrets/kubernetes.io/serviceaccount/"
kubectl exec pod-with-sa -- ls -la /var/run/secrets/kubernetes.io/serviceaccount/

echo ""
print_substep "Ver el namespace del pod"
print_command "kubectl exec pod-with-sa -- cat /var/run/secrets/kubernetes.io/serviceaccount/namespace"
kubectl exec pod-with-sa -- cat /var/run/secrets/kubernetes.io/serviceaccount/namespace
echo ""

echo ""
print_substep "Ver el certificado CA (primeras lineas)"
print_command "kubectl exec pod-with-sa -- head -5 /var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
kubectl exec pod-with-sa -- head -5 /var/run/secrets/kubernetes.io/serviceaccount/ca.crt

echo ""
print_substep "Ver el token (primeros 50 caracteres)"
print_command "kubectl exec pod-with-sa -- cat /var/run/secrets/kubernetes.io/serviceaccount/token | head -c 50"
kubectl exec pod-with-sa -- cat /var/run/secrets/kubernetes.io/serviceaccount/token | head -c 50
echo "..."
echo ""

echo ""
echo "Archivos montados automaticamente:"
echo "  - ca.crt    : Certificado CA del cluster"
echo "  - namespace : Namespace del pod"
echo "  - token     : Token JWT para autenticacion con la API"

echo ""
echo -e "${GREEN}OK Token de ServiceAccount verificado${NC}"

wait_for_user

# =============================================================================
# Paso 6: Acceder a la API desde el pod
# =============================================================================
print_step "Paso 6: Acceder a la API desde el pod"

print_substep "Usar kubectl dentro del pod (usa el ServiceAccount automaticamente)"
echo "El pod tiene la imagen bitnami/kubectl que incluye kubectl preinstalado."
echo ""

print_command "kubectl exec pod-with-sa -- kubectl get pods"
kubectl exec pod-with-sa -- kubectl get pods

echo ""
print_command "kubectl exec pod-with-sa -- kubectl get configmaps"
kubectl exec pod-with-sa -- kubectl get configmaps

echo ""
print_substep "Intentar acciones no permitidas"
print_command "kubectl exec pod-with-sa -- kubectl get secrets"
kubectl exec pod-with-sa -- kubectl get secrets 2>&1 || echo "(Acceso denegado - esperado)"

echo ""
print_command "kubectl exec pod-with-sa -- kubectl get deployments"
kubectl exec pod-with-sa -- kubectl get deployments 2>&1 || echo "(Acceso denegado - esperado)"

echo ""
echo -e "${GREEN}OK El ServiceAccount tiene los permisos configurados correctamente${NC}"
echo ""
echo "El pod puede:"
echo "  - Listar pods (get, list)"
echo "  - Listar configmaps (get, list)"
echo ""
echo "El pod NO puede:"
echo "  - Listar secrets"
echo "  - Listar deployments"

wait_for_user

# =============================================================================
# Paso 7: Crear ServiceAccount sin montar token automatico
# =============================================================================
print_step "Paso 7: Crear ServiceAccount sin montar token automatico"

print_substep "Ver contenido del archivo sa-no-automount.yaml"
print_command "cat $LAB_DIR/initial/sa-no-automount.yaml"
cat "$LAB_DIR/initial/sa-no-automount.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/sa-no-automount.yaml"
kubectl delete pod pod-restricted-sa --ignore-not-found &> /dev/null
kubectl delete serviceaccount restricted-sa --ignore-not-found &> /dev/null
kubectl apply -f "$LAB_DIR/initial/sa-no-automount.yaml"

echo ""
echo "Esperando a que el pod este listo..."
kubectl wait --for=condition=Ready pod/pod-restricted-sa --timeout=60s

echo ""
print_substep "Verificar que NO hay token montado"
print_command "kubectl exec pod-restricted-sa -- ls /var/run/secrets/kubernetes.io/serviceaccount/ 2>/dev/null || echo 'No token mounted'"
kubectl exec pod-restricted-sa -- ls /var/run/secrets/kubernetes.io/serviceaccount/ 2>/dev/null || echo "No token mounted - correcto!"

echo ""
echo -e "${GREEN}OK ServiceAccount con automountServiceAccountToken: false${NC}"
echo ""
echo "Usar automountServiceAccountToken: false es una buena practica de seguridad"
echo "para pods que no necesitan acceder a la API de Kubernetes."

wait_for_user

# =============================================================================
# Paso 8: Crear token manualmente (Kubernetes 1.24+)
# =============================================================================
print_step "Paso 8: Crear token manualmente (Kubernetes 1.24+)"

print_substep "Crear token con duracion especifica"
print_command "kubectl create token app-service-account --duration=1h"
TOKEN=$(kubectl create token app-service-account --duration=1h)
echo "Token creado (primeros 50 caracteres): ${TOKEN:0:50}..."

echo ""
print_substep "Usar el token para autenticarse"
print_command 'TOKEN=$(kubectl create token app-service-account)'
print_command 'kubectl get pods --token=$TOKEN'
kubectl get pods --token=$TOKEN

echo ""
print_substep "Comparar tipos de tokens"
echo ""
echo "| Tipo                | Descripcion                           |"
echo "|---------------------|---------------------------------------|"
echo "| Legacy tokens       | Secrets creados automaticamente       |"
echo "|                     | Sin expiracion, menos seguros         |"
echo "| Bound tokens        | TokenRequest API (Kubernetes 1.20+)   |"
echo "|                     | Tiempo limitado, mas seguros          |"
echo "| Projected tokens    | Montados en pods via projected volume |"
echo "|                     | Rotan automaticamente                 |"

echo ""
echo -e "${GREEN}OK Token creado manualmente${NC}"

wait_for_user

# =============================================================================
# Paso 9: Ejercicio Adicional - ServiceAccount para leer Secrets
# =============================================================================
print_step "Paso 9: Ejercicio Adicional - ServiceAccount para leer Secrets"

print_substep "Ver contenido del archivo sa-secret-reader.yaml"
print_command "cat $LAB_DIR/initial/sa-secret-reader.yaml"
cat "$LAB_DIR/initial/sa-secret-reader.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/sa-secret-reader.yaml"
kubectl apply -f "$LAB_DIR/initial/sa-secret-reader.yaml"

echo ""
print_substep "Verificar permisos del secret-reader-sa"
print_command "kubectl auth can-i list secrets --as=system:serviceaccount:default:secret-reader-sa"
kubectl auth can-i list secrets --as=system:serviceaccount:default:secret-reader-sa

print_command "kubectl auth can-i get secrets --as=system:serviceaccount:default:secret-reader-sa"
kubectl auth can-i get secrets --as=system:serviceaccount:default:secret-reader-sa

print_command "kubectl auth can-i create secrets --as=system:serviceaccount:default:secret-reader-sa"
kubectl auth can-i create secrets --as=system:serviceaccount:default:secret-reader-sa || echo "(Esperado: no)"

echo ""
echo -e "${GREEN}OK ServiceAccount secret-reader-sa creado${NC}"

wait_for_user

# =============================================================================
# Paso 10: Acceso directo a la API con curl
# =============================================================================
print_step "Paso 10: Acceso directo a la API con curl (Avanzado)"

print_substep "Ver contenido del archivo pod-api-access.yaml"
print_command "cat $LAB_DIR/initial/pod-api-access.yaml"
cat "$LAB_DIR/initial/pod-api-access.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/pod-api-access.yaml"
kubectl delete pod pod-api-access --ignore-not-found &> /dev/null
kubectl apply -f "$LAB_DIR/initial/pod-api-access.yaml"

echo ""
echo "Esperando a que el pod este listo..."
kubectl wait --for=condition=Ready pod/pod-api-access --timeout=60s

echo ""
print_substep "Acceder a la API usando curl desde dentro del pod"
echo "Comando que se ejecutara:"
echo 'curl -s --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \'
echo '  -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \'
echo '  https://kubernetes.default.svc/api/v1/namespaces/default/pods'
echo ""

print_command "kubectl exec pod-api-access -- sh -c 'curl -s --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H \"Authorization: Bearer \$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)\" https://kubernetes.default.svc/api/v1/namespaces/default/pods | head -30'"
kubectl exec pod-api-access -- sh -c 'curl -s --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" https://kubernetes.default.svc/api/v1/namespaces/default/pods' | head -30

echo ""
echo "..."
echo ""
echo -e "${GREEN}OK Acceso directo a la API de Kubernetes${NC}"

wait_for_user

# =============================================================================
# Limpieza
# =============================================================================
print_step "Limpieza de Recursos"

print_command "kubectl delete pod pod-with-sa pod-restricted-sa pod-api-access --ignore-not-found"
kubectl delete pod pod-with-sa pod-restricted-sa pod-api-access --ignore-not-found

print_command "kubectl delete serviceaccount app-service-account restricted-sa secret-reader-sa --ignore-not-found"
kubectl delete serviceaccount app-service-account restricted-sa secret-reader-sa --ignore-not-found

print_command "kubectl delete role pod-manager secret-reader --ignore-not-found"
kubectl delete role pod-manager secret-reader --ignore-not-found

print_command "kubectl delete rolebinding app-sa-binding secret-reader-binding --ignore-not-found"
kubectl delete rolebinding app-sa-binding secret-reader-binding --ignore-not-found

echo ""
print_command "kubectl get serviceaccounts"
kubectl get serviceaccounts

echo ""
echo -e "${GREEN}OK Recursos limpiados${NC}"

wait_for_user

# =============================================================================
# Resumen Final
# =============================================================================
print_step "Laboratorio Completado"

echo "Has completado exitosamente el Lab 16: Service Accounts"
echo ""
echo "Resumen de lo aprendido:"
echo ""
echo "  SERVICEACCOUNTS:"
echo "    - Identidades para aplicaciones/pods en el cluster"
echo "    - ServiceAccount 'default' existe en cada namespace"
echo "    - Se pueden crear ServiceAccounts personalizados"
echo ""
echo "  TOKENS:"
echo "    - Montados automaticamente en /var/run/secrets/kubernetes.io/serviceaccount/"
echo "    - Archivos: token, ca.crt, namespace"
echo "    - automountServiceAccountToken: false para deshabilitar"
echo "    - kubectl create token para tokens con expiracion"
echo ""
echo "  PERMISOS:"
echo "    - ServiceAccount + Role + RoleBinding = permisos"
echo "    - kubectl auth can-i --as=system:serviceaccount:<ns>:<sa>"
echo "    - Principio de menor privilegio"
echo ""
echo "  BUENAS PRACTICAS:"
echo "    - No usar ServiceAccount 'default' para aplicaciones"
echo "    - Crear ServiceAccounts especificos por aplicacion"
echo "    - Deshabilitar automount si no se necesita"
echo "    - Usar tokens con expiracion corta"
echo ""
echo "Comandos principales aprendidos:"
echo "  - kubectl get serviceaccounts"
echo "  - kubectl describe serviceaccount <nombre>"
echo "  - kubectl create token <sa> --duration=<tiempo>"
echo "  - kubectl auth can-i <verbo> <recurso> --as=system:serviceaccount:<ns>:<sa>"
echo ""
echo -e "${GREEN}Felicitaciones! Estas listo para el Lab 17: Prometheus y Grafana${NC}"
