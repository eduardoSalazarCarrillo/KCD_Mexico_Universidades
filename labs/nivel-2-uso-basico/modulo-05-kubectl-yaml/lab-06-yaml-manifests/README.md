# Lab 06: YAML Manifests

## Objetivo

Dominar la creación y estructura de manifiestos YAML de Kubernetes.

## Prerrequisitos

- Lab 05 completado
- Conocimiento básico de YAML

## Duración

60 minutos

## Instrucciones

### Paso 1: Entender la estructura básica

Todo manifiesto de Kubernetes tiene estos campos:

```yaml
apiVersion: v1 # Versión de la API
kind: Pod # Tipo de recurso
metadata: # Metadatos del recurso
  name: mi-pod
  labels:
    app: ejemplo
spec: # Especificación del recurso
  # Contenido específico del tipo de recurso
```

### Paso 2: Crear un Pod desde cero

Crea el archivo `pod-completo.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-completo
  namespace: default
  labels:
    app: mi-app
    version: v1
    environment: development
  annotations:
    description: "Pod de ejemplo para el laboratorio"
spec:
  containers:
    - name: app
      image: nginx:1.21-alpine
      ports:
        - containerPort: 80
          name: http
          protocol: TCP
      resources:
        requests:
          memory: "64Mi"
          cpu: "100m"
        limits:
          memory: "128Mi"
          cpu: "200m"
  restartPolicy: Always
```

```bash
kubectl apply -f pod-completo.yaml
kubectl describe pod pod-completo
```

### Paso 3: Crear un Deployment completo

Crea el archivo `deployment-completo.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment
  labels:
    app: mi-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mi-app
  template:
    metadata:
      labels:
        app: mi-app
        version: v1
    spec:
      containers:
        - name: app
          image: nginx:1.21-alpine
          ports:
            - containerPort: 80
          resources:
            requests:
              memory: "64Mi"
              cpu: "100m"
            limits:
              memory: "128Mi"
              cpu: "200m"
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 3
            periodSeconds: 5
```

```bash
kubectl apply -f deployment-completo.yaml
kubectl get deployment app-deployment
```

### Paso 4: Generar YAML con dry-run

```bash
# Generar YAML de un pod sin crearlo
kubectl run test-pod --image=nginx:alpine --dry-run=client -o yaml > generated-pod.yaml

# Generar YAML de un deployment
kubectl create deployment test-deploy --image=nginx:alpine --dry-run=client -o yaml > generated-deployment.yaml

# Ver el contenido generado
cat generated-pod.yaml
cat generated-deployment.yaml
```

### Paso 5: Exportar recursos existentes

```bash
# Obtener YAML de un recurso existente
kubectl get pod pod-completo -o yaml > exported-pod.yaml

# Limpiar campos innecesarios para reutilizar
# (status, uid, resourceVersion, creationTimestamp)
```

### Paso 6: Usar labels y selectors

```bash
# Listar pods con label específico
kubectl get pods -l app=mi-app

# Listar pods con múltiples labels
kubectl get pods -l app=mi-app,version=v1

# Listar pods excluyendo un label
kubectl get pods -l 'app!=mi-app'

# Agregar label a un pod existente
kubectl label pod pod-completo tier=frontend

# Ver labels de todos los pods
kubectl get pods --show-labels
```

## Ejercicios Adicionales

1. Crea un manifiesto multi-documento (varios recursos en un archivo)
2. Investiga qué hace `kubectl diff`
3. Crea un namespace con YAML y despliega recursos en él

## Verificación

- [ ] Puedo escribir manifiestos YAML desde cero
- [ ] Entiendo todos los campos principales
- [ ] Puedo generar YAML con --dry-run
- [ ] Domino el uso de labels y selectors

## Solución

Consulta el directorio `solution/` para ver todos los manifiestos.
