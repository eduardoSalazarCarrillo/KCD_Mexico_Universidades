# Lab 09: Ingress

## Objetivo

Configurar Ingress para enrutamiento HTTP/HTTPS, permitiendo exponer múltiples aplicaciones a través de un único punto de entrada con reglas de enrutamiento basadas en path y host.

## Prerrequisitos

- Lab 08 completado (Services)
- Clúster de Minikube ejecutándose (`minikube status` debe mostrar "Running")
- Comprensión de Services ClusterIP y NodePort

## Duración

60 minutos

## Conceptos Clave

Antes de comenzar, es importante entender estos conceptos:

| Concepto               | Descripción                                                                                               |
| ---------------------- | --------------------------------------------------------------------------------------------------------- |
| **Ingress**            | Objeto de Kubernetes que gestiona acceso externo a servicios, típicamente HTTP/HTTPS.                     |
| **Ingress Controller** | Componente que implementa las reglas de Ingress. Ejemplos: NGINX, Traefik, HAProxy.                       |
| **Path-based routing** | Enrutamiento basado en la ruta URL (ej: `/api` → backend, `/` → frontend).                                |
| **Host-based routing** | Enrutamiento basado en el nombre de host (ej: `api.ejemplo.com` → backend, `www.ejemplo.com` → frontend). |
| **IngressClass**       | Define qué Ingress Controller debe manejar un Ingress específico.                                         |
| **Annotations**        | Metadatos que configuran comportamientos específicos del Ingress Controller.                              |
| **TLS Termination**    | El Ingress puede manejar certificados SSL/TLS para conexiones HTTPS.                                      |

### Ingress vs Service

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                            │
│                                  │                                               │
│                                  │ HTTP/HTTPS                                    │
│                                  ▼                                               │
│  ┌───────────────────────────────────────────────────────────────────────────┐  │
│  │                         INGRESS CONTROLLER                                 │  │
│  │                         (nginx-ingress)                                    │  │
│  │                                                                            │  │
│  │   Reglas de Ingress:                                                       │  │
│  │   ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐           │  │
│  │   │ /frontend/*     │  │ /backend/*      │  │ api.local/*     │           │  │
│  │   └────────┬────────┘  └────────┬────────┘  └────────┬────────┘           │  │
│  │            │                    │                    │                     │  │
│  └────────────┼────────────────────┼────────────────────┼─────────────────────┘  │
│               │                    │                    │                        │
│               ▼                    ▼                    ▼                        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                  │
│  │   frontend-svc  │  │   backend-svc   │  │    api-svc      │                  │
│  │   (ClusterIP)   │  │   (ClusterIP)   │  │   (ClusterIP)   │                  │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘                  │
│           │                    │                    │                            │
│           ▼                    ▼                    ▼                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                  │
│  │  Frontend Pods  │  │  Backend Pods   │  │    API Pods     │                  │
│  │  (nginx)        │  │  (httpd)        │  │   (custom)      │                  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘                  │
│                                                                                  │
│                              KUBERNETES CLUSTER                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### ¿Por qué usar Ingress en lugar de NodePort/LoadBalancer?

| Característica         | NodePort         | LoadBalancer    | Ingress               |
| ---------------------- | ---------------- | --------------- | --------------------- |
| Un puerto por servicio | Sí (30000-32767) | Sí              | No (usa 80/443)       |
| Costo en cloud         | Bajo             | Alto (1 LB/svc) | Bajo (1 LB para todo) |
| Enrutamiento por path  | No               | No              | Sí                    |
| Enrutamiento por host  | No               | No              | Sí                    |
| TLS/SSL centralizado   | No               | No              | Sí                    |
| Balanceo de carga L7   | No               | Depende         | Sí                    |

## Instrucciones

### Paso 1: Verificar que el Clúster está Funcionando

Antes de comenzar, asegúrate de que tu clúster está corriendo:

```bash
minikube status
```

**Salida esperada**:

```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

Si el clúster no está corriendo, inícialo con:

```bash
minikube start --driver=docker
```

### Paso 2: Habilitar el Ingress Controller en Minikube

Minikube incluye un addon de NGINX Ingress Controller que debemos habilitar:

```bash
# Habilitar el addon de Ingress
minikube addons enable ingress
```

**Salida esperada**:

```
💡  ingress is an addon maintained by Kubernetes. For any concerns contact minikube on GitHub.
🔎  Verifying ingress addon...
🌟  The 'ingress' addon is enabled
```

Verificar que el Ingress Controller está corriendo:

```bash
# Ver los pods del Ingress Controller
kubectl get pods -n ingress-nginx
```

**Salida esperada**:

```
NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-xxxxx        0/1     Completed   0          1m
ingress-nginx-admission-patch-xxxxx         0/1     Completed   0          1m
ingress-nginx-controller-xxxxxxxxxx-xxxxx   1/1     Running     0          1m
```

Esperar a que el controlador esté completamente listo:

```bash
# Esperar a que el controlador esté listo
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

**Salida esperada**:

```
pod/ingress-nginx-controller-xxxxxxxxxx-xxxxx condition met
```

### Paso 3: Desplegar las Aplicaciones de Ejemplo

Ahora desplegaremos dos aplicaciones simples que expondremos a través del Ingress. Usa el archivo `initial/apps.yaml`:

```bash
# Ver el contenido del archivo
cat initial/apps.yaml
```

**Contenido del archivo**:

```yaml
# Deployment y Service para Frontend (nginx)
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-frontend
  labels:
    app: frontend
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
          # Personalizar la página de inicio para identificar el frontend
          command: ["/bin/sh", "-c"]
          args:
            - |
              echo '<!DOCTYPE html>
              <html>
              <head><title>Frontend App</title></head>
              <body>
              <h1>🎨 Frontend Application</h1>
              <p>Hostname: '$(hostname)'</p>
              <p>Esta es la aplicación FRONTEND servida por NGINX</p>
              </body>
              </html>' > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-svc
spec:
  type: ClusterIP
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 80
# Deployment y Service para Backend (httpd/Apache)
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-backend
  labels:
    app: backend
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
          # Personalizar la página de inicio para identificar el backend
          command: ["/bin/sh", "-c"]
          args:
            - |
              echo '<!DOCTYPE html>
              <html>
              <head><title>Backend App</title></head>
              <body>
              <h1>⚙️ Backend Application</h1>
              <p>Hostname: '$(hostname)'</p>
              <p>Esta es la aplicación BACKEND servida por Apache HTTPD</p>
              </body>
              </html>' > /usr/local/apache2/htdocs/index.html && httpd-foreground
---
apiVersion: v1
kind: Service
metadata:
  name: backend-svc
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
    - port: 80
      targetPort: 80
```

Aplica el manifiesto:

```bash
# Crear los deployments y services
kubectl apply -f initial/apps.yaml
```

**Salida esperada**:

```
deployment.apps/app-frontend created
service/frontend-svc created
deployment.apps/app-backend created
service/backend-svc created
```

Verifica que las aplicaciones están corriendo:

```bash
# Ver deployments
kubectl get deployments

# Ver services
kubectl get services

# Ver pods
kubectl get pods -l 'app in (frontend, backend)'
```

**Salida esperada**:

```
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
app-backend    2/2     2            2           30s
app-frontend   2/2     2            2           30s

NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
backend-svc    ClusterIP   10.96.xxx.xxx    <none>        80/TCP    30s
frontend-svc   ClusterIP   10.96.xxx.xxx    <none>        80/TCP    30s
kubernetes     ClusterIP   10.96.0.1        <none>        443/TCP   1d

NAME                            READY   STATUS    RESTARTS   AGE
app-backend-xxxxxxxxxx-xxxxx    1/1     Running   0          30s
app-backend-xxxxxxxxxx-xxxxx    1/1     Running   0          30s
app-frontend-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
app-frontend-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
```

### Paso 4: Crear Ingress con Reglas de Path

Ahora crearemos un Ingress que enruta el tráfico basándose en el path de la URL. Usa el archivo `initial/ingress-path.yaml`:

```bash
# Ver el contenido del archivo
cat initial/ingress-path.yaml
```

**Contenido del archivo**:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    # Reescribe el path al enviar al backend
    # /frontend/algo → /algo
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - http:
        paths:
          # Ruta para frontend: /frontend/*
          - path: /frontend
            pathType: Prefix
            backend:
              service:
                name: frontend-svc
                port:
                  number: 80
          # Ruta para backend: /backend/*
          - path: /backend
            pathType: Prefix
            backend:
              service:
                name: backend-svc
                port:
                  number: 80
```

**Explicación del YAML**:

| Campo                     | Descripción                                                                       |
| ------------------------- | --------------------------------------------------------------------------------- |
| `apiVersion`              | `networking.k8s.io/v1` para recursos de red                                       |
| `kind`                    | `Ingress` indica el tipo de recurso                                               |
| `annotations`             | Configuración específica del Ingress Controller                                   |
| `rewrite-target`          | Reescribe el path antes de enviarlo al servicio                                   |
| `spec.ingressClassName`   | Especifica qué Ingress Controller usar                                            |
| `spec.rules`              | Lista de reglas de enrutamiento                                                   |
| `spec.rules[].http.paths` | Rutas HTTP a coincidir                                                            |
| `path`                    | El path URL a coincidir                                                           |
| `pathType`                | `Prefix` (comienza con), `Exact` (coincide exactamente), `ImplementationSpecific` |
| `backend.service`         | El Service al que enviar el tráfico                                               |

Aplica el Ingress:

```bash
# Crear el Ingress
kubectl apply -f initial/ingress-path.yaml
```

**Salida esperada**:

```
ingress.networking.k8s.io/app-ingress created
```

Verifica el Ingress:

```bash
# Ver el Ingress creado
kubectl get ingress
```

**Salida esperada**:

```
NAME          CLASS   HOSTS   ADDRESS        PORTS   AGE
app-ingress   nginx   *       192.168.49.2   80      30s
```

> **Nota**: El ADDRESS puede tardar unos segundos en aparecer.

Ver detalles del Ingress:

```bash
# Describir el Ingress
kubectl describe ingress app-ingress
```

**Salida esperada**:

```
Name:             app-ingress
Labels:           <none>
Namespace:        default
Address:          192.168.49.2
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  *
              /frontend   frontend-svc:80 (10.244.0.x:80,10.244.0.x:80)
              /backend    backend-svc:80 (10.244.0.x:80,10.244.0.x:80)
Annotations:  nginx.ingress.kubernetes.io/rewrite-target: /
Events:
  Type    Reason  Age   From                      Message
  ----    ------  ----  ----                      -------
  Normal  Sync    30s   nginx-ingress-controller  Scheduled for sync
```

### Paso 5: Probar el Enrutamiento por Path

Ahora probaremos que el enrutamiento funciona correctamente. Necesitamos obtener la IP del Ingress:

```bash
# Obtener la IP de Minikube
minikube ip
```

**Salida esperada**:

```
192.168.49.2
```

Opción A - Usando curl directamente (recomendado para Minikube):

```bash
# Probar la ruta del frontend
curl http://$(minikube ip)/frontend

# Probar la ruta del backend
curl http://$(minikube ip)/backend
```

**Salida esperada para /frontend**:

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Frontend App</title>
  </head>
  <body>
    <h1>🎨 Frontend Application</h1>
    <p>Hostname: app-frontend-xxxxxxxxxx-xxxxx</p>
    <p>Esta es la aplicación FRONTEND servida por NGINX</p>
  </body>
</html>
```

**Salida esperada para /backend**:

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Backend App</title>
  </head>
  <body>
    <h1>⚙️ Backend Application</h1>
    <p>Hostname: app-backend-xxxxxxxxxx-xxxxx</p>
    <p>Esta es la aplicación BACKEND servida por Apache HTTPD</p>
  </body>
</html>
```

Opción B - Usando minikube tunnel (necesario si curl directo no funciona):

```bash
# En una terminal separada, iniciar el tunnel (requiere contraseña sudo)
minikube tunnel
```

Luego en otra terminal:

```bash
# Probar usando localhost
curl http://localhost/frontend
curl http://localhost/backend
```

### Paso 6: Crear Ingress con Reglas de Host (Virtual Hosts)

Ahora crearemos un segundo Ingress que enruta el tráfico basándose en el nombre de host. Usa el archivo `initial/ingress-host.yaml`:

```bash
# Ver el contenido del archivo
cat initial/ingress-host.yaml
```

**Contenido del archivo**:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress-host
spec:
  ingressClassName: nginx
  rules:
    # Regla para frontend.local
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
    # Regla para backend.local
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

**Explicación**:

- `host: frontend.local` - Solo coincide peticiones con este Host header
- Sin `rewrite-target` - No necesitamos reescribir porque usamos `/`

Aplica el Ingress:

```bash
# Crear el Ingress basado en host
kubectl apply -f initial/ingress-host.yaml
```

**Salida esperada**:

```
ingress.networking.k8s.io/app-ingress-host created
```

Verifica los Ingress:

```bash
# Ver todos los Ingress
kubectl get ingress
```

**Salida esperada**:

```
NAME               CLASS   HOSTS                         ADDRESS        PORTS   AGE
app-ingress        nginx   *                             192.168.49.2   80      5m
app-ingress-host   nginx   frontend.local,backend.local  192.168.49.2   80      30s
```

### Paso 7: Configurar /etc/hosts para Virtual Hosts

Para que los nombres de host funcionen localmente, debemos agregarlos a `/etc/hosts`:

```bash
# Agregar entradas al archivo /etc/hosts
echo "$(minikube ip) frontend.local backend.local" | sudo tee -a /etc/hosts
```

**Salida esperada**:

```
192.168.49.2 frontend.local backend.local
```

Verificar que se agregaron:

```bash
# Ver las últimas líneas de /etc/hosts
tail -2 /etc/hosts
```

### Paso 8: Probar el Enrutamiento por Host

Ahora probemos el enrutamiento basado en host:

```bash
# Probar frontend.local
curl http://frontend.local

# Probar backend.local
curl http://backend.local
```

**Salida esperada para frontend.local**:

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Frontend App</title>
  </head>
  <body>
    <h1>🎨 Frontend Application</h1>
    <p>Hostname: app-frontend-xxxxxxxxxx-xxxxx</p>
    <p>Esta es la aplicación FRONTEND servida por NGINX</p>
  </body>
</html>
```

**Salida esperada para backend.local**:

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Backend App</title>
  </head>
  <body>
    <h1>⚙️ Backend Application</h1>
    <p>Hostname: app-backend-xxxxxxxxxx-xxxxx</p>
    <p>Esta es la aplicación BACKEND servida por Apache HTTPD</p>
  </body>
</html>
```

También puedes probar con el header Host directamente:

```bash
# Usando el header Host
curl -H "Host: frontend.local" http://$(minikube ip)
curl -H "Host: backend.local" http://$(minikube ip)
```

### Paso 9: Explorar Anotaciones del Ingress Controller

El Ingress Controller de NGINX soporta muchas anotaciones útiles. Vamos a explorar algunas:

```bash
# Ver la configuración del Ingress Controller
kubectl get configmap -n ingress-nginx ingress-nginx-controller -o yaml
```

Algunas anotaciones útiles para el Ingress:

| Anotación                                        | Descripción                             |
| ------------------------------------------------ | --------------------------------------- |
| `nginx.ingress.kubernetes.io/rewrite-target`     | Reescribe el path de la petición        |
| `nginx.ingress.kubernetes.io/ssl-redirect`       | Redirige HTTP a HTTPS (default: true)   |
| `nginx.ingress.kubernetes.io/proxy-body-size`    | Tamaño máximo del cuerpo de la petición |
| `nginx.ingress.kubernetes.io/proxy-read-timeout` | Timeout de lectura del proxy            |
| `nginx.ingress.kubernetes.io/proxy-send-timeout` | Timeout de envío del proxy              |
| `nginx.ingress.kubernetes.io/use-regex`          | Habilita expresiones regulares en paths |
| `nginx.ingress.kubernetes.io/affinity`           | Habilita sticky sessions                |

Ejemplo de Ingress con más anotaciones:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ejemplo-anotaciones
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/proxy-body-size: "8m"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
spec:
  ingressClassName: nginx
  rules:
    - host: ejemplo.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: mi-servicio
                port:
                  number: 80
```

### Paso 10: Ver Logs del Ingress Controller

Para debugging, es útil ver los logs del Ingress Controller:

```bash
# Ver logs del Ingress Controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=20
```

**Salida esperada** (extracto):

```
192.168.49.1 - - [01/Jan/2024:12:00:00 +0000] "GET /frontend HTTP/1.1" 200 ...
192.168.49.1 - - [01/Jan/2024:12:00:05 +0000] "GET /backend HTTP/1.1" 200 ...
```

### Paso 11: Limpiar los Recursos

Antes de terminar, limpiemos los recursos creados:

```bash
# Eliminar los Ingress
kubectl delete ingress app-ingress app-ingress-host

# Eliminar los deployments y services
kubectl delete -f initial/apps.yaml

# Verificar que todo fue eliminado
kubectl get ingress
kubectl get deployments
kubectl get services
```

**Salida esperada**:

```
ingress.networking.k8s.io "app-ingress" deleted
ingress.networking.k8s.io "app-ingress-host" deleted
deployment.apps "app-frontend" deleted
service "frontend-svc" deleted
deployment.apps "app-backend" deleted
service "backend-svc" deleted

No resources found in default namespace.

No resources found in default namespace.

NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   1d
```

Opcionalmente, limpia las entradas de `/etc/hosts`:

```bash
# Remover las entradas que agregamos (requiere editar manualmente)
sudo nano /etc/hosts
# Elimina la línea con "frontend.local backend.local"
```

## Ejercicios Adicionales

### Ejercicio 1: Configurar TLS con Certificado Auto-firmado

```bash
# Generar certificado auto-firmado
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=frontend.local/O=Lab"

# Crear Secret con el certificado
kubectl create secret tls frontend-tls --key tls.key --cert tls.crt

# Crear Ingress con TLS
cat << 'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-tls
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - frontend.local
    secretName: frontend-tls
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
EOF

# Probar HTTPS (ignorando verificación de certificado)
curl -k https://frontend.local

# Limpiar
kubectl delete ingress ingress-tls
kubectl delete secret frontend-tls
rm tls.key tls.crt
```

### Ejercicio 2: Implementar Rate Limiting

```bash
# Crear un Ingress con rate limiting
cat << 'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-rate-limit
  annotations:
    nginx.ingress.kubernetes.io/limit-rps: "5"
    nginx.ingress.kubernetes.io/limit-connections: "3"
spec:
  ingressClassName: nginx
  rules:
  - host: limited.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-svc
            port:
              number: 80
EOF

# Probar enviando muchas peticiones
for i in {1..20}; do curl -s -o /dev/null -w "%{http_code}\n" http://limited.local; done

# Limpiar
kubectl delete ingress ingress-rate-limit
```

### Ejercicio 3: Usar Expresiones Regulares en Paths

```bash
# Crear Ingress con regex
cat << 'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-regex
  annotations:
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /app(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: frontend-svc
            port:
              number: 80
EOF

# Probar diferentes paths
curl http://$(minikube ip)/app
curl http://$(minikube ip)/app/
curl http://$(minikube ip)/app/subpath

# Limpiar
kubectl delete ingress ingress-regex
```

### Ejercicio 4: Default Backend

```bash
# Crear un default backend para manejar rutas no definidas
kubectl create deployment default-backend --image=nginx:alpine
kubectl expose deployment default-backend --port=80

cat << 'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-default
spec:
  ingressClassName: nginx
  defaultBackend:
    service:
      name: default-backend
      port:
        number: 80
  rules:
  - http:
      paths:
      - path: /specific
        pathType: Prefix
        backend:
          service:
            name: frontend-svc
            port:
              number: 80
EOF

# Probar - /specific va a frontend, todo lo demás al default
curl http://$(minikube ip)/specific
curl http://$(minikube ip)/cualquier-otra-cosa

# Limpiar
kubectl delete ingress ingress-default
kubectl delete deployment default-backend
kubectl delete service default-backend
```

## Verificación

Antes de continuar al siguiente laboratorio, asegúrate de poder marcar todos estos puntos:

- [ ] Puedo habilitar el Ingress Controller en Minikube con `minikube addons enable ingress`
- [ ] Entiendo la diferencia entre Ingress e Ingress Controller
- [ ] Puedo crear un Ingress con enrutamiento basado en path
- [ ] Puedo crear un Ingress con enrutamiento basado en host (virtual hosts)
- [ ] Entiendo cómo funcionan las anotaciones del Ingress Controller
- [ ] Puedo usar la anotación `rewrite-target` para reescribir paths
- [ ] Puedo verificar el estado de un Ingress con `kubectl get ingress` y `kubectl describe ingress`
- [ ] Puedo ver los logs del Ingress Controller para debugging
- [ ] Entiendo cuándo usar Ingress vs NodePort vs LoadBalancer
- [ ] Puedo configurar `/etc/hosts` para probar virtual hosts localmente

## Resumen de Comandos

| Comando                                                                   | Descripción                                  |
| ------------------------------------------------------------------------- | -------------------------------------------- |
| `minikube addons enable ingress`                                          | Habilitar el Ingress Controller en Minikube  |
| `minikube addons list`                                                    | Listar todos los addons disponibles          |
| `kubectl get pods -n ingress-nginx`                                       | Ver pods del Ingress Controller              |
| `kubectl apply -f <archivo.yaml>`                                         | Crear/actualizar recursos desde archivo YAML |
| `kubectl get ingress`                                                     | Listar todos los Ingress                     |
| `kubectl describe ingress <nombre>`                                       | Ver detalles de un Ingress                   |
| `kubectl delete ingress <nombre>`                                         | Eliminar un Ingress                          |
| `kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller` | Ver logs del Ingress Controller              |
| `minikube ip`                                                             | Obtener la IP de Minikube                    |
| `minikube tunnel`                                                         | Crear un tunnel para acceder a LoadBalancer  |
| `curl -H "Host: hostname" http://ip`                                      | Probar con header Host específico            |

## Conceptos Aprendidos

1. **Ingress**: Objeto que define reglas de enrutamiento HTTP/HTTPS externo
2. **Ingress Controller**: Componente que implementa las reglas del Ingress
3. **Path-based routing**: Enrutar por la ruta URL (`/frontend` → frontend-svc)
4. **Host-based routing**: Enrutar por el nombre de host (frontend.local → frontend-svc)
5. **IngressClass**: Especifica qué Ingress Controller usar
6. **Annotations**: Configuración específica del controller (rewrite-target, ssl-redirect, etc.)
7. **Default Backend**: Servicio para manejar peticiones que no coinciden con ninguna regla

## Solución

Consulta el directorio `solution/` para ver los scripts con todos los comandos y las salidas esperadas.

## Navegación

- **Anterior**: [Lab 08: Services](../lab-08-services/README.md)
- **Siguiente**: [Lab 10: ConfigMaps](../../../nivel-3-uso-intermedio/modulo-07-configuracion/lab-10-configmaps/README.md)
