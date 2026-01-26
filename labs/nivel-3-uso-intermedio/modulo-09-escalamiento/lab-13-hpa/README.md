# Lab 13: Horizontal Pod Autoscaler (HPA)

## Objetivo

Configurar escalamiento automático basado en métricas.

## Prerrequisitos

- Lab 12 completado

## Duración

60 minutos

## Instrucciones

### Paso 1: Habilitar Metrics Server

```bash
# En Minikube
minikube addons enable metrics-server

# Verificar que está corriendo
kubectl get pods -n kube-system | grep metrics-server

# Esperar a que esté listo (puede tardar unos minutos)
kubectl top nodes
kubectl top pods
```

### Paso 2: Crear Deployment con resource requests

Crea el archivo `app-hpa.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-apache
spec:
  replicas: 1
  selector:
    matchLabels:
      app: php-apache
  template:
    metadata:
      labels:
        app: php-apache
    spec:
      containers:
        - name: php-apache
          image: registry.k8s.io/hpa-example
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: 200m
              memory: 64Mi
            limits:
              cpu: 500m
              memory: 128Mi
---
apiVersion: v1
kind: Service
metadata:
  name: php-apache
spec:
  selector:
    app: php-apache
  ports:
    - port: 80
```

```bash
kubectl apply -f app-hpa.yaml
kubectl get deployment php-apache
kubectl get pods
```

### Paso 3: Crear HPA con kubectl

```bash
# Crear HPA
kubectl autoscale deployment php-apache \
  --cpu-percent=50 \
  --min=1 \
  --max=10

# Verificar HPA
kubectl get hpa
kubectl describe hpa php-apache
```

### Paso 4: Crear HPA con YAML

Crea el archivo `hpa.yaml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 70
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
```

```bash
# Eliminar HPA anterior
kubectl delete hpa php-apache

# Aplicar nuevo HPA
kubectl apply -f hpa.yaml
kubectl get hpa php-apache-hpa
```

### Paso 5: Generar carga

```bash
# En una terminal, observar el HPA
kubectl get hpa -w

# En otra terminal, generar carga
kubectl run -i --tty load-generator --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"
```

### Paso 6: Observar el escalamiento

```bash
# Ver pods escalando
kubectl get pods -w

# Ver métricas
kubectl top pods

# Ver eventos del HPA
kubectl describe hpa php-apache-hpa
```

### Paso 7: Detener carga y observar scale-down

```bash
# Detener el generador de carga (Ctrl+C)

# Observar cómo bajan las réplicas (toma tiempo por stabilizationWindow)
kubectl get hpa -w
kubectl get pods -w
```

## Ejercicios Adicionales

1. Configura HPA basado en métricas personalizadas
2. Experimenta con diferentes valores de stabilizationWindow
3. Investiga Vertical Pod Autoscaler (VPA)

## Verificación

- [ ] Metrics Server está funcionando
- [ ] Puedo crear HPA con kubectl y YAML
- [ ] Entiendo cómo funciona el escalamiento automático
- [ ] Puedo observar el comportamiento bajo carga

## Solución

Consulta el directorio `solution/` para configuraciones avanzadas.
