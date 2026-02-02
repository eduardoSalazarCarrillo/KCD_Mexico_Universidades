# Lab 07: Resource Updates

## Objetivo

Dominar la modificación y actualización de recursos existentes en Kubernetes, entendiendo las diferencias entre los comandos `apply`, `create`, `replace` y `edit`, y cómo gestionar el historial de cambios.

## Prerrequisitos

- Lab 06 completado (YAML Manifests)
- Clúster de Minikube ejecutándose (`minikube status` debe mostrar "Running")

## Duración

45 minutos

## Conceptos Clave

Antes de comenzar, es importante entender estos conceptos:

| Concepto            | Descripción                                                                                         |
| ------------------- | --------------------------------------------------------------------------------------------------- |
| **kubectl apply**   | Crea o actualiza recursos de forma declarativa. Guarda la configuración para futuras comparaciones. |
| **kubectl create**  | Crea recursos de forma imperativa. Falla si el recurso ya existe.                                   |
| **kubectl replace** | Reemplaza un recurso existente completamente. Requiere que exista.                                  |
| **kubectl edit**    | Abre el recurso en un editor para modificación directa.                                             |
| **kubectl patch**   | Aplica cambios parciales a un recurso sin reemplazarlo completamente.                               |
| **kubectl set**     | Modifica campos específicos de recursos (como image, resources, env).                               |
| **Rollout**         | Proceso de actualización gradual de pods en un Deployment.                                          |
| **Revision**        | Versión histórica de un Deployment que permite hacer rollback.                                      |
| **change-cause**    | Anotación que documenta la razón del cambio en el historial.                                        |

### Flujo de Actualización de un Deployment

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     FLUJO DE ACTUALIZACIÓN DE DEPLOYMENT                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. MODIFICAR       2. APLICAR          3. ROLLOUT         4. VERIFICAR    │
│  ┌─────────────┐   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐   │
│  │ Editar YAML │──▶│kubectl apply│───▶│  Rolling    │───▶│ Pods nuevos │   │
│  │ o usar set  │   │ -f file.yaml│    │  Update     │    │  corriendo  │   │
│  └─────────────┘   └─────────────┘    └─────────────┘    └─────────────┘   │
│                                              │                              │
│                                              ▼                              │
│                                       ┌─────────────┐                       │
│                                       │  Historial  │                       │
│                                       │  Revision N │                       │
│                                       └─────────────┘                       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Comparación: apply vs create vs replace

```
┌────────────────────────────────────────────────────────────────────────────┐
│                      COMPARACIÓN DE COMANDOS                               │
├─────────────────┬──────────────────┬──────────────────┬────────────────────┤
│                 │  kubectl create  │  kubectl apply   │  kubectl replace   │
├─────────────────┼──────────────────┼──────────────────┼────────────────────┤
│ Recurso existe  │     ❌ Error      │   ✓ Actualiza    │    ✓ Reemplaza     │
│ Recurso no existe │   ✓ Crea        │   ✓ Crea         │    ❌ Error         │
│ Enfoque         │   Imperativo     │   Declarativo    │    Imperativo      │
│ Guarda config   │       No         │       Sí         │        No          │
│ Uso recomendado │   Una sola vez   │   Siempre        │    Casos especiales│
└─────────────────┴──────────────────┴──────────────────┴────────────────────┘
```

### Estrategias de Actualización de Deployments

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     ESTRATEGIAS DE ACTUALIZACIÓN                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ROLLING UPDATE (Por defecto)               RECREATE                        │
│  ─────────────────────────────             ─────────────────────────        │
│                                                                             │
│  Pods v1: ●●● → ●●○ → ●○○ → ○○○           Pods v1: ●●● → ○○○               │
│  Pods v2: ○○○ → ○○● → ○●● → ●●●           Pods v2: ○○○ → ●●●               │
│                                                                             │
│  ✓ Sin downtime                            ✗ Hay downtime                   │
│  ✓ Gradual                                 ✓ Más rápido                     │
│  ✓ Permite rollback                        ✓ Sin versiones mixtas           │
│                                                                             │
│  Configuración:                            Configuración:                   │
│    strategy:                                 strategy:                      │
│      type: RollingUpdate                       type: Recreate               │
│      rollingUpdate:                                                         │
│        maxSurge: 1                                                          │
│        maxUnavailable: 0                                                    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
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

### Paso 2: Desplegar la Aplicación Inicial (v1)

Examina el archivo `initial/app-deployment-v1.yaml` que contiene un Deployment con la versión 1 de nuestra aplicación:

```bash
cat initial/app-deployment-v1.yaml
```

**Contenido del archivo**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  labels:
    app: webapp
    version: v1
  annotations:
    kubernetes.io/change-cause: "Despliegue inicial v1 - nginx:1.24-alpine"
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1 # Máximo pods adicionales durante actualización
      maxUnavailable: 0 # Siempre mantener todos los pods disponibles
  template:
    metadata:
      labels:
        app: webapp
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
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 3
            periodSeconds: 5
```

**Campos importantes para actualizaciones**:

| Campo                                    | Descripción                                   |
| ---------------------------------------- | --------------------------------------------- |
| `annotations.kubernetes.io/change-cause` | Documenta la razón del cambio en el historial |
| `strategy.type`                          | Tipo de estrategia de actualización           |
| `strategy.rollingUpdate.maxSurge`        | Pods adicionales permitidos durante update    |
| `strategy.rollingUpdate.maxUnavailable`  | Pods que pueden estar no disponibles          |

Aplica el deployment:

```bash
kubectl apply -f initial/app-deployment-v1.yaml
```

**Salida esperada**:

```
deployment.apps/webapp created
```

Verifica que el deployment está listo:

```bash
kubectl rollout status deployment/webapp
```

**Salida esperada**:

```
deployment "webapp" successfully rolled out
```

Verifica los pods y su versión:

```bash
kubectl get pods -l app=webapp -L version
```

**Salida esperada**:

```
NAME                      READY   STATUS    RESTARTS   AGE   VERSION
webapp-6d9c5f8d9d-abc12   1/1     Running   0          30s   v1
webapp-6d9c5f8d9d-def34   1/1     Running   0          30s   v1
webapp-6d9c5f8d9d-ghi56   1/1     Running   0          30s   v1
```

### Paso 3: Ver el Historial de Revisiones

Kubernetes mantiene un historial de las revisiones de un Deployment:

```bash
kubectl rollout history deployment/webapp
```

**Salida esperada**:

```
deployment.apps/webapp
REVISION  CHANGE-CAUSE
1         Despliegue inicial v1 - nginx:1.24-alpine
```

Para ver detalles de una revisión específica:

```bash
kubectl rollout history deployment/webapp --revision=1
```

**Salida esperada**:

```
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
    ...
```

### Paso 4: Actualizar la Imagen Usando kubectl set image

El comando `kubectl set image` permite actualizar la imagen de un contenedor de forma rápida:

```bash
# Actualizar la imagen a nginx:1.25-alpine
kubectl set image deployment/webapp nginx=nginx:1.25-alpine
```

**Salida esperada**:

```
deployment.apps/webapp image updated
```

Observa el rollout en tiempo real:

```bash
kubectl rollout status deployment/webapp
```

**Salida esperada**:

```
Waiting for deployment "webapp" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "webapp" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "webapp" rollout to finish: 3 out of 3 new replicas have been updated...
Waiting for deployment "webapp" rollout to finish: 2 of 3 updated replicas are available...
deployment "webapp" successfully rolled out
```

Verifica la nueva imagen:

```bash
kubectl describe deployment webapp | grep -i image
```

**Salida esperada**:

```
    Image:        nginx:1.25-alpine
```

### Paso 5: Documentar el Cambio con change-cause

El cambio anterior no tiene documentación en el historial. Añade una anotación para documentarlo:

```bash
kubectl annotate deployment/webapp kubernetes.io/change-cause="Actualización a nginx:1.25-alpine para parches de seguridad" --overwrite
```

**Salida esperada**:

```
deployment.apps/webapp annotated
```

Verifica el historial actualizado:

```bash
kubectl rollout history deployment/webapp
```

**Salida esperada**:

```
deployment.apps/webapp
REVISION  CHANGE-CAUSE
1         Despliegue inicial v1 - nginx:1.24-alpine
2         Actualización a nginx:1.25-alpine para parches de seguridad
```

### Paso 6: Actualizar Usando kubectl apply

Ahora actualizaremos usando un archivo YAML modificado. Examina el archivo `initial/app-deployment-v2.yaml`:

```bash
cat initial/app-deployment-v2.yaml
```

**Contenido del archivo** (diferencias con v1):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  labels:
    app: webapp
    version: v2
  annotations:
    kubernetes.io/change-cause: "v2 - Aumentar recursos y réplicas"
spec:
  replicas: 4 # Aumentado de 3 a 4
  selector:
    matchLabels:
      app: webapp
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: webapp
        version: v2 # Cambiado de v1 a v2
    spec:
      containers:
        - name: nginx
          image: nginx:1.25-alpine
          ports:
            - containerPort: 80
              name: http
          resources:
            requests:
              memory: "128Mi" # Aumentado de 64Mi
              cpu: "150m" # Aumentado de 100m
            limits:
              memory: "256Mi" # Aumentado de 128Mi
              cpu: "300m" # Aumentado de 200m
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 3
            periodSeconds: 5
```

Antes de aplicar, usa `kubectl diff` para ver los cambios:

```bash
kubectl diff -f initial/app-deployment-v2.yaml
```

**Salida esperada** (extracto):

```diff
...
-  replicas: 3
+  replicas: 4
...
-        version: v1
+        version: v2
...
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
...
```

Aplica los cambios:

```bash
kubectl apply -f initial/app-deployment-v2.yaml
```

**Salida esperada**:

```
deployment.apps/webapp configured
```

> **Nota**: `configured` indica que el recurso fue actualizado, mientras que `created` indica que fue creado.

Verifica el rollout:

```bash
kubectl rollout status deployment/webapp
```

Verifica que ahora hay 4 réplicas con la etiqueta v2:

```bash
kubectl get pods -l app=webapp -L version
```

**Salida esperada**:

```
NAME                      READY   STATUS    RESTARTS   AGE   VERSION
webapp-7f8b6c8d7e-abc12   1/1     Running   0          30s   v2
webapp-7f8b6c8d7e-def34   1/1     Running   0          30s   v2
webapp-7f8b6c8d7e-ghi56   1/1     Running   0          30s   v2
webapp-7f8b6c8d7e-jkl78   1/1     Running   0          30s   v2
```

### Paso 7: Ver el Historial Completo

```bash
kubectl rollout history deployment/webapp
```

**Salida esperada**:

```
deployment.apps/webapp
REVISION  CHANGE-CAUSE
1         Despliegue inicial v1 - nginx:1.24-alpine
2         Actualización a nginx:1.25-alpine para parches de seguridad
3         v2 - Aumentar recursos y réplicas
```

### Paso 8: Usar kubectl edit para Cambios Rápidos

El comando `kubectl edit` abre el recurso en tu editor predeterminado (vim por defecto):

```bash
# Establecer nano como editor (más fácil de usar que vim)
export KUBE_EDITOR="nano"

# Editar el deployment
kubectl edit deployment/webapp
```

En el editor, busca la línea `replicas: 4` y cámbiala a `replicas: 5`. Guarda y cierra el editor.

> **Nota**: En nano, haz el cambio, presiona `Ctrl+O` para guardar, `Enter` para confirmar, y `Ctrl+X` para salir.
> En vim, presiona `i` para entrar en modo inserción, haz el cambio, presiona `Esc`, y escribe `:wq` para guardar y salir.

**Salida esperada** (después de guardar):

```
deployment.apps/webapp edited
```

Verifica que ahora hay 5 réplicas:

```bash
kubectl get deployment webapp
```

**Salida esperada**:

```
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
webapp   5/5     5            5           10m
```

Documenta el cambio:

```bash
kubectl annotate deployment/webapp kubernetes.io/change-cause="Escalar a 5 réplicas usando kubectl edit" --overwrite
```

### Paso 9: Usar kubectl patch para Cambios Específicos

El comando `kubectl patch` permite modificar campos específicos sin abrir un editor:

```bash
# Cambiar el número de réplicas a 3 usando patch JSON
kubectl patch deployment webapp -p '{"spec":{"replicas":3}}'
```

**Salida esperada**:

```
deployment.apps/webapp patched
```

También puedes usar patch para modificar campos anidados:

```bash
# Cambiar los límites de memoria usando patch JSON
kubectl patch deployment webapp -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","resources":{"limits":{"memory":"192Mi"}}}]}}}}'
```

**Salida esperada**:

```
deployment.apps/webapp patched
```

Verifica los cambios:

```bash
kubectl describe deployment webapp | grep -A 5 "Limits:"
```

**Salida esperada**:

```
    Limits:
      cpu:     300m
      memory:  192Mi
    Requests:
      cpu:     150m
      memory:  128Mi
```

### Paso 10: Diferencia entre create, apply y replace

Vamos a demostrar las diferencias entre estos comandos:

**Intentar create cuando el recurso existe:**

```bash
kubectl create -f initial/app-deployment-v1.yaml
```

**Salida esperada** (error):

```
Error from server (AlreadyExists): error when creating "initial/app-deployment-v1.yaml": deployments.apps "webapp" already exists
```

**Usar apply cuando el recurso existe** (funciona):

```bash
kubectl apply -f initial/app-deployment-v1.yaml
```

**Salida esperada**:

```
deployment.apps/webapp configured
```

**Usar replace para reemplazar completamente:**

```bash
kubectl replace -f initial/app-deployment-v1.yaml
```

**Salida esperada**:

```
deployment.apps/webapp replaced
```

> **Importante**: `replace` elimina todos los campos no especificados en el archivo, mientras que `apply` solo actualiza los campos especificados.

### Paso 11: Simular un Deployment Fallido

Vamos a simular un deployment fallido usando una imagen que no existe:

```bash
kubectl set image deployment/webapp nginx=nginx:version-inexistente
```

Observa el rollout fallido:

```bash
kubectl rollout status deployment/webapp --timeout=30s
```

**Salida esperada**:

```
Waiting for deployment "webapp" rollout to finish: 1 out of 3 new replicas have been updated...
error: timed out waiting for rollout to finish
```

Verifica el estado de los pods:

```bash
kubectl get pods -l app=webapp
```

**Salida esperada**:

```
NAME                      READY   STATUS             RESTARTS   AGE
webapp-6d9c5f8d9d-abc12   1/1     Running            0          5m
webapp-6d9c5f8d9d-def34   1/1     Running            0          5m
webapp-6d9c5f8d9d-ghi56   1/1     Running            0          5m
webapp-8f9a7b6c5d-xyz99   0/1     ImagePullBackOff   0          30s
```

> **Nota**: La estrategia RollingUpdate con `maxUnavailable: 0` mantiene los pods v1 funcionando mientras el nuevo pod falla.

### Paso 12: Ejecutar Rollback

Cuando un deployment falla, podemos hacer rollback a una versión anterior:

```bash
# Ver el historial
kubectl rollout history deployment/webapp

# Hacer rollback a la revisión anterior
kubectl rollout undo deployment/webapp
```

**Salida esperada**:

```
deployment.apps/webapp rolled back
```

Verifica que el rollback fue exitoso:

```bash
kubectl rollout status deployment/webapp
kubectl get pods -l app=webapp
```

**Salida esperada**:

```
deployment "webapp" successfully rolled out

NAME                      READY   STATUS    RESTARTS   AGE
webapp-6d9c5f8d9d-abc12   1/1     Running   0          8m
webapp-6d9c5f8d9d-def34   1/1     Running   0          8m
webapp-6d9c5f8d9d-ghi56   1/1     Running   0          8m
```

### Paso 13: Rollback a una Revisión Específica

Puedes hacer rollback a cualquier revisión anterior:

```bash
# Ver todas las revisiones disponibles
kubectl rollout history deployment/webapp

# Rollback a la revisión 1 (la original)
kubectl rollout undo deployment/webapp --to-revision=1
```

**Salida esperada**:

```
deployment.apps/webapp rolled back
```

Verifica la imagen:

```bash
kubectl describe deployment webapp | grep -i image
```

**Salida esperada**:

```
    Image:        nginx:1.24-alpine
```

### Paso 14: Pausar y Reanudar Rollouts

Puedes pausar un rollout para hacer múltiples cambios antes de desplegar:

```bash
# Pausar el deployment
kubectl rollout pause deployment/webapp
```

**Salida esperada**:

```
deployment.apps/webapp paused
```

Ahora puedes hacer múltiples cambios sin que se inicie un rollout:

```bash
# Cambiar la imagen
kubectl set image deployment/webapp nginx=nginx:1.25-alpine

# Cambiar los recursos
kubectl set resources deployment/webapp -c nginx --limits=memory=256Mi,cpu=300m

# Cambiar las réplicas
kubectl scale deployment/webapp --replicas=4
```

Verifica que no ha habido rollout (los cambios están pendientes):

```bash
kubectl get deployment webapp
kubectl rollout status deployment/webapp
```

**Salida esperada**:

```
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
webapp   3/3     0            3           15m

Waiting for deployment "webapp" rollout to resume...
```

Reanuda el rollout para aplicar todos los cambios de una vez:

```bash
kubectl rollout resume deployment/webapp
```

**Salida esperada**:

```
deployment.apps/webapp resumed
```

Observa el rollout:

```bash
kubectl rollout status deployment/webapp
```

**Salida esperada**:

```
Waiting for deployment "webapp" rollout to finish: 1 out of 4 new replicas have been updated...
...
deployment "webapp" successfully rolled out
```

### Paso 15: Limpiar los Recursos

```bash
# Eliminar el deployment
kubectl delete deployment webapp

# Verificar limpieza
kubectl get deployments
kubectl get pods -l app=webapp
```

**Salida esperada**:

```
deployment.apps "webapp" deleted
No resources found in default namespace.
No resources found in default namespace.
```

## Ejercicios Adicionales

### Ejercicio 1: Actualización con Estrategia Recreate

Crea un deployment con estrategia Recreate y observa la diferencia:

```bash
cat << 'EOF' > /tmp/recreate-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-recreate
  annotations:
    kubernetes.io/change-cause: "Deployment con estrategia Recreate"
spec:
  replicas: 3
  selector:
    matchLabels:
      app: app-recreate
  strategy:
    type: Recreate  # Todos los pods se eliminan antes de crear nuevos
  template:
    metadata:
      labels:
        app: app-recreate
    spec:
      containers:
        - name: nginx
          image: nginx:1.24-alpine
          ports:
            - containerPort: 80
EOF

# Aplicar
kubectl apply -f /tmp/recreate-deployment.yaml
kubectl rollout status deployment/app-recreate

# Actualizar imagen y observar (todos los pods se eliminan primero)
kubectl set image deployment/app-recreate nginx=nginx:1.25-alpine

# Observar que hay downtime
kubectl get pods -l app=app-recreate -w
# (Presiona Ctrl+C para salir)

# Limpiar
kubectl delete deployment app-recreate
```

### Ejercicio 2: Configurar maxSurge y maxUnavailable

Experimenta con diferentes configuraciones de rolling update:

```bash
cat << 'EOF' > /tmp/custom-rolling.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: custom-rolling
spec:
  replicas: 6
  selector:
    matchLabels:
      app: custom-rolling
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2        # Puede crear 2 pods extra (8 total)
      maxUnavailable: 1  # Puede tener 1 pod no disponible (5 mínimo)
  template:
    metadata:
      labels:
        app: custom-rolling
    spec:
      containers:
        - name: nginx
          image: nginx:1.24-alpine
EOF

kubectl apply -f /tmp/custom-rolling.yaml
kubectl rollout status deployment/custom-rolling

# Actualizar y observar
kubectl set image deployment/custom-rolling nginx=nginx:1.25-alpine
kubectl get pods -l app=custom-rolling -w
# (Presiona Ctrl+C para salir)

# Limpiar
kubectl delete deployment custom-rolling
```

### Ejercicio 3: Usar kubectl set para Múltiples Cambios

```bash
# Crear deployment de prueba
kubectl create deployment test-set --image=nginx:alpine --replicas=2

# Cambiar variables de entorno
kubectl set env deployment/test-set ENVIRONMENT=production DEBUG=false

# Verificar
kubectl describe deployment test-set | grep -A 5 "Environment:"

# Cambiar recursos
kubectl set resources deployment/test-set -c nginx --requests=cpu=50m,memory=64Mi --limits=cpu=100m,memory=128Mi

# Verificar
kubectl describe deployment test-set | grep -A 10 "Limits:"

# Limpiar
kubectl delete deployment test-set
```

### Ejercicio 4: Verificar Configuración Guardada por apply

```bash
# Crear deployment con apply
kubectl apply -f initial/app-deployment-v1.yaml

# Ver la anotación last-applied-configuration
kubectl get deployment webapp -o jsonpath='{.metadata.annotations.kubectl\.kubernetes\.io/last-applied-configuration}' | python3 -m json.tool

# Esta configuración se usa para calcular diferencias en futuros apply

# Limpiar
kubectl delete deployment webapp
```

## Verificación

Antes de continuar al siguiente laboratorio, asegúrate de poder marcar todos estos puntos:

- [ ] Entiendo la diferencia entre `apply`, `create` y `replace`
- [ ] Puedo actualizar la imagen de un deployment con `kubectl set image`
- [ ] Puedo documentar cambios usando la anotación `change-cause`
- [ ] Puedo ver el historial de revisiones con `kubectl rollout history`
- [ ] Puedo usar `kubectl diff` para ver cambios antes de aplicarlos
- [ ] Puedo usar `kubectl edit` para modificar recursos directamente
- [ ] Puedo usar `kubectl patch` para cambios específicos
- [ ] Entiendo las estrategias RollingUpdate y Recreate
- [ ] Puedo hacer rollback a versiones anteriores con `kubectl rollout undo`
- [ ] Puedo pausar y reanudar rollouts con `pause` y `resume`
- [ ] Entiendo el significado de maxSurge y maxUnavailable

## Resumen de Comandos

| Comando                                                    | Descripción                                  |
| ---------------------------------------------------------- | -------------------------------------------- |
| `kubectl apply -f <archivo.yaml>`                          | Crear o actualizar recursos declarativamente |
| `kubectl create -f <archivo.yaml>`                         | Crear recursos (falla si existe)             |
| `kubectl replace -f <archivo.yaml>`                        | Reemplazar recurso completamente             |
| `kubectl set image deployment/<n> <c>=<img>`               | Actualizar imagen de contenedor              |
| `kubectl set resources deployment/<n> -c <c> --limits=...` | Actualizar recursos de contenedor            |
| `kubectl set env deployment/<n> VAR=value`                 | Establecer variables de entorno              |
| `kubectl edit deployment/<nombre>`                         | Editar recurso en editor                     |
| `kubectl patch deployment/<n> -p '<json>'`                 | Aplicar cambio parcial con JSON              |
| `kubectl diff -f <archivo.yaml>`                           | Ver diferencias antes de aplicar             |
| `kubectl annotate deployment/<n> key=value`                | Añadir/modificar anotación                   |
| `kubectl rollout status deployment/<nombre>`               | Ver estado del rollout                       |
| `kubectl rollout history deployment/<nombre>`              | Ver historial de revisiones                  |
| `kubectl rollout history deployment/<n> --revision=N`      | Ver detalles de revisión específica          |
| `kubectl rollout undo deployment/<nombre>`                 | Rollback a revisión anterior                 |
| `kubectl rollout undo deployment/<n> --to-revision=N`      | Rollback a revisión específica               |
| `kubectl rollout pause deployment/<nombre>`                | Pausar rollout                               |
| `kubectl rollout resume deployment/<nombre>`               | Reanudar rollout pausado                     |
| `kubectl scale deployment/<nombre> --replicas=N`           | Escalar réplicas                             |

## Conceptos Aprendidos

1. **Gestión Declarativa vs Imperativa**: `apply` es declarativo (define estado deseado), mientras que `create`/`set` son imperativos
2. **Historial de Revisiones**: Kubernetes guarda el historial de cambios de Deployments
3. **change-cause**: Anotación para documentar la razón de cada cambio
4. **Rolling Updates**: Actualizaciones graduales sin downtime
5. **maxSurge/maxUnavailable**: Control fino sobre el proceso de actualización
6. **Rollback**: Capacidad de volver a versiones anteriores
7. **Pause/Resume**: Control sobre cuándo se aplican los cambios

## Solución

Consulta el directorio `solution/` para ver los scripts con todos los comandos y las salidas esperadas.

## Navegación

- **Anterior**: [Lab 06: YAML Manifests](../lab-06-yaml-manifests/README.md)
- **Siguiente**: [Lab 08: Services](../../modulo-06-servicios-networking/lab-08-services/README.md)
