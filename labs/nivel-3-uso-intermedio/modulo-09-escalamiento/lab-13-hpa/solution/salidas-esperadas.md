# Lab 13: Horizontal Pod Autoscaler (HPA) - Salidas Esperadas

Este documento muestra las salidas esperadas de cada comando del laboratorio para que puedas verificar que todo funciona correctamente.

## Paso 1: Habilitar Metrics Server

### minikube addons enable metrics-server

```
$ minikube addons enable metrics-server
💡  metrics-server is an addon maintained by Kubernetes. For any concerns contact minikube on GitHub.
You can view the list of minikube maintainers at: https://github.com/kubernetes/minikube/blob/master/OWNERS
    ▪ Using image registry.k8s.io/metrics-server/metrics-server:v0.6.4
🌟  The 'metrics-server' addon is enabled
```

### kubectl get pods -n kube-system | grep metrics-server

```
$ kubectl get pods -n kube-system | grep metrics-server
metrics-server-7746886d4f-abc12   1/1     Running   0          2m
```

### kubectl top nodes

```
$ kubectl top nodes
NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
minikube   250m         12%    1024Mi          27%
```

**Explicación de columnas**:

| Columna         | Descripción                          |
| --------------- | ------------------------------------ |
| `NAME`          | Nombre del nodo                      |
| `CPU(cores)`    | CPU usado en milicores               |
| `CPU%`          | Porcentaje del CPU total usado       |
| `MEMORY(bytes)` | Memoria usada en bytes               |
| `MEMORY%`       | Porcentaje de la memoria total usada |

### kubectl top pods

```
$ kubectl top pods
NAME                          CPU(cores)   MEMORY(bytes)
php-apache-5d9d7b8c6f-abc12   1m           10Mi
```

> **Nota**: Si ves `error: Metrics API not available`, espera 1-2 minutos a que Metrics Server termine de iniciar.

## Paso 2: Crear Deployment con Resource Requests

### kubectl apply -f initial/app-hpa.yaml

```
$ kubectl apply -f initial/app-hpa.yaml
deployment.apps/php-apache created
service/php-apache created
```

### kubectl get deployment php-apache

```
$ kubectl get deployment php-apache
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
php-apache   1/1     1            1           30s
```

### kubectl get pods -l app=php-apache

```
$ kubectl get pods -l app=php-apache
NAME                          READY   STATUS    RESTARTS   AGE
php-apache-5d9d7b8c6f-abc12   1/1     Running   0          45s
```

### kubectl get service php-apache

```
$ kubectl get service php-apache
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
php-apache   ClusterIP   10.96.123.456   <none>        80/TCP    1m
```

## Paso 3: Crear HPA con kubectl

### kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10

```
$ kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10
horizontalpodautoscaler.autoscaling/php-apache autoscaled
```

### kubectl get hpa

```
$ kubectl get hpa
NAME         REFERENCE               TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
php-apache   Deployment/php-apache   <unknown>/50%   1         10        1          30s
```

> **Nota**: `<unknown>` aparece inicialmente mientras Metrics Server recolecta datos. Después de unos segundos, mostrará el porcentaje real de CPU.

### kubectl get hpa (después de unos minutos)

```
$ kubectl get hpa
NAME         REFERENCE               TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
php-apache   Deployment/php-apache   0%/50%    1         10        1          2m
```

**Explicación de columnas**:

| Columna     | Descripción                                                  |
| ----------- | ------------------------------------------------------------ |
| `NAME`      | Nombre del HPA                                               |
| `REFERENCE` | Recurso que el HPA controla                                  |
| `TARGETS`   | Uso actual / objetivo (ej: 0%/50% = 0% actual, 50% objetivo) |
| `MINPODS`   | Número mínimo de réplicas                                    |
| `MAXPODS`   | Número máximo de réplicas                                    |
| `REPLICAS`  | Número actual de réplicas                                    |
| `AGE`       | Tiempo desde la creación                                     |

### kubectl describe hpa php-apache

```
$ kubectl describe hpa php-apache
Name:                                                  php-apache
Namespace:                                             default
Labels:                                                <none>
Annotations:                                           <none>
CreationTimestamp:                                     Mon, 15 Jan 2024 10:00:00 -0600
Reference:                                             Deployment/php-apache
Metrics:                                               ( current / target )
  resource cpu on pods  (as a percentage of request):  0% (1m) / 50%
Min replicas:                                          1
Max replicas:                                          10
Deployment pods:                                       1 current / 1 desired
Conditions:
  Type            Status  Reason              Message
  ----            ------  ------              -------
  AbleToScale     True    ReadyForNewScale    recommended size matches current size
  ScalingActive   True    ValidMetricFound    the HPA was able to successfully calculate a replica count from cpu resource utilization (percentage of request)
  ScalingLimited  False   DesiredWithinRange  the desired count is within the acceptable range
Events:           <none>
```

## Paso 4: Crear HPA con YAML

### kubectl delete hpa php-apache

```
$ kubectl delete hpa php-apache
horizontalpodautoscaler.autoscaling "php-apache" deleted
```

### kubectl apply -f initial/hpa.yaml

```
$ kubectl apply -f initial/hpa.yaml
horizontalpodautoscaler.autoscaling/php-apache-hpa created
```

### kubectl get hpa php-apache-hpa

```
$ kubectl get hpa php-apache-hpa
NAME             REFERENCE               TARGETS                        MINPODS   MAXPODS   REPLICAS   AGE
php-apache-hpa   Deployment/php-apache   <unknown>/70%, <unknown>/50%   2         10        1          30s
```

> **Nota**: Cuando se definen múltiples métricas (CPU y memoria), TARGETS muestra ambas.

### kubectl describe hpa php-apache-hpa

```
$ kubectl describe hpa php-apache-hpa
Name:                                                  php-apache-hpa
Namespace:                                             default
Labels:                                                app=php-apache
Annotations:                                           <none>
CreationTimestamp:                                     Mon, 15 Jan 2024 10:05:00 -0600
Reference:                                             Deployment/php-apache
Metrics:                                               ( current / target )
  resource memory on pods (as a percentage of request):  15% (10Mi) / 70%
  resource cpu on pods  (as a percentage of request):    0% (1m) / 50%
Min replicas:                                          2
Max replicas:                                          10
Behavior:
  Scale Up:
    Stabilization Window: 0 seconds
    Select Policy: Max
    Policies:
      - Type: Percent  Value: 100  Period: 15 seconds
      - Type: Pods     Value: 4    Period: 15 seconds
  Scale Down:
    Stabilization Window: 60 seconds
    Select Policy: Max
    Policies:
      - Type: Percent  Value: 50  Period: 30 seconds
Deployment pods:                                       2 current / 2 desired
Conditions:
  Type            Status  Reason              Message
  ----            ------  ------              -------
  AbleToScale     True    ReadyForNewScale    recommended size matches current size
  ScalingActive   True    ValidMetricFound    the HPA was able to successfully calculate a replica count
  ScalingLimited  False   DesiredWithinRange  the desired count is within the acceptable range
Events:
  Type    Reason             Age   From                       Message
  ----    ------             ----  ----                       -------
  Normal  SuccessfulRescale  30s   horizontal-pod-autoscaler  New size: 2; reason: Current number of replicas below Spec.MinReplicas
```

## Paso 5: Generar Carga

### Estado inicial antes de la carga

```
$ kubectl get hpa php-apache-hpa
NAME             REFERENCE               TARGETS          MINPODS   MAXPODS   REPLICAS   AGE
php-apache-hpa   Deployment/php-apache   15%/70%, 0%/50%   2         10        2          5m

$ kubectl get pods -l app=php-apache
NAME                          READY   STATUS    RESTARTS   AGE
php-apache-5d9d7b8c6f-abc12   1/1     Running   0          10m
php-apache-5d9d7b8c6f-def34   1/1     Running   0          5m
```

### Iniciar generador de carga

```
$ kubectl run -i --tty load-generator --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"
If you don't see a command prompt, try pressing enter.
OK!OK!OK!OK!OK!OK!OK!...
```

### Observar el escalamiento (en otra terminal)

```
$ kubectl get hpa php-apache-hpa -w
NAME             REFERENCE               TARGETS           MINPODS   MAXPODS   REPLICAS   AGE
php-apache-hpa   Deployment/php-apache   15%/70%, 0%/50%   2         10        2          6m
php-apache-hpa   Deployment/php-apache   15%/70%, 45%/50%  2         10        2          6m30s
php-apache-hpa   Deployment/php-apache   15%/70%, 85%/50%  2         10        2          7m
php-apache-hpa   Deployment/php-apache   15%/70%, 120%/50% 2         10        4          7m30s
php-apache-hpa   Deployment/php-apache   15%/70%, 95%/50%  2         10        4          8m
php-apache-hpa   Deployment/php-apache   15%/70%, 65%/50%  2         10        6          8m30s
php-apache-hpa   Deployment/php-apache   15%/70%, 55%/50%  2         10        6          9m
php-apache-hpa   Deployment/php-apache   15%/70%, 45%/50%  2         10        7          9m30s
```

### kubectl get pods -l app=php-apache (durante la carga)

```
$ kubectl get pods -l app=php-apache
NAME                          READY   STATUS    RESTARTS   AGE
php-apache-5d9d7b8c6f-abc12   1/1     Running   0          15m
php-apache-5d9d7b8c6f-def34   1/1     Running   0          10m
php-apache-5d9d7b8c6f-ghi56   1/1     Running   0          2m
php-apache-5d9d7b8c6f-jkl78   1/1     Running   0          2m
php-apache-5d9d7b8c6f-mno90   1/1     Running   0          1m
php-apache-5d9d7b8c6f-pqr12   1/1     Running   0          1m
php-apache-5d9d7b8c6f-stu34   1/1     Running   0          30s
```

### kubectl top pods -l app=php-apache (durante la carga)

```
$ kubectl top pods -l app=php-apache
NAME                          CPU(cores)   MEMORY(bytes)
php-apache-5d9d7b8c6f-abc12   245m         12Mi
php-apache-5d9d7b8c6f-def34   198m         11Mi
php-apache-5d9d7b8c6f-ghi56   187m         10Mi
php-apache-5d9d7b8c6f-jkl78   201m         11Mi
php-apache-5d9d7b8c6f-mno90   156m         10Mi
php-apache-5d9d7b8c6f-pqr12   142m         10Mi
php-apache-5d9d7b8c6f-stu34   98m          9Mi
```

## Paso 7: Detener Carga y Observar Scale-Down

### Después de detener el generador de carga (Ctrl+C)

```
$ kubectl get hpa php-apache-hpa -w
NAME             REFERENCE               TARGETS          MINPODS   MAXPODS   REPLICAS   AGE
php-apache-hpa   Deployment/php-apache   15%/70%, 45%/50%  2         10        7          15m
php-apache-hpa   Deployment/php-apache   15%/70%, 25%/50%  2         10        7          15m30s
php-apache-hpa   Deployment/php-apache   15%/70%, 10%/50%  2         10        7          16m
php-apache-hpa   Deployment/php-apache   15%/70%, 5%/50%   2         10        7          16m30s
php-apache-hpa   Deployment/php-apache   15%/70%, 0%/50%   2         10        7          17m
php-apache-hpa   Deployment/php-apache   15%/70%, 0%/50%   2         10        5          18m
php-apache-hpa   Deployment/php-apache   15%/70%, 0%/50%   2         10        3          19m
php-apache-hpa   Deployment/php-apache   15%/70%, 0%/50%   2         10        2          20m
```

> **Nota**: El scale-down es gradual debido al `stabilizationWindowSeconds: 60` configurado. Esto previene fluctuaciones rápidas.

### kubectl describe hpa php-apache-hpa (eventos de escalamiento)

```
$ kubectl describe hpa php-apache-hpa | grep -A 15 "Events:"
Events:
  Type    Reason             Age    From                       Message
  ----    ------             ----   ----                       -------
  Normal  SuccessfulRescale  15m    horizontal-pod-autoscaler  New size: 2; reason: Current number of replicas below Spec.MinReplicas
  Normal  SuccessfulRescale  8m     horizontal-pod-autoscaler  New size: 4; reason: cpu resource utilization (percentage of request) above target
  Normal  SuccessfulRescale  7m30s  horizontal-pod-autoscaler  New size: 6; reason: cpu resource utilization (percentage of request) above target
  Normal  SuccessfulRescale  7m     horizontal-pod-autoscaler  New size: 7; reason: cpu resource utilization (percentage of request) above target
  Normal  SuccessfulRescale  3m     horizontal-pod-autoscaler  New size: 5; reason: All metrics below target
  Normal  SuccessfulRescale  2m     horizontal-pod-autoscaler  New size: 3; reason: All metrics below target
  Normal  SuccessfulRescale  1m     horizontal-pod-autoscaler  New size: 2; reason: All metrics below target
```

## Comandos Adicionales Útiles

### Ver HPA en formato YAML

```
$ kubectl get hpa php-apache-hpa -o yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache-hpa
  namespace: default
spec:
  maxReplicas: 10
  metrics:
  - resource:
      name: cpu
      target:
        averageUtilization: 50
        type: Utilization
    type: Resource
  - resource:
      name: memory
      target:
        averageUtilization: 70
        type: Utilization
    type: Resource
  minReplicas: 2
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
status:
  conditions:
  - lastTransitionTime: "2024-01-15T16:00:00Z"
    message: recommended size matches current size
    reason: ReadyForNewScale
    status: "True"
    type: AbleToScale
  currentMetrics:
  - resource:
      current:
        averageUtilization: 0
        averageValue: 1m
      name: cpu
    type: Resource
  - resource:
      current:
        averageUtilization: 15
        averageValue: 10Mi
      name: memory
    type: Resource
  currentReplicas: 2
  desiredReplicas: 2
```

### Modificar HPA con kubectl patch

```
$ kubectl patch hpa php-apache-hpa --patch '{"spec":{"maxReplicas":15}}'
horizontalpodautoscaler.autoscaling/php-apache-hpa patched

$ kubectl get hpa php-apache-hpa
NAME             REFERENCE               TARGETS          MINPODS   MAXPODS   REPLICAS   AGE
php-apache-hpa   Deployment/php-apache   15%/70%, 0%/50%   2         15        2          25m
```

## Limpieza

### kubectl delete hpa php-apache-hpa

```
$ kubectl delete hpa php-apache-hpa
horizontalpodautoscaler.autoscaling "php-apache-hpa" deleted
```

### kubectl delete -f initial/app-hpa.yaml

```
$ kubectl delete -f initial/app-hpa.yaml
deployment.apps "php-apache" deleted
service "php-apache" deleted
```

## Resumen

Si todas tus salidas son similares a las mostradas en este documento, has completado exitosamente el Lab 13.

Las diferencias menores que puedes esperar:

- **Nombres de pods**: Los sufijos aleatorios (como `-abc12`) serán diferentes
- **Valores de métricas**: Variarán según la carga real en tu sistema
- **Tiempos de escalamiento**: Dependen de la velocidad de respuesta de Metrics Server
- **Número de réplicas durante la carga**: Puede variar según la intensidad de la carga

### Conceptos Clave del HPA

| Concepto                     | Descripción                                   |
| ---------------------------- | --------------------------------------------- |
| `Metrics Server`             | Recolecta métricas de CPU/memoria de los pods |
| `Resource Requests`          | Requerido para que HPA calcule porcentajes    |
| `minReplicas/maxReplicas`    | Límites de escalamiento automático            |
| `averageUtilization`         | Porcentaje objetivo de uso de recursos        |
| `stabilizationWindowSeconds` | Tiempo de espera para evitar fluctuaciones    |
| `behavior`                   | Control detallado de scale-up y scale-down    |

### Fórmula de Escalamiento

El HPA calcula las réplicas deseadas usando:

```
desiredReplicas = ceil[currentReplicas * (currentMetricValue / desiredMetricValue)]
```

Por ejemplo:

- Réplicas actuales: 2
- CPU actual: 120%
- CPU objetivo: 50%
- Réplicas deseadas: ceil[2 * (120/50)] = ceil[4.8] = 5
