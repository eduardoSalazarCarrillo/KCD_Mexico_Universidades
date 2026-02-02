# Proyecto Final: Aplicación Full-Stack en Kubernetes

## Objetivo

Aplicar todos los conocimientos adquiridos desplegando una aplicación completa en Kubernetes.

## Prerrequisitos

- Todos los laboratorios anteriores completados
- Minikube o clúster Kubernetes funcionando

## Duración

4-6 horas

## Descripción del Proyecto

Desplegarás una aplicación de gestión de tareas (To-Do App) con:

- **Frontend**: Aplicación React/Vue
- **Backend**: API REST en Node.js/Python
- **Base de datos**: PostgreSQL

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                        Ingress                               │
│                    (todo.local)                              │
└─────────────────────┬───────────────────────────────────────┘
                      │
        ┌─────────────┴─────────────┐
        ▼                           ▼
┌───────────────┐           ┌───────────────┐
│   Frontend    │           │   Backend     │
│   Service     │           │   Service     │
│  (ClusterIP)  │           │  (ClusterIP)  │
└───────┬───────┘           └───────┬───────┘
        │                           │
        ▼                           ▼
┌───────────────┐           ┌───────────────┐
│   Frontend    │           │   Backend     │
│  Deployment   │           │  Deployment   │
│  (3 replicas) │           │  (3 replicas) │
└───────────────┘           └───────┬───────┘
                                    │
                            ┌───────┴───────┐
                            ▼               ▼
                    ┌───────────┐   ┌───────────────┐
                    │ ConfigMap │   │    Secret     │
                    │           │   │  (DB creds)   │
                    └───────────┘   └───────────────┘
                                            │
                                            ▼
                                    ┌───────────────┐
                                    │   PostgreSQL  │
                                    │   Service     │
                                    └───────┬───────┘
                                            │
                                            ▼
                                    ┌───────────────┐
                                    │   PostgreSQL  │
                                    │  StatefulSet  │
                                    │  (1 replica)  │
                                    └───────┬───────┘
                                            │
                                            ▼
                                    ┌───────────────┐
                                    │      PVC      │
                                    │   (1Gi)       │
                                    └───────────────┘
```

## Fase 1: Containerización

### 1.1 Crear Dockerfile para Frontend

```dockerfile
# frontend/Dockerfile
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
```

### 1.2 Crear Dockerfile para Backend

```dockerfile
# backend/Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
```

### 1.3 Construir imágenes

```bash
# Usar el registro de Minikube
eval $(minikube docker-env)

# Construir imágenes
docker build -t todo-frontend:v1 ./frontend
docker build -t todo-backend:v1 ./backend
```

## Fase 2: Despliegue Básico

### 2.1 Crear namespace

```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: todo-app
```

### 2.2 Desplegar PostgreSQL

```yaml
# postgres.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: todo-app
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: todo-app
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:15-alpine
          ports:
            - containerPort: 5432
          envFrom:
            - secretRef:
                name: postgres-secret
          volumeMounts:
            - name: postgres-storage
              mountPath: /var/lib/postgresql/data
      volumes:
        - name: postgres-storage
          persistentVolumeClaim:
            claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: todo-app
spec:
  selector:
    app: postgres
  ports:
    - port: 5432
```

### 2.3 Desplegar Backend

```yaml
# backend.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: todo-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend
          image: todo-backend:v1
          ports:
            - containerPort: 3000
          envFrom:
            - configMapRef:
                name: backend-config
            - secretRef:
                name: postgres-secret
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 200m
              memory: 256Mi
          readinessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 5
          livenessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: todo-app
spec:
  selector:
    app: backend
  ports:
    - port: 3000
```

### 2.4 Desplegar Frontend

```yaml
# frontend.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: todo-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: frontend
          image: todo-frontend:v1
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 100m
              memory: 128Mi
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: todo-app
spec:
  selector:
    app: frontend
  ports:
    - port: 80
```

## Fase 3: Configuración

### 3.1 ConfigMaps

```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
  namespace: todo-app
data:
  NODE_ENV: production
  PORT: "3000"
  DB_HOST: postgres
  DB_PORT: "5432"
  DB_NAME: tododb
```

### 3.2 Secrets

```yaml
# secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: todo-app
type: Opaque
stringData:
  POSTGRES_USER: todouser
  POSTGRES_PASSWORD: supersecret123
  POSTGRES_DB: tododb
  DB_USER: todouser
  DB_PASSWORD: supersecret123
```

## Fase 4: Networking

### 4.1 Ingress

```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: todo-ingress
  namespace: todo-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  ingressClassName: nginx
  rules:
    - host: todo.local
      http:
        paths:
          - path: /api(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: backend
                port:
                  number: 3000
          - path: /()(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: frontend
                port:
                  number: 80
```

## Fase 5: Escalamiento

### 5.1 HPA para Backend

```yaml
# hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
  namespace: todo-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

## Fase 6: Despliegue

```bash
# Aplicar todos los manifiestos
kubectl apply -f namespace.yaml
kubectl apply -f secrets.yaml
kubectl apply -f configmap.yaml
kubectl apply -f postgres.yaml
kubectl apply -f backend.yaml
kubectl apply -f frontend.yaml
kubectl apply -f ingress.yaml
kubectl apply -f hpa.yaml

# Verificar
kubectl get all -n todo-app

# Agregar entrada a /etc/hosts
echo "$(minikube ip) todo.local" | sudo tee -a /etc/hosts

# Probar
curl http://todo.local
curl http://todo.local/api/health
```

## Entregables

1. **Código fuente** en repositorio Git
2. **Manifiestos YAML** organizados por componente
3. **Diagrama de arquitectura** actualizado
4. **README.md** con instrucciones de despliegue
5. **Presentación técnica** (10-15 minutos)

## Criterios de Evaluación

| Criterio         | Peso | Descripción                          |
| ---------------- | ---- | ------------------------------------ |
| Funcionalidad    | 30%  | La aplicación funciona correctamente |
| Buenas prácticas | 25%  | Uso correcto de recursos K8s         |
| Documentación    | 20%  | Claridad y completitud               |
| Presentación     | 15%  | Explicación técnica clara            |
| Código limpio    | 10%  | Organización y legibilidad           |

## Recursos

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [12 Factor App](https://12factor.net/)
- [Docker Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

## Solución

Consulta el directorio `solution/` para una implementación completa de referencia.

---

[← Lab 18: Managed Kubernetes](../nivel-4-operacion/modulo-12-cloud/lab-18-managed-kubernetes/README.md) | [Inicio](../../README.md)
