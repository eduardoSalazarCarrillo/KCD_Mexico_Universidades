#!/bin/bash
# =============================================================================
# Lab 15: RBAC - Script de Solucion Completa
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

print_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
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
# Paso 1: Crear Namespace para el Laboratorio
# =============================================================================
print_step "Paso 1: Crear Namespace para el Laboratorio"

print_info "Los Roles estan limitados a un namespace especifico."
print_info "Crearemos un namespace dedicado para este laboratorio."

echo ""
print_command "kubectl create namespace rbac-lab"
kubectl delete namespace rbac-lab --ignore-not-found &> /dev/null || true
sleep 2
kubectl create namespace rbac-lab

echo ""
print_command "kubectl get namespace rbac-lab"
kubectl get namespace rbac-lab

echo ""
print_command "kubectl get namespaces"
kubectl get namespaces

echo ""
echo -e "${GREEN}OK Namespace rbac-lab creado${NC}"

wait_for_user

# =============================================================================
# Paso 2: Crear un Role con Permisos de Solo Lectura
# =============================================================================
print_step "Paso 2: Crear un Role con Permisos de Solo Lectura"

print_info "Un Role define QUE permisos existen (pero no QUIEN los tiene)"

echo ""
print_substep "Contenido del archivo role-readonly.yaml"
print_command "cat $LAB_DIR/initial/role-readonly.yaml"
cat "$LAB_DIR/initial/role-readonly.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/role-readonly.yaml"
kubectl apply -f "$LAB_DIR/initial/role-readonly.yaml"

echo ""
print_command "kubectl describe role pod-reader -n rbac-lab"
kubectl describe role pod-reader -n rbac-lab

echo ""
print_substep "Entendiendo la estructura del Role"
echo "  apiGroups: ['']  -> Core API (pods, services, configmaps, secrets)"
echo "  apiGroups: ['apps'] -> Apps API (deployments, replicasets, statefulsets)"
echo "  resources: ['pods'] -> Tipo de recurso"
echo "  verbs: ['get', 'list', 'watch'] -> Acciones permitidas"

echo ""
echo -e "${GREEN}OK Role pod-reader creado${NC}"

wait_for_user

# =============================================================================
# Paso 3: Crear un Role con Mas Permisos (Developer)
# =============================================================================
print_step "Paso 3: Crear un Role con Mas Permisos (Developer)"

print_info "Este Role tiene permisos CRUD completos para varios recursos"

echo ""
print_substep "Contenido del archivo role-developer.yaml"
print_command "cat $LAB_DIR/initial/role-developer.yaml"
cat "$LAB_DIR/initial/role-developer.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/role-developer.yaml"
kubectl apply -f "$LAB_DIR/initial/role-developer.yaml"

echo ""
print_command "kubectl describe role developer -n rbac-lab"
kubectl describe role developer -n rbac-lab

echo ""
print_substep "Comparacion de permisos"
echo "  pod-reader: Solo puede VER pods (get, list, watch)"
echo "  developer:  Puede CREAR, MODIFICAR y ELIMINAR pods, services, configmaps, deployments"

echo ""
echo -e "${GREEN}OK Role developer creado${NC}"

wait_for_user

# =============================================================================
# Paso 4: Crear RoleBinding
# =============================================================================
print_step "Paso 4: Crear RoleBinding"

print_info "Un RoleBinding vincula un Role con usuarios, grupos o ServiceAccounts"
print_info "Define QUIEN tiene los permisos definidos en el Role"

echo ""
print_substep "Contenido del archivo rolebinding.yaml"
print_command "cat $LAB_DIR/initial/rolebinding.yaml"
cat "$LAB_DIR/initial/rolebinding.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/rolebinding.yaml"
kubectl apply -f "$LAB_DIR/initial/rolebinding.yaml"

echo ""
print_command "kubectl describe rolebinding read-pods-binding -n rbac-lab"
kubectl describe rolebinding read-pods-binding -n rbac-lab

echo ""
print_substep "Crear RoleBinding para developer"
print_command "kubectl apply -f $LAB_DIR/initial/rolebinding-developer.yaml"
kubectl apply -f "$LAB_DIR/initial/rolebinding-developer.yaml"

echo ""
print_command "kubectl get rolebindings -n rbac-lab"
kubectl get rolebindings -n rbac-lab

echo ""
echo -e "${GREEN}OK RoleBindings creados${NC}"

wait_for_user

# =============================================================================
# Paso 5: Verificar Permisos con kubectl auth can-i
# =============================================================================
print_step "Paso 5: Verificar Permisos con kubectl auth can-i"

print_info "kubectl auth can-i permite verificar permisos sin ejecutar acciones"

echo ""
print_substep "Verificar permisos del usuario actual (admin)"
print_command "kubectl auth can-i create pods -n rbac-lab"
kubectl auth can-i create pods -n rbac-lab

print_command "kubectl auth can-i delete deployments -n rbac-lab"
kubectl auth can-i delete deployments -n rbac-lab

echo ""
print_substep "Verificar permisos de 'jane' (tiene role pod-reader)"
print_command "kubectl auth can-i list pods -n rbac-lab --as=jane"
kubectl auth can-i list pods -n rbac-lab --as=jane

print_command "kubectl auth can-i create pods -n rbac-lab --as=jane"
kubectl auth can-i create pods -n rbac-lab --as=jane || true

print_command "kubectl auth can-i delete pods -n rbac-lab --as=jane"
kubectl auth can-i delete pods -n rbac-lab --as=jane || true

print_command "kubectl auth can-i get pods/log -n rbac-lab --as=jane"
kubectl auth can-i get pods/log -n rbac-lab --as=jane

echo ""
print_substep "Verificar permisos de 'john' (tiene role developer)"
print_command "kubectl auth can-i create pods -n rbac-lab --as=john"
kubectl auth can-i create pods -n rbac-lab --as=john

print_command "kubectl auth can-i create deployments -n rbac-lab --as=john"
kubectl auth can-i create deployments -n rbac-lab --as=john

print_command "kubectl auth can-i delete services -n rbac-lab --as=john"
kubectl auth can-i delete services -n rbac-lab --as=john

echo ""
print_substep "Ver TODOS los permisos de un usuario"
print_command "kubectl auth can-i --list -n rbac-lab --as=jane"
kubectl auth can-i --list -n rbac-lab --as=jane

echo ""
echo -e "${GREEN}OK Verificacion de permisos completada${NC}"

wait_for_user

# =============================================================================
# Paso 6: Crear ClusterRole
# =============================================================================
print_step "Paso 6: Crear ClusterRole"

print_info "ClusterRole define permisos a nivel de TODO el cluster"
print_info "Util para recursos sin namespace como nodes, namespaces, persistentvolumes"

echo ""
print_substep "Contenido del archivo clusterrole.yaml"
print_command "cat $LAB_DIR/initial/clusterrole.yaml"
cat "$LAB_DIR/initial/clusterrole.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/clusterrole.yaml"
kubectl apply -f "$LAB_DIR/initial/clusterrole.yaml"

echo ""
print_command "kubectl describe clusterrole namespace-reader"
kubectl describe clusterrole namespace-reader

echo ""
print_substep "Diferencia: Role vs ClusterRole"
echo "  ROLE:"
echo "    - Tiene 'namespace' en metadata"
echo "    - Permisos solo en ESE namespace"
echo "    - Usado con RoleBinding"
echo ""
echo "  CLUSTERROLE:"
echo "    - NO tiene 'namespace' en metadata"
echo "    - Puede definir permisos para recursos sin namespace"
echo "    - Usado con ClusterRoleBinding (global) o RoleBinding (en un namespace)"

echo ""
echo -e "${GREEN}OK ClusterRole namespace-reader creado${NC}"

wait_for_user

# =============================================================================
# Paso 7: Crear ClusterRoleBinding
# =============================================================================
print_step "Paso 7: Crear ClusterRoleBinding"

print_info "ClusterRoleBinding vincula un ClusterRole globalmente"

echo ""
print_substep "Contenido del archivo clusterrolebinding.yaml"
print_command "cat $LAB_DIR/initial/clusterrolebinding.yaml"
cat "$LAB_DIR/initial/clusterrolebinding.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/clusterrolebinding.yaml"
kubectl apply -f "$LAB_DIR/initial/clusterrolebinding.yaml"

echo ""
print_command "kubectl describe clusterrolebinding namespace-reader-binding"
kubectl describe clusterrolebinding namespace-reader-binding

echo ""
print_substep "Verificar permisos globales"
print_command "kubectl auth can-i list namespaces --as=bob --as-group=all-users"
kubectl auth can-i list namespaces --as=bob --as-group=all-users

print_command "kubectl auth can-i get nodes --as=bob --as-group=all-users"
kubectl auth can-i get nodes --as=bob --as-group=all-users

echo ""
echo -e "${GREEN}OK ClusterRoleBinding namespace-reader-binding creado${NC}"

wait_for_user

# =============================================================================
# Paso 8: Explorar Roles Predefinidos del Sistema
# =============================================================================
print_step "Paso 8: Explorar Roles Predefinidos del Sistema"

print_info "Kubernetes incluye ClusterRoles predefinidos para casos comunes"

echo ""
print_substep "Listar ClusterRoles del sistema"
print_command "kubectl get clusterroles | grep -E '^(admin|edit|view|cluster-admin)'"
kubectl get clusterroles | grep -E "^(admin|edit|view|cluster-admin)" || kubectl get clusterroles | head -20

echo ""
print_substep "ClusterRole: view (solo lectura)"
print_command "kubectl describe clusterrole view | head -40"
kubectl describe clusterrole view | head -40

echo ""
print_substep "ClusterRole: edit (lectura y escritura)"
print_command "kubectl describe clusterrole edit | head -30"
kubectl describe clusterrole edit | head -30

echo ""
print_substep "ClusterRole: admin (permisos de admin de namespace)"
print_command "kubectl describe clusterrole admin | head -30"
kubectl describe clusterrole admin | head -30

echo ""
print_substep "ClusterRole: cluster-admin (TODOS los permisos)"
print_command "kubectl describe clusterrole cluster-admin"
kubectl describe clusterrole cluster-admin

echo ""
print_warning "cluster-admin tiene TODOS los permisos - usar con cuidado!"

echo ""
print_substep "Resumen de roles predefinidos"
echo "  view:          Solo lectura de la mayoria de recursos"
echo "  edit:          Lectura/escritura, pero no RBAC ni quotas"
echo "  admin:         Todo en un namespace, incluyendo RBAC"
echo "  cluster-admin: TODOS los permisos en TODO el cluster"

echo ""
echo -e "${GREEN}OK Roles predefinidos explorados${NC}"

wait_for_user

# =============================================================================
# Paso 9: Probar Permisos con Recursos Reales
# =============================================================================
print_step "Paso 9: Probar Permisos con Recursos Reales"

print_info "Vamos a crear recursos para probar los permisos configurados"

echo ""
print_substep "Desplegar aplicacion de prueba"
print_command "kubectl apply -f $LAB_DIR/initial/test-deployment.yaml"
kubectl apply -f "$LAB_DIR/initial/test-deployment.yaml"

echo ""
echo "Esperando a que los pods esten listos..."
kubectl wait --for=condition=Available deployment/nginx-test -n rbac-lab --timeout=60s

echo ""
print_command "kubectl get pods -n rbac-lab"
kubectl get pods -n rbac-lab

echo ""
print_substep "Simular acciones como usuario 'jane' (pod-reader)"
echo "Jane puede LISTAR pods:"
print_command "kubectl get pods -n rbac-lab --as=jane"
kubectl get pods -n rbac-lab --as=jane

echo ""
echo "Jane NO puede CREAR pods:"
print_command "kubectl run test-pod --image=nginx -n rbac-lab --as=jane"
kubectl run test-pod --image=nginx -n rbac-lab --as=jane 2>&1 || true

echo ""
print_substep "Simular acciones como usuario 'john' (developer)"
echo "John puede CREAR pods:"
print_command "kubectl run john-pod --image=nginx:alpine -n rbac-lab --as=john"
kubectl run john-pod --image=nginx:alpine -n rbac-lab --as=john

echo ""
print_command "kubectl get pods -n rbac-lab --as=john"
kubectl get pods -n rbac-lab --as=john

echo ""
echo "John puede ELIMINAR sus pods:"
print_command "kubectl delete pod john-pod -n rbac-lab --as=john"
kubectl delete pod john-pod -n rbac-lab --as=john

echo ""
echo -e "${GREEN}OK Pruebas de permisos completadas${NC}"

wait_for_user

# =============================================================================
# Paso 10: Ejercicio Adicional - Role para Escalar Deployments
# =============================================================================
print_step "Paso 10: Ejercicio Adicional - Role para Escalar Deployments"

print_info "Principio de menor privilegio: dar SOLO los permisos necesarios"

echo ""
print_substep "Contenido del archivo role-deployment-scaler.yaml"
print_command "cat $LAB_DIR/initial/role-deployment-scaler.yaml"
cat "$LAB_DIR/initial/role-deployment-scaler.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/role-deployment-scaler.yaml"
kubectl apply -f "$LAB_DIR/initial/role-deployment-scaler.yaml"

echo ""
print_substep "Crear RoleBinding para el scaler"
cat << 'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: scaler-binding
  namespace: rbac-lab
subjects:
  - kind: User
    name: scaler-user
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: deployment-scaler
  apiGroup: rbac.authorization.k8s.io
EOF

echo ""
print_substep "Verificar permisos del scaler-user"
print_command "kubectl auth can-i update deployments/scale -n rbac-lab --as=scaler-user"
kubectl auth can-i update deployments/scale -n rbac-lab --as=scaler-user

print_command "kubectl auth can-i delete deployments -n rbac-lab --as=scaler-user"
kubectl auth can-i delete deployments -n rbac-lab --as=scaler-user || true

print_command "kubectl auth can-i create pods -n rbac-lab --as=scaler-user"
kubectl auth can-i create pods -n rbac-lab --as=scaler-user || true

echo ""
print_info "scaler-user SOLO puede escalar deployments, nada mas!"

echo ""
echo -e "${GREEN}OK Role de scaler creado${NC}"

wait_for_user

# =============================================================================
# Paso 11: Ver todos los Roles y Bindings
# =============================================================================
print_step "Paso 11: Ver todos los Roles y Bindings"

echo ""
print_substep "Roles en namespace rbac-lab"
print_command "kubectl get roles -n rbac-lab"
kubectl get roles -n rbac-lab

echo ""
print_substep "RoleBindings en namespace rbac-lab"
print_command "kubectl get rolebindings -n rbac-lab"
kubectl get rolebindings -n rbac-lab

echo ""
print_substep "ClusterRoles creados por nosotros"
print_command "kubectl get clusterroles | grep namespace-reader"
kubectl get clusterroles | grep namespace-reader || echo "(namespace-reader)"

echo ""
print_substep "ClusterRoleBindings creados por nosotros"
print_command "kubectl get clusterrolebindings | grep namespace-reader"
kubectl get clusterrolebindings | grep namespace-reader || echo "(namespace-reader-binding)"

echo ""
echo -e "${GREEN}OK Listado de recursos RBAC completado${NC}"

wait_for_user

# =============================================================================
# Limpieza
# =============================================================================
print_step "Limpieza de Recursos"

print_command "kubectl delete namespace rbac-lab"
kubectl delete namespace rbac-lab --ignore-not-found

print_command "kubectl delete clusterrole namespace-reader"
kubectl delete clusterrole namespace-reader --ignore-not-found

print_command "kubectl delete clusterrolebinding namespace-reader-binding"
kubectl delete clusterrolebinding namespace-reader-binding --ignore-not-found

echo ""
echo -e "${GREEN}OK Recursos limpiados${NC}"

wait_for_user

# =============================================================================
# Resumen Final
# =============================================================================
print_step "Laboratorio Completado"

echo "Has completado exitosamente el Lab 15: RBAC"
echo ""
echo "Resumen de lo aprendido:"
echo ""
echo "  CONCEPTOS RBAC:"
echo "    - Role: Define permisos en UN namespace"
echo "    - ClusterRole: Define permisos a nivel de cluster"
echo "    - RoleBinding: Vincula Role/ClusterRole a usuarios en UN namespace"
echo "    - ClusterRoleBinding: Vincula ClusterRole globalmente"
echo ""
echo "  COMPONENTES DE UNA REGLA:"
echo "    - apiGroups: Grupo de API ('' para core, 'apps' para deployments)"
echo "    - resources: Tipos de recursos (pods, deployments, services)"
echo "    - verbs: Acciones (get, list, watch, create, update, delete)"
echo ""
echo "  ROLES PREDEFINIDOS:"
echo "    - view: Solo lectura"
echo "    - edit: Lectura y escritura (sin RBAC)"
echo "    - admin: Administrador de namespace"
echo "    - cluster-admin: Todos los permisos"
echo ""
echo "  BUENAS PRACTICAS:"
echo "    - Principio de menor privilegio"
echo "    - Usar namespaces para aislar permisos"
echo "    - Preferir Roles sobre ClusterRoles cuando sea posible"
echo "    - Auditar permisos regularmente"
echo ""
echo "Comandos principales aprendidos:"
echo "  - kubectl create role/clusterrole"
echo "  - kubectl create rolebinding/clusterrolebinding"
echo "  - kubectl auth can-i <verb> <resource> --as=<user>"
echo "  - kubectl describe role/rolebinding"
echo ""
echo -e "${GREEN}Felicitaciones! Estas listo para el Lab 16: Service Accounts${NC}"
