#!/bin/bash
# =============================================================================
# Lab 12: Persistent Storage - Script de Solucion Completa
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
echo -e "${GREEN}✓ Minikube esta corriendo${NC}"

wait_for_user

# =============================================================================
# Paso 1: Demostrar perdida de datos sin persistencia
# =============================================================================
print_step "Paso 1: Demostrar Perdida de Datos sin Persistencia"

print_substep "Crear pod PostgreSQL efimero"
print_command "kubectl run postgres-ephemeral --image=postgres:13-alpine --env=\"POSTGRES_PASSWORD=secret\""
kubectl delete pod postgres-ephemeral --ignore-not-found &> /dev/null
kubectl run postgres-ephemeral --image=postgres:13-alpine --env="POSTGRES_PASSWORD=secret"

echo ""
print_command "kubectl wait --for=condition=Ready pod/postgres-ephemeral --timeout=120s"
kubectl wait --for=condition=Ready pod/postgres-ephemeral --timeout=120s

echo ""
print_substep "Crear datos en PostgreSQL"
echo "Esperando a que PostgreSQL este listo para conexiones..."
sleep 10

print_command "kubectl exec -it postgres-ephemeral -- psql -U postgres -c \"CREATE DATABASE testdb;\""
kubectl exec postgres-ephemeral -- psql -U postgres -c "CREATE DATABASE testdb;" 2>/dev/null || echo "(Base de datos puede ya existir)"

print_command "kubectl exec -it postgres-ephemeral -- psql -U postgres -d testdb -c \"CREATE TABLE users (id SERIAL, name TEXT);\""
kubectl exec postgres-ephemeral -- psql -U postgres -d testdb -c "CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name TEXT);" 2>/dev/null

print_command "kubectl exec -it postgres-ephemeral -- psql -U postgres -d testdb -c \"INSERT INTO users (name) VALUES ('Juan');\""
kubectl exec postgres-ephemeral -- psql -U postgres -d testdb -c "INSERT INTO users (name) VALUES ('Juan');" 2>/dev/null

echo ""
print_substep "Verificar datos creados"
print_command "kubectl exec -it postgres-ephemeral -- psql -U postgres -d testdb -c \"SELECT * FROM users;\""
kubectl exec postgres-ephemeral -- psql -U postgres -d testdb -c "SELECT * FROM users;" 2>/dev/null

echo ""
echo -e "${GREEN}✓ Datos creados en el pod efimero${NC}"

wait_for_user

print_substep "Eliminar y recrear el pod para demostrar perdida de datos"
print_command "kubectl delete pod postgres-ephemeral"
kubectl delete pod postgres-ephemeral

echo ""
print_command "kubectl run postgres-ephemeral --image=postgres:13-alpine --env=\"POSTGRES_PASSWORD=secret\""
kubectl run postgres-ephemeral --image=postgres:13-alpine --env="POSTGRES_PASSWORD=secret"

print_command "kubectl wait --for=condition=Ready pod/postgres-ephemeral --timeout=120s"
kubectl wait --for=condition=Ready pod/postgres-ephemeral --timeout=120s

echo ""
echo "Esperando a que PostgreSQL este listo..."
sleep 10

print_substep "Verificar que los datos se perdieron"
print_command "kubectl exec -it postgres-ephemeral -- psql -U postgres -c \"\\l\""
kubectl exec postgres-ephemeral -- psql -U postgres -c "\l" 2>/dev/null

echo ""
echo -e "${YELLOW}Observa: La base de datos 'testdb' ya NO existe${NC}"
echo -e "${GREEN}✓ Demostracion de perdida de datos completada${NC}"

# Limpiar pod efimero
kubectl delete pod postgres-ephemeral --ignore-not-found &> /dev/null

wait_for_user

# =============================================================================
# Paso 2: Crear PersistentVolume local
# =============================================================================
print_step "Paso 2: Crear PersistentVolume Local"

print_command "cat $LAB_DIR/initial/pv.yaml"
cat "$LAB_DIR/initial/pv.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/pv.yaml"
kubectl apply -f "$LAB_DIR/initial/pv.yaml"

echo ""
print_command "kubectl get pv"
kubectl get pv

echo ""
print_command "kubectl describe pv postgres-pv"
kubectl describe pv postgres-pv

echo ""
echo -e "${GREEN}✓ PersistentVolume creado${NC}"

wait_for_user

# =============================================================================
# Paso 3: Crear PersistentVolumeClaim
# =============================================================================
print_step "Paso 3: Crear PersistentVolumeClaim"

print_command "cat $LAB_DIR/initial/pvc.yaml"
cat "$LAB_DIR/initial/pvc.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/pvc.yaml"
kubectl apply -f "$LAB_DIR/initial/pvc.yaml"

echo ""
print_command "kubectl get pvc"
kubectl get pvc

echo ""
print_command "kubectl describe pvc postgres-pvc"
kubectl describe pvc postgres-pvc

echo ""
print_substep "Verificar que el PV esta Bound"
print_command "kubectl get pv"
kubectl get pv

echo ""
echo -e "${GREEN}✓ PersistentVolumeClaim creado y vinculado (Bound)${NC}"

wait_for_user

# =============================================================================
# Paso 4: Crear Deployment con volumen persistente
# =============================================================================
print_step "Paso 4: Crear Deployment con Volumen Persistente"

print_command "cat $LAB_DIR/initial/postgres-persistent.yaml"
cat "$LAB_DIR/initial/postgres-persistent.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/postgres-persistent.yaml"
kubectl apply -f "$LAB_DIR/initial/postgres-persistent.yaml"

echo ""
print_command "kubectl get pods -l app=postgres"
kubectl get pods -l app=postgres

echo ""
print_command "kubectl wait --for=condition=Ready pod -l app=postgres --timeout=120s"
kubectl wait --for=condition=Ready pod -l app=postgres --timeout=120s

echo ""
print_command "kubectl get pods -l app=postgres -o wide"
kubectl get pods -l app=postgres -o wide

echo ""
echo -e "${GREEN}✓ Deployment con volumen persistente creado${NC}"

wait_for_user

# =============================================================================
# Paso 5: Crear datos y verificar persistencia
# =============================================================================
print_step "Paso 5: Crear Datos y Verificar Persistencia"

print_substep "Obtener nombre del pod"
print_command "POD=\$(kubectl get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}')"
POD=$(kubectl get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}')
echo "Pod: $POD"

echo ""
echo "Esperando a que PostgreSQL este listo para conexiones..."
sleep 15

print_substep "Crear datos en PostgreSQL"
print_command "kubectl exec -it \$POD -- psql -U postgres -c \"CREATE DATABASE testdb;\""
kubectl exec "$POD" -- psql -U postgres -c "CREATE DATABASE testdb;" 2>/dev/null || echo "(Base de datos puede ya existir)"

print_command "kubectl exec -it \$POD -- psql -U postgres -d testdb -c \"CREATE TABLE users (id SERIAL, name TEXT);\""
kubectl exec "$POD" -- psql -U postgres -d testdb -c "CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name TEXT);" 2>/dev/null

print_command "kubectl exec -it \$POD -- psql -U postgres -d testdb -c \"INSERT INTO users (name) VALUES ('Maria'), ('Pedro');\""
kubectl exec "$POD" -- psql -U postgres -d testdb -c "INSERT INTO users (name) VALUES ('Maria'), ('Pedro');" 2>/dev/null

echo ""
print_substep "Verificar datos creados"
print_command "kubectl exec -it \$POD -- psql -U postgres -d testdb -c \"SELECT * FROM users;\""
kubectl exec "$POD" -- psql -U postgres -d testdb -c "SELECT * FROM users;" 2>/dev/null

echo ""
echo -e "${GREEN}✓ Datos creados en el pod con persistencia${NC}"

wait_for_user

print_substep "Eliminar el pod y verificar persistencia"
print_command "kubectl delete pod \$POD"
kubectl delete pod "$POD"

echo ""
print_command "kubectl wait --for=condition=Ready pod -l app=postgres --timeout=120s"
kubectl wait --for=condition=Ready pod -l app=postgres --timeout=120s

echo ""
echo "Esperando a que PostgreSQL este listo..."
sleep 15

print_substep "Verificar que los datos persisten"
print_command "NEW_POD=\$(kubectl get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}')"
NEW_POD=$(kubectl get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}')
echo "Nuevo Pod: $NEW_POD"

echo ""
print_command "kubectl exec -it \$NEW_POD -- psql -U postgres -d testdb -c \"SELECT * FROM users;\""
kubectl exec "$NEW_POD" -- psql -U postgres -d testdb -c "SELECT * FROM users;" 2>/dev/null

echo ""
echo -e "${GREEN}✓ Los datos persisten despues de eliminar y recrear el pod!${NC}"

wait_for_user

# =============================================================================
# Paso 6: Usar StorageClass dinamica
# =============================================================================
print_step "Paso 6: Usar StorageClass Dinamica"

print_substep "Ver StorageClasses disponibles"
print_command "kubectl get storageclass"
kubectl get storageclass

echo ""
print_command "cat $LAB_DIR/initial/pvc-dynamic.yaml"
cat "$LAB_DIR/initial/pvc-dynamic.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/pvc-dynamic.yaml"
kubectl apply -f "$LAB_DIR/initial/pvc-dynamic.yaml"

echo ""
print_command "kubectl get pvc dynamic-pvc"
kubectl get pvc dynamic-pvc

echo ""
print_command "kubectl get pv"
kubectl get pv

echo ""
echo -e "${YELLOW}Observa: Se creo automaticamente un PV para el PVC dinamico${NC}"
echo -e "${GREEN}✓ Aprovisionamiento dinamico verificado${NC}"

wait_for_user

# =============================================================================
# Paso 7: Explorar volumenes y mounts
# =============================================================================
print_step "Paso 7: Explorar Volumenes y Mounts"

print_substep "Inspeccionar volumeMounts del pod"
print_command "kubectl describe pod -l app=postgres | grep -A 5 'Mounts:'"
kubectl describe pod -l app=postgres | grep -A 5 "Mounts:" || echo "(Seccion de mounts)"

echo ""
print_substep "Ver el contenido del volumen desde dentro del pod"
POD=$(kubectl get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}')
print_command "kubectl exec \$POD -- ls -la /var/lib/postgresql/data/"
kubectl exec "$POD" -- ls -la /var/lib/postgresql/data/ 2>/dev/null || echo "(Listando directorio de datos)"

echo ""
print_command "kubectl exec \$POD -- ls -la /var/lib/postgresql/data/pgdata/"
kubectl exec "$POD" -- ls -la /var/lib/postgresql/data/pgdata/ 2>/dev/null | head -15 || echo "(Listando directorio pgdata)"

echo ""
echo -e "${GREEN}✓ Volumenes explorados${NC}"

wait_for_user

# =============================================================================
# Paso 8: Ver Access Modes
# =============================================================================
print_step "Paso 8: Entender Access Modes"

echo "Los Access Modes disponibles en Kubernetes son:"
echo ""
echo "  ReadWriteOnce (RWO) - Montado como lectura/escritura por un solo nodo"
echo "  ReadOnlyMany (ROX)  - Montado como solo lectura por multiples nodos"
echo "  ReadWriteMany (RWX) - Montado como lectura/escritura por multiples nodos"
echo ""

print_command "kubectl get pv -o custom-columns='NAME:.metadata.name,CAPACITY:.spec.capacity.storage,ACCESS MODES:.spec.accessModes,STATUS:.status.phase'"
kubectl get pv -o custom-columns='NAME:.metadata.name,CAPACITY:.spec.capacity.storage,ACCESS MODES:.spec.accessModes,STATUS:.status.phase'

echo ""
print_command "kubectl get pvc -o custom-columns='NAME:.metadata.name,STATUS:.status.phase,VOLUME:.spec.volumeName,CAPACITY:.status.capacity.storage'"
kubectl get pvc -o custom-columns='NAME:.metadata.name,STATUS:.status.phase,VOLUME:.spec.volumeName,CAPACITY:.status.capacity.storage'

echo ""
echo -e "${GREEN}✓ Access Modes explicados${NC}"

wait_for_user

# =============================================================================
# Paso 9: Limpiar Recursos
# =============================================================================
print_step "Paso 9: Limpiar Recursos"

print_command "kubectl delete deployment postgres"
kubectl delete deployment postgres --ignore-not-found

echo ""
print_command "kubectl delete pvc postgres-pvc dynamic-pvc"
kubectl delete pvc postgres-pvc dynamic-pvc --ignore-not-found

echo ""
print_command "kubectl delete pv postgres-pv"
kubectl delete pv postgres-pv --ignore-not-found

echo ""
print_command "kubectl get pv,pvc"
kubectl get pv,pvc 2>/dev/null || echo "No hay PVs ni PVCs"

echo ""
echo -e "${GREEN}✓ Recursos limpiados${NC}"

wait_for_user

# =============================================================================
# Resumen Final
# =============================================================================
print_step "Laboratorio Completado"

echo "Has completado exitosamente el Lab 12: Persistent Storage"
echo ""
echo "Resumen de lo aprendido:"
echo ""
echo "  ALMACENAMIENTO EFIMERO vs PERSISTENTE:"
echo "    - Efimero    : Datos se pierden al eliminar/recrear el pod"
echo "    - Persistente: Datos sobreviven al ciclo de vida del pod"
echo ""
echo "  RECURSOS DE ALMACENAMIENTO:"
echo "    - PersistentVolume (PV)     : Recurso de almacenamiento en el cluster"
echo "    - PersistentVolumeClaim (PVC): Solicitud de almacenamiento por una app"
echo "    - StorageClass              : Define tipos de almacenamiento disponibles"
echo ""
echo "  ACCESS MODES:"
echo "    - ReadWriteOnce (RWO) : Un solo nodo puede montar el volumen"
echo "    - ReadOnlyMany (ROX)  : Multiples nodos pueden leer"
echo "    - ReadWriteMany (RWX) : Multiples nodos pueden leer/escribir"
echo ""
echo "  RECLAIM POLICIES:"
echo "    - Retain : Mantiene los datos al liberar el PV"
echo "    - Delete : Elimina los datos al liberar el PV"
echo "    - Recycle: (Obsoleto) Limpia el volumen para reutilizacion"
echo ""
echo "Comandos principales aprendidos:"
echo "  - kubectl get pv / pvc"
echo "  - kubectl describe pv/pvc <nombre>"
echo "  - kubectl get storageclass"
echo ""
echo -e "${GREEN}Felicitaciones! Estas listo para el Lab 13: HPA${NC}"
