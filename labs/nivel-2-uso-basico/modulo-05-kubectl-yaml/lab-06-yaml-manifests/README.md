# Lab 06: YAML Manifests

## Objetivo

Dominar la creación y estructura de manifiestos YAML de Kubernetes, entendiendo cada campo y su propósito.

## Prerrequisitos

- Lab 05 completado (Scaling)
- Clúster de Minikube ejecutándose (`minikube status` debe mostrar "Running")

## Duración

60 minutos

## Conceptos Clave

Antes de comenzar, es importante entender estos conceptos:

| Concepto            | Descripción                                                                                        |
| ------------------- | -------------------------------------------------------------------------------------------------- |
| **Manifiesto YAML** | Archivo que describe el estado deseado de un recurso de Kubernetes en formato declarativo.         |
| **apiVersion**      | Versión de la API de Kubernetes que define el esquema del recurso (ej: `v1`, `apps/v1`).           |
| **kind**            | Tipo de recurso a crear (ej: Pod, Deployment, Service, ConfigMap).                                 |
| **metadata**        | Información que identifica el recurso: nombre, namespace, labels, annotations.                     |
| **spec**            | Especificación del estado deseado del recurso. Su estructura depende del `kind`.                   |
| **Labels**          | Pares clave-valor para organizar y seleccionar recursos. Se usan en selectors.                     |
| **Annotations**     | Metadatos adicionales no usados para selección. Útiles para documentación o herramientas externas. |
| **Selector**        | Filtro que identifica recursos basándose en sus labels.                                            |
| **dry-run**         | Modo que valida y genera YAML sin crear el recurso. Útil para generar templates.                   |

### Estructura de un Manifiesto YAML

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ESTRUCTURA DE MANIFIESTO                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  apiVersion: <group>/<version>    ◄── Versión de la API                     │
│  kind: <TipoDeRecurso>            ◄── Tipo de recurso                       │
│  metadata:                        ◄── Metadatos del recurso                 │
│    name: <nombre-unico>               ├── Nombre (requerido)                │
│    namespace: <namespace>             ├── Namespace (opcional)              │
│    labels:                            ├── Labels (opcional)                 │
│      <clave>: <valor>                 │                                     │
│    annotations:                       └── Annotations (opcional)            │
│      <clave>: <valor>                                                       │
│  spec:                            ◄── Especificación (varía por kind)       │
│    <configuracion-especifica>                                               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### API Groups y Versiones

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         API VERSIONS COMUNES                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  CORE (sin grupo):                                                          │
│    apiVersion: v1                                                           │
│    └── Pod, Service, ConfigMap, Secret, Namespace, PersistentVolume         │
│                                                                             │
│  APPS:                                                                      │
│    apiVersion: apps/v1                                                      │
│    └── Deployment, ReplicaSet, StatefulSet, DaemonSet                       │
│                                                                             │
│  NETWORKING:                                                                │
│    apiVersion: networking.k8s.io/v1                                         │
│    └── Ingress, NetworkPolicy                                               │
│                                                                             │
│  BATCH:                                                                     │
│    apiVersion: batch/v1                                                     │
│    └── Job, CronJob                                                         │
│                                                                             │
│  RBAC:                                                                      │
│    apiVersion: rbac.authorization.k8s.io/v1                                 │
│    └── Role, ClusterRole, RoleBinding, ClusterRoleBinding                   │
│                                                                             │
│  AUTOSCALING:                                                               │
│    apiVersion: autoscaling/v2                                               │
│    └── HorizontalPodAutoscaler                                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Labels vs Annotations

```
┌────────────────────────────────────┬────────────────────────────────────────┐
│             LABELS                 │             ANNOTATIONS                │
├────────────────────────────────────┼────────────────────────────────────────┤
│                                    │                                        │
│  - Identifican objetos             │  - Almacenan metadatos                 │
│  - Se usan en selectors            │  - NO se usan en selectors             │
│  - Organizan recursos              │  - Documentación, herramientas         │
│  - Deben ser cortos                │  - Pueden ser largos                   │
│                                    │                                        │
│  Ejemplos:                         │  Ejemplos:                             │
│    app: nginx                      │    description: "API principal"        │
│    environment: production         │    owner: "equipo-backend"             │
│    tier: frontend                  │    commit-sha: "abc123def456"          │
│    version: v1.2.3                 │    prometheus.io/scrape: "true"        │
│                                    │                                        │
└────────────────────────────────────┴────────────────────────────────────────┘
```

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

### Paso 2: Analizar la Estructura de un Pod YAML

Examina el archivo `initial/pod-ejemplo.yaml` que contiene un Pod con todos los campos importantes:

```bash
# Ver el contenido del archivo
cat initial/pod-ejemplo.yaml
```

**Contenido del archivo**:

```yaml
# Cada manifiesto de Kubernetes sigue esta estructura
apiVersion: v1 # Versión de la API (v1 para recursos core)
kind: Pod # Tipo de recurso
metadata: # Metadatos del recurso
  name: pod-ejemplo # Nombre único del recurso (requerido)
  namespace: default # Namespace donde se crea (default si se omite)
  labels: # Labels para organizar y seleccionar
    app: mi-aplicacion
    environment: desarrollo
    version: v1.0.0
  annotations: # Metadatos adicionales (no para selección)
    description: "Pod de ejemplo para el laboratorio 06"
    creado-por: "equipo-devops"
spec: # Especificación del estado deseado
  containers: # Lista de contenedores (mínimo 1)
    - name: nginx # Nombre del contenedor
      image: nginx:1.24-alpine # Imagen a usar
      ports: # Puertos que expone el contenedor
        - containerPort: 80
          name: http
          protocol: TCP
      resources: # Recursos del contenedor
        requests: # Recursos mínimos garantizados
          memory: "64Mi"
          cpu: "100m" # 100 milicores = 0.1 CPU
        limits: # Recursos máximos permitidos
          memory: "128Mi"
          cpu: "200m"
      env: # Variables de entorno
        - name: NGINX_HOST
          value: "localhost"
        - name: NGINX_PORT
          value: "80"
  restartPolicy: Always # Política de reinicio (Always, OnFailure, Never)
```

**Explicación de cada sección**:

| Sección                       | Descripción                                       |
| ----------------------------- | ------------------------------------------------- |
| `apiVersion: v1`              | Pods son recursos "core", usan `v1` sin grupo     |
| `kind: Pod`                   | Define que estamos creando un Pod                 |
| `metadata.name`               | Nombre único del Pod en el namespace              |
| `metadata.labels`             | Etiquetas para filtrar y seleccionar el Pod       |
| `metadata.annotations`        | Metadatos informativos                            |
| `spec.containers`             | Lista de contenedores (un Pod puede tener varios) |
| `spec.containers[].name`      | Nombre del contenedor dentro del Pod              |
| `spec.containers[].image`     | Imagen Docker a usar                              |
| `spec.containers[].ports`     | Puertos que el contenedor expone                  |
| `spec.containers[].resources` | Requests y limits de CPU/memoria                  |
| `spec.containers[].env`       | Variables de entorno del contenedor               |
| `spec.restartPolicy`          | Qué hacer cuando el contenedor termina            |

### Paso 3: Crear el Pod desde el Archivo YAML

```bash
# Aplicar el manifiesto
kubectl apply -f initial/pod-ejemplo.yaml
```

**Salida esperada**:

```
pod/pod-ejemplo created
```

Verifica que el Pod se creó correctamente:

```bash
# Ver el pod con sus labels
kubectl get pod pod-ejemplo --show-labels
```

**Salida esperada**:

```
NAME          READY   STATUS    RESTARTS   AGE   LABELS
pod-ejemplo   1/1     Running   0          30s   app=mi-aplicacion,environment=desarrollo,version=v1.0.0
```

### Paso 4: Ver el YAML Completo del Pod Creado

Kubernetes añade campos adicionales cuando crea el recurso:

```bash
# Ver el YAML completo del pod (incluyendo campos generados)
kubectl get pod pod-ejemplo -o yaml
```

Observa los campos adicionales que Kubernetes añadió:

- `metadata.uid` - Identificador único global
- `metadata.resourceVersion` - Versión del recurso para control de concurrencia
- `metadata.creationTimestamp` - Cuándo se creó
- `status` - Estado actual del Pod

### Paso 5: Analizar la Estructura de un Deployment YAML

Examina el archivo `initial/deployment-ejemplo.yaml`:

```bash
cat initial/deployment-ejemplo.yaml
```

**Contenido del archivo**:

```yaml
apiVersion: apps/v1 # Deployments están en el grupo "apps"
kind: Deployment
metadata:
  name: web-deployment
  labels:
    app: web
    tier: frontend
  annotations:
    kubernetes.io/change-cause: "Versión inicial del deployment"
spec:
  replicas: 3 # Número de réplicas deseadas
  selector: # Cómo el Deployment encuentra sus Pods
    matchLabels:
      app: web
      tier: frontend
  template: # Template para crear Pods
    metadata:
      labels: # DEBEN coincidir con selector.matchLabels
        app: web
        tier: frontend
        version: v1
    spec:
      containers:
        - name: nginx
          image: nginx:1.24-alpine
          ports:
            - containerPort: 80
              name: http
          resources:
            requests:
              memory: "64Mi"
              cpu: "100m"
            limits:
              memory: "128Mi"
              cpu: "200m"
          livenessProbe: # Verifica si el contenedor está vivo
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10
          readinessProbe: # Verifica si el contenedor puede recibir tráfico
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 3
            periodSeconds: 5
```

**Campos específicos del Deployment**:

| Campo                           | Descripción                                            |
| ------------------------------- | ------------------------------------------------------ |
| `spec.replicas`                 | Número de Pods que el Deployment debe mantener         |
| `spec.selector`                 | Define qué Pods pertenecen a este Deployment           |
| `spec.selector.matchLabels`     | Labels que deben tener los Pods para ser gestionados   |
| `spec.template`                 | Template usado para crear nuevos Pods                  |
| `spec.template.metadata.labels` | Labels de los Pods creados (deben incluir matchLabels) |
| `spec.template.spec`            | Especificación del Pod (igual que un Pod individual)   |
| `livenessProbe`                 | Kubernetes reinicia el contenedor si falla             |
| `readinessProbe`                | Kubernetes no envía tráfico si falla                   |

> **Importante**: `spec.selector.matchLabels` debe ser un subconjunto de `spec.template.metadata.labels`. Si no coinciden, Kubernetes rechazará el manifiesto.

### Paso 6: Crear el Deployment

```bash
# Aplicar el deployment
kubectl apply -f initial/deployment-ejemplo.yaml
```

**Salida esperada**:

```
deployment.apps/web-deployment created
```

Verifica el deployment:

```bash
# Ver el deployment
kubectl get deployment web-deployment

# Ver los pods creados
kubectl get pods -l app=web,tier=frontend
```

**Salida esperada**:

```
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
web-deployment   3/3     3            3           30s

NAME                              READY   STATUS    RESTARTS   AGE
web-deployment-5d9c6c9f8d-abc12   1/1     Running   0          30s
web-deployment-5d9c6c9f8d-def34   1/1     Running   0          30s
web-deployment-5d9c6c9f8d-ghi56   1/1     Running   0          30s
```

### Paso 7: Crear un Pod desde Cero en YAML

Ahora crearemos un Pod escribiendo el YAML desde cero. Crea el archivo `mi-pod.yaml`:

```bash
# Crear el archivo usando cat con heredoc
cat << 'EOF' > /tmp/mi-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: mi-pod-custom
  labels:
    app: custom-app
    environment: lab
    creado-en: lab-06
spec:
  containers:
    - name: httpd
      image: httpd:alpine
      ports:
        - containerPort: 80
      resources:
        requests:
          memory: "32Mi"
          cpu: "50m"
        limits:
          memory: "64Mi"
          cpu: "100m"
EOF
```

Aplica el archivo:

```bash
kubectl apply -f /tmp/mi-pod.yaml
```

**Salida esperada**:

```
pod/mi-pod-custom created
```

Verifica:

```bash
kubectl get pod mi-pod-custom --show-labels
```

**Salida esperada**:

```
NAME            READY   STATUS    RESTARTS   AGE   LABELS
mi-pod-custom   1/1     Running   0          30s   app=custom-app,creado-en=lab-06,environment=lab
```

### Paso 8: Generar YAML con dry-run

El flag `--dry-run=client` permite generar YAML sin crear el recurso:

```bash
# Generar YAML de un Pod
kubectl run generated-pod --image=nginx:alpine --dry-run=client -o yaml
```

**Salida esperada**:

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: generated-pod
  name: generated-pod
spec:
  containers:
    - image: nginx:alpine
      name: generated-pod
      resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

Guarda el YAML a un archivo:

```bash
# Generar y guardar a archivo
kubectl run generated-pod --image=nginx:alpine --dry-run=client -o yaml > /tmp/generated-pod.yaml

# Ver el contenido
cat /tmp/generated-pod.yaml
```

### Paso 9: Generar YAML de Deployment con dry-run

```bash
# Generar YAML de un Deployment
kubectl create deployment generated-deploy \
  --image=nginx:alpine \
  --replicas=2 \
  --dry-run=client -o yaml
```

**Salida esperada**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: generated-deploy
  name: generated-deploy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: generated-deploy
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: generated-deploy
    spec:
      containers:
        - image: nginx:alpine
          name: nginx
          resources: {}
status: {}
```

### Paso 10: Exportar un Recurso Existente a YAML

Puedes obtener el YAML de recursos existentes:

```bash
# Obtener YAML del pod existente
kubectl get pod pod-ejemplo -o yaml > /tmp/pod-ejemplo-export.yaml

# Ver el archivo (tiene muchos campos adicionales)
cat /tmp/pod-ejemplo-export.yaml | head -50
```

Para reutilizar este YAML, necesitarás eliminar los campos generados:

- `metadata.uid`
- `metadata.resourceVersion`
- `metadata.creationTimestamp`
- `metadata.managedFields`
- `status`

### Paso 11: Usar Labels y Selectors

Los labels son fundamentales para organizar recursos:

```bash
# Listar pods con label específico
kubectl get pods -l app=web

# Listar pods con múltiples labels (AND)
kubectl get pods -l app=web,tier=frontend

# Listar pods excluyendo un valor
kubectl get pods -l 'app!=web'

# Listar pods donde un label existe
kubectl get pods -l 'environment'

# Listar pods con selector de conjunto
kubectl get pods -l 'environment in (desarrollo, lab)'
```

Agregar labels a recursos existentes:

```bash
# Agregar un label
kubectl label pod pod-ejemplo team=backend

# Ver el label añadido
kubectl get pod pod-ejemplo --show-labels

# Sobrescribir un label existente
kubectl label pod pod-ejemplo version=v1.0.1 --overwrite

# Eliminar un label (usando el sufijo -)
kubectl label pod pod-ejemplo team-
```

### Paso 12: Ver Labels de Todos los Pods

```bash
# Ver todos los pods con labels
kubectl get pods --show-labels

# Ver pods en formato de tabla con labels específicos como columnas
kubectl get pods -L app,environment,version
```

**Salida esperada**:

```
NAME                              READY   STATUS    RESTARTS   AGE   APP              ENVIRONMENT   VERSION
mi-pod-custom                     1/1     Running   0          5m    custom-app       lab
pod-ejemplo                       1/1     Running   0          10m   mi-aplicacion    desarrollo    v1.0.1
web-deployment-5d9c6c9f8d-abc12   1/1     Running   0          8m    web              <none>        v1
web-deployment-5d9c6c9f8d-def34   1/1     Running   0          8m    web              <none>        v1
web-deployment-5d9c6c9f8d-ghi56   1/1     Running   0          8m    web              <none>        v1
```

### Paso 13: Crear Manifiesto Multi-Documento

Puedes definir múltiples recursos en un solo archivo separándolos con `---`:

```bash
# Crear un archivo multi-documento
cat << 'EOF' > /tmp/multi-recursos.yaml
# Primero creamos un Namespace
apiVersion: v1
kind: Namespace
metadata:
  name: lab-06-ns
---
# Luego un Pod en ese namespace
apiVersion: v1
kind: Pod
metadata:
  name: pod-en-namespace
  namespace: lab-06-ns
  labels:
    app: demo
spec:
  containers:
    - name: nginx
      image: nginx:alpine
---
# Y un segundo Pod
apiVersion: v1
kind: Pod
metadata:
  name: pod-secundario
  namespace: lab-06-ns
  labels:
    app: demo
    role: secondary
spec:
  containers:
    - name: busybox
      image: busybox
      command: ['sh', '-c', 'echo Hello && sleep 3600']
EOF
```

Aplica todos los recursos a la vez:

```bash
kubectl apply -f /tmp/multi-recursos.yaml
```

**Salida esperada**:

```
namespace/lab-06-ns created
pod/pod-en-namespace created
pod/pod-secundario created
```

Verifica los recursos en el nuevo namespace:

```bash
kubectl get all -n lab-06-ns
```

**Salida esperada**:

```
NAME                     READY   STATUS    RESTARTS   AGE
pod/pod-en-namespace     1/1     Running   0          30s
pod/pod-secundario       1/1     Running   0          30s
```

### Paso 14: Usar kubectl diff

El comando `kubectl diff` muestra las diferencias entre el estado actual y los cambios propuestos:

```bash
# Modificar el archivo pod-ejemplo.yaml localmente
cat << 'EOF' > /tmp/pod-ejemplo-modified.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-ejemplo
  namespace: default
  labels:
    app: mi-aplicacion
    environment: produccion
    version: v2.0.0
  annotations:
    description: "Pod modificado para demostrar kubectl diff"
spec:
  containers:
    - name: nginx
      image: nginx:1.25-alpine
      ports:
        - containerPort: 80
          name: http
      resources:
        requests:
          memory: "128Mi"
          cpu: "200m"
        limits:
          memory: "256Mi"
          cpu: "400m"
  restartPolicy: Always
EOF

# Ver las diferencias (sin aplicar cambios)
kubectl diff -f /tmp/pod-ejemplo-modified.yaml
```

> **Nota**: `kubectl diff` muestra cambios como un diff de git. Las líneas con `-` se eliminarán y las líneas con `+` se añadirán.

### Paso 15: Limpiar los Recursos

```bash
# Eliminar recursos individuales
kubectl delete pod pod-ejemplo
kubectl delete pod mi-pod-custom
kubectl delete deployment web-deployment

# Eliminar el namespace (elimina todo su contenido)
kubectl delete namespace lab-06-ns

# Verificar limpieza
kubectl get pods
kubectl get deployments
kubectl get namespaces | grep lab-06
```

**Salida esperada**:

```
pod "pod-ejemplo" deleted
pod "mi-pod-custom" deleted
deployment.apps "web-deployment" deleted
namespace "lab-06-ns" deleted

No resources found in default namespace.
No resources found in default namespace.
(sin resultados para namespace lab-06-ns)
```

## Ejercicios Adicionales

### Ejercicio 1: Crear un Deployment Completo desde Cero

Crea un archivo `ejercicio1-deployment.yaml` con:

- Nombre: `api-deployment`
- 2 réplicas
- Imagen: `httpd:alpine`
- Labels: `app=api`, `tier=backend`
- Resource requests: cpu 50m, memory 32Mi
- Resource limits: cpu 100m, memory 64Mi

```bash
# Solución
cat << 'EOF' > /tmp/ejercicio1-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-deployment
  labels:
    app: api
    tier: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
      tier: backend
  template:
    metadata:
      labels:
        app: api
        tier: backend
    spec:
      containers:
        - name: httpd
          image: httpd:alpine
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: "50m"
              memory: "32Mi"
            limits:
              cpu: "100m"
              memory: "64Mi"
EOF

# Aplicar y verificar
kubectl apply -f /tmp/ejercicio1-deployment.yaml
kubectl get deployment api-deployment
kubectl get pods -l app=api

# Limpiar
kubectl delete deployment api-deployment
```

### Ejercicio 2: Explorar API Resources

```bash
# Ver todos los recursos disponibles
kubectl api-resources | head -20

# Ver recursos de un grupo específico
kubectl api-resources --api-group=apps

# Ver recursos con namespaced=true
kubectl api-resources --namespaced=true | head -20

# Ver la documentación de un recurso
kubectl explain pod
kubectl explain pod.spec.containers
kubectl explain deployment.spec.strategy
```

### Ejercicio 3: Validar YAML antes de Aplicar

```bash
# Crear un YAML con error intencional
cat << 'EOF' > /tmp/pod-con-error.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-error
spec:
  containers:
    - name: test
      # Falta el campo 'image' que es requerido
EOF

# Validar con dry-run (detectará el error)
kubectl apply -f /tmp/pod-con-error.yaml --dry-run=server
```

### Ejercicio 4: Usar kubectl explain

El comando `kubectl explain` muestra documentación de los campos:

```bash
# Ver estructura de un Pod
kubectl explain pod

# Ver campos específicos
kubectl explain pod.spec
kubectl explain pod.spec.containers
kubectl explain pod.spec.containers.resources

# Ver toda la estructura recursivamente
kubectl explain pod --recursive | head -50
```

## Verificación

Antes de continuar al siguiente laboratorio, asegúrate de poder marcar todos estos puntos:

- [ ] Entiendo la estructura básica de un manifiesto YAML (apiVersion, kind, metadata, spec)
- [ ] Sé qué apiVersion usar para Pods (`v1`) y Deployments (`apps/v1`)
- [ ] Puedo escribir un Pod YAML desde cero con labels, resources y env vars
- [ ] Puedo escribir un Deployment YAML con selector y template
- [ ] Entiendo que `selector.matchLabels` debe coincidir con `template.metadata.labels`
- [ ] Puedo generar YAML con `--dry-run=client -o yaml`
- [ ] Puedo exportar recursos existentes a YAML con `-o yaml`
- [ ] Sé usar labels para filtrar recursos con `-l`
- [ ] Puedo agregar, modificar y eliminar labels con `kubectl label`
- [ ] Puedo crear archivos multi-documento con `---`
- [ ] Sé usar `kubectl diff` para ver cambios antes de aplicarlos
- [ ] Puedo usar `kubectl explain` para consultar documentación de campos

## Resumen de Comandos

| Comando                                                              | Descripción                                    |
| -------------------------------------------------------------------- | ---------------------------------------------- |
| `kubectl apply -f <archivo.yaml>`                                    | Crear o actualizar recursos desde archivo YAML |
| `kubectl get <recurso> -o yaml`                                      | Ver recurso en formato YAML                    |
| `kubectl run <nombre> --image=<img> --dry-run=client -o yaml`        | Generar YAML de Pod sin crearlo                |
| `kubectl create deployment <n> --image=<i> --dry-run=client -o yaml` | Generar YAML de Deployment                     |
| `kubectl get pods -l <label>=<valor>`                                | Filtrar pods por label                         |
| `kubectl get pods -L <label1>,<label2>`                              | Mostrar labels como columnas                   |
| `kubectl get pods --show-labels`                                     | Mostrar todos los labels de pods               |
| `kubectl label <recurso> <nombre> <clave>=<valor>`                   | Agregar label a un recurso                     |
| `kubectl label <recurso> <nombre> <clave>-`                          | Eliminar label de un recurso                   |
| `kubectl diff -f <archivo.yaml>`                                     | Ver diferencias antes de aplicar               |
| `kubectl explain <recurso>`                                          | Ver documentación de un recurso                |
| `kubectl explain <recurso>.<campo>`                                  | Ver documentación de un campo específico       |
| `kubectl api-resources`                                              | Listar todos los tipos de recursos             |
| `kubectl api-versions`                                               | Listar todas las versiones de API disponibles  |

## Conceptos Aprendidos

1. **Estructura de Manifiestos**: Todo recurso tiene apiVersion, kind, metadata y spec
2. **API Groups**: Diferentes recursos pertenecen a diferentes grupos (core, apps, networking, etc.)
3. **Labels**: Metadatos clave-valor para organizar y seleccionar recursos
4. **Annotations**: Metadatos adicionales no usados para selección
5. **Selectors**: Filtros basados en labels para encontrar recursos
6. **dry-run**: Modo para generar YAML sin crear recursos
7. **Multi-documento**: Múltiples recursos en un archivo separados por `---`
8. **kubectl explain**: Documentación integrada de campos de recursos

## Solución

Consulta el directorio `solution/` para ver los scripts con todos los comandos y las salidas esperadas.

## Navegación

- **Anterior**: [Lab 05: Scaling](../../modulo-04-objetos-fundamentales/lab-05-scaling/README.md)
- **Siguiente**: [Lab 07: Resource Updates](../lab-07-resource-updates/README.md)
