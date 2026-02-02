# Salidas Esperadas - Proyecto Final

Este documento muestra las salidas esperadas para cada fase del proyecto final.

## Fase 0: Verificación del entorno

### Minikube Status

```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

### Addons habilitados

```
$ minikube addons list | grep -E "ingress|metrics"
| ingress                     | minikube | enabled ✅   |
| metrics-server              | minikube | enabled ✅   |
```

## Fase 1: Imágenes Docker

```
$ docker images | grep todo
todo-frontend   v1    abc123def456   10 seconds ago   25MB
todo-backend    v1    789ghi012jkl   30 seconds ago   180MB
```

## Fase 2: Configuración

### Namespace

```
$ kubectl get namespace todo-app
NAME       STATUS   AGE
todo-app   Active   10s
```

### Secrets y ConfigMaps

```
$ kubectl get secrets,configmaps -n todo-app
NAME                         TYPE     DATA   AGE
secret/postgres-secret       Opaque   5      10s

NAME                         DATA   AGE
configmap/backend-config     5      10s
configmap/kube-root-ca.crt   1      10s
```

## Fase 3: PostgreSQL

### Pods, PVC y Service

```
$ kubectl get pods,pvc,svc -n todo-app -l app=postgres
NAME             READY   STATUS    RESTARTS   AGE
pod/postgres-0   1/1     Running   0          60s

NAME                                 STATUS   VOLUME     CAPACITY   ACCESS MODES   AGE
persistentvolumeclaim/postgres-pvc   Bound    pvc-xxx    1Gi        RWO            60s

NAME               TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
service/postgres   ClusterIP   None         <none>        5432/TCP   60s
```

## Fase 4: Backend

### Pods y Service

```
$ kubectl get pods,svc -n todo-app -l app=backend
NAME                           READY   STATUS    RESTARTS   AGE
pod/backend-5d9f8b7c4d-abc12   1/1     Running   0          30s
pod/backend-5d9f8b7c4d-def34   1/1     Running   0          30s
pod/backend-5d9f8b7c4d-ghi56   1/1     Running   0          30s

NAME              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/backend   ClusterIP   10.96.xxx.xxx   <none>        3000/TCP   30s
```

### Logs del Backend

```
$ kubectl logs -l app=backend -n todo-app --tail=5
Base de datos inicializada correctamente
Servidor corriendo en puerto 3000
Ambiente: production
```

### Health Check

```
$ curl http://localhost:3000/health
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "environment": "production"
}
```

## Fase 5: Frontend

### Pods y Service

```
$ kubectl get pods,svc -n todo-app -l app=frontend
NAME                            READY   STATUS    RESTARTS   AGE
pod/frontend-7b8c9d0e1f-jkl78   1/1     Running   0          20s
pod/frontend-7b8c9d0e1f-mno90   1/1     Running   0          20s
pod/frontend-7b8c9d0e1f-pqr12   1/1     Running   0          20s

NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/frontend   ClusterIP   10.96.xxx.xxx   <none>        80/TCP    20s
```

## Fase 6: Ingress

```
$ kubectl get ingress -n todo-app
NAME           CLASS   HOSTS        ADDRESS        PORTS   AGE
todo-ingress   nginx   todo.local   192.168.49.2   80      10s
```

### Describe Ingress

```
$ kubectl describe ingress todo-ingress -n todo-app
Name:             todo-ingress
Namespace:        todo-app
Address:          192.168.49.2
Ingress Class:    nginx
Rules:
  Host        Path  Backends
  ----        ----  --------
  todo.local
              /api(/|$)(.*)   backend:3000 (10.244.0.x:3000,10.244.0.x:3000,10.244.0.x:3000)
              /()(.*)         frontend:80 (10.244.0.x:80,10.244.0.x:80,10.244.0.x:80)
Annotations:
  nginx.ingress.kubernetes.io/rewrite-target: /$2
  nginx.ingress.kubernetes.io/use-regex: true
```

## Fase 7: HPA

```
$ kubectl get hpa -n todo-app
NAME          REFERENCE            TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
backend-hpa   Deployment/backend   10%/70%   2         10        3          10s
```

### Describe HPA

```
$ kubectl describe hpa backend-hpa -n todo-app
Name:                     backend-hpa
Namespace:                todo-app
Reference:                Deployment/backend
Metrics:                  ( current / target )
  resource cpu:           10% / 70%
Min replicas:             2
Max replicas:             10
Deployment pods:          3 current / 3 desired
```

## Verificación Final

### Todos los recursos

```
$ kubectl get all -n todo-app
NAME                            READY   STATUS    RESTARTS   AGE
pod/backend-5d9f8b7c4d-abc12    1/1     Running   0          5m
pod/backend-5d9f8b7c4d-def34    1/1     Running   0          5m
pod/backend-5d9f8b7c4d-ghi56    1/1     Running   0          5m
pod/frontend-7b8c9d0e1f-jkl78   1/1     Running   0          4m
pod/frontend-7b8c9d0e1f-mno90   1/1     Running   0          4m
pod/frontend-7b8c9d0e1f-pqr12   1/1     Running   0          4m
pod/postgres-0                  1/1     Running   0          6m

NAME               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/backend    ClusterIP   10.96.100.100    <none>        3000/TCP   5m
service/frontend   ClusterIP   10.96.100.101    <none>        80/TCP     4m
service/postgres   ClusterIP   None             <none>        5432/TCP   6m

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/backend    3/3     3            3           5m
deployment.apps/frontend   3/3     3            3           4m

NAME                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/backend-5d9f8b7c4d    3         3         3       5m
replicaset.apps/frontend-7b8c9d0e1f   3         3         3       4m

NAME                        READY   AGE
statefulset.apps/postgres   1/1     6m
```

## Pruebas de la Aplicación

### API - Crear tarea

```
$ curl -X POST http://todo.local/api/todos \
  -H "Content-Type: application/json" \
  -d '{"title": "Mi primera tarea"}'

{
  "id": 1,
  "title": "Mi primera tarea",
  "completed": false,
  "created_at": "2024-01-15T10:35:00.000Z"
}
```

### API - Listar tareas

```
$ curl http://todo.local/api/todos

[
  {
    "id": 1,
    "title": "Mi primera tarea",
    "completed": false,
    "created_at": "2024-01-15T10:35:00.000Z"
  }
]
```

### API - Actualizar tarea

```
$ curl -X PUT http://todo.local/api/todos/1 \
  -H "Content-Type: application/json" \
  -d '{"completed": true}'

{
  "id": 1,
  "title": "Mi primera tarea",
  "completed": true,
  "created_at": "2024-01-15T10:35:00.000Z"
}
```

### Frontend

Al abrir `http://todo.local` en el navegador, deberías ver:

- Encabezado con título "Lista de Tareas"
- Formulario para agregar nuevas tareas
- Lista de tareas existentes
- Checkboxes para marcar como completadas
- Botones para eliminar tareas

## Prueba de Persistencia

```bash
# Eliminar el pod de PostgreSQL
$ kubectl delete pod postgres-0 -n todo-app

# Esperar a que se recree
$ kubectl wait --for=condition=ready pod -l app=postgres -n todo-app --timeout=60s

# Verificar que los datos persisten
$ curl http://todo.local/api/todos
[
  {
    "id": 1,
    "title": "Mi primera tarea",
    "completed": true,
    "created_at": "2024-01-15T10:35:00.000Z"
  }
]
```

## Prueba de Escalamiento

```bash
# Ver réplicas actuales
$ kubectl get deployment backend -n todo-app
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
backend   3/3     3            3           10m

# El HPA ajustará automáticamente las réplicas según la carga
$ kubectl get hpa backend-hpa -n todo-app -w
NAME          REFERENCE            TARGETS   MINPODS   MAXPODS   REPLICAS
backend-hpa   Deployment/backend   10%/70%   2         10        3
```
