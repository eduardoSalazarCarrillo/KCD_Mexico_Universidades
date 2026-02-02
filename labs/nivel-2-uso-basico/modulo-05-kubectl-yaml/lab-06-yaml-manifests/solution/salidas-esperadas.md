# Lab 06: YAML Manifests - Salidas Esperadas

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

## Paso 2: Analizar la Estructura de un Pod YAML

### cat initial/pod-ejemplo.yaml

```yaml
$ cat initial/pod-ejemplo.yaml
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

## Paso 3: Crear el Pod desde el Archivo YAML

### kubectl apply -f initial/pod-ejemplo.yaml

```
$ kubectl apply -f initial/pod-ejemplo.yaml
pod/pod-ejemplo created
```

### kubectl get pod pod-ejemplo --show-labels

```
$ kubectl get pod pod-ejemplo --show-labels
NAME          READY   STATUS    RESTARTS   AGE   LABELS
pod-ejemplo   1/1     Running   0          30s   app=mi-aplicacion,environment=desarrollo,version=v1.0.0
```

**Explicación de columnas**:

| Columna    | Descripción                 |
| ---------- | --------------------------- |
| `NAME`     | Nombre del pod              |
| `READY`    | Contenedores listos / Total |
| `STATUS`   | Estado actual del pod       |
| `RESTARTS` | Número de reinicios         |
| `AGE`      | Tiempo desde la creación    |
| `LABELS`   | Labels asignados al pod     |

## Paso 4: Ver el YAML Completo del Pod Creado

### kubectl get pod pod-ejemplo -o yaml (extracto)

```yaml
$ kubectl get pod pod-ejemplo -o yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    creado-por: equipo-devops
    description: Pod de ejemplo para el laboratorio 06
  creationTimestamp: "2024-01-15T10:30:00Z"
  labels:
    app: mi-aplicacion
    environment: desarrollo
    version: v1.0.0
  name: pod-ejemplo
  namespace: default
  resourceVersion: "12345"
  uid: abc123-def456-ghi789
spec:
  containers:
  - env:
    - name: NGINX_HOST
      value: localhost
    - name: NGINX_PORT
      value: "80"
    image: nginx:1.24-alpine
    name: nginx
    ports:
    - containerPort: 80
      name: http
      protocol: TCP
    resources:
      limits:
        cpu: 200m
        memory: 128Mi
      requests:
        cpu: 100m
        memory: 64Mi
...
status:
  phase: Running
  conditions:
  - type: Ready
    status: "True"
...
```

> **Nota**: Kubernetes añade campos como `uid`, `resourceVersion`, `creationTimestamp` y `status`.

## Paso 5: Analizar la Estructura de un Deployment YAML

### cat initial/deployment-ejemplo.yaml

```yaml
$ cat initial/deployment-ejemplo.yaml
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

## Paso 6: Crear el Deployment

### kubectl apply -f initial/deployment-ejemplo.yaml

```
$ kubectl apply -f initial/deployment-ejemplo.yaml
deployment.apps/web-deployment created
```

### kubectl get deployment web-deployment

```
$ kubectl get deployment web-deployment
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
web-deployment   3/3     3            3           30s
```

### kubectl get pods -l app=web,tier=frontend

```
$ kubectl get pods -l app=web,tier=frontend
NAME                              READY   STATUS    RESTARTS   AGE
web-deployment-5d9c6c9f8d-abc12   1/1     Running   0          30s
web-deployment-5d9c6c9f8d-def34   1/1     Running   0          30s
web-deployment-5d9c6c9f8d-ghi56   1/1     Running   0          30s
```

## Paso 7: Crear un Pod desde Cero en YAML

### kubectl apply -f /tmp/mi-pod.yaml

```
$ kubectl apply -f /tmp/mi-pod.yaml
pod/mi-pod-custom created
```

### kubectl get pod mi-pod-custom --show-labels

```
$ kubectl get pod mi-pod-custom --show-labels
NAME            READY   STATUS    RESTARTS   AGE   LABELS
mi-pod-custom   1/1     Running   0          30s   app=custom-app,creado-en=lab-06,environment=lab
```

## Paso 8: Generar YAML con dry-run

### kubectl run generated-pod --image=nginx:alpine --dry-run=client -o yaml

```yaml
$ kubectl run generated-pod --image=nginx:alpine --dry-run=client -o yaml
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

> **Nota**: El YAML generado es un template básico. Los campos con `null` o `{}` se pueden eliminar o completar según necesidades.

## Paso 9: Generar YAML de Deployment con dry-run

### kubectl create deployment generated-deploy --image=nginx:alpine --replicas=2 --dry-run=client -o yaml

```yaml
$ kubectl create deployment generated-deploy --image=nginx:alpine --replicas=2 --dry-run=client -o yaml
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

## Paso 10: Exportar un Recurso Existente a YAML

### kubectl get pod pod-ejemplo -o yaml (extracto)

```
$ kubectl get pod pod-ejemplo -o yaml | head -50
apiVersion: v1
kind: Pod
metadata:
  annotations:
    creado-por: equipo-devops
    description: Pod de ejemplo para el laboratorio 06
  creationTimestamp: "2024-01-15T10:30:00Z"
  labels:
    app: mi-aplicacion
    environment: desarrollo
    version: v1.0.0
  managedFields:
  - apiVersion: v1
    fieldsType: FieldsV1
    fieldsV1:
      ...
  name: pod-ejemplo
  namespace: default
  resourceVersion: "12345"
  uid: abc123-def456-ghi789
spec:
  containers:
  - env:
    ...
```

> **Nota**: Para reutilizar este YAML, elimina: `uid`, `resourceVersion`, `creationTimestamp`, `managedFields`, `status`.

## Paso 11: Usar Labels y Selectors

### kubectl get pods -l app=web

```
$ kubectl get pods -l app=web
NAME                              READY   STATUS    RESTARTS   AGE
web-deployment-5d9c6c9f8d-abc12   1/1     Running   0          5m
web-deployment-5d9c6c9f8d-def34   1/1     Running   0          5m
web-deployment-5d9c6c9f8d-ghi56   1/1     Running   0          5m
```

### kubectl get pods -l 'app!=web'

```
$ kubectl get pods -l 'app!=web'
NAME            READY   STATUS    RESTARTS   AGE
mi-pod-custom   1/1     Running   0          3m
pod-ejemplo     1/1     Running   0          8m
```

### kubectl label pod pod-ejemplo team=backend

```
$ kubectl label pod pod-ejemplo team=backend
pod/pod-ejemplo labeled
```

### kubectl get pod pod-ejemplo --show-labels (después de agregar label)

```
$ kubectl get pod pod-ejemplo --show-labels
NAME          READY   STATUS    RESTARTS   AGE   LABELS
pod-ejemplo   1/1     Running   0          10m   app=mi-aplicacion,environment=desarrollo,team=backend,version=v1.0.0
```

### kubectl label pod pod-ejemplo version=v1.0.1 --overwrite

```
$ kubectl label pod pod-ejemplo version=v1.0.1 --overwrite
pod/pod-ejemplo labeled
```

### kubectl label pod pod-ejemplo team-

```
$ kubectl label pod pod-ejemplo team-
pod/pod-ejemplo unlabeled
```

## Paso 12: Ver Labels de Todos los Pods

### kubectl get pods --show-labels

```
$ kubectl get pods --show-labels
NAME                              READY   STATUS    RESTARTS   AGE   LABELS
mi-pod-custom                     1/1     Running   0          5m    app=custom-app,creado-en=lab-06,environment=lab
pod-ejemplo                       1/1     Running   0          10m   app=mi-aplicacion,environment=desarrollo,version=v1.0.1
web-deployment-5d9c6c9f8d-abc12   1/1     Running   0          8m    app=web,pod-template-hash=5d9c6c9f8d,tier=frontend,version=v1
web-deployment-5d9c6c9f8d-def34   1/1     Running   0          8m    app=web,pod-template-hash=5d9c6c9f8d,tier=frontend,version=v1
web-deployment-5d9c6c9f8d-ghi56   1/1     Running   0          8m    app=web,pod-template-hash=5d9c6c9f8d,tier=frontend,version=v1
```

### kubectl get pods -L app,environment,version

```
$ kubectl get pods -L app,environment,version
NAME                              READY   STATUS    RESTARTS   AGE   APP              ENVIRONMENT   VERSION
mi-pod-custom                     1/1     Running   0          5m    custom-app       lab           <none>
pod-ejemplo                       1/1     Running   0          10m   mi-aplicacion    desarrollo    v1.0.1
web-deployment-5d9c6c9f8d-abc12   1/1     Running   0          8m    web              <none>        v1
web-deployment-5d9c6c9f8d-def34   1/1     Running   0          8m    web              <none>        v1
web-deployment-5d9c6c9f8d-ghi56   1/1     Running   0          8m    web              <none>        v1
```

## Paso 13: Crear Manifiesto Multi-Documento

### kubectl apply -f /tmp/multi-recursos.yaml

```
$ kubectl apply -f /tmp/multi-recursos.yaml
namespace/lab-06-ns created
pod/pod-en-namespace created
pod/pod-secundario created
```

### kubectl get all -n lab-06-ns

```
$ kubectl get all -n lab-06-ns
NAME                     READY   STATUS    RESTARTS   AGE
pod/pod-en-namespace     1/1     Running   0          30s
pod/pod-secundario       1/1     Running   0          30s
```

## Paso 14: Usar kubectl diff

### kubectl diff -f /tmp/pod-ejemplo-modified.yaml (ejemplo)

```diff
$ kubectl diff -f /tmp/pod-ejemplo-modified.yaml
diff -u -N /tmp/LIVE-123/v1.Pod.default.pod-ejemplo /tmp/MERGED-456/v1.Pod.default.pod-ejemplo
--- /tmp/LIVE-123/v1.Pod.default.pod-ejemplo
+++ /tmp/MERGED-456/v1.Pod.default.pod-ejemplo
@@ -4,10 +4,10 @@
   annotations:
-    description: Pod de ejemplo para el laboratorio 06
+    description: Pod modificado para demostrar kubectl diff
   labels:
     app: mi-aplicacion
-    environment: desarrollo
-    version: v1.0.0
+    environment: produccion
+    version: v2.0.0
 ...
@@ -15,7 +15,7 @@
   containers:
   - name: nginx
-    image: nginx:1.24-alpine
+    image: nginx:1.25-alpine
     resources:
       requests:
-        memory: "64Mi"
-        cpu: "100m"
+        memory: "128Mi"
+        cpu: "200m"
       limits:
-        memory: "128Mi"
-        cpu: "200m"
+        memory: "256Mi"
+        cpu: "400m"
```

> **Nota**: Las líneas con `-` se eliminarían y las líneas con `+` se añadirían al aplicar.

## Paso 15: Limpiar los Recursos

### kubectl delete pod pod-ejemplo

```
$ kubectl delete pod pod-ejemplo
pod "pod-ejemplo" deleted
```

### kubectl delete pod mi-pod-custom

```
$ kubectl delete pod mi-pod-custom
pod "mi-pod-custom" deleted
```

### kubectl delete deployment web-deployment

```
$ kubectl delete deployment web-deployment
deployment.apps "web-deployment" deleted
```

### kubectl delete namespace lab-06-ns

```
$ kubectl delete namespace lab-06-ns
namespace "lab-06-ns" deleted
```

### kubectl get pods (después de limpiar)

```
$ kubectl get pods
No resources found in default namespace.
```

## Ejercicios Adicionales

### Ejercicio 2: kubectl api-resources

```
$ kubectl api-resources | head -15
NAME                              SHORTNAMES   APIVERSION                        NAMESPACED   KIND
bindings                                       v1                                true         Binding
componentstatuses                 cs           v1                                false        ComponentStatus
configmaps                        cm           v1                                true         ConfigMap
endpoints                         ep           v1                                true         Endpoints
events                            ev           v1                                true         Event
limitranges                       limits       v1                                true         LimitRange
namespaces                        ns           v1                                false        Namespace
nodes                             no           v1                                false        Node
persistentvolumeclaims            pvc          v1                                true         PersistentVolumeClaim
persistentvolumes                 pv           v1                                false        PersistentVolume
pods                              po           v1                                true         Pod
podtemplates                                   v1                                true         PodTemplate
replicationcontrollers            rc           v1                                true         ReplicationController
resourcequotas                    quota        v1                                true         ResourceQuota
```

### kubectl api-resources --api-group=apps

```
$ kubectl api-resources --api-group=apps
NAME                  SHORTNAMES   APIVERSION   NAMESPACED   KIND
controllerrevisions                apps/v1      true         ControllerRevision
daemonsets            ds           apps/v1      true         DaemonSet
deployments           deploy       apps/v1      true         Deployment
replicasets           rs           apps/v1      true         ReplicaSet
statefulsets          sts          apps/v1      true         StatefulSet
```

### Ejercicio 4: kubectl explain

```
$ kubectl explain pod
KIND:     Pod
VERSION:  v1

DESCRIPTION:
     Pod is a collection of containers that can run on a host. This resource is
     created by clients and scheduled onto hosts.

FIELDS:
   apiVersion   <string>
   kind <string>
   metadata     <Object>
   spec <Object>
   status       <Object>
```

```
$ kubectl explain pod.spec.containers | head -20
KIND:     Pod
VERSION:  v1

RESOURCE: containers <[]Object>

DESCRIPTION:
     List of containers belonging to the pod. Containers cannot currently be
     added or removed. There must be at least one container in a Pod. Cannot be
     updated.

FIELDS:
   args <[]string>
   command      <[]string>
   env  <[]Object>
   envFrom      <[]Object>
   image        <string>
   imagePullPolicy      <string>
   lifecycle    <Object>
   livenessProbe        <Object>
   name <string> -required-
```

## Resumen

Si todas tus salidas son similares a las mostradas en este documento, has completado exitosamente el Lab 06.

Las diferencias menores que puedes esperar:

- **Nombres de pods**: Los sufijos aleatorios del deployment serán diferentes
- **IPs**: Las direcciones IP de los pods variarán
- **Timestamps**: Dependen de cuándo ejecutaste los comandos
- **UIDs y resourceVersions**: Son únicos para cada recurso

### Conceptos Clave Demostrados

| Concepto              | Demostración                                 |
| --------------------- | -------------------------------------------- |
| Estructura de YAML    | apiVersion, kind, metadata, spec             |
| API Groups            | v1 para core, apps/v1 para Deployments       |
| Labels                | Organización y filtrado de recursos          |
| Selectors             | Filtrado con -l, matchLabels en Deployments  |
| dry-run               | Generación de YAML sin crear recursos        |
| Multi-documento       | Múltiples recursos en un archivo con ---     |
| kubectl diff          | Vista previa de cambios antes de aplicar     |
| kubectl explain       | Documentación integrada de campos            |
| kubectl api-resources | Exploración de tipos de recursos disponibles |
