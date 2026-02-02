#!/bin/bash
# =============================================================================
# Lab 06: YAML Manifests - Script de Solución Completa
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

cleanup() {
    echo "Limpiando recursos previos..."
    kubectl delete pod pod-ejemplo --ignore-not-found=true &> /dev/null
    kubectl delete pod mi-pod-custom --ignore-not-found=true &> /dev/null
    kubectl delete deployment web-deployment --ignore-not-found=true &> /dev/null
    kubectl delete namespace lab-06-ns --ignore-not-found=true &> /dev/null
}

# =============================================================================
# Verificación Inicial
# =============================================================================
print_step "Verificación Inicial"

if ! command -v minikube &> /dev/null; then
    echo -e "${RED}Error: Minikube no está instalado.${NC}"
    echo "Por favor, completa los labs anteriores primero."
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl no está instalado.${NC}"
    echo "Por favor, completa los labs anteriores primero."
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

# Limpiar recursos previos
cleanup

wait_for_user

# =============================================================================
# Paso 2: Analizar la Estructura de un Pod YAML
# =============================================================================
print_step "Paso 2: Analizar la Estructura de un Pod YAML"

print_command "cat $LAB_DIR/initial/pod-ejemplo.yaml"
cat "$LAB_DIR/initial/pod-ejemplo.yaml"

echo ""
echo -e "${GREEN}✓ Archivo YAML analizado${NC}"

wait_for_user

# =============================================================================
# Paso 3: Crear el Pod desde el Archivo YAML
# =============================================================================
print_step "Paso 3: Crear el Pod desde el Archivo YAML"

print_command "kubectl apply -f $LAB_DIR/initial/pod-ejemplo.yaml"
kubectl apply -f "$LAB_DIR/initial/pod-ejemplo.yaml"

echo ""
echo "Esperando a que el pod esté listo..."
kubectl wait --for=condition=Ready pod/pod-ejemplo --timeout=60s

echo ""
print_command "kubectl get pod pod-ejemplo --show-labels"
kubectl get pod pod-ejemplo --show-labels

echo ""
echo -e "${GREEN}✓ Pod creado desde archivo YAML${NC}"

wait_for_user

# =============================================================================
# Paso 4: Ver el YAML Completo del Pod Creado
# =============================================================================
print_step "Paso 4: Ver el YAML Completo del Pod Creado"

print_command "kubectl get pod pod-ejemplo -o yaml | head -40"
kubectl get pod pod-ejemplo -o yaml | head -40

echo ""
echo "..."
echo "(Salida truncada - Kubernetes añade uid, resourceVersion, status, etc.)"

echo ""
echo -e "${GREEN}✓ YAML completo visualizado${NC}"

wait_for_user

# =============================================================================
# Paso 5: Analizar la Estructura de un Deployment YAML
# =============================================================================
print_step "Paso 5: Analizar la Estructura de un Deployment YAML"

print_command "cat $LAB_DIR/initial/deployment-ejemplo.yaml"
cat "$LAB_DIR/initial/deployment-ejemplo.yaml"

echo ""
echo -e "${GREEN}✓ Deployment YAML analizado${NC}"

wait_for_user

# =============================================================================
# Paso 6: Crear el Deployment
# =============================================================================
print_step "Paso 6: Crear el Deployment"

print_command "kubectl apply -f $LAB_DIR/initial/deployment-ejemplo.yaml"
kubectl apply -f "$LAB_DIR/initial/deployment-ejemplo.yaml"

echo ""
echo "Esperando a que el deployment esté listo..."
kubectl rollout status deployment/web-deployment --timeout=120s

echo ""
print_command "kubectl get deployment web-deployment"
kubectl get deployment web-deployment

echo ""
print_command "kubectl get pods -l app=web,tier=frontend"
kubectl get pods -l app=web,tier=frontend

echo ""
echo -e "${GREEN}✓ Deployment creado${NC}"

wait_for_user

# =============================================================================
# Paso 7: Crear un Pod desde Cero en YAML
# =============================================================================
print_step "Paso 7: Crear un Pod desde Cero en YAML"

print_substep "Creando archivo mi-pod.yaml"
cat << 'EOF' > /tmp/mi-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: mi-pod-custom
  labels:
    app: custom-app
    environment: lab
    creado-en: lab-06
spec:
  containers:
    - name: httpd
      image: httpd:alpine
      ports:
        - containerPort: 80
      resources:
        requests:
          memory: "32Mi"
          cpu: "50m"
        limits:
          memory: "64Mi"
          cpu: "100m"
EOF

echo "Archivo creado en /tmp/mi-pod.yaml"
cat /tmp/mi-pod.yaml

echo ""
print_command "kubectl apply -f /tmp/mi-pod.yaml"
kubectl apply -f /tmp/mi-pod.yaml

echo ""
echo "Esperando a que el pod esté listo..."
kubectl wait --for=condition=Ready pod/mi-pod-custom --timeout=60s

echo ""
print_command "kubectl get pod mi-pod-custom --show-labels"
kubectl get pod mi-pod-custom --show-labels

echo ""
echo -e "${GREEN}✓ Pod personalizado creado${NC}"

wait_for_user

# =============================================================================
# Paso 8: Generar YAML con dry-run
# =============================================================================
print_step "Paso 8: Generar YAML con dry-run"

print_command "kubectl run generated-pod --image=nginx:alpine --dry-run=client -o yaml"
kubectl run generated-pod --image=nginx:alpine --dry-run=client -o yaml

echo ""
print_substep "Guardando YAML a archivo"
print_command "kubectl run generated-pod --image=nginx:alpine --dry-run=client -o yaml > /tmp/generated-pod.yaml"
kubectl run generated-pod --image=nginx:alpine --dry-run=client -o yaml > /tmp/generated-pod.yaml
echo "Archivo guardado en /tmp/generated-pod.yaml"

echo ""
echo -e "${GREEN}✓ YAML generado con dry-run${NC}"

wait_for_user

# =============================================================================
# Paso 9: Generar YAML de Deployment con dry-run
# =============================================================================
print_step "Paso 9: Generar YAML de Deployment con dry-run"

print_command "kubectl create deployment generated-deploy --image=nginx:alpine --replicas=2 --dry-run=client -o yaml"
kubectl create deployment generated-deploy --image=nginx:alpine --replicas=2 --dry-run=client -o yaml

echo ""
echo -e "${GREEN}✓ YAML de Deployment generado${NC}"

wait_for_user

# =============================================================================
# Paso 10: Exportar un Recurso Existente a YAML
# =============================================================================
print_step "Paso 10: Exportar un Recurso Existente a YAML"

print_command "kubectl get pod pod-ejemplo -o yaml > /tmp/pod-ejemplo-export.yaml"
kubectl get pod pod-ejemplo -o yaml > /tmp/pod-ejemplo-export.yaml

echo ""
print_command "cat /tmp/pod-ejemplo-export.yaml | head -50"
cat /tmp/pod-ejemplo-export.yaml | head -50

echo ""
echo "..."
echo "(Salida truncada - contiene metadata.uid, resourceVersion, status, etc.)"

echo ""
echo -e "${GREEN}✓ Recurso exportado a YAML${NC}"

wait_for_user

# =============================================================================
# Paso 11: Usar Labels y Selectors
# =============================================================================
print_step "Paso 11: Usar Labels y Selectors"

print_substep "Filtrar pods con labels"

print_command "kubectl get pods -l app=web"
kubectl get pods -l app=web

echo ""
print_command "kubectl get pods -l app=web,tier=frontend"
kubectl get pods -l app=web,tier=frontend

echo ""
print_command "kubectl get pods -l 'app!=web'"
kubectl get pods -l 'app!=web'

echo ""
print_substep "Agregar y modificar labels"

print_command "kubectl label pod pod-ejemplo team=backend"
kubectl label pod pod-ejemplo team=backend

print_command "kubectl get pod pod-ejemplo --show-labels"
kubectl get pod pod-ejemplo --show-labels

echo ""
print_command "kubectl label pod pod-ejemplo version=v1.0.1 --overwrite"
kubectl label pod pod-ejemplo version=v1.0.1 --overwrite

print_command "kubectl get pod pod-ejemplo --show-labels"
kubectl get pod pod-ejemplo --show-labels

echo ""
print_command "kubectl label pod pod-ejemplo team-"
kubectl label pod pod-ejemplo team-

print_command "kubectl get pod pod-ejemplo --show-labels"
kubectl get pod pod-ejemplo --show-labels

echo ""
echo -e "${GREEN}✓ Labels y selectors utilizados${NC}"

wait_for_user

# =============================================================================
# Paso 12: Ver Labels de Todos los Pods
# =============================================================================
print_step "Paso 12: Ver Labels de Todos los Pods"

print_command "kubectl get pods --show-labels"
kubectl get pods --show-labels

echo ""
print_command "kubectl get pods -L app,environment,version"
kubectl get pods -L app,environment,version

echo ""
echo -e "${GREEN}✓ Labels visualizados${NC}"

wait_for_user

# =============================================================================
# Paso 13: Crear Manifiesto Multi-Documento
# =============================================================================
print_step "Paso 13: Crear Manifiesto Multi-Documento"

print_substep "Creando archivo multi-recursos.yaml"
cat << 'EOF' > /tmp/multi-recursos.yaml
# Primero creamos un Namespace
apiVersion: v1
kind: Namespace
metadata:
  name: lab-06-ns
---
# Luego un Pod en ese namespace
apiVersion: v1
kind: Pod
metadata:
  name: pod-en-namespace
  namespace: lab-06-ns
  labels:
    app: demo
spec:
  containers:
    - name: nginx
      image: nginx:alpine
---
# Y un segundo Pod
apiVersion: v1
kind: Pod
metadata:
  name: pod-secundario
  namespace: lab-06-ns
  labels:
    app: demo
    role: secondary
spec:
  containers:
    - name: busybox
      image: busybox
      command: ['sh', '-c', 'echo Hello && sleep 3600']
EOF

echo "Archivo creado:"
cat /tmp/multi-recursos.yaml

echo ""
print_command "kubectl apply -f /tmp/multi-recursos.yaml"
kubectl apply -f /tmp/multi-recursos.yaml

echo ""
echo "Esperando a que los pods estén listos..."
sleep 5
kubectl wait --for=condition=Ready pods -n lab-06-ns --all --timeout=60s 2>/dev/null || true

echo ""
print_command "kubectl get all -n lab-06-ns"
kubectl get all -n lab-06-ns

echo ""
echo -e "${GREEN}✓ Manifiesto multi-documento aplicado${NC}"

wait_for_user

# =============================================================================
# Paso 14: Usar kubectl diff
# =============================================================================
print_step "Paso 14: Usar kubectl diff"

print_substep "Creando archivo modificado"
cat << 'EOF' > /tmp/pod-ejemplo-modified.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-ejemplo
  namespace: default
  labels:
    app: mi-aplicacion
    environment: produccion
    version: v2.0.0
  annotations:
    description: "Pod modificado para demostrar kubectl diff"
spec:
  containers:
    - name: nginx
      image: nginx:1.25-alpine
      ports:
        - containerPort: 80
          name: http
      resources:
        requests:
          memory: "128Mi"
          cpu: "200m"
        limits:
          memory: "256Mi"
          cpu: "400m"
  restartPolicy: Always
EOF

echo "Archivo modificado creado. Mostrando diferencias:"
echo ""

print_command "kubectl diff -f /tmp/pod-ejemplo-modified.yaml"
kubectl diff -f /tmp/pod-ejemplo-modified.yaml 2>/dev/null || echo "(Las diferencias se muestran arriba)"

echo ""
echo -e "${YELLOW}Nota: Las líneas con '-' se eliminarían y las líneas con '+' se añadirían${NC}"

echo ""
echo -e "${GREEN}✓ kubectl diff utilizado${NC}"

wait_for_user

# =============================================================================
# Paso 15: Limpiar los Recursos
# =============================================================================
print_step "Paso 15: Limpiar los Recursos"

print_command "kubectl delete pod pod-ejemplo"
kubectl delete pod pod-ejemplo

print_command "kubectl delete pod mi-pod-custom"
kubectl delete pod mi-pod-custom

print_command "kubectl delete deployment web-deployment"
kubectl delete deployment web-deployment

print_command "kubectl delete namespace lab-06-ns"
kubectl delete namespace lab-06-ns

echo ""
echo "Esperando a que los recursos se eliminen..."
sleep 5

print_command "kubectl get pods"
kubectl get pods 2>/dev/null || echo "No resources found in default namespace."

print_command "kubectl get deployments"
kubectl get deployments 2>/dev/null || echo "No resources found in default namespace."

echo ""
echo -e "${GREEN}✓ Recursos limpiados${NC}"

wait_for_user

# =============================================================================
# Ejercicios Adicionales
# =============================================================================
print_step "Ejercicios Adicionales"

print_substep "Ejercicio 1: Deployment desde cero"
cat << 'EOF' > /tmp/ejercicio1-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-deployment
  labels:
    app: api
    tier: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
      tier: backend
  template:
    metadata:
      labels:
        app: api
        tier: backend
    spec:
      containers:
        - name: httpd
          image: httpd:alpine
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: "50m"
              memory: "32Mi"
            limits:
              cpu: "100m"
              memory: "64Mi"
EOF

print_command "kubectl apply -f /tmp/ejercicio1-deployment.yaml"
kubectl apply -f /tmp/ejercicio1-deployment.yaml

echo ""
kubectl rollout status deployment/api-deployment --timeout=60s

print_command "kubectl get deployment api-deployment"
kubectl get deployment api-deployment

print_command "kubectl get pods -l app=api"
kubectl get pods -l app=api

echo ""
print_command "kubectl delete deployment api-deployment"
kubectl delete deployment api-deployment

echo ""
print_substep "Ejercicio 2: Explorar API Resources"
print_command "kubectl api-resources | head -15"
kubectl api-resources | head -15

echo ""
print_command "kubectl api-resources --api-group=apps"
kubectl api-resources --api-group=apps

echo ""
print_substep "Ejercicio 4: kubectl explain"
print_command "kubectl explain pod.spec.containers | head -20"
kubectl explain pod.spec.containers | head -20

echo ""
echo -e "${GREEN}✓ Ejercicios adicionales completados${NC}"

wait_for_user

# =============================================================================
# Resumen Final
# =============================================================================
print_step "Laboratorio Completado"

echo "Has completado exitosamente el Lab 06: YAML Manifests"
echo ""
echo "Resumen de conceptos aprendidos:"
echo ""
echo "  ESTRUCTURA DE MANIFIESTOS:"
echo "    - apiVersion: Define la versión de la API (v1, apps/v1, etc.)"
echo "    - kind: Tipo de recurso (Pod, Deployment, Service, etc.)"
echo "    - metadata: Nombre, namespace, labels, annotations"
echo "    - spec: Configuración específica del recurso"
echo ""
echo "  LABELS Y SELECTORS:"
echo "    - Labels: Pares clave-valor para organizar recursos"
echo "    - Selectors: Filtros basados en labels (-l app=web)"
echo "    - kubectl label: Agregar/modificar/eliminar labels"
echo ""
echo "  GENERACIÓN DE YAML:"
echo "    - --dry-run=client -o yaml: Genera YAML sin crear"
echo "    - kubectl get <recurso> -o yaml: Exporta YAML existente"
echo "    - kubectl diff: Muestra diferencias antes de aplicar"
echo ""
echo "  MULTI-DOCUMENTO:"
echo "    - Separador --- permite múltiples recursos en un archivo"
echo "    - Se crean en orden de aparición"
echo ""
echo "Comandos principales aprendidos:"
echo "  - kubectl apply -f <archivo.yaml>"
echo "  - kubectl get <recurso> -o yaml"
echo "  - kubectl run/create --dry-run=client -o yaml"
echo "  - kubectl get pods -l <label>=<valor>"
echo "  - kubectl get pods -L <label1>,<label2>"
echo "  - kubectl label <recurso> <nombre> <clave>=<valor>"
echo "  - kubectl diff -f <archivo.yaml>"
echo "  - kubectl explain <recurso>.<campo>"
echo "  - kubectl api-resources"
echo ""
echo -e "${GREEN}¡Felicitaciones! Estás listo para el Lab 07: Resource Updates${NC}"
