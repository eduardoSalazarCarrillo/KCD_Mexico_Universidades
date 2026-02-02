#!/bin/bash
# =============================================================================
# Lab 17: Prometheus y Grafana - Script de Solución Completa
# =============================================================================
# Este script ejecuta todos los comandos del laboratorio de forma secuencial.
# Úsalo como referencia o para verificar que completaste correctamente el lab.
#
# NOTA: Este script asume que Minikube está corriendo y Helm está instalado.
# =============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

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

# =============================================================================
# Verificación Inicial
# =============================================================================
print_step "Verificación Inicial"

if ! command -v minikube &> /dev/null; then
    echo -e "${RED}Error: Minikube no está instalado.${NC}"
    echo "Por favor, completa el Lab 02 primero."
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl no está instalado.${NC}"
    echo "Por favor, completa el Lab 02 primero."
    exit 1
fi

print_command "minikube status"
if ! minikube status &> /dev/null; then
    echo -e "${YELLOW}Minikube no está corriendo. Iniciando...${NC}"
    minikube start --driver=docker --memory=4096 --cpus=2
fi
minikube status

echo ""
echo -e "${GREEN}✓ Minikube está corriendo${NC}"

wait_for_user

# =============================================================================
# Paso 1: Instalar Helm
# =============================================================================
print_step "Paso 1: Instalar Helm"

if command -v helm &> /dev/null; then
    echo -e "${GREEN}✓ Helm ya está instalado${NC}"
    print_command "helm version"
    helm version --short
else
    echo "Instalando Helm..."
    print_command "curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo ""
echo -e "${GREEN}✓ Helm está disponible${NC}"

wait_for_user

# =============================================================================
# Paso 2: Agregar repositorio de Prometheus
# =============================================================================
print_step "Paso 2: Agregar Repositorio de Prometheus"

print_command "helm repo add prometheus-community https://prometheus-community.github.io/helm-charts"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true

print_command "helm repo update"
helm repo update

echo ""
print_substep "Charts disponibles de Prometheus"
print_command "helm search repo prometheus-community | head -20"
helm search repo prometheus-community | head -20

echo ""
echo -e "${GREEN}✓ Repositorio de Prometheus agregado${NC}"

wait_for_user

# =============================================================================
# Paso 3: Crear namespace y desplegar aplicación de ejemplo
# =============================================================================
print_step "Paso 3: Desplegar Aplicación de Ejemplo"

print_substep "Aplicar aplicación de ejemplo"
print_command "kubectl apply -f $LAB_DIR/initial/sample-app.yaml"
kubectl apply -f "$LAB_DIR/initial/sample-app.yaml"

echo ""
echo "Esperando a que los pods estén listos..."
kubectl wait --for=condition=ready pod -l app=web-app -n demo-app --timeout=120s 2>/dev/null || true
kubectl wait --for=condition=ready pod -l app=backend-api -n demo-app --timeout=120s 2>/dev/null || true

echo ""
print_command "kubectl get all -n demo-app"
kubectl get all -n demo-app

echo ""
echo -e "${GREEN}✓ Aplicación de ejemplo desplegada${NC}"

wait_for_user

# =============================================================================
# Paso 4: Instalar Prometheus Stack
# =============================================================================
print_step "Paso 4: Instalar Prometheus Stack"

print_substep "Crear namespace para monitoreo"
print_command "kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -"
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

echo ""
print_substep "Instalar kube-prometheus-stack con Helm"
echo -e "${YELLOW}Esto puede tardar varios minutos...${NC}"
echo ""

print_command "helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \\"
echo "  --namespace monitoring \\"
echo "  -f $LAB_DIR/initial/prometheus-values.yaml"

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    -f "$LAB_DIR/initial/prometheus-values.yaml" \
    --wait --timeout 10m

echo ""
echo "Esperando a que todos los pods estén listos..."
sleep 30

print_command "kubectl get pods -n monitoring"
kubectl get pods -n monitoring

echo ""
print_command "kubectl get services -n monitoring"
kubectl get services -n monitoring

echo ""
echo -e "${GREEN}✓ Prometheus Stack instalado${NC}"

wait_for_user

# =============================================================================
# Paso 5: Acceder a Prometheus
# =============================================================================
print_step "Paso 5: Acceder a Prometheus"

print_substep "Verificar que Prometheus está funcionando"
print_command "kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus"
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus

echo ""
print_substep "Port-forward a Prometheus"
echo -e "${YELLOW}Iniciando port-forward en segundo plano...${NC}"
echo ""

# Matar cualquier port-forward existente
pkill -f "port-forward.*prometheus.*9090" 2>/dev/null || true
sleep 2

print_command "kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &"
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &
sleep 5

echo ""
echo -e "${GREEN}✓ Prometheus disponible en http://localhost:9090${NC}"
echo ""
echo "Puedes abrir tu navegador y visitar: http://localhost:9090"

wait_for_user

# =============================================================================
# Paso 6: Explorar Métricas en Prometheus
# =============================================================================
print_step "Paso 6: Explorar Métricas en Prometheus"

echo "Ejemplos de queries PromQL que puedes probar en http://localhost:9090:"
echo ""

echo -e "${CYAN}1. Uso de CPU por pod:${NC}"
echo '   sum(rate(container_cpu_usage_seconds_total{namespace="demo-app"}[5m])) by (pod)'
echo ""

echo -e "${CYAN}2. Memoria usada por pod:${NC}"
echo '   sum(container_memory_working_set_bytes{namespace="demo-app"}) by (pod)'
echo ""

echo -e "${CYAN}3. Número de pods por namespace:${NC}"
echo '   count by (namespace) (kube_pod_info)'
echo ""

echo -e "${CYAN}4. Pods en estado Running:${NC}"
echo '   kube_pod_status_phase{phase="Running"}'
echo ""

echo -e "${CYAN}5. Requests HTTP al API server:${NC}"
echo '   sum(rate(apiserver_request_total[5m])) by (verb)'
echo ""

print_substep "Probar una query con curl"
print_command "curl -s 'http://localhost:9090/api/v1/query?query=up' | head -c 500"
curl -s 'http://localhost:9090/api/v1/query?query=up' 2>/dev/null | head -c 500 || echo "(Port-forward puede no estar activo)"
echo ""

wait_for_user

# =============================================================================
# Paso 7: Acceder a Grafana
# =============================================================================
print_step "Paso 7: Acceder a Grafana"

print_substep "Verificar que Grafana está funcionando"
print_command "kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana"
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana

echo ""
print_substep "Port-forward a Grafana"
echo -e "${YELLOW}Iniciando port-forward en segundo plano...${NC}"
echo ""

# Matar cualquier port-forward existente
pkill -f "port-forward.*grafana.*3000" 2>/dev/null || true
sleep 2

print_command "kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &"
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &
sleep 5

echo ""
echo -e "${GREEN}✓ Grafana disponible en http://localhost:3000${NC}"
echo ""
echo "Credenciales de acceso:"
echo "  Usuario: admin"
echo "  Contraseña: admin123"

wait_for_user

# =============================================================================
# Paso 8: Explorar Dashboards de Grafana
# =============================================================================
print_step "Paso 8: Explorar Dashboards de Grafana"

echo "En Grafana (http://localhost:3000), explora los siguientes dashboards:"
echo ""
echo "1. Ve a: Dashboards → Browse"
echo ""
echo "2. Dashboards recomendados para explorar:"
echo "   - Kubernetes / Compute Resources / Cluster"
echo "   - Kubernetes / Compute Resources / Namespace (Pods)"
echo "   - Kubernetes / Compute Resources / Node (Pods)"
echo "   - Kubernetes / Networking / Pod"
echo "   - Node Exporter / Nodes"
echo "   - CoreDNS"
echo ""
echo "3. Cada dashboard muestra diferentes métricas del clúster:"
echo "   - Uso de CPU y memoria"
echo "   - Tráfico de red"
echo "   - Estado de pods y deployments"
echo "   - Métricas del sistema operativo"

wait_for_user

# =============================================================================
# Paso 9: Crear Dashboard Personalizado
# =============================================================================
print_step "Paso 9: Crear Dashboard Personalizado"

echo "Instrucciones para crear un dashboard personalizado en Grafana:"
echo ""
echo "1. Click en '+' → 'New Dashboard'"
echo "2. Click en 'Add visualization'"
echo "3. Selecciona 'Prometheus' como datasource"
echo ""
echo "4. Panel 1 - CPU Usage:"
echo '   Query: sum(rate(container_cpu_usage_seconds_total{namespace="demo-app"}[5m])) by (pod)'
echo "   Title: CPU Usage by Pod"
echo "   Legend: {{pod}}"
echo ""
echo "5. Panel 2 - Memory Usage:"
echo '   Query: sum(container_memory_working_set_bytes{namespace="demo-app"}) by (pod)'
echo "   Title: Memory Usage by Pod"
echo "   Legend: {{pod}}"
echo ""
echo "6. Panel 3 - Pod Count:"
echo '   Query: count(kube_pod_info{namespace="demo-app"})'
echo "   Title: Total Pods in demo-app"
echo "   Visualization: Stat"
echo ""
echo "7. Guarda el dashboard con un nombre descriptivo"

wait_for_user

# =============================================================================
# Paso 10: Configurar Alertas
# =============================================================================
print_step "Paso 10: Configurar Alertas"

print_substep "Aplicar reglas de alerta personalizadas"
print_command "cat $LAB_DIR/initial/alertrule.yaml"
cat "$LAB_DIR/initial/alertrule.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/alertrule.yaml"
kubectl apply -f "$LAB_DIR/initial/alertrule.yaml"

echo ""
print_substep "Verificar reglas de alerta"
print_command "kubectl get prometheusrules -n monitoring"
kubectl get prometheusrules -n monitoring

echo ""
print_substep "Ver alertas activas"
echo "Puedes ver las alertas en: http://localhost:9090/alerts"

echo ""
echo -e "${GREEN}✓ Reglas de alerta configuradas${NC}"

wait_for_user

# =============================================================================
# Paso 11: Acceder a Alertmanager
# =============================================================================
print_step "Paso 11: Acceder a Alertmanager"

print_substep "Port-forward a Alertmanager"
echo -e "${YELLOW}Iniciando port-forward en segundo plano...${NC}"
echo ""

# Matar cualquier port-forward existente
pkill -f "port-forward.*alertmanager.*9093" 2>/dev/null || true
sleep 2

print_command "kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093 &"
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093 &
sleep 5

echo ""
echo -e "${GREEN}✓ Alertmanager disponible en http://localhost:9093${NC}"
echo ""
echo "En Alertmanager puedes:"
echo "  - Ver alertas activas"
echo "  - Silenciar alertas temporalmente"
echo "  - Ver el estado de las notificaciones"

wait_for_user

# =============================================================================
# Paso 12: Ver métricas con kubectl
# =============================================================================
print_step "Paso 12: Ver Métricas con kubectl"

print_substep "Métricas de nodos"
print_command "kubectl top nodes"
kubectl top nodes 2>/dev/null || echo "(Metrics Server puede no estar habilitado en Minikube)"

echo ""
print_substep "Métricas de pods en monitoring"
print_command "kubectl top pods -n monitoring"
kubectl top pods -n monitoring 2>/dev/null || echo "(Metrics Server puede no estar habilitado)"

echo ""
print_substep "Métricas de pods en demo-app"
print_command "kubectl top pods -n demo-app"
kubectl top pods -n demo-app 2>/dev/null || echo "(Metrics Server puede no estar habilitado)"

echo ""
echo -e "${YELLOW}Nota: Si kubectl top no funciona, habilita Metrics Server:${NC}"
echo "  minikube addons enable metrics-server"

wait_for_user

# =============================================================================
# Ejercicios Adicionales
# =============================================================================
print_step "Ejercicios Adicionales"

echo "Ejercicios para practicar:"
echo ""
echo "1. Crear un dashboard para la aplicación demo-app:"
echo "   - Mostrar CPU, memoria y número de pods"
echo "   - Agregar alertas visuales cuando CPU > 50%"
echo ""
echo "2. Configurar una alerta por uso excesivo de CPU:"
echo "   - Editar alertrule.yaml"
echo "   - Cambiar el umbral de 80% a 50%"
echo "   - Aplicar con kubectl apply"
echo ""
echo "3. Explorar métricas de Kubernetes:"
echo "   - kube_deployment_* para deployments"
echo "   - kube_pod_* para pods"
echo "   - container_* para contenedores"
echo ""
echo "4. Configurar notificaciones en Alertmanager:"
echo "   - Agregar receptor de email"
echo "   - Configurar rutas de notificación"

wait_for_user

# =============================================================================
# Resumen Final
# =============================================================================
print_step "Laboratorio Completado"

echo "Has completado exitosamente el Lab 17: Prometheus y Grafana"
echo ""
echo "Resumen de conceptos aprendidos:"
echo ""
echo "  PROMETHEUS:"
echo "    - Sistema de monitoreo y alertas"
echo "    - Pull-based (scraping de métricas)"
echo "    - Lenguaje de queries: PromQL"
echo "    - Almacenamiento de series temporales"
echo ""
echo "  GRAFANA:"
echo "    - Plataforma de visualización"
echo "    - Dashboards interactivos"
echo "    - Múltiples datasources"
echo "    - Alertas visuales"
echo ""
echo "  ALERTMANAGER:"
echo "    - Manejo de alertas"
echo "    - Agrupación y deduplicación"
echo "    - Notificaciones (email, Slack, etc.)"
echo ""
echo "  kube-prometheus-stack:"
echo "    - Prometheus Operator"
echo "    - ServiceMonitor y PodMonitor"
echo "    - PrometheusRule para alertas"
echo "    - Node Exporter para métricas del sistema"
echo ""
echo "URLs de acceso:"
echo "  - Prometheus: http://localhost:9090"
echo "  - Grafana:    http://localhost:3000 (admin/admin123)"
echo "  - Alertmanager: http://localhost:9093"
echo ""
echo "Comandos principales aprendidos:"
echo "  - helm repo add/update"
echo "  - helm install/upgrade"
echo "  - kubectl port-forward"
echo "  - kubectl top nodes/pods"
echo "  - kubectl get prometheusrules"
echo ""
echo -e "${GREEN}¡Felicitaciones! Estás listo para el Lab 18: Managed Kubernetes${NC}"
echo ""
echo -e "${YELLOW}Para limpiar los recursos, ejecuta:${NC}"
echo "  helm uninstall prometheus -n monitoring"
echo "  kubectl delete namespace monitoring"
echo "  kubectl delete -f $LAB_DIR/initial/sample-app.yaml"
