# Lab 04: Pods y Deployments

## Objetivo

Crear y gestionar Pods y Deployments en Kubernetes.

## Prerrequisitos

- Lab 03 completado

## Duración

60 minutos

## Instrucciones

### Paso 1: Crear un Pod simple

```bash
# Crear un pod usando kubectl run
kubectl run mi-pod --image=nginx:alpine

# Verificar el pod
kubectl get pods

# Ver detalles del pod
kubectl describe pod mi-pod

# Ver logs del pod
kubectl logs mi-pod
```

### Paso 2: Crear un Pod con YAML

Crea el archivo `pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-manual
  labels:
    app: web
    env: lab
spec:
  containers:
    - name: nginx
      image: nginx:alpine
      ports:
        - containerPort: 80
```

```bash
# Aplicar el manifiesto
kubectl apply -f pod.yaml

# Verificar
kubectl get pods -l app=web
```

### Paso 3: Crear un Deployment

Crea el archivo `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
  labels:
    app: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: nginx
          image: nginx:alpine
          ports:
            - containerPort: 80
```

```bash
# Aplicar el deployment
kubectl apply -f deployment.yaml

# Ver el deployment
kubectl get deployments

# Ver el ReplicaSet creado automáticamente
kubectl get replicasets

# Ver todos los pods
kubectl get pods -l app=web
```

### Paso 4: Entender la relación de objetos

```bash
# Ver la jerarquía
kubectl get all -l app=web

# Describir el deployment
kubectl describe deployment web-deployment

# Ver eventos
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Paso 5: Probar el self-healing

```bash
# Eliminar un pod
kubectl delete pod <nombre-del-pod>

# Observar cómo se recrea automáticamente
kubectl get pods -w
```

### Paso 6: Limpieza

```bash
# Eliminar el deployment (elimina pods y replicaset)
kubectl delete deployment web-deployment

# Eliminar pods individuales
kubectl delete pod mi-pod pod-manual
```

## Ejercicios Adicionales

1. Crea un deployment con imagen `httpd:alpine` y 5 réplicas
2. Agrega labels adicionales a los pods
3. Crea un pod con múltiples contenedores

## Verificación

- [ ] Puedo crear pods con kubectl run
- [ ] Puedo crear pods con archivos YAML
- [ ] Entiendo la relación Deployment → ReplicaSet → Pods
- [ ] Entiendo el concepto de self-healing

## Solución

Consulta el directorio `solution/` para ver los manifiestos completos.
