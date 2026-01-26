# Lab 05: Scaling

## Objetivo

Escalar aplicaciones manualmente en Kubernetes.

## Prerrequisitos

- Lab 04 completado

## Duración

30 minutos

## Instrucciones

### Paso 1: Crear un Deployment inicial

```bash
# Crear deployment con 1 réplica
kubectl create deployment web-app --image=nginx:alpine --replicas=1

# Verificar
kubectl get deployment web-app
kubectl get pods
```

### Paso 2: Escalar usando kubectl scale

```bash
# Escalar a 5 réplicas
kubectl scale deployment web-app --replicas=5

# Observar la creación de pods
kubectl get pods -w

# Verificar el deployment
kubectl get deployment web-app
```

### Paso 3: Reducir réplicas

```bash
# Reducir a 2 réplicas
kubectl scale deployment web-app --replicas=2

# Observar la terminación de pods
kubectl get pods -w

# Verificar estado final
kubectl get pods
```

### Paso 4: Escalar con kubectl edit

```bash
# Editar el deployment directamente
kubectl edit deployment web-app

# Cambiar el campo 'replicas' a 4
# Guardar y salir

# Verificar cambios
kubectl get deployment web-app
kubectl get pods
```

### Paso 5: Escalar modificando YAML

Crea el archivo `scaled-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 6
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
        - name: nginx
          image: nginx:alpine
          ports:
            - containerPort: 80
```

```bash
# Aplicar cambios
kubectl apply -f scaled-deployment.yaml

# Verificar
kubectl get deployment web-app
kubectl get pods
```

### Paso 6: Verificar distribución en nodos

```bash
# Ver en qué nodo está cada pod
kubectl get pods -o wide

# En un clúster multi-nodo, los pods se distribuyen automáticamente
```

## Ejercicios Adicionales

1. Escala a 0 réplicas y observa qué sucede
2. Escala a 10 réplicas y verifica la distribución
3. Investiga el parámetro `--current-replicas` de kubectl scale

## Verificación

- [ ] Puedo escalar deployments con kubectl scale
- [ ] Puedo escalar editando el deployment
- [ ] Puedo escalar modificando el archivo YAML
- [ ] Entiendo el escalamiento horizontal

## Solución

Consulta el directorio `solution/` para ver ejemplos adicionales.
