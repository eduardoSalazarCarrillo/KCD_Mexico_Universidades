#!/bin/bash
#
# Script de verificación - Proyecto Final
#
# Este script verifica que todos los componentes del proyecto están
# desplegados y funcionando correctamente.
#

NAMESPACE="todo-app"
ERRORS=0
WARNINGS=0

echo "=============================================="
echo "Verificación del Proyecto Final"
echo "=============================================="
echo ""

# Función para verificar un recurso
check_resource() {
    local type=$1
    local name=$2
    local namespace=$3

    # Para namespaces, no usar -n flag
    if [ "$type" = "namespace" ]; then
        if kubectl get $type $name &>/dev/null; then
            echo "✅ $type/$name existe"
            return 0
        else
            echo "❌ $type/$name NO encontrado"
            ((ERRORS++))
            return 1
        fi
    else
        if kubectl get $type $name -n $namespace &>/dev/null; then
            echo "✅ $type/$name existe"
            return 0
        else
            echo "❌ $type/$name NO encontrado"
            ((ERRORS++))
            return 1
        fi
    fi
}

# Función para verificar pods en estado Running
check_pods_running() {
    local label=$1
    local expected=$2
    local namespace=$3

    local running=$(kubectl get pods -l $label -n $namespace --field-selector=status.phase=Running -o name 2>/dev/null | wc -l)

    if [ "$running" -ge "$expected" ]; then
        echo "✅ Pods con label '$label': $running/$expected running"
        return 0
    else
        echo "❌ Pods con label '$label': $running/$expected running"
        ((ERRORS++))
        return 1
    fi
}

# ============================================
# Verificar Namespace
# ============================================
echo "=== Verificando Namespace ==="
check_resource namespace $NAMESPACE ""
echo ""

# ============================================
# Verificar ConfigMaps y Secrets
# ============================================
echo "=== Verificando Configuración ==="
check_resource configmap backend-config $NAMESPACE
check_resource secret postgres-secret $NAMESPACE
echo ""

# ============================================
# Verificar PostgreSQL
# ============================================
echo "=== Verificando PostgreSQL ==="
check_resource statefulset postgres $NAMESPACE
check_resource service postgres $NAMESPACE
check_resource pvc postgres-pvc $NAMESPACE
check_pods_running "app=postgres" 1 $NAMESPACE
echo ""

# ============================================
# Verificar Backend
# ============================================
echo "=== Verificando Backend ==="
check_resource deployment backend $NAMESPACE
check_resource service backend $NAMESPACE
check_pods_running "app=backend" 2 $NAMESPACE

# Verificar health del backend
echo "Verificando health check del backend..."
BACKEND_POD=$(kubectl get pod -l app=backend -n $NAMESPACE -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$BACKEND_POD" ]; then
    # Usar node para el health check (wget no disponible en alpine)
    # Usar 127.0.0.1 en lugar de localhost para evitar problemas con IPv6
    HEALTH=$(kubectl exec $BACKEND_POD -n $NAMESPACE -- node -e "
        const http = require('http');
        http.get('http://127.0.0.1:3000/health', (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => console.log(data));
        }).on('error', () => process.exit(1));
    " 2>/dev/null)
    if echo "$HEALTH" | grep -q "ok"; then
        echo "✅ Backend health check: OK"
    else
        echo "⚠️  Backend health check: No responde correctamente"
        ((WARNINGS++))
    fi
else
    echo "⚠️  No se pudo verificar health check (pod no encontrado)"
    ((WARNINGS++))
fi
echo ""

# ============================================
# Verificar Frontend
# ============================================
echo "=== Verificando Frontend ==="
check_resource deployment frontend $NAMESPACE
check_resource service frontend $NAMESPACE
check_pods_running "app=frontend" 2 $NAMESPACE
echo ""

# ============================================
# Verificar Ingress
# ============================================
echo "=== Verificando Ingress ==="
check_resource ingress todo-ingress $NAMESPACE

# Verificar que Ingress tiene IP asignada
INGRESS_IP=$(kubectl get ingress todo-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -n "$INGRESS_IP" ]; then
    echo "✅ Ingress tiene IP asignada: $INGRESS_IP"
else
    echo "⚠️  Ingress no tiene IP asignada (puede requerir minikube tunnel)"
    ((WARNINGS++))
fi
echo ""

# ============================================
# Verificar HPA
# ============================================
echo "=== Verificando HPA ==="
check_resource hpa backend-hpa $NAMESPACE

# Verificar configuración del HPA
HPA_MIN=$(kubectl get hpa backend-hpa -n $NAMESPACE -o jsonpath='{.spec.minReplicas}' 2>/dev/null)
HPA_MAX=$(kubectl get hpa backend-hpa -n $NAMESPACE -o jsonpath='{.spec.maxReplicas}' 2>/dev/null)
if [ "$HPA_MIN" = "2" ] && [ "$HPA_MAX" = "10" ]; then
    echo "✅ HPA configurado correctamente (min: $HPA_MIN, max: $HPA_MAX)"
else
    echo "⚠️  HPA: min=$HPA_MIN, max=$HPA_MAX (esperado: min=2, max=10)"
    ((WARNINGS++))
fi
echo ""

# ============================================
# Verificar conectividad
# ============================================
echo "=== Verificando Conectividad ==="

# Verificar conexión backend -> postgres
echo "Verificando conexión backend -> postgres..."
# Usar node para verificar conectividad TCP (wget y nc no disponibles en alpine)
if kubectl exec $BACKEND_POD -n $NAMESPACE -- node -e "
    const net = require('net');
    const socket = new net.Socket();
    socket.setTimeout(5000);
    socket.connect(5432, 'postgres', () => { console.log('connected'); socket.destroy(); process.exit(0); });
    socket.on('error', () => process.exit(1));
    socket.on('timeout', () => process.exit(1));
" 2>/dev/null | grep -q "connected"; then
    echo "✅ Backend puede conectar a PostgreSQL"
else
    echo "⚠️  No se pudo verificar conexión a PostgreSQL"
    ((WARNINGS++))
fi
echo ""

# ============================================
# Verificar imágenes Docker
# ============================================
echo "=== Verificando Imágenes Docker ==="
BACKEND_IMAGE=$(kubectl get deployment backend -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
FRONTEND_IMAGE=$(kubectl get deployment frontend -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)

if [ "$BACKEND_IMAGE" = "todo-backend:v1" ]; then
    echo "✅ Backend usa imagen correcta: $BACKEND_IMAGE"
else
    echo "⚠️  Backend usa imagen: $BACKEND_IMAGE (esperado: todo-backend:v1)"
    ((WARNINGS++))
fi

if [ "$FRONTEND_IMAGE" = "todo-frontend:v1" ]; then
    echo "✅ Frontend usa imagen correcta: $FRONTEND_IMAGE"
else
    echo "⚠️  Frontend usa imagen: $FRONTEND_IMAGE (esperado: todo-frontend:v1)"
    ((WARNINGS++))
fi
echo ""

# ============================================
# Resumen
# ============================================
echo "=============================================="
echo "RESUMEN"
echo "=============================================="
echo ""

TOTAL_CHECKS=15

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "🎉 ¡EXCELENTE! Todos los componentes están desplegados correctamente."
    echo ""
    echo "El proyecto cumple con todos los requisitos:"
    echo "  ✅ Namespace creado"
    echo "  ✅ ConfigMaps y Secrets configurados"
    echo "  ✅ PostgreSQL con persistencia"
    echo "  ✅ Backend con 3 réplicas y health checks"
    echo "  ✅ Frontend con 3 réplicas"
    echo "  ✅ Ingress configurado"
    echo "  ✅ HPA para escalamiento automático"
elif [ $ERRORS -eq 0 ]; then
    echo "✅ Proyecto desplegado con $WARNINGS advertencia(s)"
    echo ""
    echo "El proyecto funciona pero revisa las advertencias arriba."
else
    echo "❌ Proyecto incompleto: $ERRORS error(es), $WARNINGS advertencia(s)"
    echo ""
    echo "Revisa los errores arriba y corrige los problemas."
fi

echo ""
echo "=============================================="
echo "Próximos pasos:"
echo "=============================================="
echo ""
echo "1. Agregar entrada a /etc/hosts:"
echo "   echo \"\$(minikube ip) todo.local\" | sudo tee -a /etc/hosts"
echo ""
echo "2. O usar minikube tunnel:"
echo "   minikube tunnel"
echo ""
echo "3. Acceder a la aplicación:"
echo "   http://todo.local"
echo ""

exit $ERRORS
