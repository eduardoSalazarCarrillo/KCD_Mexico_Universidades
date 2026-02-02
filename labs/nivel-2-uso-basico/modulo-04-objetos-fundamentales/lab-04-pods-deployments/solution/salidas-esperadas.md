# Lab 04: Pods y Deployments - Salidas Esperadas

Este documento muestra las salidas esperadas de cada comando del laboratorio para que puedas verificar que todo funciona correctamente.

## Paso 1: Verificar que el Clúster está Funcionando

### minikube status

```
$ minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

## Paso 2: Crear un Pod Simple con kubectl run

### kubectl run mi-primer-pod --image=nginx:alpine

```
$ kubectl run mi-primer-pod --image=nginx:alpine
pod/mi-primer-pod created
```

### kubectl get pods

```
$ kubectl get pods
NAME            READY   STATUS    RESTARTS   AGE
mi-primer-pod   1/1     Running   0          30s
```

> **Nota**: El STATUS puede mostrar `ContainerCreating` inicialmente mientras se descarga la imagen.

### kubectl get pods -o wide

```
$ kubectl get pods -o wide
NAME            READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
mi-primer-pod   1/1     Running   0          1m    10.244.0.5   minikube   <none>           <none>
```

**Explicación de columnas**:

| Columna           | Descripción                                            |
| ----------------- | ------------------------------------------------------ |
| `NAME`            | Nombre del pod                                         |
| `READY`           | Contenedores listos / Total de contenedores            |
| `STATUS`          | Estado actual del pod                                  |
| `RESTARTS`        | Número de veces que se ha reiniciado                   |
| `AGE`             | Tiempo desde que se creó                               |
| `IP`              | Dirección IP del pod dentro del clúster                |
| `NODE`            | Nodo donde está corriendo el pod                       |
| `NOMINATED NODE`  | Nodo nominado para scheduling (raramente usado)        |
| `READINESS GATES` | Condiciones adicionales de readiness (raramente usado) |

## Paso 3: Inspeccionar el Pod

### kubectl describe pod mi-primer-pod (extracto)

```
$ kubectl describe pod mi-primer-pod
Name:             mi-primer-pod
Namespace:        default
Priority:         0
Service Account:  default
Node:             minikube/192.168.49.2
Start Time:       ...
Labels:           run=mi-primer-pod
Annotations:      <none>
Status:           Running
IP:               10.244.0.5
IPs:
  IP:  10.244.0.5
Containers:
  mi-primer-pod:
    Container ID:   docker://abc123...
    Image:          nginx:alpine
    Image ID:       docker-pullable://nginx@sha256:...
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      ...
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-xxxxx (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
...
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  1m    default-scheduler  Successfully assigned default/mi-primer-pod to minikube
  Normal  Pulled     1m    kubelet            Container image "nginx:alpine" already present on machine
  Normal  Created    1m    kubelet            Created container mi-primer-pod
  Normal  Started    1m    kubelet            Started container mi-primer-pod
```

**Secciones importantes**:

| Sección      | Descripción                                         |
| ------------ | --------------------------------------------------- |
| `Labels`     | Etiquetas asignadas al pod                          |
| `Status`     | Estado actual (Pending, Running, Succeeded, Failed) |
| `IP`         | Dirección IP asignada al pod                        |
| `Containers` | Detalles de cada contenedor                         |
| `Conditions` | Condiciones del pod (Initialized, Ready, etc.)      |
| `Events`     | Historial de eventos del pod                        |

## Paso 4: Ver los Logs del Pod

### kubectl logs mi-primer-pod

```
$ kubectl logs mi-primer-pod
(vacío si no hay tráfico)
```

> **Nota**: nginx solo genera logs cuando recibe peticiones HTTP.

## Paso 5: Ejecutar Comandos Dentro del Pod

### kubectl exec mi-primer-pod -- nginx -v

```
$ kubectl exec mi-primer-pod -- nginx -v
nginx version: nginx/1.25.3
```

### kubectl exec mi-primer-pod -- hostname

```
$ kubectl exec mi-primer-pod -- hostname
mi-primer-pod
```

### kubectl exec mi-primer-pod -- cat /etc/os-release

```
$ kubectl exec mi-primer-pod -- cat /etc/os-release
NAME="Alpine Linux"
ID=alpine
VERSION_ID=3.18.4
PRETTY_NAME="Alpine Linux v3.18"
HOME_URL="https://alpinelinux.org/"
BUG_REPORT_URL="https://gitlab.alpinelinux.org/alpine/aports/-/issues"
```

### kubectl exec mi-primer-pod -- ls /usr/share/nginx/html/

```
$ kubectl exec mi-primer-pod -- ls /usr/share/nginx/html/
50x.html
index.html
```

## Paso 6: Eliminar el Pod

### kubectl delete pod mi-primer-pod

```
$ kubectl delete pod mi-primer-pod
pod "mi-primer-pod" deleted
```

### kubectl get pods (después de eliminar)

```
$ kubectl get pods
No resources found in default namespace.
```

> **Importante**: El pod NO se recrea porque fue creado directamente sin un controlador.

## Paso 7: Crear un Pod usando un Archivo YAML

### kubectl apply -f initial/pod-nginx.yaml

```
$ kubectl apply -f initial/pod-nginx.yaml
pod/pod-nginx created
```

### kubectl get pods --show-labels

```
$ kubectl get pods --show-labels
NAME        READY   STATUS    RESTARTS   AGE   LABELS
pod-nginx   1/1     Running   0          30s   app=nginx,environment=lab
```

## Paso 8: Crear un Deployment

### kubectl apply -f initial/deployment-nginx.yaml

```
$ kubectl apply -f initial/deployment-nginx.yaml
deployment.apps/nginx-deployment created
```

## Paso 9: Verificar el Deployment, ReplicaSet y Pods

### kubectl get deployments

```
$ kubectl get deployments
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   3/3     3            3           30s
```

**Explicación de columnas**:

| Columna      | Descripción                                      |
| ------------ | ------------------------------------------------ |
| `NAME`       | Nombre del deployment                            |
| `READY`      | Réplicas listas / Réplicas deseadas              |
| `UP-TO-DATE` | Réplicas actualizadas a la última especificación |
| `AVAILABLE`  | Réplicas disponibles para servir tráfico         |
| `AGE`        | Tiempo desde que se creó el deployment           |

### kubectl get replicasets

```
$ kubectl get replicasets
NAME                          DESIRED   CURRENT   READY   AGE
nginx-deployment-7d9c6c9f8d   3         3         3       1m
```

**Explicación de columnas**:

| Columna   | Descripción                          |
| --------- | ------------------------------------ |
| `NAME`    | Nombre del ReplicaSet (incluye hash) |
| `DESIRED` | Número deseado de réplicas           |
| `CURRENT` | Número actual de réplicas            |
| `READY`   | Réplicas listas para servir          |
| `AGE`     | Tiempo desde que se creó             |

> **Nota**: El hash en el nombre (ej: `7d9c6c9f8d`) identifica la versión del pod template.

### kubectl get pods --show-labels

```
$ kubectl get pods --show-labels
NAME                                READY   STATUS    RESTARTS   AGE   LABELS
nginx-deployment-7d9c6c9f8d-abc12   1/1     Running   0          1m    app=nginx-deploy,pod-template-hash=7d9c6c9f8d
nginx-deployment-7d9c6c9f8d-def34   1/1     Running   0          1m    app=nginx-deploy,pod-template-hash=7d9c6c9f8d
nginx-deployment-7d9c6c9f8d-ghi56   1/1     Running   0          1m    app=nginx-deploy,pod-template-hash=7d9c6c9f8d
pod-nginx                           1/1     Running   0          5m    app=nginx,environment=lab
```

> **Observa**: Los pods del deployment tienen nombres generados automáticamente con el formato `<deployment>-<replicaset-hash>-<pod-hash>`.

## Paso 10: Describir el Deployment

### kubectl describe deployment nginx-deployment (extracto)

```
$ kubectl describe deployment nginx-deployment
Name:                   nginx-deployment
Namespace:              default
CreationTimestamp:      ...
Labels:                 app=nginx
Annotations:            deployment.kubernetes.io/revision: 1
Selector:               app=nginx-deploy
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=nginx-deploy
  Containers:
   nginx:
    Image:        nginx:alpine
    Port:         80/TCP
    Host Port:    0/TCP
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   nginx-deployment-7d9c6c9f8d (3/3 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  2m    deployment-controller  Scaled up replica set nginx-deployment-7d9c6c9f8d to 3
```

**Secciones importantes**:

| Sección                 | Descripción                                          |
| ----------------------- | ---------------------------------------------------- |
| `Replicas`              | Estado actual de las réplicas                        |
| `StrategyType`          | Estrategia de actualización (RollingUpdate/Recreate) |
| `RollingUpdateStrategy` | Parámetros de rolling update                         |
| `Pod Template`          | Template usado para crear pods                       |
| `Conditions`            | Condiciones del deployment                           |
| `NewReplicaSet`         | ReplicaSet activo                                    |
| `Events`                | Historial de eventos                                 |

## Paso 11: Probar el Self-Healing

### kubectl delete pod <nombre-del-pod>

```
$ kubectl delete pod nginx-deployment-7d9c6c9f8d-abc12
pod "nginx-deployment-7d9c6c9f8d-abc12" deleted
```

### kubectl get pods -l app=nginx-deploy (inmediatamente después)

```
$ kubectl get pods -l app=nginx-deploy
NAME                                READY   STATUS              RESTARTS   AGE
nginx-deployment-7d9c6c9f8d-def34   1/1     Running             0          5m
nginx-deployment-7d9c6c9f8d-ghi56   1/1     Running             0          5m
nginx-deployment-7d9c6c9f8d-xyz99   0/1     ContainerCreating   0          2s
```

> **Observa**: Kubernetes inmediatamente crea un nuevo pod (`xyz99`) para mantener 3 réplicas.

### kubectl get pods -l app=nginx-deploy (después de unos segundos)

```
$ kubectl get pods -l app=nginx-deploy
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-7d9c6c9f8d-def34   1/1     Running   0          6m
nginx-deployment-7d9c6c9f8d-ghi56   1/1     Running   0          6m
nginx-deployment-7d9c6c9f8d-xyz99   1/1     Running   0          30s
```

> **Self-healing en acción**: El deployment mantiene automáticamente el número deseado de réplicas.

## Paso 12: Filtrar Pods por Labels

### kubectl get pods -l app=nginx-deploy

```
$ kubectl get pods -l app=nginx-deploy
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-7d9c6c9f8d-def34   1/1     Running   0          10m
nginx-deployment-7d9c6c9f8d-ghi56   1/1     Running   0          10m
nginx-deployment-7d9c6c9f8d-xyz99   1/1     Running   0          4m
```

### kubectl get pods -l 'app!=nginx-deploy'

```
$ kubectl get pods -l 'app!=nginx-deploy'
NAME        READY   STATUS    RESTARTS   AGE
pod-nginx   1/1     Running   0          15m
```

### kubectl get pods -l app=nginx,environment=lab

```
$ kubectl get pods -l app=nginx,environment=lab
NAME        READY   STATUS    RESTARTS   AGE
pod-nginx   1/1     Running   0          15m
```

## Paso 13: Ver Todos los Recursos Relacionados

### kubectl get all -l app=nginx-deploy

```
$ kubectl get all -l app=nginx-deploy
NAME                                    READY   STATUS    RESTARTS   AGE
pod/nginx-deployment-7d9c6c9f8d-def34   1/1     Running   0          10m
pod/nginx-deployment-7d9c6c9f8d-ghi56   1/1     Running   0          10m
pod/nginx-deployment-7d9c6c9f8d-xyz99   1/1     Running   0          4m

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-deployment   3/3     3            3           10m

NAME                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-deployment-7d9c6c9f8d   3         3         3       10m
```

## Paso 14: Limpiar los Recursos

### kubectl delete pod pod-nginx

```
$ kubectl delete pod pod-nginx
pod "pod-nginx" deleted
```

### kubectl delete deployment nginx-deployment

```
$ kubectl delete deployment nginx-deployment
deployment.apps "nginx-deployment" deleted
```

> **Nota**: Eliminar el deployment también elimina el ReplicaSet y todos los Pods asociados.

### kubectl get all (después de limpiar)

```
$ kubectl get all
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   1d
```

> **Nota**: El service `kubernetes` es un servicio del sistema que siempre existe.

## Ejercicios Adicionales

### Ejercicio 2: Crear un Deployment con kubectl create

```
$ kubectl create deployment web-app --image=httpd:alpine --replicas=2
deployment.apps/web-app created

$ kubectl get deployment web-app
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
web-app   2/2     2            2           30s

$ kubectl get pods -l app=web-app
NAME                       READY   STATUS    RESTARTS   AGE
web-app-5d8c7b6f4d-abc12   1/1     Running   0          30s
web-app-5d8c7b6f4d-def34   1/1     Running   0          30s
```

### Ejercicio 3: Generar YAML con dry-run

```
$ kubectl run test-pod --image=nginx:alpine --dry-run=client -o yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: test-pod
  name: test-pod
spec:
  containers:
  - image: nginx:alpine
    name: test-pod
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

```
$ kubectl create deployment test-deploy --image=nginx:alpine --replicas=2 --dry-run=client -o yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: test-deploy
  name: test-deploy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: test-deploy
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: test-deploy
    spec:
      containers:
      - image: nginx:alpine
        name: nginx
        resources: {}
status: {}
```

## Resumen

Si todas tus salidas son similares a las mostradas en este documento, has completado exitosamente el Lab 04.

Las diferencias menores que puedes esperar:

- **Nombres de pods**: Los sufijos aleatorios (como `-abc12`, `-def34`) serán diferentes
- **IPs**: Las direcciones IP de los pods variarán
- **Hashes de ReplicaSet**: El hash (como `7d9c6c9f8d`) puede ser diferente
- **Timestamps y AGE**: Dependen de cuándo ejecutaste los comandos
- **Versión de nginx**: Puede variar según la versión actual de la imagen

### Conceptos Clave Demostrados

| Concepto            | Demostración                                  |
| ------------------- | --------------------------------------------- |
| Pod sin controlador | Se elimina y NO se recrea                     |
| Deployment          | Crea ReplicaSet automáticamente               |
| ReplicaSet          | Mantiene N réplicas de pods                   |
| Self-healing        | Pods eliminados son recreados automáticamente |
| Labels              | Permiten filtrar y seleccionar recursos       |
| Selectors           | Conectan Deployments con sus Pods via labels  |
