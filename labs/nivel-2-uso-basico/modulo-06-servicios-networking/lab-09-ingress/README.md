# Lab 09: Ingress

## Objetivo

Configurar Ingress para enrutamiento HTTP/HTTPS.

## Prerrequisitos

- Lab 08 completado

## Duración

60 minutos

## Instrucciones

### Paso 1: Habilitar Ingress en Minikube

```bash
# Habilitar el addon de Ingress
minikube addons enable ingress

# Verificar que el controlador está corriendo
kubectl get pods -n ingress-nginx

# Esperar a que esté listo
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### Paso 2: Crear dos aplicaciones de ejemplo

Crea el archivo `apps.yaml`:

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: nginx
          image: nginx:alpine
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-svc
spec:
  selector:
    app: frontend
  ports:
    - port: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: httpd
          image: httpd:alpine
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: backend-svc
spec:
  selector:
    app: backend
  ports:
    - port: 80
```

```bash
kubectl apply -f apps.yaml
kubectl get deployments
kubectl get services
```

### Paso 3: Crear Ingress con reglas de path

Crea el archivo `ingress-path.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - http:
        paths:
          - path: /frontend
            pathType: Prefix
            backend:
              service:
                name: frontend-svc
                port:
                  number: 80
          - path: /backend
            pathType: Prefix
            backend:
              service:
                name: backend-svc
                port:
                  number: 80
```

```bash
kubectl apply -f ingress-path.yaml
kubectl get ingress
kubectl describe ingress app-ingress
```

### Paso 4: Probar el enrutamiento

```bash
# Obtener la IP del Ingress
kubectl get ingress app-ingress

# En Minikube, usar el tunnel
minikube tunnel &

# Probar las rutas
curl http://localhost/frontend
curl http://localhost/backend
```

### Paso 5: Agregar host virtual

Crea el archivo `ingress-host.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress-host
spec:
  ingressClassName: nginx
  rules:
    - host: frontend.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-svc
                port:
                  number: 80
    - host: backend.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: backend-svc
                port:
                  number: 80
```

```bash
kubectl apply -f ingress-host.yaml

# Agregar entradas a /etc/hosts
echo "$(minikube ip) frontend.local backend.local" | sudo tee -a /etc/hosts

# Probar
curl http://frontend.local
curl http://backend.local
```

### Paso 6: Explorar anotaciones del Ingress

```bash
# Ver todas las anotaciones disponibles de nginx-ingress
kubectl describe configmap -n ingress-nginx ingress-nginx-controller

# Algunas anotaciones útiles:
# nginx.ingress.kubernetes.io/ssl-redirect: "false"
# nginx.ingress.kubernetes.io/proxy-body-size: "8m"
# nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
```

## Ejercicios Adicionales

1. Configura TLS con un certificado auto-firmado
2. Implementa rate limiting con anotaciones
3. Configura autenticación básica

## Verificación

- [ ] El Ingress Controller está funcionando
- [ ] Puedo enrutar por path
- [ ] Puedo enrutar por host
- [ ] Entiendo las anotaciones básicas

## Solución

Consulta el directorio `solution/` para configuraciones avanzadas.
