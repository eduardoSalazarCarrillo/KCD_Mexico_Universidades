#!/bin/bash
# =============================================================================
# Lab 10: ConfigMaps - Script de Solución Completa
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
# Paso 1: Crear ConfigMap desde Literales
# =============================================================================
print_step "Paso 1: Crear ConfigMap desde Literales"

print_substep "Creando ConfigMap con valores literales"
print_command "kubectl create configmap app-config --from-literal=APP_ENV=production --from-literal=APP_DEBUG=false --from-literal=LOG_LEVEL=info"
kubectl delete configmap app-config --ignore-not-found &> /dev/null
kubectl create configmap app-config \
  --from-literal=APP_ENV=production \
  --from-literal=APP_DEBUG=false \
  --from-literal=LOG_LEVEL=info

echo ""
print_substep "Verificando ConfigMap"
print_command "kubectl get configmap app-config"
kubectl get configmap app-config

echo ""
print_command "kubectl describe configmap app-config"
kubectl describe configmap app-config

echo ""
print_command "kubectl get configmap app-config -o yaml"
kubectl get configmap app-config -o yaml

echo ""
echo -e "${GREEN}✓ ConfigMap app-config creado desde literales${NC}"

wait_for_user

# =============================================================================
# Paso 2: Crear ConfigMap desde Archivo
# =============================================================================
print_step "Paso 2: Crear ConfigMap desde Archivo"

print_substep "Contenido del archivo config.properties"
print_command "cat $LAB_DIR/initial/config.properties"
cat "$LAB_DIR/initial/config.properties"

echo ""
print_substep "Creando ConfigMap desde archivo"
print_command "kubectl create configmap app-properties --from-file=$LAB_DIR/initial/config.properties"
kubectl delete configmap app-properties --ignore-not-found &> /dev/null
kubectl create configmap app-properties --from-file="$LAB_DIR/initial/config.properties"

echo ""
print_command "kubectl describe configmap app-properties"
kubectl describe configmap app-properties

echo ""
print_command "kubectl get configmap app-properties -o yaml"
kubectl get configmap app-properties -o yaml

echo ""
echo -e "${GREEN}✓ ConfigMap app-properties creado desde archivo${NC}"

wait_for_user

# =============================================================================
# Paso 3: Crear ConfigMap con YAML
# =============================================================================
print_step "Paso 3: Crear ConfigMap con YAML"

print_substep "Contenido del archivo configmap.yaml"
print_command "cat $LAB_DIR/initial/configmap.yaml"
cat "$LAB_DIR/initial/configmap.yaml"

echo ""
print_substep "Aplicando ConfigMap desde YAML"
print_command "kubectl apply -f $LAB_DIR/initial/configmap.yaml"
kubectl apply -f "$LAB_DIR/initial/configmap.yaml"

echo ""
print_command "kubectl describe configmap app-config-yaml"
kubectl describe configmap app-config-yaml

echo ""
echo -e "${YELLOW}Nota: Este ConfigMap incluye tanto valores simples como un archivo de configuración completo (nginx.conf)${NC}"
echo ""
echo -e "${GREEN}✓ ConfigMap app-config-yaml creado desde YAML${NC}"

wait_for_user

# =============================================================================
# Paso 4: Usar ConfigMap como Variables de Entorno
# =============================================================================
print_step "Paso 4: Usar ConfigMap como Variables de Entorno"

print_substep "Contenido del archivo pod-env.yaml"
print_command "cat $LAB_DIR/initial/pod-env.yaml"
cat "$LAB_DIR/initial/pod-env.yaml"

echo ""
echo -e "${CYAN}Explicación:${NC}"
echo "  - envFrom: Importa TODAS las claves del ConfigMap como variables de entorno"
echo "  - env.valueFrom: Importa UNA clave específica con un nombre personalizado"
echo ""

print_substep "Creando Pod"
print_command "kubectl apply -f $LAB_DIR/initial/pod-env.yaml"
kubectl delete pod pod-configmap-env --ignore-not-found &> /dev/null
kubectl apply -f "$LAB_DIR/initial/pod-env.yaml"

echo ""
echo "Esperando a que el Pod esté listo..."
kubectl wait --for=condition=Ready pod/pod-configmap-env --timeout=60s

echo ""
print_substep "Verificando variables de entorno"
print_command "kubectl exec pod-configmap-env -- env | grep -E 'APP_|LOG_|CUSTOM'"
kubectl exec pod-configmap-env -- env | grep -E "APP_|LOG_|CUSTOM" || true

echo ""
print_command "kubectl exec pod-configmap-env -- printenv APP_ENV"
kubectl exec pod-configmap-env -- printenv APP_ENV

echo ""
print_command "kubectl exec pod-configmap-env -- printenv CUSTOM_VAR"
kubectl exec pod-configmap-env -- printenv CUSTOM_VAR

echo ""
echo -e "${GREEN}✓ ConfigMap inyectado como variables de entorno${NC}"

wait_for_user

# =============================================================================
# Paso 5: Montar ConfigMap como Volumen
# =============================================================================
print_step "Paso 5: Montar ConfigMap como Volumen"

print_substep "Contenido del archivo pod-volume.yaml"
print_command "cat $LAB_DIR/initial/pod-volume.yaml"
cat "$LAB_DIR/initial/pod-volume.yaml"

echo ""
echo -e "${CYAN}Explicación:${NC}"
echo "  - config-volume: Monta TODO el ConfigMap como directorio"
echo "  - nginx-config: Monta solo la clave 'nginx.conf' como archivo 'default.conf'"
echo ""

print_substep "Creando Pod"
print_command "kubectl apply -f $LAB_DIR/initial/pod-volume.yaml"
kubectl delete pod pod-configmap-volume --ignore-not-found &> /dev/null
kubectl apply -f "$LAB_DIR/initial/pod-volume.yaml"

echo ""
echo "Esperando a que el Pod esté listo..."
kubectl wait --for=condition=Ready pod/pod-configmap-volume --timeout=60s

echo ""
print_substep "Verificando archivos montados en /etc/config"
print_command "kubectl exec pod-configmap-volume -- ls -la /etc/config"
kubectl exec pod-configmap-volume -- ls -la /etc/config

echo ""
print_command "kubectl exec pod-configmap-volume -- cat /etc/config/config.properties"
kubectl exec pod-configmap-volume -- cat /etc/config/config.properties

echo ""
print_substep "Verificando archivo nginx.conf montado"
print_command "kubectl exec pod-configmap-volume -- ls -la /etc/nginx/conf.d"
kubectl exec pod-configmap-volume -- ls -la /etc/nginx/conf.d

echo ""
print_command "kubectl exec pod-configmap-volume -- cat /etc/nginx/conf.d/default.conf"
kubectl exec pod-configmap-volume -- cat /etc/nginx/conf.d/default.conf

echo ""
echo -e "${GREEN}✓ ConfigMap montado como volumen${NC}"

wait_for_user

# =============================================================================
# Paso 6: Actualizar ConfigMap y Observar Comportamiento
# =============================================================================
print_step "Paso 6: Actualizar ConfigMap y Observar Comportamiento"

print_substep "Estado actual del ConfigMap app-config"
print_command "kubectl get configmap app-config -o yaml"
kubectl get configmap app-config -o yaml

echo ""
print_substep "Actualizando ConfigMap con kubectl patch"
print_command "kubectl patch configmap app-config --type merge -p '{\"data\":{\"LOG_LEVEL\":\"debug\"}}'"
kubectl patch configmap app-config --type merge -p '{"data":{"LOG_LEVEL":"debug"}}'

echo ""
print_command "kubectl get configmap app-config -o yaml"
kubectl get configmap app-config -o yaml

echo ""
print_substep "Verificando variable de entorno en el Pod (NO se actualiza automáticamente)"
print_command "kubectl exec pod-configmap-env -- printenv LOG_LEVEL"
kubectl exec pod-configmap-env -- printenv LOG_LEVEL

echo ""
echo -e "${YELLOW}IMPORTANTE: Las variables de entorno NO se actualizan automáticamente.${NC}"
echo -e "${YELLOW}El Pod necesita ser recreado para ver los nuevos valores.${NC}"

echo ""
print_substep "Verificando volumen montado (SÍ se actualiza, con delay)"
echo "Esperando 30 segundos para que el volumen se actualice..."
sleep 5
echo "(En producción puede tomar hasta 1-2 minutos)"

print_command "kubectl exec pod-configmap-volume -- cat /etc/config/config.properties"
kubectl exec pod-configmap-volume -- cat /etc/config/config.properties

echo ""
echo -e "${GREEN}✓ Comportamiento de actualización demostrado${NC}"

wait_for_user

# =============================================================================
# Paso 7: Crear ConfigMap Inmutable
# =============================================================================
print_step "Paso 7: Crear ConfigMap Inmutable (Ejercicio Adicional)"

echo "Creando ConfigMap inmutable..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config-immutable
data:
  SETTING: "valor-fijo"
immutable: true
EOF

echo ""
print_command "kubectl describe configmap app-config-immutable"
kubectl describe configmap app-config-immutable

echo ""
print_substep "Intentando modificar ConfigMap inmutable"
print_command "kubectl patch configmap app-config-immutable --type merge -p '{\"data\":{\"SETTING\":\"nuevo-valor\"}}'"
kubectl patch configmap app-config-immutable --type merge -p '{"data":{"SETTING":"nuevo-valor"}}' 2>&1 || true

echo ""
echo -e "${YELLOW}NOTA: Los ConfigMaps inmutables no se pueden modificar después de crear.${NC}"
echo -e "${YELLOW}Esto mejora el rendimiento y previene cambios accidentales.${NC}"
echo ""
echo -e "${GREEN}✓ ConfigMap inmutable demostrado${NC}"

wait_for_user

# =============================================================================
# Paso 8: Listar y Comparar ConfigMaps
# =============================================================================
print_step "Paso 8: Listar y Comparar ConfigMaps"

print_command "kubectl get configmaps"
kubectl get configmaps

echo ""
print_substep "Comparación de métodos de creación"
echo ""
echo "| Método             | Comando/Archivo                              | Uso Principal                    |"
echo "|--------------------|----------------------------------------------|----------------------------------|"
echo "| --from-literal     | kubectl create cm --from-literal=KEY=value   | Valores simples, pocos datos     |"
echo "| --from-file        | kubectl create cm --from-file=archivo        | Archivos de configuración        |"
echo "| YAML declarativo   | kubectl apply -f configmap.yaml              | Control de versiones, GitOps     |"
echo ""

echo -e "${GREEN}✓ ConfigMaps listados y comparados${NC}"

wait_for_user

# =============================================================================
# Paso 9: Limpiar Recursos
# =============================================================================
print_step "Paso 9: Limpiar Recursos"

print_command "kubectl delete pod pod-configmap-env pod-configmap-volume"
kubectl delete pod pod-configmap-env pod-configmap-volume --ignore-not-found

echo ""
print_command "kubectl delete configmap app-config app-properties app-config-yaml app-config-immutable"
kubectl delete configmap app-config app-properties app-config-yaml app-config-immutable --ignore-not-found

echo ""
print_command "kubectl get configmaps"
kubectl get configmaps

echo ""
print_command "kubectl get pods"
kubectl get pods

echo ""
echo -e "${GREEN}✓ Recursos limpiados${NC}"

wait_for_user

# =============================================================================
# Resumen Final
# =============================================================================
print_step "Laboratorio Completado"

echo "Has completado exitosamente el Lab 10: ConfigMaps"
echo ""
echo "Resumen de lo aprendido:"
echo ""
echo "  MÉTODOS DE CREACIÓN:"
echo "    - --from-literal : Valores individuales en línea de comandos"
echo "    - --from-file    : Desde archivos de configuración"
echo "    - YAML           : Definición declarativa completa"
echo ""
echo "  FORMAS DE CONSUMO:"
echo "    - envFrom        : Todas las claves como variables de entorno"
echo "    - env.valueFrom  : Claves específicas como variables"
echo "    - volumeMounts   : Como archivos en el sistema de archivos"
echo ""
echo "  COMPORTAMIENTO DE ACTUALIZACIÓN:"
echo "    - Variables de entorno : NO se actualizan (requiere recrear Pod)"
echo "    - Volúmenes            : SÍ se actualizan (con delay de ~1 min)"
echo ""
echo "  MEJORES PRÁCTICAS:"
echo "    - Separar configuración del código"
echo "    - Usar ConfigMaps inmutables en producción"
echo "    - Versionar ConfigMaps con sufijos (-v1, -v2)"
echo ""
echo "Comandos principales aprendidos:"
echo "  - kubectl create configmap <nombre> --from-literal=KEY=value"
echo "  - kubectl create configmap <nombre> --from-file=archivo"
echo "  - kubectl get configmap <nombre> -o yaml"
echo "  - kubectl describe configmap <nombre>"
echo "  - kubectl patch configmap <nombre> --type merge -p '{...}'"
echo ""
echo -e "${GREEN}¡Felicitaciones! Estás listo para el Lab 11: Secrets${NC}"
