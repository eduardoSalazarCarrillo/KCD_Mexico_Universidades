#!/bin/bash
# =============================================================================
# Lab 08: Services - Script de Solución Completa
# =============================================================================
# Este script ejecuta todos los comandos del laboratorio de forma secuencial.
# Úsalo como referencia o para verificar que completaste correctamente el lab.
#
# NOTA: Este script asume que Minikube está corriendo (Labs anteriores completados).
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
# Verificación Inicial
# =============================================================================
print_step "Verificación Inicial"

if ! command -v minikube &> /dev/null; then
    echo -e "${RED}Error: Minikube no está instalado.${NC}"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl no está instalado.${NC}"
    exit 1
fi

print_command "minikube status"
if ! minikube status &> /dev/null; then
    echo -e "${YELLOW}Minikube no está corriendo. Iniciando...${NC}"
    minikube start --driver=docker
fi
minikube status

echo ""
echo -e "${GREEN}✓ Minikube está corriendo${NC}"

wait_for_user

# =============================================================================
# Paso 2: Crear el Deployment Base
# =============================================================================
print_step "Paso 2: Crear el Deployment Base"

print_command "cat $LAB_DIR/initial/deployment-web.yaml"
cat "$LAB_DIR/initial/deployment-web.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/deployment-web.yaml"
kubectl apply -f "$LAB_DIR/initial/deployment-web.yaml"

echo ""
print_command "kubectl get pods -l app=web -o wide"
kubectl get pods -l app=web -o wide

echo ""
echo "Esperando a que los pods estén listos..."
kubectl rollout status deployment web-app --timeout=60s

echo ""
print_command "kubectl get pods -l app=web -o wide"
kubectl get pods -l app=web -o wide

echo ""
echo -e "${GREEN}✓ Deployment creado con 3 réplicas${NC}"

wait_for_user

# =============================================================================
# Paso 3: Demostrar IPs Efímeras
# =============================================================================
print_step "Paso 3: Demostrar Problema de IPs Efímeras"

print_command "POD_IP=\$(kubectl get pod -l app=web -o jsonpath='{.items[0].status.podIP}')"
POD_IP=$(kubectl get pod -l app=web -o jsonpath='{.items[0].status.podIP}')
echo "IP del Pod: $POD_IP"

print_command "POD_NAME=\$(kubectl get pod -l app=web -o jsonpath='{.items[0].metadata.name}')"
POD_NAME=$(kubectl get pod -l app=web -o jsonpath='{.items[0].metadata.name}')
echo "Nombre del Pod: $POD_NAME"

echo ""
print_command "kubectl delete pod $POD_NAME"
kubectl delete pod $POD_NAME

echo ""
echo "Esperando a que se cree el nuevo Pod..."
sleep 5
kubectl rollout status deployment web-app --timeout=60s

echo ""
print_command "kubectl get pods -l app=web -o wide"
kubectl get pods -l app=web -o wide

echo ""
echo -e "${YELLOW}Observa: El nuevo Pod tiene una IP diferente${NC}"
echo -e "${GREEN}✓ Demostración de IPs efímeras completada${NC}"

wait_for_user

# =============================================================================
# Paso 4: Crear Service ClusterIP
# =============================================================================
print_step "Paso 4: Crear Service ClusterIP"

print_command "cat $LAB_DIR/initial/service-clusterip.yaml"
cat "$LAB_DIR/initial/service-clusterip.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/service-clusterip.yaml"
kubectl apply -f "$LAB_DIR/initial/service-clusterip.yaml"

echo ""
print_command "kubectl get service web-clusterip"
kubectl get service web-clusterip

echo ""
echo -e "${GREEN}✓ Service ClusterIP creado${NC}"

wait_for_user

# =============================================================================
# Paso 5: Inspeccionar Endpoints
# =============================================================================
print_step "Paso 5: Inspeccionar Endpoints"

print_command "kubectl get endpoints web-clusterip"
kubectl get endpoints web-clusterip

echo ""
print_command "kubectl describe endpoints web-clusterip"
kubectl describe endpoints web-clusterip

echo ""
echo -e "${GREEN}✓ Endpoints inspeccionados${NC}"

wait_for_user

# =============================================================================
# Paso 6: Probar Conectividad Interna
# =============================================================================
print_step "Paso 6: Probar Conectividad Interna (ClusterIP)"

echo "Creando pod de prueba para verificar conectividad..."
echo ""

print_command "kubectl run test-client --image=busybox:1.36 --restart=Never -- sleep 300"
kubectl run test-client --image=busybox:1.36 --restart=Never -- sleep 300 2>/dev/null || true

echo "Esperando a que el pod de prueba esté listo..."
kubectl wait --for=condition=Ready pod/test-client --timeout=60s 2>/dev/null || sleep 5

echo ""
print_substep "Probando conexión al Service"
print_command "kubectl exec test-client -- wget -qO- http://web-clusterip"
kubectl exec test-client -- wget -qO- http://web-clusterip 2>/dev/null | head -10

echo ""
print_substep "Probando DNS del Service"
print_command "kubectl exec test-client -- nslookup web-clusterip"
kubectl exec test-client -- nslookup web-clusterip 2>/dev/null || echo "(nslookup completado)"

echo ""
print_command "kubectl delete pod test-client"
kubectl delete pod test-client --ignore-not-found

echo ""
echo -e "${GREEN}✓ Conectividad interna verificada${NC}"

wait_for_user

# =============================================================================
# Paso 7: Crear Service NodePort
# =============================================================================
print_step "Paso 7: Crear Service NodePort"

print_command "cat $LAB_DIR/initial/service-nodeport.yaml"
cat "$LAB_DIR/initial/service-nodeport.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/service-nodeport.yaml"
kubectl apply -f "$LAB_DIR/initial/service-nodeport.yaml"

echo ""
print_command "kubectl get service web-nodeport"
kubectl get service web-nodeport

echo ""
echo -e "${GREEN}✓ Service NodePort creado${NC}"

wait_for_user

# =============================================================================
# Paso 8: Acceder desde Fuera del Clúster
# =============================================================================
print_step "Paso 8: Acceder desde Fuera del Clúster"

print_command "minikube service web-nodeport --url"
SERVICE_URL=$(minikube service web-nodeport --url 2>/dev/null)
echo "URL del Service: $SERVICE_URL"

echo ""
print_command "curl -s $SERVICE_URL"
curl -s "$SERVICE_URL" 2>/dev/null | head -10

echo ""
print_substep "Usando minikube ip manualmente"
print_command "minikube ip"
MINIKUBE_IP=$(minikube ip)
echo "IP de Minikube: $MINIKUBE_IP"

echo ""
print_command "curl -s http://$MINIKUBE_IP:30080"
curl -s "http://$MINIKUBE_IP:30080" 2>/dev/null | head -10

echo ""
echo -e "${GREEN}✓ Acceso externo verificado${NC}"

wait_for_user

# =============================================================================
# Paso 9: Crear Service con kubectl expose
# =============================================================================
print_step "Paso 9: Crear Service con kubectl expose"

print_command "kubectl expose deployment web-app --name=web-exposed --port=8080 --target-port=80"
kubectl expose deployment web-app --name=web-exposed --port=8080 --target-port=80

echo ""
print_command "kubectl get service web-exposed"
kubectl get service web-exposed

echo ""
print_command "kubectl describe service web-exposed"
kubectl describe service web-exposed

echo ""
echo -e "${GREEN}✓ Service creado con kubectl expose${NC}"

wait_for_user

# =============================================================================
# Paso 10: Comparar Todos los Services
# =============================================================================
print_step "Paso 10: Comparar Todos los Services"

print_command "kubectl get services"
kubectl get services

echo ""
print_command "kubectl get endpoints"
kubectl get endpoints

echo ""
echo -e "${GREEN}✓ Services comparados${NC}"

wait_for_user

# =============================================================================
# Paso 11: Verificar Balanceo de Carga
# =============================================================================
print_step "Paso 11: Verificar Balanceo de Carga"

print_substep "Modificando respuesta de cada Pod"
PODS=$(kubectl get pods -l app=web -o jsonpath='{.items[*].metadata.name}')
for POD in $PODS; do
    print_command "kubectl exec $POD -- sh -c \"echo '<h1>Pod: $POD</h1>' > /usr/share/nginx/html/index.html\""
    kubectl exec $POD -- sh -c "echo '<h1>Pod: $POD</h1>' > /usr/share/nginx/html/index.html"
done

echo ""
print_substep "Probando balanceo de carga (5 requests)"
for i in $(seq 1 5); do
    echo "Request $i:"
    curl -s "http://$MINIKUBE_IP:30080" 2>/dev/null || echo "(Error de conexión)"
done

echo ""
echo -e "${GREEN}✓ Balanceo de carga verificado${NC}"

wait_for_user

# =============================================================================
# Paso 12: Escalar y Observar Endpoints
# =============================================================================
print_step "Paso 12: Escalar y Observar Endpoints"

print_command "kubectl get endpoints web-clusterip"
kubectl get endpoints web-clusterip

echo ""
print_command "kubectl scale deployment web-app --replicas=5"
kubectl scale deployment web-app --replicas=5

echo ""
echo "Esperando a que los pods estén listos..."
kubectl rollout status deployment web-app --timeout=60s

echo ""
print_command "kubectl get endpoints web-clusterip"
kubectl get endpoints web-clusterip

echo ""
print_command "kubectl get pods -l app=web"
kubectl get pods -l app=web

echo ""
print_substep "Escalando de vuelta a 3"
print_command "kubectl scale deployment web-app --replicas=3"
kubectl scale deployment web-app --replicas=3
kubectl rollout status deployment web-app --timeout=60s

echo ""
echo -e "${GREEN}✓ Escalado y endpoints verificados${NC}"

wait_for_user

# =============================================================================
# Paso 13: Service con Múltiples Labels
# =============================================================================
print_step "Paso 13: Service con Múltiples Labels"

print_command "cat $LAB_DIR/initial/service-multi-selector.yaml"
cat "$LAB_DIR/initial/service-multi-selector.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/service-multi-selector.yaml"
kubectl apply -f "$LAB_DIR/initial/service-multi-selector.yaml"

echo ""
print_command "kubectl get service web-v1-only"
kubectl get service web-v1-only

echo ""
print_command "kubectl get endpoints web-v1-only"
kubectl get endpoints web-v1-only

echo ""
echo -e "${GREEN}✓ Service con múltiples labels creado${NC}"

wait_for_user

# =============================================================================
# Paso 14: Limpiar Recursos
# =============================================================================
print_step "Paso 14: Limpiar Recursos"

print_command "kubectl delete service web-clusterip web-nodeport web-exposed web-v1-only"
kubectl delete service web-clusterip web-nodeport web-exposed web-v1-only

echo ""
print_command "kubectl delete deployment web-app"
kubectl delete deployment web-app

echo ""
print_command "kubectl get all"
kubectl get all

echo ""
echo -e "${GREEN}✓ Recursos limpiados${NC}"

wait_for_user

# =============================================================================
# Resumen Final
# =============================================================================
print_step "Laboratorio Completado"

echo "Has completado exitosamente el Lab 08: Services"
echo ""
echo "Resumen de lo aprendido:"
echo ""
echo "  TIPOS DE SERVICES:"
echo "    - ClusterIP    : IP interna estable, acceso solo dentro del clúster"
echo "    - NodePort     : Expone en puerto del nodo (30000-32767)"
echo "    - LoadBalancer : IP externa via balanceador de carga del cloud"
echo ""
echo "  CONCEPTOS CLAVE:"
echo "    - Selector     : Define qué Pods pertenecen al Service"
echo "    - Endpoints    : IPs de los Pods que coinciden con el selector"
echo "    - DNS interno  : <service>.<namespace>.svc.cluster.local"
echo "    - Balanceo     : kube-proxy distribuye tráfico entre Pods"
echo ""
echo "Comandos principales aprendidos:"
echo "  - kubectl get services / svc"
echo "  - kubectl get endpoints"
echo "  - kubectl describe service <nombre>"
echo "  - kubectl expose deployment <nombre>"
echo "  - minikube service <nombre> --url"
echo ""
echo -e "${GREEN}¡Felicitaciones! Estás listo para el Lab 09: Ingress${NC}"
