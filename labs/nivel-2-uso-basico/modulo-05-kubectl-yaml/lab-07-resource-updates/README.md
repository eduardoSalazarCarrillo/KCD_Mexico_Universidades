# Lab 07: Resource Updates

## Objetivo

Modificar y actualizar recursos existentes en Kubernetes.

## Prerrequisitos

- Lab 06 completado

## Duración

45 minutos

## Instrucciones

### Paso 1: Crear el deployment inicial

Crea el archivo `app-v1.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mi-app
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
          image: nginx:1.20-alpine
          ports:
            - containerPort: 80
```

```bash
kubectl apply -f app-v1.yaml
kubectl get deployment mi-app
kubectl get pods -l app=mi-app
```

### Paso 2: Actualizar con kubectl apply

Modifica el archivo `app-v1.yaml` cambiando la imagen:

```yaml
# Cambiar de nginx:1.20-alpine a nginx:1.21-alpine
image: nginx:1.21-alpine
```

```bash
# Aplicar cambios
kubectl apply -f app-v1.yaml

# Observar el rollout
kubectl rollout status deployment mi-app

# Ver la nueva versión de los pods
kubectl get pods -l app=mi-app -o wide
```

### Paso 3: Actualizar con kubectl set

```bash
# Cambiar imagen directamente
kubectl set image deployment/mi-app app=nginx:1.22-alpine

# Ver el rollout
kubectl rollout status deployment mi-app

# Verificar la imagen actual
kubectl describe deployment mi-app | grep Image
```

### Paso 4: Actualizar con kubectl edit

```bash
# Abrir el editor
kubectl edit deployment mi-app

# Modificar replicas de 3 a 5
# Guardar y salir

# Verificar
kubectl get deployment mi-app
```

### Paso 5: Ver historial de cambios

```bash
# Ver historial de rollouts
kubectl rollout history deployment mi-app

# Ver detalles de una revisión específica
kubectl rollout history deployment mi-app --revision=1

# Agregar causa del cambio (para futuros cambios)
kubectl annotate deployment mi-app kubernetes.io/change-cause="Actualización a nginx 1.22"
```

### Paso 6: Entender apply vs create vs replace

```bash
# create: Crea un recurso nuevo (falla si existe)
kubectl create -f app-v1.yaml  # Fallará porque ya existe

# apply: Crea o actualiza (declarativo, recomendado)
kubectl apply -f app-v1.yaml  # Actualiza el recurso

# replace: Reemplaza completamente el recurso
kubectl replace -f app-v1.yaml  # Reemplaza todo

# patch: Aplica cambios parciales
kubectl patch deployment mi-app -p '{"spec":{"replicas":4}}'
```

### Paso 7: Usar kubectl diff

```bash
# Modificar el archivo localmente
# Luego ver qué cambiaría sin aplicar
kubectl diff -f app-v1.yaml
```

## Ejercicios Adicionales

1. Investiga `kubectl patch` con diferentes tipos de patch (strategic, merge, json)
2. Experimenta con `--record` en los comandos
3. Prueba actualizar un campo inmutable y observa el error

## Verificación

- [ ] Puedo actualizar recursos con kubectl apply
- [ ] Puedo actualizar con kubectl set y kubectl edit
- [ ] Entiendo la diferencia entre apply, create y replace
- [ ] Puedo ver el historial de cambios

## Solución

Consulta el directorio `solution/` para ver ejemplos completos.
