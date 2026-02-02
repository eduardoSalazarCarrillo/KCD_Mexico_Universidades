# Lab 04: Pods y Deployments

## Objetivo

Crear y gestionar Pods y Deployments en Kubernetes, entendiendo la relación entre Pod, ReplicaSet y Deployment.

## Prerrequisitos

- Lab 03 completado (Cluster Exploration)
- Clúster de Minikube ejecutándose (`minikube status` debe mostrar "Running")

## Duración

60 minutos

## Conceptos Clave

Antes de comenzar, es importante entender estos conceptos:

| Concepto         | Descripción                                                                                                            |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Pod**          | Unidad mínima de despliegue en Kubernetes. Contiene uno o más contenedores que comparten red y almacenamiento.         |
| **ReplicaSet**   | Asegura que un número específico de réplicas de un Pod estén corriendo en todo momento. Raramente se usa directamente. |
| **Deployment**   | Proporciona actualizaciones declarativas para Pods y ReplicaSets. Es la forma recomendada de gestionar aplicaciones.   |
| **Label**        | Par clave-valor que se adjunta a objetos como Pods. Se usa para organizar y seleccionar subconjuntos de objetos.       |
| **Selector**     | Permite filtrar objetos basándose en sus labels. Los Deployments usan selectores para identificar qué Pods gestionar.  |
| **Namespace**    | Forma de dividir recursos del clúster entre múltiples usuarios o proyectos. El namespace por defecto es `default`.     |
| **Self-healing** | Capacidad de Kubernetes de detectar y reemplazar automáticamente Pods que fallan o son eliminados.                     |

### Jerarquía de Objetos

```
┌─────────────────────────────────────────────────────────────────────┐
│                         DEPLOYMENT                                  │
│                                                                     │
│  - Define el estado deseado                                         │
│  - Gestiona actualizaciones y rollbacks                             │
│  - Mantiene historial de versiones                                  │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                      REPLICASET                               │  │
│  │                                                               │  │
│  │  - Creado automáticamente por el Deployment                   │  │
│  │  - Asegura N réplicas del Pod                                 │  │
│  │  - Reemplaza Pods que fallan                                  │  │
│  │                                                               │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │  │
│  │  │    POD 1    │  │    POD 2    │  │    POD 3    │   ...      │  │
│  │  │             │  │             │  │             │            │  │
│  │  │ ┌─────────┐ │  │ ┌─────────┐ │  │ ┌─────────┐ │            │  │
│  │  │ │Container│ │  │ │Container│ │  │ │Container│ │            │  │
│  │  │ │ (nginx) │ │  │ │ (nginx) │ │  │ │ (nginx) │ │            │  │
│  │  │ └─────────┘ │  │ └─────────┘ │  │ └─────────┘ │            │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘            │  │
│  │                                                               │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### ¿Por qué usar Deployments en lugar de Pods directamente?

| Característica         | Pod Solo | Deployment |
| ---------------------- | -------- | ---------- |
| Recreación automática  | No       | Sí         |
| Múltiples réplicas     | No       | Sí         |
| Rolling updates        | No       | Sí         |
| Rollback               | No       | Sí         |
| Historial de versiones | No       | Sí         |

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

### Paso 2: Crear un Pod Simple con kubectl run

El comando `kubectl run` es la forma más rápida de crear un Pod:

```bash
# Crear un pod llamado "mi-primer-pod" con la imagen nginx
kubectl run mi-primer-pod --image=nginx:alpine
```

**Salida esperada**:

```
pod/mi-primer-pod created
```

Verifica que el pod se creó:

```bash
# Listar pods en el namespace default
kubectl get pods
```

**Salida esperada**:

```
NAME            READY   STATUS    RESTARTS   AGE
mi-primer-pod   1/1     Running   0          30s
```

> **Nota**: El STATUS puede mostrar `ContainerCreating` mientras se descarga la imagen. Espera unos segundos y vuelve a ejecutar el comando.

Ver más detalles del pod:

```bash
# Información extendida
kubectl get pods -o wide
```

**Salida esperada**:

```
NAME            READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
mi-primer-pod   1/1     Running   0          1m    10.244.0.5   minikube   <none>           <none>
```

### Paso 3: Inspeccionar el Pod

Para ver información detallada del pod:

```bash
# Describir el pod
kubectl describe pod mi-primer-pod
```

Observa estas secciones importantes en la salida:

**Sección de metadatos**:

```
Name:             mi-primer-pod
Namespace:        default
Node:             minikube/192.168.49.2
Labels:           run=mi-primer-pod
```

**Sección de contenedor**:

```
Containers:
  mi-primer-pod:
    Image:          nginx:alpine
    Port:           <none>
    State:          Running
```

**Sección de eventos**:

```
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  1m    default-scheduler  Successfully assigned default/mi-primer-pod to minikube
  Normal  Pulled     1m    kubelet            Container image "nginx:alpine" already present on machine
  Normal  Created    1m    kubelet            Created container mi-primer-pod
  Normal  Started    1m    kubelet            Started container mi-primer-pod
```

### Paso 4: Ver los Logs del Pod

```bash
# Ver logs del pod
kubectl logs mi-primer-pod
```

> **Nota**: Si el pod no ha recibido tráfico, los logs pueden estar vacíos.

Para seguir los logs en tiempo real:

```bash
# Seguir logs (Ctrl+C para salir)
kubectl logs mi-primer-pod --follow
```

### Paso 5: Ejecutar Comandos Dentro del Pod

Puedes ejecutar comandos dentro del contenedor:

```bash
# Ejecutar un comando dentro del pod
kubectl exec mi-primer-pod -- nginx -v
```

**Salida esperada**:

```
nginx version: nginx/1.25.3
```

Para obtener una shell interactiva:

```bash
# Abrir una shell en el pod (salir con 'exit')
kubectl exec -it mi-primer-pod -- /bin/sh
```

Dentro del pod, explora:

```bash
# Dentro del pod
hostname
cat /etc/os-release
ls /usr/share/nginx/html/
exit
```

### Paso 6: Eliminar el Pod y Observar que NO se Recrea

Un Pod creado directamente NO se recreará si se elimina:

```bash
# Eliminar el pod
kubectl delete pod mi-primer-pod
```

**Salida esperada**:

```
pod "mi-primer-pod" deleted
```

Verifica que el pod fue eliminado:

```bash
kubectl get pods
```

**Salida esperada**:

```
No resources found in default namespace.
```

> **Importante**: El pod no se recrea automáticamente porque fue creado directamente, sin un controlador que lo gestione.

### Paso 7: Crear un Pod usando un Archivo YAML

Ahora crearemos un Pod usando un manifiesto YAML. Usa el archivo `initial/pod-nginx.yaml`:

```bash
# Ver el contenido del archivo
cat initial/pod-nginx.yaml
```

**Contenido del archivo**:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-nginx
  labels:
    app: nginx
    environment: lab
spec:
  containers:
    - name: nginx
      image: nginx:alpine
      ports:
        - containerPort: 80
```

**Explicación del YAML**:

| Campo                     | Descripción                                   |
| ------------------------- | --------------------------------------------- |
| `apiVersion: v1`          | Versión de la API de Kubernetes para Pods     |
| `kind: Pod`               | Tipo de recurso a crear                       |
| `metadata.name`           | Nombre único del Pod                          |
| `metadata.labels`         | Etiquetas para organizar y seleccionar el Pod |
| `spec.containers`         | Lista de contenedores en el Pod               |
| `spec.containers[].name`  | Nombre del contenedor                         |
| `spec.containers[].image` | Imagen de Docker a usar                       |
| `spec.containers[].ports` | Puertos que expone el contenedor              |

Aplica el manifiesto:

```bash
# Crear el pod desde el archivo YAML
kubectl apply -f initial/pod-nginx.yaml
```

**Salida esperada**:

```
pod/pod-nginx created
```

Verifica:

```bash
kubectl get pods --show-labels
```

**Salida esperada**:

```
NAME        READY   STATUS    RESTARTS   AGE   LABELS
pod-nginx   1/1     Running   0          30s   app=nginx,environment=lab
```

### Paso 8: Crear un Deployment

Ahora crearemos un Deployment que gestiona múltiples réplicas de Pods. Usa el archivo `initial/deployment-nginx.yaml`:

```bash
# Ver el contenido del archivo
cat initial/deployment-nginx.yaml
```

**Contenido del archivo**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-deploy
  template:
    metadata:
      labels:
        app: nginx-deploy
    spec:
      containers:
        - name: nginx
          image: nginx:alpine
          ports:
            - containerPort: 80
```

**Explicación del YAML**:

| Campo           | Descripción                                               |
| --------------- | --------------------------------------------------------- |
| `apiVersion`    | `apps/v1` para Deployments (diferente a Pods)             |
| `kind`          | `Deployment` indica el tipo de recurso                    |
| `spec.replicas` | Número de réplicas de Pods deseadas                       |
| `spec.selector` | Define cómo el Deployment encuentra los Pods que gestiona |
| `spec.template` | Plantilla para crear los Pods                             |

> **Importante**: El `selector.matchLabels` debe coincidir con `template.metadata.labels`.

Aplica el Deployment:

```bash
# Crear el deployment
kubectl apply -f initial/deployment-nginx.yaml
```

**Salida esperada**:

```
deployment.apps/nginx-deployment created
```

### Paso 9: Verificar el Deployment, ReplicaSet y Pods

Ver el estado del Deployment:

```bash
kubectl get deployments
```

**Salida esperada**:

```
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   3/3     3            3           30s
```

**Explicación de columnas**:

| Columna      | Descripción                            |
| ------------ | -------------------------------------- |
| `READY`      | Réplicas listas / Réplicas deseadas    |
| `UP-TO-DATE` | Réplicas actualizadas a la última spec |
| `AVAILABLE`  | Réplicas disponibles para servir       |

Ver el ReplicaSet creado automáticamente:

```bash
kubectl get replicasets
```

**Salida esperada**:

```
NAME                          DESIRED   CURRENT   READY   AGE
nginx-deployment-7d9c6c9f8d   3         3         3       1m
```

> **Nota**: El nombre del ReplicaSet incluye un hash (ej: `7d9c6c9f8d`) que identifica la versión del template.

Ver los Pods creados:

```bash
kubectl get pods --show-labels
```

**Salida esperada**:

```
NAME                                READY   STATUS    RESTARTS   AGE   LABELS
nginx-deployment-7d9c6c9f8d-abc12   1/1     Running   0          1m    app=nginx-deploy,pod-template-hash=7d9c6c9f8d
nginx-deployment-7d9c6c9f8d-def34   1/1     Running   0          1m    app=nginx-deploy,pod-template-hash=7d9c6c9f8d
nginx-deployment-7d9c6c9f8d-ghi56   1/1     Running   0          1m    app=nginx-deploy,pod-template-hash=7d9c6c9f8d
pod-nginx                           1/1     Running   0          5m    app=nginx,environment=lab
```

### Paso 10: Describir el Deployment

```bash
kubectl describe deployment nginx-deployment
```

Observa estas secciones:

**Estrategia de actualización**:

```
StrategyType:           RollingUpdate
RollingUpdateStrategy:  25% max unavailable, 25% max surge
```

**Estado de las réplicas**:

```
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
```

**Condiciones**:

```
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
```

### Paso 11: Probar el Self-Healing - Eliminar un Pod

Una de las ventajas de usar Deployments es el self-healing. Kubernetes automáticamente reemplaza Pods que fallan o son eliminados.

Primero, obtén el nombre de uno de los pods del Deployment:

```bash
# Guardar el nombre de un pod en una variable
POD_NAME=$(kubectl get pods -l app=nginx-deploy -o jsonpath='{.items[0].metadata.name}')
echo "Pod a eliminar: $POD_NAME"
```

Elimina el pod:

```bash
# Eliminar el pod
kubectl delete pod $POD_NAME
```

**Salida esperada**:

```
pod "nginx-deployment-7d9c6c9f8d-abc12" deleted
```

Inmediatamente verifica los pods:

```bash
# Ver pods (ejecutar rápidamente después de eliminar)
kubectl get pods -l app=nginx-deploy
```

**Salida esperada**:

```
NAME                                READY   STATUS              RESTARTS   AGE
nginx-deployment-7d9c6c9f8d-def34   1/1     Running             0          5m
nginx-deployment-7d9c6c9f8d-ghi56   1/1     Running             0          5m
nginx-deployment-7d9c6c9f8d-xyz99   0/1     ContainerCreating   0          2s
```

> **Observa**: Kubernetes detectó que hay menos de 3 réplicas y automáticamente creó un nuevo Pod (`xyz99`) para mantener el estado deseado.

Espera unos segundos y verifica de nuevo:

```bash
kubectl get pods -l app=nginx-deploy
```

**Salida esperada**:

```
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-7d9c6c9f8d-def34   1/1     Running   0          6m
nginx-deployment-7d9c6c9f8d-ghi56   1/1     Running   0          6m
nginx-deployment-7d9c6c9f8d-xyz99   1/1     Running   0          30s
```

### Paso 12: Filtrar Pods por Labels

Los labels son útiles para filtrar recursos:

```bash
# Ver todos los pods con label app=nginx-deploy
kubectl get pods -l app=nginx-deploy

# Ver pods que NO tienen cierto label
kubectl get pods -l 'app!=nginx-deploy'

# Ver pods con múltiples labels
kubectl get pods -l app=nginx,environment=lab
```

### Paso 13: Ver Todos los Recursos Relacionados

Para ver el Deployment, ReplicaSet y Pods juntos:

```bash
# Ver todo con un comando
kubectl get all -l app=nginx-deploy
```

**Salida esperada**:

```
NAME                                    READY   STATUS    RESTARTS   AGE
pod/nginx-deployment-7d9c6c9f8d-def34   1/1     Running   0          10m
pod/nginx-deployment-7d9c6c9f8d-ghi56   1/1     Running   0          10m
pod/nginx-deployment-7d9c6c9f8d-xyz99   1/1     Running   0          4m

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-deployment   3/3     3            3           10m

NAME                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-deployment-7d9c6c9f8d   3         3         3       10m
```

### Paso 14: Limpiar los Recursos

Elimina los recursos creados:

```bash
# Eliminar el pod individual
kubectl delete pod pod-nginx

# Eliminar el deployment (esto también elimina el ReplicaSet y los Pods)
kubectl delete deployment nginx-deployment
```

**Salida esperada**:

```
pod "pod-nginx" deleted
deployment.apps "nginx-deployment" deleted
```

Verifica que todo fue eliminado:

```bash
kubectl get all
```

**Salida esperada**:

```
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   1d
```

> **Nota**: El service `kubernetes` es un servicio del sistema que siempre existe.

## Ejercicios Adicionales

### Ejercicio 1: Crear un Pod con Múltiples Contenedores

```bash
# Crear un archivo multi-container.yaml
cat << 'EOF' > /tmp/multi-container.yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
  - name: sidecar
    image: busybox
    command: ['sh', '-c', 'while true; do echo "Sidecar running"; sleep 10; done']
EOF

# Aplicar el archivo
kubectl apply -f /tmp/multi-container.yaml

# Ver los contenedores del pod
kubectl get pod multi-container-pod

# Ver logs de un contenedor específico
kubectl logs multi-container-pod -c sidecar

# Limpiar
kubectl delete pod multi-container-pod
```

### Ejercicio 2: Crear un Deployment con kubectl create

```bash
# Crear deployment sin archivo YAML
kubectl create deployment web-app --image=httpd:alpine --replicas=2

# Verificar
kubectl get deployment web-app
kubectl get pods -l app=web-app

# Limpiar
kubectl delete deployment web-app
```

### Ejercicio 3: Generar YAML con dry-run

```bash
# Generar YAML de un pod sin crearlo
kubectl run test-pod --image=nginx:alpine --dry-run=client -o yaml

# Generar YAML de un deployment sin crearlo
kubectl create deployment test-deploy --image=nginx:alpine --replicas=2 --dry-run=client -o yaml
```

### Ejercicio 4: Ver el Historial de ReplicaSets

```bash
# Crear un deployment
kubectl create deployment history-test --image=nginx:alpine

# Ver el ReplicaSet
kubectl get rs -l app=history-test

# Ver el historial del deployment
kubectl rollout history deployment/history-test

# Limpiar
kubectl delete deployment history-test
```

### Ejercicio 5: Explorar el Comportamiento de Labels

```bash
# Crear un deployment
kubectl create deployment label-test --image=nginx:alpine --replicas=2

# Obtener el nombre de un pod
POD=$(kubectl get pods -l app=label-test -o jsonpath='{.items[0].metadata.name}')

# Ver los labels del pod
kubectl get pod $POD --show-labels

# Intentar cambiar el label del pod (esto lo desasocia del deployment)
kubectl label pod $POD app=otro-valor --overwrite

# Ver qué pasa (el deployment creará un nuevo pod!)
kubectl get pods --show-labels

# Limpiar
kubectl delete deployment label-test
kubectl delete pod -l app=otro-valor
```

## Verificación

Antes de continuar al siguiente laboratorio, asegúrate de poder marcar todos estos puntos:

- [ ] Puedo crear un Pod con `kubectl run`
- [ ] Puedo crear un Pod desde un archivo YAML con `kubectl apply -f`
- [ ] Puedo inspeccionar un Pod con `kubectl describe pod`
- [ ] Puedo ver los logs de un Pod con `kubectl logs`
- [ ] Puedo ejecutar comandos dentro de un Pod con `kubectl exec`
- [ ] Entiendo que un Pod solo no se recrea si se elimina
- [ ] Puedo crear un Deployment desde un archivo YAML
- [ ] Entiendo la relación Deployment → ReplicaSet → Pods
- [ ] Observé el self-healing: al eliminar un Pod del Deployment, se crea uno nuevo
- [ ] Puedo filtrar recursos usando labels con `-l`
- [ ] Puedo eliminar recursos con `kubectl delete`

## Resumen de Comandos

| Comando                                              | Descripción                                  |
| ---------------------------------------------------- | -------------------------------------------- |
| `kubectl run <nombre> --image=<imagen>`              | Crear un pod rápidamente                     |
| `kubectl apply -f <archivo.yaml>`                    | Crear/actualizar recursos desde archivo YAML |
| `kubectl get pods`                                   | Listar pods                                  |
| `kubectl get pods -o wide`                           | Listar pods con información extendida        |
| `kubectl get pods --show-labels`                     | Listar pods mostrando sus labels             |
| `kubectl get pods -l <label>=<valor>`                | Filtrar pods por label                       |
| `kubectl describe pod <nombre>`                      | Ver detalles de un pod                       |
| `kubectl logs <pod>`                                 | Ver logs de un pod                           |
| `kubectl logs <pod> -c <container>`                  | Ver logs de un contenedor específico         |
| `kubectl exec <pod> -- <comando>`                    | Ejecutar comando en un pod                   |
| `kubectl exec -it <pod> -- /bin/sh`                  | Abrir shell interactiva en un pod            |
| `kubectl delete pod <nombre>`                        | Eliminar un pod                              |
| `kubectl get deployments`                            | Listar deployments                           |
| `kubectl describe deployment <nombre>`               | Ver detalles de un deployment                |
| `kubectl get replicasets`                            | Listar replicasets                           |
| `kubectl get all`                                    | Listar todos los recursos                    |
| `kubectl delete deployment <nombre>`                 | Eliminar deployment y sus pods               |
| `kubectl create deployment --dry-run=client -o yaml` | Generar YAML sin crear el recurso            |

## Conceptos Aprendidos

1. **Pod**: Unidad mínima de despliegue, contiene uno o más contenedores
2. **Deployment**: Controlador que gestiona Pods de forma declarativa
3. **ReplicaSet**: Mantiene el número deseado de réplicas (creado automáticamente por Deployment)
4. **Self-healing**: Kubernetes reemplaza automáticamente Pods que fallan
5. **Labels**: Metadatos clave-valor para organizar y seleccionar recursos
6. **Selectors**: Filtros para encontrar recursos por sus labels

## Solución

Consulta el directorio `solution/` para ver los scripts con todos los comandos y las salidas esperadas.

## Navegación

- **Anterior**: [Lab 03: Cluster Exploration](../../../nivel-1-fundamentos/modulo-03-arquitectura/lab-03-cluster-exploration/README.md)
- **Siguiente**: [Lab 05: Scaling](../lab-05-scaling/README.md)
