#!/bin/bash
# =============================================================================
# Lab 11: Secrets - Script de Solucion Completa
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
# Paso 1: Crear Secret desde Literales
# =============================================================================
print_step "Paso 1: Crear Secret desde Literales"

print_command "kubectl create secret generic db-credentials --from-literal=username=admin --from-literal=password=supersecret123"
kubectl delete secret db-credentials --ignore-not-found &> /dev/null
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=supersecret123

echo ""
print_command "kubectl get secret db-credentials"
kubectl get secret db-credentials

echo ""
print_command "kubectl describe secret db-credentials"
kubectl describe secret db-credentials

echo ""
print_command "kubectl get secret db-credentials -o yaml"
kubectl get secret db-credentials -o yaml

echo ""
print_warning "Los valores estan en base64, NO encriptados"
echo -e "${GREEN}OK Secret db-credentials creado${NC}"

wait_for_user

# =============================================================================
# Paso 2: Decodificar Valores
# =============================================================================
print_step "Paso 2: Decodificar Valores (Demostrar que base64 NO es encriptacion)"

print_substep "Decodificar username"
print_command "kubectl get secret db-credentials -o jsonpath='{.data.username}' | base64 -d"
USERNAME=$(kubectl get secret db-credentials -o jsonpath='{.data.username}' | base64 -d)
echo "Username decodificado: $USERNAME"

echo ""
print_substep "Decodificar password"
print_command "kubectl get secret db-credentials -o jsonpath='{.data.password}' | base64 -d"
PASSWORD=$(kubectl get secret db-credentials -o jsonpath='{.data.password}' | base64 -d)
echo "Password decodificado: $PASSWORD"

echo ""
print_warning "Cualquier persona con acceso al Secret puede decodificar los valores"
echo -e "${GREEN}OK Valores decodificados exitosamente${NC}"

wait_for_user

# =============================================================================
# Paso 3: Crear Secret con YAML
# =============================================================================
print_step "Paso 3: Crear Secret con YAML"

print_substep "Mostrar como codificar valores en base64"
print_command "echo -n 'api-key-1234567890' | base64"
echo -n 'api-key-1234567890' | base64

echo ""
print_command "echo -n 'super-secret-jwt-key' | base64"
echo -n 'super-secret-jwt-key' | base64

echo ""
print_substep "Ver contenido del archivo YAML"
print_command "cat $LAB_DIR/initial/secret.yaml"
cat "$LAB_DIR/initial/secret.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/secret.yaml"
kubectl apply -f "$LAB_DIR/initial/secret.yaml"

echo ""
print_command "kubectl describe secret app-secrets"
kubectl describe secret app-secrets

echo ""
print_substep "Verificar que stringData se convirtio a data (base64)"
print_command "kubectl get secret app-secrets -o jsonpath='{.data.database-url}' | base64 -d"
kubectl get secret app-secrets -o jsonpath='{.data.database-url}' | base64 -d
echo ""

echo ""
echo -e "${GREEN}OK Secret app-secrets creado con data y stringData${NC}"

wait_for_user

# =============================================================================
# Paso 4: Usar Secret como Variables de Entorno
# =============================================================================
print_step "Paso 4: Usar Secret como Variables de Entorno"

print_command "cat $LAB_DIR/initial/pod-secret-env.yaml"
cat "$LAB_DIR/initial/pod-secret-env.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/pod-secret-env.yaml"
kubectl delete pod pod-secret-env --ignore-not-found &> /dev/null
kubectl apply -f "$LAB_DIR/initial/pod-secret-env.yaml"

echo ""
echo "Esperando a que el pod este listo..."
kubectl wait --for=condition=Ready pod/pod-secret-env --timeout=60s

echo ""
print_substep "Verificar variables de entorno (SENSIBLE!)"
print_command "kubectl exec pod-secret-env -- env | grep -E 'DB_|api|jwt|database'"
kubectl exec pod-secret-env -- env | grep -E "DB_|api|jwt|database" || echo "(Algunas variables pueden tener nombres diferentes)"

echo ""
print_warning "Las variables de entorno son visibles con 'kubectl exec ... env'"
echo -e "${GREEN}OK Pod con Secrets como variables de entorno${NC}"

wait_for_user

# =============================================================================
# Paso 5: Montar Secret como Volumen
# =============================================================================
print_step "Paso 5: Montar Secret como Volumen"

print_command "cat $LAB_DIR/initial/pod-secret-volume.yaml"
cat "$LAB_DIR/initial/pod-secret-volume.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/pod-secret-volume.yaml"
kubectl delete pod pod-secret-volume --ignore-not-found &> /dev/null
kubectl apply -f "$LAB_DIR/initial/pod-secret-volume.yaml"

echo ""
echo "Esperando a que el pod este listo..."
kubectl wait --for=condition=Ready pod/pod-secret-volume --timeout=60s

echo ""
print_substep "Ver archivos montados y sus permisos"
print_command "kubectl exec pod-secret-volume -- ls -la /etc/secrets"
kubectl exec pod-secret-volume -- ls -la /etc/secrets

echo ""
print_substep "Leer contenido de los archivos"
print_command "kubectl exec pod-secret-volume -- cat /etc/secrets/username"
kubectl exec pod-secret-volume -- cat /etc/secrets/username
echo ""

print_command "kubectl exec pod-secret-volume -- cat /etc/secrets/password"
kubectl exec pod-secret-volume -- cat /etc/secrets/password
echo ""

echo ""
echo -e "${GREEN}OK Pod con Secret montado como volumen${NC}"

wait_for_user

# =============================================================================
# Paso 6: Tipos de Secrets
# =============================================================================
print_step "Paso 6: Explorar Tipos de Secrets"

print_substep "Crear Secret para Docker Registry"
print_command "kubectl create secret docker-registry my-registry --docker-server=registry.example.com --docker-username=user --docker-password=pass --docker-email=user@example.com"
kubectl delete secret my-registry --ignore-not-found &> /dev/null
kubectl create secret docker-registry my-registry \
  --docker-server=registry.example.com \
  --docker-username=user \
  --docker-password=pass \
  --docker-email=user@example.com

echo ""
print_command "kubectl get secret my-registry -o yaml | head -20"
kubectl get secret my-registry -o yaml | head -20

echo ""
print_substep "Ver todos los Secrets y sus tipos"
print_command "kubectl get secrets"
kubectl get secrets

echo ""
print_substep "Tipos de Secrets comunes"
echo "  - Opaque: Datos arbitrarios (por defecto)"
echo "  - kubernetes.io/dockerconfigjson: Credenciales de Docker registry"
echo "  - kubernetes.io/tls: Certificados TLS"
echo "  - kubernetes.io/service-account-token: Tokens de ServiceAccount"
echo "  - kubernetes.io/basic-auth: Autenticacion basica"

echo ""
echo -e "${GREEN}OK Tipos de Secrets explorados${NC}"

wait_for_user

# =============================================================================
# Paso 7: Buenas Practicas de Seguridad
# =============================================================================
print_step "Paso 7: Buenas Practicas de Seguridad"

print_substep "Ver ejemplo de RBAC para limitar acceso a Secrets"
print_command "cat $LAB_DIR/initial/rbac-secret-reader.yaml"
cat "$LAB_DIR/initial/rbac-secret-reader.yaml"

echo ""
print_substep "Verificar permisos con kubectl auth can-i"
print_command "kubectl auth can-i get secrets"
kubectl auth can-i get secrets

print_command "kubectl auth can-i get secrets --as=system:serviceaccount:default:default"
kubectl auth can-i get secrets --as=system:serviceaccount:default:default || echo "(Puede estar restringido)"

echo ""
print_substep "Buenas practicas resumidas"
echo "  1. Usar RBAC para limitar acceso a Secrets"
echo "  2. No incluir Secrets en repositorios Git"
echo "  3. Considerar herramientas como sealed-secrets o external-secrets"
echo "  4. Rotar Secrets regularmente"
echo "  5. Usar namespaces para aislar Secrets"
echo "  6. Habilitar encryption at rest en etcd"

echo ""
echo -e "${GREEN}OK Buenas practicas revisadas${NC}"

wait_for_user

# =============================================================================
# Paso 8: Crear Secret Inmutable (Ejercicio Adicional)
# =============================================================================
print_step "Paso 8: Secret Inmutable (Bonus)"

print_substep "Crear un Secret inmutable"
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: immutable-secret
type: Opaque
immutable: true
data:
  api-key: c2VjcmV0LWtleS0xMjM0NQ==
EOF

echo ""
print_command "kubectl describe secret immutable-secret"
kubectl describe secret immutable-secret

echo ""
print_substep "Intentar modificar el Secret inmutable"
echo "Intentando actualizar el Secret inmutable..."
if kubectl patch secret immutable-secret -p '{"data":{"new-key":"bmV3LXZhbHVl"}}' 2>&1; then
    echo "El Secret fue modificado (inesperado)"
else
    echo ""
    echo -e "${GREEN}OK El Secret inmutable no puede ser modificado${NC}"
fi

echo ""
echo "Nota: Los Secrets inmutables mejoran el rendimiento y la seguridad"

wait_for_user

# =============================================================================
# Paso 9: Comparar Secrets vs ConfigMaps
# =============================================================================
print_step "Paso 9: Comparar Secrets vs ConfigMaps"

echo "| Caracteristica      | ConfigMap          | Secret                    |"
echo "|---------------------|--------------------|-----------------------------|"
echo "| Proposito           | Configuracion      | Datos sensibles             |"
echo "| Almacenamiento      | Texto plano        | Base64 (no encriptado*)     |"
echo "| Tamano maximo       | 1 MB               | 1 MB                        |"
echo "| Montaje tmpfs       | No                 | Si (por defecto)            |"
echo "| Visible en logs     | Si                 | Parcialmente oculto         |"
echo "| RBAC separado       | No comun           | Recomendado                 |"
echo ""
echo "* Se puede habilitar encryption at rest en etcd"

wait_for_user

# =============================================================================
# Limpieza
# =============================================================================
print_step "Limpieza de Recursos"

print_command "kubectl delete pod pod-secret-env pod-secret-volume --ignore-not-found"
kubectl delete pod pod-secret-env pod-secret-volume --ignore-not-found

print_command "kubectl delete secret db-credentials app-secrets my-registry immutable-secret --ignore-not-found"
kubectl delete secret db-credentials app-secrets my-registry immutable-secret --ignore-not-found

echo ""
print_command "kubectl get secrets"
kubectl get secrets

echo ""
echo -e "${GREEN}OK Recursos limpiados${NC}"

wait_for_user

# =============================================================================
# Resumen Final
# =============================================================================
print_step "Laboratorio Completado"

echo "Has completado exitosamente el Lab 11: Secrets"
echo ""
echo "Resumen de lo aprendido:"
echo ""
echo "  CREACION DE SECRETS:"
echo "    - kubectl create secret generic ... --from-literal"
echo "    - kubectl create secret generic ... --from-file"
echo "    - kubectl apply -f secret.yaml (con data o stringData)"
echo ""
echo "  USO DE SECRETS:"
echo "    - Como variables de entorno (env y envFrom)"
echo "    - Como volumenes montados (con permisos restrictivos)"
echo ""
echo "  TIPOS DE SECRETS:"
echo "    - Opaque (generico)"
echo "    - kubernetes.io/dockerconfigjson (Docker registry)"
echo "    - kubernetes.io/tls (Certificados TLS)"
echo ""
echo "  SEGURIDAD:"
echo "    - base64 NO es encriptacion"
echo "    - Usar RBAC para limitar acceso"
echo "    - Considerar sealed-secrets o external-secrets para GitOps"
echo "    - Secrets inmutables para mayor seguridad"
echo ""
echo "Comandos principales aprendidos:"
echo "  - kubectl create secret generic <nombre>"
echo "  - kubectl get secret <nombre> -o yaml"
echo "  - kubectl get secret <nombre> -o jsonpath='{.data.key}' | base64 -d"
echo "  - kubectl describe secret <nombre>"
echo ""
echo -e "${GREEN}Felicitaciones! Estas listo para el Lab 12: Persistent Storage${NC}"
