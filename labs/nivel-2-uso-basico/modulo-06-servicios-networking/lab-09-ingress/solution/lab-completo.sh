#!/bin/bash
# =============================================================================
# Lab 09: Ingress - Script de Solución Completa
# =============================================================================
# Este script ejecuta todos los comandos del laboratorio de forma secuencial.
# Úsalo como referencia o para verificar que completaste correctamente el lab.
#
# NOTA: Este script asume que Minikube está corriendo (Lab 08 completado).
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

wait_for_pods() {
    local label=$1
    echo "Esperando a que los pods estén listos..."
    kubectl wait --for=condition=Ready pods -l "$label" --timeout=120s 2>/dev/null || true
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
    minikube start --driver=docker
fi
minikube status

echo ""
echo -e "${GREEN}✓ Minikube está corriendo${NC}"

wait_for_user

# =============================================================================
# Paso 2: Habilitar el Ingress Controller en Minikube
# =============================================================================
print_step "Paso 2: Habilitar el Ingress Controller en Minikube"

print_command "minikube addons enable ingress"
minikube addons enable ingress

echo ""
print_substep "Verificando que el Ingress Controller está corriendo"
print_command "kubectl get pods -n ingress-nginx"

# Esperar a que el namespace exista
sleep 5

kubectl get pods -n ingress-nginx 2>/dev/null || echo "Esperando a que se creen los pods..."

echo ""
print_substep "Esperando a que el controlador esté listo"
print_command "kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s"
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s 2>/dev/null || echo "El controlador puede tardar en estar listo..."

echo ""
print_command "kubectl get pods -n ingress-nginx"
kubectl get pods -n ingress-nginx

echo ""
echo -e "${GREEN}✓ Ingress Controller habilitado${NC}"

wait_for_user

# =============================================================================
# Paso 3: Desplegar las Aplicaciones de Ejemplo
# =============================================================================
print_step "Paso 3: Desplegar las Aplicaciones de Ejemplo"

# Limpiar recursos previos si existen
kubectl delete deployment app-frontend app-backend --ignore-not-found=true 2>/dev/null
kubectl delete service frontend-svc backend-svc --ignore-not-found=true 2>/dev/null
kubectl delete ingress app-ingress app-ingress-host --ignore-not-found=true 2>/dev/null

print_command "cat $LAB_DIR/initial/apps.yaml"
echo "(Mostrando extracto...)"
head -50 "$LAB_DIR/initial/apps.yaml"
echo "..."

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/apps.yaml"
kubectl apply -f "$LAB_DIR/initial/apps.yaml"

echo ""
echo "Esperando a que los deployments estén listos..."
kubectl rollout status deployment/app-frontend --timeout=60s
kubectl rollout status deployment/app-backend --timeout=60s

echo ""
print_command "kubectl get deployments"
kubectl get deployments

echo ""
print_command "kubectl get services"
kubectl get services

echo ""
print_command "kubectl get pods -l 'app in (frontend, backend)'"
kubectl get pods -l 'app in (frontend, backend)'

echo ""
echo -e "${GREEN}✓ Aplicaciones desplegadas${NC}"

wait_for_user

# =============================================================================
# Paso 4: Crear Ingress con Reglas de Path
# =============================================================================
print_step "Paso 4: Crear Ingress con Reglas de Path"

print_command "cat $LAB_DIR/initial/ingress-path.yaml"
cat "$LAB_DIR/initial/ingress-path.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/ingress-path.yaml"
kubectl apply -f "$LAB_DIR/initial/ingress-path.yaml"

echo ""
echo "Esperando a que el Ingress tenga una dirección..."
sleep 5

print_command "kubectl get ingress"
kubectl get ingress

echo ""
print_command "kubectl describe ingress app-ingress"
kubectl describe ingress app-ingress

echo ""
echo -e "${GREEN}✓ Ingress basado en path creado${NC}"

wait_for_user

# =============================================================================
# Paso 5: Probar el Enrutamiento por Path
# =============================================================================
print_step "Paso 5: Probar el Enrutamiento por Path"

MINIKUBE_IP=$(minikube ip)
echo "IP de Minikube: $MINIKUBE_IP"

echo ""
print_substep "Probando /frontend"
print_command "curl http://$MINIKUBE_IP/frontend"
curl -s "http://$MINIKUBE_IP/frontend" 2>/dev/null || echo "Si curl falla, prueba con 'minikube tunnel' en otra terminal"

echo ""
print_substep "Probando /backend"
print_command "curl http://$MINIKUBE_IP/backend"
curl -s "http://$MINIKUBE_IP/backend" 2>/dev/null || echo "Si curl falla, prueba con 'minikube tunnel' en otra terminal"

echo ""
echo -e "${GREEN}✓ Enrutamiento por path probado${NC}"

wait_for_user

# =============================================================================
# Paso 6: Crear Ingress con Reglas de Host
# =============================================================================
print_step "Paso 6: Crear Ingress con Reglas de Host"

print_command "cat $LAB_DIR/initial/ingress-host.yaml"
cat "$LAB_DIR/initial/ingress-host.yaml"

echo ""
print_command "kubectl apply -f $LAB_DIR/initial/ingress-host.yaml"
kubectl apply -f "$LAB_DIR/initial/ingress-host.yaml"

echo ""
print_command "kubectl get ingress"
kubectl get ingress

echo ""
echo -e "${GREEN}✓ Ingress basado en host creado${NC}"

wait_for_user

# =============================================================================
# Paso 7: Configurar /etc/hosts
# =============================================================================
print_step "Paso 7: Configurar /etc/hosts"

echo -e "${YELLOW}NOTA: Este paso requiere privilegios de sudo.${NC}"
echo "Se agregará la siguiente línea a /etc/hosts:"
echo "$MINIKUBE_IP frontend.local backend.local"
echo ""

if grep -q "frontend.local" /etc/hosts; then
    echo "Las entradas ya existen en /etc/hosts"
else
    echo "Para agregar las entradas manualmente, ejecuta:"
    echo "  echo \"$MINIKUBE_IP frontend.local backend.local\" | sudo tee -a /etc/hosts"
fi

echo ""
echo -e "${GREEN}✓ Instrucciones de /etc/hosts mostradas${NC}"

wait_for_user

# =============================================================================
# Paso 8: Probar el Enrutamiento por Host
# =============================================================================
print_step "Paso 8: Probar el Enrutamiento por Host"

print_substep "Probando con header Host (funciona sin modificar /etc/hosts)"

print_command "curl -H 'Host: frontend.local' http://$MINIKUBE_IP"
curl -s -H "Host: frontend.local" "http://$MINIKUBE_IP" 2>/dev/null || echo "Si curl falla, el Ingress puede necesitar más tiempo"

echo ""
print_command "curl -H 'Host: backend.local' http://$MINIKUBE_IP"
curl -s -H "Host: backend.local" "http://$MINIKUBE_IP" 2>/dev/null || echo "Si curl falla, el Ingress puede necesitar más tiempo"

echo ""
echo -e "${GREEN}✓ Enrutamiento por host probado${NC}"

wait_for_user

# =============================================================================
# Paso 9: Explorar Anotaciones del Ingress Controller
# =============================================================================
print_step "Paso 9: Explorar Anotaciones del Ingress Controller"

print_command "kubectl get configmap -n ingress-nginx"
kubectl get configmap -n ingress-nginx

echo ""
echo "Algunas anotaciones útiles para el Ingress:"
echo ""
echo "  nginx.ingress.kubernetes.io/rewrite-target      - Reescribe el path"
echo "  nginx.ingress.kubernetes.io/ssl-redirect        - Redirige HTTP a HTTPS"
echo "  nginx.ingress.kubernetes.io/proxy-body-size     - Tamaño máximo del body"
echo "  nginx.ingress.kubernetes.io/proxy-read-timeout  - Timeout de lectura"
echo "  nginx.ingress.kubernetes.io/use-regex           - Habilita regex en paths"
echo "  nginx.ingress.kubernetes.io/affinity            - Habilita sticky sessions"

echo ""
echo -e "${GREEN}✓ Anotaciones exploradas${NC}"

wait_for_user

# =============================================================================
# Paso 10: Ver Logs del Ingress Controller
# =============================================================================
print_step "Paso 10: Ver Logs del Ingress Controller"

print_command "kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=20"
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=20 2>/dev/null || echo "Logs no disponibles"

echo ""
echo -e "${GREEN}✓ Logs del Ingress Controller revisados${NC}"

wait_for_user

# =============================================================================
# Paso 11: Limpiar los Recursos
# =============================================================================
print_step "Paso 11: Limpiar los Recursos"

print_command "kubectl delete ingress app-ingress app-ingress-host"
kubectl delete ingress app-ingress app-ingress-host

echo ""
print_command "kubectl delete -f $LAB_DIR/initial/apps.yaml"
kubectl delete -f "$LAB_DIR/initial/apps.yaml"

echo ""
echo "Esperando a que los recursos se eliminen..."
sleep 3

print_command "kubectl get ingress"
kubectl get ingress 2>/dev/null || echo "No resources found"

print_command "kubectl get deployments"
kubectl get deployments 2>/dev/null || echo "No resources found"

print_command "kubectl get services"
kubectl get services

echo ""
echo -e "${GREEN}✓ Recursos limpiados${NC}"

wait_for_user

# =============================================================================
# Resumen Final
# =============================================================================
print_step "Laboratorio Completado"

echo "Has completado exitosamente el Lab 09: Ingress"
echo ""
echo "Resumen de conceptos aprendidos:"
echo ""
echo "  INGRESS:"
echo "    - Objeto de Kubernetes que gestiona acceso HTTP/HTTPS externo"
echo "    - Permite enrutamiento basado en path y host"
echo "    - Requiere un Ingress Controller para funcionar"
echo ""
echo "  INGRESS CONTROLLER:"
echo "    - Componente que implementa las reglas de Ingress"
echo "    - En Minikube se habilita con 'minikube addons enable ingress'"
echo "    - Ejemplos: NGINX, Traefik, HAProxy"
echo ""
echo "  ENRUTAMIENTO:"
echo "    - Path-based: /frontend → frontend-svc, /backend → backend-svc"
echo "    - Host-based: frontend.local → frontend-svc, backend.local → backend-svc"
echo ""
echo "  ANOTACIONES:"
echo "    - Configuran comportamientos específicos del Ingress Controller"
echo "    - rewrite-target: Reescribe paths antes de enviarlos al backend"
echo ""
echo "Comandos principales aprendidos:"
echo "  - minikube addons enable ingress"
echo "  - kubectl get ingress"
echo "  - kubectl describe ingress <nombre>"
echo "  - kubectl get pods -n ingress-nginx"
echo "  - kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller"
echo "  - curl -H 'Host: hostname' http://ip"
echo ""
echo -e "${GREEN}¡Felicitaciones! Estás listo para el Lab 10: ConfigMaps${NC}"
