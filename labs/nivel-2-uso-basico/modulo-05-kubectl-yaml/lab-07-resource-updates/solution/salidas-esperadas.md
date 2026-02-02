# Lab 07: Resource Updates - Salidas Esperadas

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

## Paso 2: Desplegar la Aplicación Inicial (v1)

### kubectl apply -f initial/app-deployment-v1.yaml

```
$ kubectl apply -f initial/app-deployment-v1.yaml
deployment.apps/webapp created
```

### kubectl rollout status deployment/webapp

```
$ kubectl rollout status deployment/webapp
Waiting for deployment "webapp" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "webapp" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "webapp" rollout to finish: 2 of 3 updated replicas are available...
deployment "webapp" successfully rolled out
```

### kubectl get pods -l app=webapp -L version

```
$ kubectl get pods -l app=webapp -L version
NAME                      READY   STATUS    RESTARTS   AGE   VERSION
webapp-6d9c5f8d9d-abc12   1/1     Running   0          30s   v1
webapp-6d9c5f8d9d-def34   1/1     Running   0          30s   v1
webapp-6d9c5f8d9d-ghi56   1/1     Running   0          30s   v1
```

## Paso 3: Ver el Historial de Revisiones

### kubectl rollout history deployment/webapp

```
$ kubectl rollout history deployment/webapp
deployment.apps/webapp
REVISION  CHANGE-CAUSE
1         Despliegue inicial v1 - nginx:1.24-alpine
```

### kubectl rollout history deployment/webapp --revision=1

```
$ kubectl rollout history deployment/webapp --revision=1
deployment.apps/webapp with revision #1
Pod Template:
  Labels:       app=webapp
        pod-template-hash=6d9c5f8d9d
        version=v1
  Annotations:  kubernetes.io/change-cause: Despliegue inicial v1 - nginx:1.24-alpine
  Containers:
   nginx:
    Image:      nginx:1.24-alpine
    Port:       80/TCP
    Host Port:  0/TCP
    Limits:
      cpu:     200m
      memory:  128Mi
    Requests:
      cpu:        100m
      memory:     64Mi
    Readiness:  http-get http://:80/ delay=3s timeout=1s period=5s #success=1 #failure=3
    Environment:        <none>
    Mounts:     <none>
  Volumes:      <none>
```

## Paso 4: Actualizar la Imagen Usando kubectl set image

### kubectl set image deployment/webapp nginx=nginx:1.25-alpine

```
$ kubectl set image deployment/webapp nginx=nginx:1.25-alpine
deployment.apps/webapp image updated
```

### kubectl rollout status deployment/webapp

```
$ kubectl rollout status deployment/webapp
Waiting for deployment "webapp" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "webapp" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "webapp" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "webapp" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "webapp" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "webapp" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "webapp" rollout to finish: 1 old replicas are pending termination...
deployment "webapp" successfully rolled out
```

### kubectl describe deployment webapp | grep -i image

```
$ kubectl describe deployment webapp | grep -i image
    Image:        nginx:1.25-alpine
```

## Paso 5: Documentar el Cambio con change-cause

### kubectl annotate deployment/webapp kubernetes.io/change-cause="..." --overwrite

```
$ kubectl annotate deployment/webapp kubernetes.io/change-cause="Actualización a nginx:1.25-alpine para parches de seguridad" --overwrite
deployment.apps/webapp annotated
```

### kubectl rollout history deployment/webapp (después de anotar)

```
$ kubectl rollout history deployment/webapp
deployment.apps/webapp
REVISION  CHANGE-CAUSE
1         Despliegue inicial v1 - nginx:1.24-alpine
2         Actualización a nginx:1.25-alpine para parches de seguridad
```

## Paso 6: Actualizar Usando kubectl apply

### kubectl diff -f initial/app-deployment-v2.yaml (extracto)

```diff
$ kubectl diff -f initial/app-deployment-v2.yaml
diff -u -N /tmp/LIVE-123456/apps.v1.Deployment.default.webapp /tmp/MERGED-789012/apps.v1.Deployment.default.webapp
--- /tmp/LIVE-123456/apps.v1.Deployment.default.webapp
+++ /tmp/MERGED-789012/apps.v1.Deployment.default.webapp
@@ -6,8 +6,8 @@
   annotations:
-    kubernetes.io/change-cause: Actualización a nginx:1.25-alpine para parches de seguridad
+    kubernetes.io/change-cause: v2 - Aumentar recursos y réplicas
   labels:
     app: webapp
-    version: v1
+    version: v2
 spec:
-  replicas: 3
+  replicas: 4
   selector:
@@ -22,7 +22,7 @@
       labels:
         app: webapp
-        version: v1
+        version: v2
     spec:
       containers:
@@ -32,13 +32,13 @@
           resources:
             limits:
-              cpu: 200m
-              memory: 128Mi
+              cpu: 300m
+              memory: 256Mi
             requests:
-              cpu: 100m
-              memory: 64Mi
+              cpu: 150m
+              memory: 128Mi
```

### kubectl apply -f initial/app-deployment-v2.yaml

```
$ kubectl apply -f initial/app-deployment-v2.yaml
deployment.apps/webapp configured
```

> **Nota**: `configured` indica que el recurso fue actualizado, no creado.

### kubectl get pods -l app=webapp -L version (después de actualizar a v2)

```
$ kubectl get pods -l app=webapp -L version
NAME                      READY   STATUS    RESTARTS   AGE   VERSION
webapp-7f8b6c8d7e-abc12   1/1     Running   0          30s   v2
webapp-7f8b6c8d7e-def34   1/1     Running   0          30s   v2
webapp-7f8b6c8d7e-ghi56   1/1     Running   0          30s   v2
webapp-7f8b6c8d7e-jkl78   1/1     Running   0          30s   v2
```

## Paso 7: Ver el Historial Completo

### kubectl rollout history deployment/webapp

```
$ kubectl rollout history deployment/webapp
deployment.apps/webapp
REVISION  CHANGE-CAUSE
1         Despliegue inicial v1 - nginx:1.24-alpine
2         Actualización a nginx:1.25-alpine para parches de seguridad
3         v2 - Aumentar recursos y réplicas
```

## Paso 8: Usar kubectl edit para Cambios Rápidos

### kubectl edit deployment/webapp

```
$ kubectl edit deployment/webapp
deployment.apps/webapp edited
```

> **Nota**: Este comando abre el editor. Después de modificar y guardar, muestra el mensaje "edited".

### kubectl get deployment webapp (después de editar réplicas a 5)

```
$ kubectl get deployment webapp
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
webapp   5/5     5            5           10m
```

## Paso 9: Usar kubectl patch para Cambios Específicos

### kubectl patch deployment webapp -p '{"spec":{"replicas":3}}'

```
$ kubectl patch deployment webapp -p '{"spec":{"replicas":3}}'
deployment.apps/webapp patched
```

### kubectl patch deployment webapp -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","resources":{"limits":{"memory":"192Mi"}}}]}}}}'

```
$ kubectl patch deployment webapp -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","resources":{"limits":{"memory":"192Mi"}}}]}}}}'
deployment.apps/webapp patched
```

### kubectl describe deployment webapp | grep -A 5 "Limits:"

```
$ kubectl describe deployment webapp | grep -A 5 "Limits:"
    Limits:
      cpu:     300m
      memory:  192Mi
    Requests:
      cpu:     150m
      memory:  128Mi
```

## Paso 10: Diferencia entre create, apply y replace

### kubectl create cuando el recurso existe (error)

```
$ kubectl create -f initial/app-deployment-v1.yaml
Error from server (AlreadyExists): error when creating "initial/app-deployment-v1.yaml": deployments.apps "webapp" already exists
```

### kubectl apply cuando el recurso existe (funciona)

```
$ kubectl apply -f initial/app-deployment-v1.yaml
deployment.apps/webapp configured
```

### kubectl replace

```
$ kubectl replace -f initial/app-deployment-v1.yaml
deployment.apps/webapp replaced
```

## Paso 11: Simular un Deployment Fallido

### kubectl set image deployment/webapp nginx=nginx:version-inexistente

```
$ kubectl set image deployment/webapp nginx=nginx:version-inexistente
deployment.apps/webapp image updated
```

### kubectl rollout status deployment/webapp --timeout=30s

```
$ kubectl rollout status deployment/webapp --timeout=30s
Waiting for deployment "webapp" rollout to finish: 1 out of 3 new replicas have been updated...
error: timed out waiting for rollout to finish
```

### kubectl get pods -l app=webapp

```
$ kubectl get pods -l app=webapp
NAME                      READY   STATUS             RESTARTS   AGE
webapp-6d9c5f8d9d-abc12   1/1     Running            0          5m
webapp-6d9c5f8d9d-def34   1/1     Running            0          5m
webapp-6d9c5f8d9d-ghi56   1/1     Running            0          5m
webapp-8f9a7b6c5d-xyz99   0/1     ImagePullBackOff   0          30s
```

> **Nota**: Los pods v1 siguen corriendo mientras el pod con la imagen inválida falla. Esto es gracias a `maxUnavailable: 0`.

## Paso 12: Ejecutar Rollback

### kubectl rollout undo deployment/webapp

```
$ kubectl rollout undo deployment/webapp
deployment.apps/webapp rolled back
```

### kubectl rollout status deployment/webapp (después del rollback)

```
$ kubectl rollout status deployment/webapp
deployment "webapp" successfully rolled out
```

### kubectl get pods -l app=webapp (después del rollback)

```
$ kubectl get pods -l app=webapp
NAME                      READY   STATUS    RESTARTS   AGE
webapp-6d9c5f8d9d-abc12   1/1     Running   0          8m
webapp-6d9c5f8d9d-def34   1/1     Running   0          8m
webapp-6d9c5f8d9d-ghi56   1/1     Running   0          8m
```

## Paso 13: Rollback a una Revisión Específica

### kubectl rollout undo deployment/webapp --to-revision=1

```
$ kubectl rollout undo deployment/webapp --to-revision=1
deployment.apps/webapp rolled back
```

### kubectl describe deployment webapp | grep -i image (después del rollback a rev 1)

```
$ kubectl describe deployment webapp | grep -i image
    Image:        nginx:1.24-alpine
```

## Paso 14: Pausar y Reanudar Rollouts

### kubectl rollout pause deployment/webapp

```
$ kubectl rollout pause deployment/webapp
deployment.apps/webapp paused
```

### kubectl get deployment webapp (mientras está pausado, después de cambios)

```
$ kubectl get deployment webapp
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
webapp   3/3     0            3           15m
```

> **Nota**: `UP-TO-DATE` es 0 porque los cambios están pendientes.

### kubectl rollout status deployment/webapp (mientras está pausado)

```
$ kubectl rollout status deployment/webapp
Waiting for deployment "webapp" rollout to resume...
```

### kubectl rollout resume deployment/webapp

```
$ kubectl rollout resume deployment/webapp
deployment.apps/webapp resumed
```

### kubectl rollout status deployment/webapp (después de resume)

```
$ kubectl rollout status deployment/webapp
Waiting for deployment "webapp" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "webapp" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "webapp" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "webapp" rollout to finish: 4 out of 4 new replicas have been updated...
Waiting for deployment "webapp" rollout to finish: 3 of 4 updated replicas are available...
deployment "webapp" successfully rolled out
```

## Paso 15: Limpiar los Recursos

### kubectl delete deployment webapp

```
$ kubectl delete deployment webapp
deployment.apps "webapp" deleted
```

### kubectl get deployments

```
$ kubectl get deployments
No resources found in default namespace.
```

## Ejercicios Adicionales

### Ejercicio 1: Estrategia Recreate

```
$ kubectl apply -f /tmp/recreate-deployment.yaml
deployment.apps/app-recreate created

$ kubectl rollout status deployment/app-recreate
deployment "app-recreate" successfully rolled out

$ kubectl set image deployment/app-recreate nginx=nginx:1.25-alpine
deployment.apps/app-recreate image updated

$ kubectl get pods -l app=app-recreate -w
NAME                            READY   STATUS        RESTARTS   AGE
app-recreate-5d9c6c9f8d-abc12   1/1     Terminating   0          30s
app-recreate-5d9c6c9f8d-def34   1/1     Terminating   0          30s
app-recreate-5d9c6c9f8d-ghi56   1/1     Terminating   0          30s
app-recreate-5d9c6c9f8d-abc12   0/1     Terminating   0          35s
app-recreate-5d9c6c9f8d-def34   0/1     Terminating   0          35s
app-recreate-5d9c6c9f8d-ghi56   0/1     Terminating   0          35s
app-recreate-7f8b6c8d7e-jkl78   0/1     Pending       0          0s
app-recreate-7f8b6c8d7e-mno90   0/1     Pending       0          0s
app-recreate-7f8b6c8d7e-pqr12   0/1     Pending       0          0s
app-recreate-7f8b6c8d7e-jkl78   0/1     ContainerCreating   0   0s
app-recreate-7f8b6c8d7e-mno90   0/1     ContainerCreating   0   0s
app-recreate-7f8b6c8d7e-pqr12   0/1     ContainerCreating   0   0s
app-recreate-7f8b6c8d7e-jkl78   1/1     Running             0   5s
app-recreate-7f8b6c8d7e-mno90   1/1     Running             0   5s
app-recreate-7f8b6c8d7e-pqr12   1/1     Running             0   5s
```

> **Nota**: Con estrategia Recreate, todos los pods se terminan ANTES de crear los nuevos. Hay downtime.

### Ejercicio 3: kubectl set env

```
$ kubectl create deployment test-set --image=nginx:alpine --replicas=2
deployment.apps/test-set created

$ kubectl set env deployment/test-set ENVIRONMENT=production DEBUG=false
deployment.apps/test-set env updated

$ kubectl describe deployment test-set | grep -A 5 "Environment:"
    Environment:
      ENVIRONMENT:  production
      DEBUG:        false
```

## Resumen de Salidas

Si todas tus salidas son similares a las mostradas en este documento, has completado exitosamente el Lab 07.

Las diferencias menores que puedes esperar:

- **Nombres de pods**: Los sufijos aleatorios serán diferentes
- **Tiempos**: Los tiempos de AGE y espera variarán
- **Números de revisión**: Dependen de cuántas actualizaciones hayas hecho

### Mensajes Importantes a Observar

| Mensaje                                | Significado                                  |
| -------------------------------------- | -------------------------------------------- |
| `deployment.apps/webapp created`       | Recurso creado exitosamente                  |
| `deployment.apps/webapp configured`    | Recurso actualizado con apply                |
| `deployment.apps/webapp replaced`      | Recurso reemplazado completamente            |
| `deployment.apps/webapp image updated` | Imagen actualizada con set image             |
| `deployment.apps/webapp patched`       | Cambio parcial aplicado con patch            |
| `deployment.apps/webapp annotated`     | Anotación añadida/modificada                 |
| `deployment.apps/webapp rolled back`   | Rollback ejecutado                           |
| `deployment.apps/webapp paused`        | Rollout pausado                              |
| `deployment.apps/webapp resumed`       | Rollout reanudado                            |
| `deployment.apps/webapp edited`        | Recurso editado con kubectl edit             |
| `Error from server (AlreadyExists)`    | create falló porque el recurso ya existe     |
| `error: timed out waiting for rollout` | El rollout no completó en el tiempo esperado |
