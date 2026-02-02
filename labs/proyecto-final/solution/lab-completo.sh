#!/bin/bash
#
# Lab Completo: Proyecto Final - Aplicación Full-Stack en Kubernetes
#
# Este script contiene todos los comandos necesarios para completar el proyecto final.
# Ejecutar paso a paso para entender cada componente.
#

set -e  # Salir si hay errores

echo "=============================================="
echo "Proyecto Final: To-Do App en Kubernetes"
echo "=============================================="

# ============================================
# FASE 0: Preparación del entorno
# ============================================
echo ""
echo "=== FASE 0: Preparación del entorno ==="

# Verificar que Minikube está corriendo
echo "Verificando Minikube..."
minikube status

# Habilitar el addon de Ingress
echo "Habilitando Ingress Controller..."
minikube addons enable ingress

# Habilitar metrics-server para HPA
echo "Habilitando Metrics Server..."
minikube addons enable metrics-server

# Usar el Docker daemon de Minikube
echo "Configurando Docker de Minikube..."
eval $(minikube docker-env)

# ============================================
# FASE 1: Containerización
# ============================================
echo ""
echo "=== FASE 1: Containerización ==="

# Construir imagen del backend
echo "Construyendo imagen del backend..."
cd backend/
docker build -t todo-backend:v1 .
cd ..

# Construir imagen del frontend
echo "Construyendo imagen del frontend..."
cd frontend/
docker build -t todo-frontend:v1 .
cd ..

# Verificar imágenes
echo "Verificando imágenes construidas..."
docker images | grep todo

# ============================================
# FASE 2: Despliegue de infraestructura base
# ============================================
echo ""
echo "=== FASE 2: Despliegue de infraestructura base ==="

# Crear namespace
echo "Creando namespace..."
kubectl apply -f kubernetes/namespace.yaml

# Crear secrets
echo "Creando secrets..."
kubectl apply -f kubernetes/secrets.yaml

# Crear configmap
echo "Creando configmap..."
kubectl apply -f kubernetes/configmap.yaml

# Verificar recursos de configuración
echo "Verificando configuración..."
kubectl get secrets,configmaps -n todo-app

# ============================================
# FASE 3: Despliegue de PostgreSQL
# ============================================
echo ""
echo "=== FASE 3: Despliegue de PostgreSQL ==="

# Desplegar PostgreSQL
echo "Desplegando PostgreSQL..."
kubectl apply -f kubernetes/postgres.yaml

# Esperar a que PostgreSQL esté listo
echo "Esperando a que PostgreSQL esté listo..."
kubectl wait --for=condition=ready pod -l app=postgres -n todo-app --timeout=120s

# Verificar PostgreSQL
echo "Verificando PostgreSQL..."
kubectl get pods,pvc,svc -n todo-app -l app=postgres

# ============================================
# FASE 4: Despliegue del Backend
# ============================================
echo ""
echo "=== FASE 4: Despliegue del Backend ==="

# Desplegar backend
echo "Desplegando backend..."
kubectl apply -f kubernetes/backend.yaml

# Esperar a que el backend esté listo
echo "Esperando a que el backend esté listo..."
kubectl wait --for=condition=ready pod -l app=backend -n todo-app --timeout=120s

# Verificar backend
echo "Verificando backend..."
kubectl get pods,svc -n todo-app -l app=backend

# Verificar logs del backend
echo "Logs del backend:"
kubectl logs -l app=backend -n todo-app --tail=10

# ============================================
# FASE 5: Despliegue del Frontend
# ============================================
echo ""
echo "=== FASE 5: Despliegue del Frontend ==="

# Desplegar frontend
echo "Desplegando frontend..."
kubectl apply -f kubernetes/frontend.yaml

# Esperar a que el frontend esté listo
echo "Esperando a que el frontend esté listo..."
kubectl wait --for=condition=ready pod -l app=frontend -n todo-app --timeout=120s

# Verificar frontend
echo "Verificando frontend..."
kubectl get pods,svc -n todo-app -l app=frontend

# ============================================
# FASE 6: Configuración de Ingress
# ============================================
echo ""
echo "=== FASE 6: Configuración de Ingress ==="

# Crear Ingress
echo "Creando Ingress..."
kubectl apply -f kubernetes/ingress.yaml

# Esperar a que Ingress tenga IP
echo "Esperando asignación de IP al Ingress..."
sleep 10

# Verificar Ingress
echo "Verificando Ingress..."
kubectl get ingress -n todo-app

# Obtener IP de Minikube
MINIKUBE_IP=$(minikube ip)
echo ""
echo "IP de Minikube: $MINIKUBE_IP"
echo ""
echo "Agregar al archivo /etc/hosts:"
echo "$MINIKUBE_IP todo.local"

# ============================================
# FASE 7: Configuración de HPA
# ============================================
echo ""
echo "=== FASE 7: Configuración de HPA ==="

# Crear HPA
echo "Creando HPA..."
kubectl apply -f kubernetes/hpa.yaml

# Verificar HPA
echo "Verificando HPA..."
kubectl get hpa -n todo-app

# ============================================
# VERIFICACIÓN FINAL
# ============================================
echo ""
echo "=== VERIFICACIÓN FINAL ==="

# Mostrar todos los recursos
echo "Todos los recursos en el namespace todo-app:"
kubectl get all -n todo-app

echo ""
echo "ConfigMaps y Secrets:"
kubectl get configmaps,secrets -n todo-app

echo ""
echo "PersistentVolumeClaims:"
kubectl get pvc -n todo-app

echo ""
echo "Ingress:"
kubectl get ingress -n todo-app

echo ""
echo "HPA:"
kubectl get hpa -n todo-app

# ============================================
# PRUEBAS
# ============================================
echo ""
echo "=== PRUEBAS ==="

# Probar health check del backend (usando port-forward)
echo "Probando health check del backend..."
kubectl port-forward svc/backend 3000:3000 -n todo-app &
PF_PID=$!
sleep 3
curl -s http://localhost:3000/health | head -20
kill $PF_PID 2>/dev/null || true

echo ""
echo "=============================================="
echo "¡Proyecto Final desplegado exitosamente!"
echo "=============================================="
echo ""
echo "Para acceder a la aplicación:"
echo "1. Agregar a /etc/hosts: $(minikube ip) todo.local"
echo "2. Abrir en el navegador: http://todo.local"
echo ""
echo "Para usar Minikube tunnel (alternativa):"
echo "  minikube tunnel"
echo ""
