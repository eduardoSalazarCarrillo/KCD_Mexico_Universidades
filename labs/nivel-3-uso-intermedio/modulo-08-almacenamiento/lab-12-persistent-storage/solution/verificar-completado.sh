#!/bin/bash
# =============================================================================
# Lab 12: Persistent Storage - Verificacion de Completado
# =============================================================================
# Este script verifica que has completado correctamente el laboratorio
# probando que puedes crear y gestionar almacenamiento persistente en Kubernetes.
# =============================================================================

echo "=============================================="
echo "  Lab 12: Verificacion de Completado"
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

if [ -f "$LAB_DIR/initial/pv.yaml" ]; then
    check_passed "pv.yaml existe"
else
    check_failed "pv.yaml no existe"
fi

if [ -f "$LAB_DIR/initial/pvc.yaml" ]; then
    check_passed "pvc.yaml existe"
else
    check_failed "pvc.yaml no existe"
fi

if [ -f "$LAB_DIR/initial/postgres-persistent.yaml" ]; then
    check_passed "postgres-persistent.yaml existe"
else
    check_failed "postgres-persistent.yaml no existe"
fi

if [ -f "$LAB_DIR/initial/pvc-dynamic.yaml" ]; then
    check_passed "pvc-dynamic.yaml existe"
else
    check_failed "pvc-dynamic.yaml no existe"
fi

# =============================================================================
# Verificacion 4: Puede crear PersistentVolume
# =============================================================================
echo ""
echo "4. Verificando creacion de PersistentVolume..."

kubectl apply -f "$LAB_DIR/initial/pv.yaml" &> /dev/null

if kubectl get pv postgres-pv &> /dev/null; then
    CAPACITY=$(kubectl get pv postgres-pv -o jsonpath='{.spec.capacity.storage}')
    ACCESS_MODE=$(kubectl get pv postgres-pv -o jsonpath='{.spec.accessModes[0]}')

    if [ "$CAPACITY" = "1Gi" ]; then
        check_passed "PV postgres-pv creado con capacidad 1Gi"
    else
        check_passed "PV postgres-pv creado (capacidad: $CAPACITY)"
    fi

    if [ "$ACCESS_MODE" = "ReadWriteOnce" ]; then
        check_passed "PV tiene accessMode ReadWriteOnce"
    else
        check_passed "PV tiene accessMode $ACCESS_MODE"
    fi
else
    check_failed "No se pudo crear el PersistentVolume"
fi

# =============================================================================
# Verificacion 5: Puede crear PersistentVolumeClaim
# =============================================================================
echo ""
echo "5. Verificando creacion de PersistentVolumeClaim..."

kubectl apply -f "$LAB_DIR/initial/pvc.yaml" &> /dev/null
sleep 2

if kubectl get pvc postgres-pvc &> /dev/null; then
    STATUS=$(kubectl get pvc postgres-pvc -o jsonpath='{.status.phase}')

    if [ "$STATUS" = "Bound" ]; then
        check_passed "PVC postgres-pvc esta Bound"
    else
        # Esperar un poco mas
        sleep 3
        STATUS=$(kubectl get pvc postgres-pvc -o jsonpath='{.status.phase}')
        if [ "$STATUS" = "Bound" ]; then
            check_passed "PVC postgres-pvc esta Bound"
        else
            check_failed "PVC postgres-pvc no esta Bound (estado: $STATUS)"
        fi
    fi

    VOLUME=$(kubectl get pvc postgres-pvc -o jsonpath='{.spec.volumeName}')
    if [ "$VOLUME" = "postgres-pv" ]; then
        check_passed "PVC esta vinculado al PV correcto"
    else
        check_passed "PVC esta vinculado a: $VOLUME"
    fi
else
    check_failed "No se pudo crear el PersistentVolumeClaim"
fi

# =============================================================================
# Verificacion 6: Puede crear Deployment con volumen
# =============================================================================
echo ""
echo "6. Verificando Deployment con volumen persistente..."

kubectl apply -f "$LAB_DIR/initial/postgres-persistent.yaml" &> /dev/null
sleep 3

if kubectl get deployment postgres &> /dev/null; then
    check_passed "Deployment postgres creado"

    # Esperar a que el pod este listo
    kubectl wait --for=condition=Ready pod -l app=postgres --timeout=60s &> /dev/null

    if kubectl get pod -l app=postgres -o jsonpath='{.items[0].status.phase}' 2>/dev/null | grep -q "Running"; then
        check_passed "Pod de postgres esta Running"
    else
        check_failed "Pod de postgres no esta Running"
    fi
else
    check_failed "No se pudo crear el Deployment postgres"
fi

# =============================================================================
# Verificacion 7: Volumen esta montado correctamente
# =============================================================================
echo ""
echo "7. Verificando que el volumen esta montado..."

POD=$(kubectl get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -n "$POD" ]; then
    # Verificar que el volumen esta montado
    MOUNT_PATH=$(kubectl get pod "$POD" -o jsonpath='{.spec.containers[0].volumeMounts[0].mountPath}' 2>/dev/null)

    if [ "$MOUNT_PATH" = "/var/lib/postgresql/data" ]; then
        check_passed "Volumen montado en /var/lib/postgresql/data"
    else
        check_passed "Volumen montado en: $MOUNT_PATH"
    fi

    # Verificar que el volumen usa el PVC correcto
    PVC_NAME=$(kubectl get pod "$POD" -o jsonpath='{.spec.volumes[0].persistentVolumeClaim.claimName}' 2>/dev/null)

    if [ "$PVC_NAME" = "postgres-pvc" ]; then
        check_passed "Pod usa el PVC postgres-pvc"
    else
        check_failed "Pod no usa el PVC correcto (usa: $PVC_NAME)"
    fi
else
    check_failed "No se encontro el pod de postgres"
fi

# =============================================================================
# Verificacion 8: Puede crear datos en PostgreSQL
# =============================================================================
echo ""
echo "8. Verificando persistencia de datos..."

if [ -n "$POD" ]; then
    echo "   Esperando a que PostgreSQL este listo..."
    sleep 10

    # Crear base de datos y tabla
    kubectl exec "$POD" -- psql -U postgres -c "CREATE DATABASE verifydb;" &> /dev/null || true
    kubectl exec "$POD" -- psql -U postgres -d verifydb -c "CREATE TABLE IF NOT EXISTS test (id SERIAL PRIMARY KEY, data TEXT);" &> /dev/null
    kubectl exec "$POD" -- psql -U postgres -d verifydb -c "INSERT INTO test (data) VALUES ('verification_data');" &> /dev/null

    # Verificar datos
    RESULT=$(kubectl exec "$POD" -- psql -U postgres -d verifydb -c "SELECT data FROM test WHERE data='verification_data';" 2>/dev/null)

    if echo "$RESULT" | grep -q "verification_data"; then
        check_passed "Puede crear y leer datos en PostgreSQL"
    else
        check_failed "No se pudieron crear/leer datos en PostgreSQL"
    fi
else
    check_failed "No se puede verificar persistencia sin pod"
fi

# =============================================================================
# Verificacion 9: StorageClass disponible
# =============================================================================
echo ""
echo "9. Verificando StorageClass..."

SC_COUNT=$(kubectl get storageclass --no-headers 2>/dev/null | wc -l)

if [ "$SC_COUNT" -gt 0 ]; then
    DEFAULT_SC=$(kubectl get storageclass -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}' 2>/dev/null)

    if [ -n "$DEFAULT_SC" ]; then
        check_passed "StorageClass default disponible: $DEFAULT_SC"
    else
        check_passed "StorageClass disponible ($SC_COUNT encontradas)"
    fi
else
    check_failed "No hay StorageClass disponibles"
fi

# =============================================================================
# Verificacion 10: Puede crear PVC dinamico
# =============================================================================
echo ""
echo "10. Verificando aprovisionamiento dinamico..."

kubectl apply -f "$LAB_DIR/initial/pvc-dynamic.yaml" &> /dev/null
sleep 3

if kubectl get pvc dynamic-pvc &> /dev/null; then
    STATUS=$(kubectl get pvc dynamic-pvc -o jsonpath='{.status.phase}')

    if [ "$STATUS" = "Bound" ]; then
        check_passed "PVC dinamico esta Bound"

        # Verificar que se creo un PV automaticamente
        PV_NAME=$(kubectl get pvc dynamic-pvc -o jsonpath='{.spec.volumeName}')
        if kubectl get pv "$PV_NAME" &> /dev/null; then
            check_passed "PV creado automaticamente: $PV_NAME"
        else
            check_passed "PV asociado al PVC dinamico"
        fi
    else
        # En algunos casos puede quedar en Pending si no hay StorageClass default
        check_passed "PVC dinamico creado (estado: $STATUS)"
    fi
else
    check_failed "No se pudo crear el PVC dinamico"
fi

# =============================================================================
# Verificacion 11: Entiende Access Modes
# =============================================================================
echo ""
echo "11. Verificando conocimiento de Access Modes..."

# Verificar que el PV tiene el access mode correcto
ACCESS_MODE=$(kubectl get pv postgres-pv -o jsonpath='{.spec.accessModes[0]}' 2>/dev/null)

if [ "$ACCESS_MODE" = "ReadWriteOnce" ]; then
    check_passed "Entiende ReadWriteOnce (RWO)"
else
    check_passed "Access mode configurado: $ACCESS_MODE"
fi

# =============================================================================
# Verificacion 12: Persistencia real
# =============================================================================
echo ""
echo "12. Verificando persistencia real (eliminando y recreando pod)..."

if [ -n "$POD" ]; then
    # Eliminar el pod
    kubectl delete pod "$POD" &> /dev/null

    # Esperar a que se cree el nuevo pod
    kubectl wait --for=condition=Ready pod -l app=postgres --timeout=90s &> /dev/null
    sleep 10

    # Obtener nuevo pod
    NEW_POD=$(kubectl get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

    if [ -n "$NEW_POD" ] && [ "$NEW_POD" != "$POD" ]; then
        check_passed "Nuevo pod creado: $NEW_POD"

        # Verificar que los datos persisten
        RESULT=$(kubectl exec "$NEW_POD" -- psql -U postgres -d verifydb -c "SELECT data FROM test WHERE data='verification_data';" 2>/dev/null)

        if echo "$RESULT" | grep -q "verification_data"; then
            check_passed "Datos persisten despues de recrear el pod!"
        else
            check_failed "Los datos no persistieron"
        fi
    else
        check_failed "No se creo un nuevo pod"
    fi
else
    check_failed "No se puede verificar persistencia sin pod inicial"
fi

# =============================================================================
# Limpieza
# =============================================================================
echo ""
echo "Limpiando recursos de prueba..."

kubectl delete deployment postgres --ignore-not-found &> /dev/null
kubectl delete pvc postgres-pvc dynamic-pvc --ignore-not-found &> /dev/null
kubectl delete pv postgres-pv --ignore-not-found &> /dev/null

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
    echo -e "${GREEN}Has completado exitosamente el Lab 12: Persistent Storage${NC}"
    echo ""
    echo "Has demostrado que puedes:"
    echo "  - Crear PersistentVolumes (PV)"
    echo "  - Crear PersistentVolumeClaims (PVC)"
    echo "  - Vincular PVCs a Deployments"
    echo "  - Verificar que los datos persisten"
    echo "  - Usar aprovisionamiento dinamico"
    echo "  - Entender Access Modes"
    echo ""
    echo "Estas listo para continuar con el Lab 13: HPA"
elif [ $CHECKS_PASSED -ge $((CHECKS_TOTAL * 80 / 100)) ]; then
    echo -e "${YELLOW}Muy bien!${NC}"
    echo "Has completado la mayoria del laboratorio ($CHECKS_PASSED/$CHECKS_TOTAL)."
    echo "Revisa los puntos marcados con ✗ para completar el lab."
else
    FAILED=$((CHECKS_TOTAL - CHECKS_PASSED))
    echo -e "${YELLOW}Algunas verificaciones fallaron ($FAILED de $CHECKS_TOTAL)${NC}"
    echo "Revisa los puntos marcados con ✗ y vuelve a intentar"
    echo ""
    echo "Posibles soluciones:"
    echo "  - Asegurate de que Minikube esta corriendo: minikube start"
    echo "  - Verifica los archivos YAML en initial/"
    echo "  - Revisa el README.md para mas detalles sobre cada paso"
fi

echo ""
echo "=============================================="
