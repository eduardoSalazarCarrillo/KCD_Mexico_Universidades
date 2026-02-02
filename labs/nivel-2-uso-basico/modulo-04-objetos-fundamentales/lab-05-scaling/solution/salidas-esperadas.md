# Lab 05: Scaling - Salidas Esperadas

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

## Paso 2: Crear un Deployment con 1 Réplica

### kubectl apply -f initial/deployment-scaling.yaml

```
$ kubectl apply -f initial/deployment-scaling.yaml
deployment.apps/web-app created
```

### kubectl get deployment web-app

```
$ kubectl get deployment web-app
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
web-app   1/1     1            1           30s
```

**Explicación de columnas**:

| Columna      | Descripción                          |
| ------------ | ------------------------------------ |
| `NAME`       | Nombre del deployment                |
| `READY`      | Réplicas listas / Réplicas deseadas  |
| `UP-TO-DATE` | Réplicas con la configuración actual |
| `AVAILABLE`  | Réplicas disponibles para servir     |
| `AGE`        | Tiempo desde la creación             |

### kubectl get pods -l app=web-app

```
$ kubectl get pods -l app=web-app
NAME                       READY   STATUS    RESTARTS   AGE
web-app-5d9d7b8c6f-abc12   1/1     Running   0          45s
```

## Paso 3: Verificar el Número Actual de Réplicas

### kubectl get deployment web-app -o jsonpath='{.spec.replicas}'

```
$ kubectl get deployment web-app -o jsonpath='{.spec.replicas}'
1
```

### kubectl describe deployment web-app | grep Replicas

```
$ kubectl describe deployment web-app | grep -E "Replicas:"
Replicas:               1 desired | 1 updated | 1 total | 1 available | 0 unavailable
```

**Explicación de valores**:

| Valor         | Descripción                                    |
| ------------- | ---------------------------------------------- |
| `desired`     | Número de réplicas que queremos                |
| `updated`     | Réplicas con la configuración actual           |
| `total`       | Total de réplicas (incluyendo las que escalan) |
| `available`   | Réplicas listas para recibir tráfico           |
| `unavailable` | Réplicas no disponibles                        |

## Paso 4: Escalar a 5 Réplicas con kubectl scale

### kubectl scale deployment web-app --replicas=5

```
$ kubectl scale deployment web-app --replicas=5
deployment.apps/web-app scaled
```

### kubectl get pods -l app=web-app -w (durante el escalamiento)

```
$ kubectl get pods -l app=web-app -w
NAME                       READY   STATUS              RESTARTS   AGE
web-app-5d9d7b8c6f-abc12   1/1     Running             0          2m
web-app-5d9d7b8c6f-def34   0/1     ContainerCreating   0          2s
web-app-5d9d7b8c6f-ghi56   0/1     ContainerCreating   0          2s
web-app-5d9d7b8c6f-jkl78   0/1     ContainerCreating   0          2s
web-app-5d9d7b8c6f-mno90   0/1     ContainerCreating   0          2s
web-app-5d9d7b8c6f-def34   1/1     Running             0          5s
web-app-5d9d7b8c6f-ghi56   1/1     Running             0          5s
web-app-5d9d7b8c6f-jkl78   1/1     Running             0          6s
web-app-5d9d7b8c6f-mno90   1/1     Running             0          6s
```

> **Nota**: El estado `ContainerCreating` indica que Kubernetes está descargando la imagen y creando el contenedor.

### kubectl get deployment web-app (después del escalamiento)

```
$ kubectl get deployment web-app
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
web-app   5/5     5            5           3m
```

## Paso 5: Verificar Distribución de Pods

### kubectl get pods -l app=web-app -o wide

```
$ kubectl get pods -l app=web-app -o wide
NAME                       READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
web-app-5d9d7b8c6f-abc12   1/1     Running   0          4m    10.244.0.5   minikube   <none>           <none>
web-app-5d9d7b8c6f-def34   1/1     Running   0          2m    10.244.0.6   minikube   <none>           <none>
web-app-5d9d7b8c6f-ghi56   1/1     Running   0          2m    10.244.0.7   minikube   <none>           <none>
web-app-5d9d7b8c6f-jkl78   1/1     Running   0          2m    10.244.0.8   minikube   <none>           <none>
web-app-5d9d7b8c6f-mno90   1/1     Running   0          2m    10.244.0.9   minikube   <none>           <none>
```

**Explicación de columnas adicionales**:

| Columna           | Descripción                                |
| ----------------- | ------------------------------------------ |
| `IP`              | Dirección IP interna del pod               |
| `NODE`            | Nodo donde se ejecuta el pod               |
| `NOMINATED NODE`  | Nodo preferido para scheduling (si aplica) |
| `READINESS GATES` | Condiciones adicionales de disponibilidad  |

## Paso 6: Reducir a 2 Réplicas

### kubectl scale deployment web-app --replicas=2

```
$ kubectl scale deployment web-app --replicas=2
deployment.apps/web-app scaled
```

### kubectl get pods -l app=web-app -w (durante el scale down)

```
$ kubectl get pods -l app=web-app -w
NAME                       READY   STATUS        RESTARTS   AGE
web-app-5d9d7b8c6f-abc12   1/1     Running       0          5m
web-app-5d9d7b8c6f-def34   1/1     Running       0          3m
web-app-5d9d7b8c6f-ghi56   1/1     Terminating   0          3m
web-app-5d9d7b8c6f-jkl78   1/1     Terminating   0          3m
web-app-5d9d7b8c6f-mno90   1/1     Terminating   0          3m
web-app-5d9d7b8c6f-ghi56   0/1     Terminating   0          3m
web-app-5d9d7b8c6f-jkl78   0/1     Terminating   0          3m
web-app-5d9d7b8c6f-mno90   0/1     Terminating   0          3m
```

> **Nota**: El estado `Terminating` indica que Kubernetes está deteniendo el pod de forma graceful.

### kubectl get deployment web-app (después del scale down)

```
$ kubectl get deployment web-app
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
web-app   2/2     2            2           6m
```

## Paso 7: Escalar Usando kubectl patch

### kubectl patch deployment web-app -p '{"spec":{"replicas":4}}'

```
$ kubectl patch deployment web-app -p '{"spec":{"replicas":4}}'
deployment.apps/web-app patched
```

### kubectl get deployment web-app

```
$ kubectl get deployment web-app
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
web-app   4/4     4            4           7m
```

## Paso 8: Escalar Modificando el YAML

### kubectl apply -f initial/deployment-scaled.yaml

```
$ kubectl apply -f initial/deployment-scaled.yaml
deployment.apps/web-app configured
```

> **Nota**: El mensaje dice `configured` (no `created`) porque el deployment ya existía y fue actualizado.

### kubectl get deployment web-app

```
$ kubectl get deployment web-app
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
web-app   6/6     6            6           8m
```

## Paso 9: Escalar a 0 Réplicas

### kubectl scale deployment web-app --replicas=0

```
$ kubectl scale deployment web-app --replicas=0
deployment.apps/web-app scaled
```

### kubectl get deployment web-app

```
$ kubectl get deployment web-app
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
web-app   0/0     0            0           9m
```

### kubectl get pods -l app=web-app

```
$ kubectl get pods -l app=web-app
No resources found in default namespace.
```

### kubectl get deployment,replicaset -l app=web-app

```
$ kubectl get deployment,replicaset -l app=web-app
NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web-app   0/0     0            0           9m

NAME                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/web-app-5d9d7b8c6f   0         0         0       9m
```

> **Importante**: El Deployment y ReplicaSet siguen existiendo, solo no tienen pods corriendo.

## Paso 10: Restaurar las Réplicas

### kubectl scale deployment web-app --replicas=3

```
$ kubectl scale deployment web-app --replicas=3
deployment.apps/web-app scaled
```

### kubectl get pods -l app=web-app

```
$ kubectl get pods -l app=web-app
NAME                       READY   STATUS    RESTARTS   AGE
web-app-5d9d7b8c6f-new01   1/1     Running   0          30s
web-app-5d9d7b8c6f-new02   1/1     Running   0          30s
web-app-5d9d7b8c6f-new03   1/1     Running   0          30s
```

## Paso 11: Ver el Historial de Eventos

### kubectl describe deployment web-app | grep -A 20 "Events:"

```
$ kubectl describe deployment web-app | grep -A 20 "Events:"
Events:
  Type    Reason             Age    From                   Message
  ----    ------             ----   ----                   -------
  Normal  ScalingReplicaSet  10m    deployment-controller  Scaled up replica set web-app-5d9d7b8c6f to 1
  Normal  ScalingReplicaSet  8m     deployment-controller  Scaled up replica set web-app-5d9d7b8c6f to 5
  Normal  ScalingReplicaSet  5m     deployment-controller  Scaled down replica set web-app-5d9d7b8c6f to 2
  Normal  ScalingReplicaSet  4m     deployment-controller  Scaled up replica set web-app-5d9d7b8c6f to 4
  Normal  ScalingReplicaSet  3m     deployment-controller  Scaled up replica set web-app-5d9d7b8c6f to 6
  Normal  ScalingReplicaSet  2m     deployment-controller  Scaled down replica set web-app-5d9d7b8c6f to 0
  Normal  ScalingReplicaSet  1m     deployment-controller  Scaled up replica set web-app-5d9d7b8c6f to 3
```

**Explicación de campos de eventos**:

| Campo     | Descripción                        |
| --------- | ---------------------------------- |
| `Type`    | Tipo de evento (Normal o Warning)  |
| `Reason`  | Razón del evento                   |
| `Age`     | Tiempo desde que ocurrió el evento |
| `From`    | Componente que generó el evento    |
| `Message` | Descripción detallada del evento   |

## Paso 12: Limpiar los Recursos

### kubectl delete deployment web-app

```
$ kubectl delete deployment web-app
deployment.apps "web-app" deleted
```

### kubectl get all -l app=web-app

```
$ kubectl get all -l app=web-app
No resources found in default namespace.
```

## Ejercicios Adicionales

### Ejercicio 1: Escalamiento Condicional

```
$ kubectl scale deployment test-app --current-replicas=2 --replicas=4
deployment.apps/test-app scaled

$ kubectl scale deployment test-app --current-replicas=2 --replicas=6
error: Expected replicas to be 2, was 4
```

> **Nota**: El segundo comando falla porque `--current-replicas=2` no coincide con el número actual de réplicas (4).

### Ejercicio 2: Escalar Múltiples Deployments

```
$ kubectl get deployments -l tier=frontend
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
app-a   1/1     1            1           30s
app-b   1/1     1            1           30s

$ # Después de escalar con el loop
$ kubectl get deployments -l tier=frontend
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
app-a   3/3     3            3           1m
app-b   3/3     3            3           1m
```

## Resumen

Si todas tus salidas son similares a las mostradas en este documento, has completado exitosamente el Lab 05.

Las diferencias menores que puedes esperar:

- **Nombres de pods**: Los sufijos aleatorios (como `-abc12`) serán diferentes
- **IPs de pods**: Las IPs internas variarán según tu clúster
- **Timestamps y AGE**: Dependen de cuándo ejecutaste los comandos
- **Orden de terminación**: Al reducir réplicas, el orden puede variar

### Comandos de Escalamiento Aprendidos

| Método | Comando                                       | Uso Recomendado                         |
| ------ | --------------------------------------------- | --------------------------------------- |
| Scale  | `kubectl scale deployment <n> --replicas=<N>` | Cambios rápidos, pruebas                |
| Patch  | `kubectl patch deployment <n> -p '{...}'`     | Automatización, scripts                 |
| Apply  | `kubectl apply -f <archivo.yaml>`             | Producción, infraestructura como código |
| Edit   | `kubectl edit deployment <nombre>`            | Cambios puntuales interactivos          |
