# Lab 14: Rolling Updates y Rollbacks - Salidas Esperadas

Este documento muestra las salidas esperadas de cada comando del laboratorio para que puedas verificar que todo funciona correctamente.

## Paso 1: Crear Deployment inicial

### kubectl apply -f initial/app-rolling.yaml

```
$ kubectl apply -f initial/app-rolling.yaml
deployment.apps/web-app created
```

### kubectl rollout status deployment/web-app

```
$ kubectl rollout status deployment/web-app
Waiting for deployment "web-app" rollout to finish: 0 of 4 updated replicas are available...
Waiting for deployment "web-app" rollout to finish: 1 of 4 updated replicas are available...
Waiting for deployment "web-app" rollout to finish: 2 of 4 updated replicas are available...
Waiting for deployment "web-app" rollout to finish: 3 of 4 updated replicas are available...
deployment "web-app" successfully rolled out
```

### kubectl get deployment web-app

```
$ kubectl get deployment web-app
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
web-app   4/4     4            4           30s
```

### kubectl get pods -l app=web

```
$ kubectl get pods -l app=web
NAME                       READY   STATUS    RESTARTS   AGE
web-app-5d8f9c7b4d-abc12   1/1     Running   0          30s
web-app-5d8f9c7b4d-def34   1/1     Running   0          30s
web-app-5d8f9c7b4d-ghi56   1/1     Running   0          30s
web-app-5d8f9c7b4d-jkl78   1/1     Running   0          30s
```

## Paso 2: Realizar rolling update

### kubectl set image deployment/web-app nginx=nginx:1.21-alpine

```
$ kubectl set image deployment/web-app nginx=nginx:1.21-alpine
deployment.apps/web-app image updated
```

### kubectl annotate deployment web-app kubernetes.io/change-cause="Update to nginx 1.21" --overwrite

```
$ kubectl annotate deployment web-app kubernetes.io/change-cause="Update to nginx 1.21" --overwrite
deployment.apps/web-app annotated
```

### kubectl rollout status deployment web-app

```
$ kubectl rollout status deployment web-app
Waiting for deployment "web-app" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "web-app" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "web-app" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "web-app" rollout to finish: 4 out of 4 new replicas have been updated...
Waiting for deployment "web-app" rollout to finish: 3 of 4 updated replicas are available...
deployment "web-app" successfully rolled out
```

### kubectl get pods -l app=web (durante la actualización)

```
$ kubectl get pods -l app=web -w
NAME                       READY   STATUS    RESTARTS   AGE
web-app-5d8f9c7b4d-abc12   1/1     Running   0          2m
web-app-5d8f9c7b4d-def34   1/1     Running   0          2m
web-app-5d8f9c7b4d-ghi56   1/1     Running   0          2m
web-app-5d8f9c7b4d-jkl78   1/1     Running   0          2m
web-app-6f7a8b9c5e-mno90   0/1     Pending   0          0s
web-app-6f7a8b9c5e-mno90   0/1     ContainerCreating   0   0s
web-app-6f7a8b9c5e-mno90   1/1     Running             0   5s
web-app-5d8f9c7b4d-abc12   1/1     Terminating         0   2m5s
...
```

> **Nota**: El rolling update reemplaza pods gradualmente. Con maxSurge=1 y maxUnavailable=1, siempre hay al menos 3 pods disponibles.

### kubectl describe deployment web-app | grep -i image

```
$ kubectl describe deployment web-app | grep -i image
    Image:        nginx:1.21-alpine
```

## Paso 3: Verificar el historial

### kubectl rollout history deployment web-app

```
$ kubectl rollout history deployment web-app
deployment.apps/web-app
REVISION  CHANGE-CAUSE
1         Initial deployment v1
2         Update to nginx 1.21
```

### kubectl rollout history deployment web-app --revision=1

```
$ kubectl rollout history deployment web-app --revision=1
deployment.apps/web-app with revision #1
Pod Template:
  Labels:       app=web
        pod-template-hash=5d8f9c7b4d
        version=v1
  Annotations:  kubernetes.io/change-cause: Initial deployment v1
  Containers:
   nginx:
    Image:      nginx:1.20-alpine
    Port:       80/TCP
    Host Port:  0/TCP
    Limits:
      cpu:     200m
      memory:  128Mi
    Requests:
      cpu:        100m
      memory:     64Mi
    Readiness:  http-get http://:80/ delay=5s timeout=1s period=5s #success=1 #failure=3
    Environment:        <none>
    Mounts:     <none>
  Volumes:      <none>
```

### kubectl rollout history deployment web-app --revision=2

```
$ kubectl rollout history deployment web-app --revision=2
deployment.apps/web-app with revision #2
Pod Template:
  Labels:       app=web
        pod-template-hash=6f7a8b9c5e
        version=v1
  Annotations:  kubernetes.io/change-cause: Update to nginx 1.21
  Containers:
   nginx:
    Image:      nginx:1.21-alpine
    Port:       80/TCP
    Host Port:  0/TCP
    Limits:
      cpu:     200m
      memory:  128Mi
    Requests:
      cpu:        100m
      memory:     64Mi
    Readiness:  http-get http://:80/ delay=5s timeout=1s period=5s #success=1 #failure=3
    Environment:        <none>
    Mounts:     <none>
  Volumes:      <none>
```

## Paso 4: Simular un deployment fallido

### kubectl set image deployment/web-app nginx=nginx:invalid-version

```
$ kubectl set image deployment/web-app nginx=nginx:invalid-version
deployment.apps/web-app image updated
```

### kubectl rollout status deployment web-app --timeout=30s

```
$ kubectl rollout status deployment web-app --timeout=30s
Waiting for deployment "web-app" rollout to finish: 1 out of 4 new replicas have been updated...
error: timed out waiting for rollout to finish
```

### kubectl get pods -l app=web

```
$ kubectl get pods -l app=web
NAME                       READY   STATUS             RESTARTS   AGE
web-app-6f7a8b9c5e-mno90   1/1     Running            0          3m
web-app-6f7a8b9c5e-pqr12   1/1     Running            0          3m
web-app-6f7a8b9c5e-stu34   1/1     Running            0          3m
web-app-8h9i0j1k2l-vwx56   0/1     ImagePullBackOff   0          30s
```

> **Nota**: Los pods con la version anterior siguen corriendo mientras el nuevo pod falla. Esto es gracias a maxUnavailable=1 - siempre mantiene al menos 3 pods funcionando.

### kubectl describe deployment web-app | grep -A 5 "Replicas:"

```
$ kubectl describe deployment web-app | grep -A 5 "Replicas:"
Replicas:               4 desired | 1 updated | 5 total | 3 available | 2 unavailable
```

## Paso 5: Ejecutar rollback

### kubectl rollout undo deployment web-app

```
$ kubectl rollout undo deployment web-app
deployment.apps/web-app rolled back
```

### kubectl rollout status deployment web-app (después del rollback)

```
$ kubectl rollout status deployment web-app
Waiting for deployment "web-app" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "web-app" rollout to finish: 4 out of 4 new replicas have been updated...
deployment "web-app" successfully rolled out
```

### kubectl get pods -l app=web (después del rollback)

```
$ kubectl get pods -l app=web
NAME                       READY   STATUS    RESTARTS   AGE
web-app-6f7a8b9c5e-mno90   1/1     Running   0          5m
web-app-6f7a8b9c5e-pqr12   1/1     Running   0          5m
web-app-6f7a8b9c5e-stu34   1/1     Running   0          5m
web-app-6f7a8b9c5e-xyz99   1/1     Running   0          30s
```

### kubectl rollout undo deployment web-app --to-revision=1

```
$ kubectl rollout undo deployment web-app --to-revision=1
deployment.apps/web-app rolled back
```

### kubectl describe deployment web-app | grep -i image (después del rollback a rev 1)

```
$ kubectl describe deployment web-app | grep -i image
    Image:        nginx:1.20-alpine
```

## Paso 6: Pausar y reanudar rollouts

### kubectl rollout pause deployment web-app

```
$ kubectl rollout pause deployment web-app
deployment.apps/web-app paused
```

### kubectl get pods -l app=web (mientras está pausado)

```
$ kubectl get pods -l app=web
NAME                       READY   STATUS    RESTARTS   AGE
web-app-5d8f9c7b4d-abc12   1/1     Running   0          1m
web-app-5d8f9c7b4d-def34   1/1     Running   0          1m
web-app-5d8f9c7b4d-ghi56   1/1     Running   0          1m
web-app-5d8f9c7b4d-jkl78   1/1     Running   0          1m
```

### kubectl get deployment web-app (mientras está pausado, después de cambios)

```
$ kubectl get deployment web-app
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
web-app   4/4     0            4           8m
```

> **Nota**: `UP-TO-DATE` es 0 porque los cambios están pendientes mientras el deployment está pausado.

### kubectl rollout resume deployment web-app

```
$ kubectl rollout resume deployment web-app
deployment.apps/web-app resumed
```

### kubectl rollout status deployment web-app (después de resume)

```
$ kubectl rollout status deployment web-app
Waiting for deployment "web-app" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "web-app" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "web-app" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "web-app" rollout to finish: 4 out of 4 new replicas have been updated...
deployment "web-app" successfully rolled out
```

## Paso 7: Estrategia Recreate (comparación)

### kubectl apply -f initial/app-recreate.yaml

```
$ kubectl apply -f initial/app-recreate.yaml
deployment.apps/web-app-recreate created
```

### kubectl get pods -l app=web-recreate

```
$ kubectl get pods -l app=web-recreate
NAME                                READY   STATUS    RESTARTS   AGE
web-app-recreate-7f8b6c8d7e-abc12   1/1     Running   0          30s
web-app-recreate-7f8b6c8d7e-def34   1/1     Running   0          30s
web-app-recreate-7f8b6c8d7e-ghi56   1/1     Running   0          30s
```

### kubectl set image deployment/web-app-recreate nginx=nginx:1.21-alpine

```
$ kubectl set image deployment/web-app-recreate nginx=nginx:1.21-alpine
deployment.apps/web-app-recreate image updated
```

### kubectl get pods -l app=web-recreate -w (durante actualización con Recreate)

```
$ kubectl get pods -l app=web-recreate -w
NAME                                READY   STATUS        RESTARTS   AGE
web-app-recreate-7f8b6c8d7e-abc12   1/1     Terminating   0          1m
web-app-recreate-7f8b6c8d7e-def34   1/1     Terminating   0          1m
web-app-recreate-7f8b6c8d7e-ghi56   1/1     Terminating   0          1m
web-app-recreate-7f8b6c8d7e-abc12   0/1     Terminating   0          1m5s
web-app-recreate-7f8b6c8d7e-def34   0/1     Terminating   0          1m5s
web-app-recreate-7f8b6c8d7e-ghi56   0/1     Terminating   0          1m5s
web-app-recreate-8g9h0i1j2k-jkl78   0/1     Pending       0          0s
web-app-recreate-8g9h0i1j2k-mno90   0/1     Pending       0          0s
web-app-recreate-8g9h0i1j2k-pqr12   0/1     Pending       0          0s
web-app-recreate-8g9h0i1j2k-jkl78   0/1     ContainerCreating   0   0s
web-app-recreate-8g9h0i1j2k-mno90   0/1     ContainerCreating   0   0s
web-app-recreate-8g9h0i1j2k-pqr12   0/1     ContainerCreating   0   0s
web-app-recreate-8g9h0i1j2k-jkl78   1/1     Running             0   5s
web-app-recreate-8g9h0i1j2k-mno90   1/1     Running             0   5s
web-app-recreate-8g9h0i1j2k-pqr12   1/1     Running             0   5s
```

> **IMPORTANTE**: Con estrategia Recreate, TODOS los pods se terminan ANTES de crear los nuevos. Esto significa que hay un periodo de downtime donde ningún pod está disponible.

## Limpieza

### kubectl delete deployment web-app

```
$ kubectl delete deployment web-app
deployment.apps "web-app" deleted
```

### kubectl delete deployment web-app-recreate

```
$ kubectl delete deployment web-app-recreate
deployment.apps "web-app-recreate" deleted
```

### kubectl get deployments

```
$ kubectl get deployments
No resources found in default namespace.
```

## Resumen de Salidas

Si todas tus salidas son similares a las mostradas en este documento, has completado exitosamente el Lab 14.

Las diferencias menores que puedes esperar:

- **Nombres de pods**: Los sufijos aleatorios serán diferentes
- **Tiempos**: Los tiempos de AGE y espera variarán
- **Números de revisión**: Dependen de cuántas actualizaciones hayas hecho

### Mensajes Importantes a Observar

| Mensaje                                        | Significado                                       |
| ---------------------------------------------- | ------------------------------------------------- |
| `deployment.apps/web-app image updated`        | Imagen actualizada exitosamente                   |
| `deployment.apps/web-app annotated`            | Anotación change-cause agregada                   |
| `deployment "web-app" successfully rolled out` | Rolling update completado                         |
| `deployment.apps/web-app rolled back`          | Rollback ejecutado                                |
| `deployment.apps/web-app paused`               | Deployment pausado                                |
| `deployment.apps/web-app resumed`              | Deployment reanudado                              |
| `error: timed out waiting for rollout`         | El rollout no completó (esperado con bad image)   |
| `ImagePullBackOff`                             | No se puede descargar la imagen (imagen inválida) |

### Comparación de Estrategias

| Característica      | RollingUpdate                        | Recreate                          |
| ------------------- | ------------------------------------ | --------------------------------- |
| **Downtime**        | No (cero downtime)                   | Sí (durante la transición)        |
| **Velocidad**       | Más lento (gradual)                  | Más rápido (todo de una vez)      |
| **Uso de recursos** | Usa más recursos temporalmente       | Usa menos recursos                |
| **Rollback**        | Más seguro (pods viejos disponibles) | Más arriesgado                    |
| **Caso de uso**     | Producción, alta disponibilidad      | Desarrollo, cambios incompatibles |
