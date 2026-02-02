#!/bin/bash
# =============================================================================
# Lab 17: Prometheus y Grafana - Verificación de Completado
# =============================================================================
# Este script verifica que has completado correctamente el laboratorio
# probando tus conocimientos de monitoreo con Prometheus y Grafana.
# =============================================================================

echo "=============================================="
echo "  Lab 17: Verificación de Completado"
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

check_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

# =============================================================================
# Verificación 1: Minikube corriendo
# =============================================================================
echo "1. Verificando que Minikube está corriendo..."

if minikube status &> /dev/null; then
    check_passed "Minikube está corriendo"
else
    check_failed "Minikube no está corriendo"
    echo "   Ejecuta: minikube start --driver=docker --memory=4096"
fi

# =============================================================================
# Verificación 2: kubectl disponible
# =============================================================================
echo ""
echo "2. Verificando kubectl..."

if kubectl version --client &> /dev/null; then
    check_passed "kubectl está disponible"
else
    check_failed "kubectl no está disponible"
fi

# =============================================================================
# Verificación 3: Helm instalado
# =============================================================================
echo ""
echo "3. Verificando Helm..."

if command -v helm &> /dev/null; then
    check_passed "Helm está instalado"
    HELM_VERSION=$(helm version --short 2>/dev/null)
    echo "   Versión: $HELM_VERSION"
else
    check_failed "Helm no está instalado"
    echo "   Ejecuta: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
fi

# =============================================================================
# Verificación 4: Namespace monitoring existe
# =============================================================================
echo ""
echo "4. Verificando namespace de monitoreo..."

if kubectl get namespace monitoring &> /dev/null; then
    check_passed "Namespace 'monitoring' existe"
else
    check_failed "Namespace 'monitoring' no existe"
    echo "   Ejecuta: kubectl create namespace monitoring"
fi

# =============================================================================
# Verificación 5: Prometheus Stack instalado
# =============================================================================
echo ""
echo "5. Verificando Prometheus Stack..."

if helm list -n monitoring 2>/dev/null | grep -q prometheus; then
    check_passed "Prometheus Stack está instalado con Helm"
else
    check_failed "Prometheus Stack no está instalado"
    echo "   Ejecuta: helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring"
fi

# =============================================================================
# Verificación 6: Pods de Prometheus corriendo
# =============================================================================
echo ""
echo "6. Verificando pods de Prometheus..."

PROMETHEUS_PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --no-headers 2>/dev/null | grep -c "Running" || echo "0")
if [ "$PROMETHEUS_PODS" -gt 0 ]; then
    check_passed "Prometheus está corriendo ($PROMETHEUS_PODS pods)"
else
    check_failed "Prometheus no está corriendo"
    echo "   Verifica: kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus"
fi

# =============================================================================
# Verificación 7: Pods de Grafana corriendo
# =============================================================================
echo ""
echo "7. Verificando pods de Grafana..."

GRAFANA_PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana --no-headers 2>/dev/null | grep -c "Running" || echo "0")
if [ "$GRAFANA_PODS" -gt 0 ]; then
    check_passed "Grafana está corriendo ($GRAFANA_PODS pods)"
else
    check_failed "Grafana no está corriendo"
    echo "   Verifica: kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana"
fi

# =============================================================================
# Verificación 8: Alertmanager corriendo
# =============================================================================
echo ""
echo "8. Verificando Alertmanager..."

ALERTMANAGER_PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager --no-headers 2>/dev/null | grep -c "Running" || echo "0")
if [ "$ALERTMANAGER_PODS" -gt 0 ]; then
    check_passed "Alertmanager está corriendo ($ALERTMANAGER_PODS pods)"
else
    check_failed "Alertmanager no está corriendo"
    echo "   Verifica: kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager"
fi

# =============================================================================
# Verificación 9: Prometheus Operator corriendo
# =============================================================================
echo ""
echo "9. Verificando Prometheus Operator..."

OPERATOR_PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=kube-prometheus-stack-prometheus-operator --no-headers 2>/dev/null | grep -c "Running" || echo "0")
if [ "$OPERATOR_PODS" -gt 0 ]; then
    check_passed "Prometheus Operator está corriendo"
else
    check_failed "Prometheus Operator no está corriendo"
fi

# =============================================================================
# Verificación 10: Node Exporter corriendo
# =============================================================================
echo ""
echo "10. Verificando Node Exporter..."

NODE_EXPORTER_PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus-node-exporter --no-headers 2>/dev/null | grep -c "Running" || echo "0")
if [ "$NODE_EXPORTER_PODS" -gt 0 ]; then
    check_passed "Node Exporter está corriendo ($NODE_EXPORTER_PODS pods)"
else
    check_failed "Node Exporter no está corriendo"
fi

# =============================================================================
# Verificación 11: kube-state-metrics corriendo
# =============================================================================
echo ""
echo "11. Verificando kube-state-metrics..."

KSM_PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=kube-state-metrics --no-headers 2>/dev/null | grep -c "Running" || echo "0")
if [ "$KSM_PODS" -gt 0 ]; then
    check_passed "kube-state-metrics está corriendo"
else
    check_failed "kube-state-metrics no está corriendo"
fi

# =============================================================================
# Verificación 12: Services de Prometheus existen
# =============================================================================
echo ""
echo "12. Verificando Services de monitoreo..."

PROMETHEUS_SVC=$(kubectl get svc -n monitoring prometheus-kube-prometheus-prometheus --no-headers 2>/dev/null | wc -l)
GRAFANA_SVC=$(kubectl get svc -n monitoring prometheus-grafana --no-headers 2>/dev/null | wc -l)
ALERTMANAGER_SVC=$(kubectl get svc -n monitoring prometheus-kube-prometheus-alertmanager --no-headers 2>/dev/null | wc -l)

if [ "$PROMETHEUS_SVC" -gt 0 ]; then
    check_passed "Service de Prometheus existe"
else
    check_failed "Service de Prometheus no existe"
fi

if [ "$GRAFANA_SVC" -gt 0 ]; then
    check_passed "Service de Grafana existe"
else
    check_failed "Service de Grafana no existe"
fi

if [ "$ALERTMANAGER_SVC" -gt 0 ]; then
    check_passed "Service de Alertmanager existe"
else
    check_failed "Service de Alertmanager no existe"
fi

# =============================================================================
# Verificación 13: PrometheusRules existen
# =============================================================================
echo ""
echo "13. Verificando PrometheusRules..."

PROM_RULES=$(kubectl get prometheusrules -n monitoring --no-headers 2>/dev/null | wc -l)
if [ "$PROM_RULES" -gt 0 ]; then
    check_passed "PrometheusRules están configuradas ($PROM_RULES reglas)"
else
    check_warning "No hay PrometheusRules configuradas"
    ((CHECKS_TOTAL++))
fi

# Verificar regla custom-alerts
if kubectl get prometheusrule custom-alerts -n monitoring &> /dev/null; then
    check_passed "Regla 'custom-alerts' existe"
else
    check_warning "Regla 'custom-alerts' no existe (ejercicio opcional)"
    ((CHECKS_TOTAL++))
fi

# =============================================================================
# Verificación 14: ServiceMonitors existen
# =============================================================================
echo ""
echo "14. Verificando ServiceMonitors..."

SERVICE_MONITORS=$(kubectl get servicemonitors -n monitoring --no-headers 2>/dev/null | wc -l)
if [ "$SERVICE_MONITORS" -gt 0 ]; then
    check_passed "ServiceMonitors están configurados ($SERVICE_MONITORS monitores)"
else
    check_failed "No hay ServiceMonitors configurados"
fi

# =============================================================================
# Verificación 15: Aplicación de ejemplo
# =============================================================================
echo ""
echo "15. Verificando aplicación de ejemplo (demo-app)..."

if kubectl get namespace demo-app &> /dev/null; then
    DEMO_PODS=$(kubectl get pods -n demo-app --no-headers 2>/dev/null | grep -c "Running" || echo "0")
    if [ "$DEMO_PODS" -gt 0 ]; then
        check_passed "Aplicación demo-app está corriendo ($DEMO_PODS pods)"
    else
        check_warning "demo-app existe pero no tiene pods Running"
        ((CHECKS_TOTAL++))
    fi
else
    check_warning "Namespace demo-app no existe (ejercicio opcional)"
    ((CHECKS_TOTAL++))
fi

# =============================================================================
# Verificación 16: Verificar archivos del laboratorio
# =============================================================================
echo ""
echo "16. Verificando archivos del laboratorio..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

if [ -f "$LAB_DIR/initial/alertrule.yaml" ]; then
    check_passed "Archivo alertrule.yaml existe en initial/"
else
    check_failed "Archivo alertrule.yaml no encontrado en initial/"
fi

if [ -f "$LAB_DIR/initial/sample-app.yaml" ]; then
    check_passed "Archivo sample-app.yaml existe en initial/"
else
    check_failed "Archivo sample-app.yaml no encontrado en initial/"
fi

if [ -f "$LAB_DIR/initial/prometheus-values.yaml" ]; then
    check_passed "Archivo prometheus-values.yaml existe en initial/"
else
    check_failed "Archivo prometheus-values.yaml no encontrado en initial/"
fi

# =============================================================================
# Verificación 17: Prometheus respondiendo
# =============================================================================
echo ""
echo "17. Verificando conectividad a Prometheus..."

# Intentar conectar via port-forward temporal
PROMETHEUS_POD=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$PROMETHEUS_POD" ]; then
    # Usar kubectl exec para verificar que Prometheus responde
    if kubectl exec -n monitoring "$PROMETHEUS_POD" -c prometheus -- wget -q -O- http://localhost:9090/-/healthy 2>/dev/null | grep -q "Healthy"; then
        check_passed "Prometheus responde correctamente"
    else
        check_warning "No se pudo verificar la salud de Prometheus"
        ((CHECKS_TOTAL++))
    fi
else
    check_failed "No se encontró el pod de Prometheus"
fi

# =============================================================================
# Resumen
# =============================================================================
echo ""
echo "=============================================="
echo "  Resumen de Verificación"
echo "=============================================="
echo ""
echo "Verificaciones pasadas: $CHECKS_PASSED/$CHECKS_TOTAL"
echo ""

if [ $CHECKS_PASSED -eq $CHECKS_TOTAL ]; then
    echo -e "${GREEN}¡FELICITACIONES!${NC}"
    echo -e "${GREEN}Has completado exitosamente el Lab 17: Prometheus y Grafana${NC}"
    echo ""
    echo "Has demostrado que puedes:"
    echo "  - Instalar y configurar Prometheus con Helm"
    echo "  - Desplegar Grafana para visualización"
    echo "  - Configurar Alertmanager para alertas"
    echo "  - Crear reglas de alerta personalizadas"
    echo "  - Entender métricas de Kubernetes"
    echo ""
    echo "URLs de acceso (requieren port-forward):"
    echo "  - Prometheus: kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
    echo "  - Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
    echo "  - Alertmanager: kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093"
    echo ""
    echo "Estás listo para continuar con el Lab 18: Managed Kubernetes"
elif [ $CHECKS_PASSED -ge $((CHECKS_TOTAL * 70 / 100)) ]; then
    echo -e "${YELLOW}¡Buen progreso!${NC}"
    echo "Has completado la mayoría de las verificaciones ($CHECKS_PASSED/$CHECKS_TOTAL)"
    echo ""
    echo "Revisa los puntos marcados con ✗ y vuelve a intentar."
else
    FAILED=$((CHECKS_TOTAL - CHECKS_PASSED))
    echo -e "${YELLOW}Algunas verificaciones fallaron ($FAILED de $CHECKS_TOTAL)${NC}"
    echo "Revisa los puntos marcados con ✗ y vuelve a intentar"
    echo ""
    echo "Posibles soluciones:"
    echo "  - Asegúrate de que Minikube está corriendo con suficiente memoria (4GB)"
    echo "  - Instala Helm si no está disponible"
    echo "  - Agrega el repositorio: helm repo add prometheus-community https://prometheus-community.github.io/helm-charts"
    echo "  - Instala el stack: helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring"
    echo "  - Espera a que todos los pods estén en estado Running"
    echo "  - Revisa el README.md para más detalles"
fi

echo ""
echo "=============================================="
