# Lab 14: Rolling Updates y Rollbacks

## Objetivo

Implementar actualizaciones sin downtime y recuperación ante fallos.

## Prerrequisitos

- Lab 13 completado

## Duración

45 minutos

## Instrucciones

### Paso 1: Crear Deployment inicial

Crea el archivo `app-rolling.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  annotations:
    kubernetes.io/change-cause: "Initial deployment v1"
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
        version: v1
    spec:
      containers:
        - name: nginx
          image: nginx:1.20-alpine
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 5
```

```bash
kubectl apply -f app-rolling.yaml
kubectl get deployment web-app
kubectl get pods -l app=web
```

### Paso 2: Realizar rolling update

```bash
# Actualizar la imagen
kubectl set image deployment/web-app nginx=nginx:1.21-alpine

# Agregar causa del cambio
kubectl annotate deployment web-app kubernetes.io/change-cause="Update to nginx 1.21"

# Observar el rollout en tiempo real
kubectl rollout status deployment web-app

# Ver pods durante la actualización
kubectl get pods -l app=web -w
```

### Paso 3: Verificar el historial

```bash
# Ver historial de revisiones
kubectl rollout history deployment web-app

# Ver detalles de una revisión específica
kubectl rollout history deployment web-app --revision=1
kubectl rollout history deployment web-app --revision=2
```

### Paso 4: Simular un deployment fallido

```bash
# Actualizar a una imagen que no existe
kubectl set image deployment/web-app nginx=nginx:invalid-version
kubectl annotate deployment web-app kubernetes.io/change-cause="Bad update"

# Observar el fallo
kubectl rollout status deployment web-app

# Ver estado de los pods
kubectl get pods -l app=web

# Verificar que algunos pods siguen funcionando (gracias a maxUnavailable)
kubectl describe deployment web-app
```

### Paso 5: Ejecutar rollback

```bash
# Rollback a la versión anterior
kubectl rollout undo deployment web-app

# Verificar
kubectl rollout status deployment web-app
kubectl get pods -l app=web

# Rollback a una revisión específica
kubectl rollout undo deployment web-app --to-revision=1
```

### Paso 6: Pausar y reanudar rollouts

```bash
# Actualizar imagen
kubectl set image deployment/web-app nginx=nginx:1.22-alpine

# Pausar inmediatamente
kubectl rollout pause deployment web-app

# Ver estado (parcialmente actualizado)
kubectl get pods -l app=web

# Hacer más cambios mientras está pausado
kubectl set resources deployment web-app -c nginx --limits=memory=128Mi

# Reanudar
kubectl rollout resume deployment web-app
kubectl rollout status deployment web-app
```

### Paso 7: Estrategia Recreate (comparación)

Crea el archivo `app-recreate.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-recreate
spec:
  replicas: 3
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: web-recreate
  template:
    metadata:
      labels:
        app: web-recreate
    spec:
      containers:
        - name: nginx
          image: nginx:1.20-alpine
```

```bash
kubectl apply -f app-recreate.yaml

# Actualizar y observar (todos los pods se eliminan primero)
kubectl set image deployment/web-app-recreate nginx=nginx:1.21-alpine
kubectl get pods -l app=web-recreate -w
```

## Ejercicios Adicionales

1. Experimenta con diferentes valores de maxSurge y maxUnavailable
2. Configura minReadySeconds para controlar la velocidad del rollout
3. Investiga canary deployments con labels

## Verificación

- [ ] Puedo realizar rolling updates sin downtime
- [ ] Puedo ver el historial de revisiones
- [ ] Puedo hacer rollback a versiones anteriores
- [ ] Entiendo las diferencias entre RollingUpdate y Recreate

## Solución

Consulta el directorio `solution/` para estrategias avanzadas.
