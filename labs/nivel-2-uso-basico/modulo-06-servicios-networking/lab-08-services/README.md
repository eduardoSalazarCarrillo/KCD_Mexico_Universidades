# Lab 08: Services

## Objetivo

Exponer aplicaciones usando diferentes tipos de Services.

## Prerrequisitos

- Lab 07 completado

## Duración

60 minutos

## Instrucciones

### Paso 1: Crear el deployment base

Crea el archivo `web-app.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
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
kubectl apply -f web-app.yaml
kubectl get pods -l app=web
```

### Paso 2: Crear un Service ClusterIP

Crea el archivo `service-clusterip.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-clusterip
spec:
  type: ClusterIP
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
```

```bash
kubectl apply -f service-clusterip.yaml
kubectl get service web-clusterip

# Ver endpoints
kubectl get endpoints web-clusterip
```

### Paso 3: Probar conectividad interna

```bash
# Crear un pod temporal para probar
kubectl run test-pod --image=busybox --rm -it -- sh

# Dentro del pod:
wget -qO- http://web-clusterip
wget -qO- http://web-clusterip.default.svc.cluster.local
exit
```

### Paso 4: Crear un Service NodePort

Crea el archivo `service-nodeport.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-nodeport
spec:
  type: NodePort
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

```bash
kubectl apply -f service-nodeport.yaml
kubectl get service web-nodeport

# Obtener la URL de acceso en Minikube
minikube service web-nodeport --url
```

### Paso 5: Acceder desde fuera del clúster

```bash
# Obtener IP del nodo
kubectl get nodes -o wide

# Con Minikube
minikube ip

# Acceder en el navegador o con curl
curl http://$(minikube ip):30080
```

### Paso 6: Crear un Service con kubectl expose

```bash
# Crear service rápidamente
kubectl expose deployment web-app --name=web-exposed --port=8080 --target-port=80

# Verificar
kubectl get service web-exposed
kubectl describe service web-exposed
```

### Paso 7: Inspeccionar endpoints

```bash
# Ver todos los services
kubectl get services

# Ver endpoints detallados
kubectl get endpoints

# Describir un endpoint
kubectl describe endpoints web-clusterip
```

## Ejercicios Adicionales

1. Crea un Service que seleccione pods con múltiples labels
2. Investiga el Service tipo LoadBalancer con Minikube tunnel
3. Crea un Service headless (clusterIP: None) y entiende su uso

## Verificación

- [ ] Puedo crear Services ClusterIP
- [ ] Puedo crear Services NodePort
- [ ] Entiendo cómo funcionan los selectors
- [ ] Puedo verificar endpoints

## Solución

Consulta el directorio `solution/` para ver todos los manifiestos.
