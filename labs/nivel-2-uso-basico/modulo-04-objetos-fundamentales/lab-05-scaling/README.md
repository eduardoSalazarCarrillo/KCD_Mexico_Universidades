# Lab 05: Scaling

## Objetivo

Escalar aplicaciones manualmente en Kubernetes y comprender el escalamiento horizontal.

## Prerrequisitos

- Lab 04 completado (Pods y Deployments)
- Clúster de Minikube ejecutándose (`minikube status` debe mostrar "Running")

## Duración

30 minutos

## Conceptos Clave

Antes de comenzar, es importante entender estos conceptos:

| Concepto                      | Descripción                                                                                                |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------- |
| **Escalamiento Horizontal**   | Aumentar o disminuir el número de réplicas (instancias) de una aplicación. Es lo que hace Kubernetes.      |
| **Escalamiento Vertical**     | Aumentar los recursos (CPU, memoria) de una instancia existente. Menos común en Kubernetes.                |
| **Réplicas**                  | Número de copias idénticas de un Pod que se ejecutan simultáneamente.                                      |
| **kubectl scale**             | Comando para cambiar el número de réplicas de un Deployment, ReplicaSet o StatefulSet.                     |
| **Declarativo vs Imperativo** | Declarativo: define el estado deseado en YAML. Imperativo: ejecuta comandos directos como `kubectl scale`. |
| **Alta Disponibilidad**       | Capacidad de mantener el servicio funcionando incluso si algunas réplicas fallan.                          |
| **Load Balancing**            | Distribución automática del tráfico entre todas las réplicas disponibles.                                  |

### Escalamiento Horizontal vs Vertical

```
ESCALAMIENTO VERTICAL                    ESCALAMIENTO HORIZONTAL
(Scale Up/Down)                          (Scale Out/In)

┌─────────────────────┐                  ┌─────────┐ ┌─────────┐ ┌─────────┐
│                     │                  │   Pod   │ │   Pod   │ │   Pod   │
│    Pod Grande       │                  │    1    │ │    2    │ │    3    │
│                     │                  └─────────┘ └─────────┘ └─────────┘
│  CPU: 4 cores       │        vs
│  RAM: 8 GB          │                  ┌─────────┐ ┌─────────┐
│                     │                  │   Pod   │ │   Pod   │
│                     │                  │    4    │ │    5    │
└─────────────────────┘                  └─────────┘ └─────────┘

- Límite físico de recursos           - Sin límite práctico de réplicas
- Requiere reinicio                   - Sin downtime
- Un punto de falla                   - Alta disponibilidad
```

### ¿Por qué Escalar Horizontalmente?

| Beneficio               | Descripción                                                            |
| ----------------------- | ---------------------------------------------------------------------- |
| **Alta Disponibilidad** | Si un Pod falla, los demás siguen funcionando                          |
| **Mejor Rendimiento**   | El tráfico se distribuye entre múltiples réplicas                      |
| **Sin Downtime**        | Se pueden agregar/quitar réplicas sin interrumpir el servicio          |
| **Costo Eficiente**     | Usar múltiples instancias pequeñas suele ser más barato que una grande |
| **Flexibilidad**        | Escalar según demanda (más réplicas en horas pico)                     |

### Formas de Escalar en Kubernetes

```
┌─────────────────────────────────────────────────────────────────────┐
│                    FORMAS DE ESCALAR                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. IMPERATIVO (comandos directos)                                  │
│     ┌─────────────────────────────────────────────────────────┐     │
│     │  kubectl scale deployment <nombre> --replicas=<N>       │     │
│     └─────────────────────────────────────────────────────────┘     │
│                                                                     │
│  2. DECLARATIVO (modificar YAML)                                    │
│     ┌─────────────────────────────────────────────────────────┐     │
│     │  spec:                                                  │     │
│     │    replicas: 5  # Cambiar este valor                    │     │
│     │  ---                                                    │     │
│     │  kubectl apply -f deployment.yaml                       │     │
│     └─────────────────────────────────────────────────────────┘     │
│                                                                     │
│  3. EDICIÓN DIRECTA                                                 │
│     ┌─────────────────────────────────────────────────────────┐     │
│     │  kubectl edit deployment <nombre>                       │     │
│     │  # Modificar replicas en el editor y guardar            │     │
│     └─────────────────────────────────────────────────────────┘     │
│                                                                     │
│  4. AUTOMÁTICO (HPA - Horizontal Pod Autoscaler)                    │
│     ┌─────────────────────────────────────────────────────────┐     │
│     │  Se verá en el Lab 13                                   │     │
│     └─────────────────────────────────────────────────────────┘     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
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

### Paso 2: Crear un Deployment con 1 Réplica

Primero, creamos un Deployment inicial con una sola réplica usando el archivo `initial/deployment-scaling.yaml`:

```bash
# Ver el contenido del archivo
cat initial/deployment-scaling.yaml
```

**Contenido del archivo**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  labels:
    app: web-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
        - name: nginx
          image: nginx:alpine
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: "50m"
              memory: "64Mi"
            limits:
              cpu: "100m"
              memory: "128Mi"
```

**Explicación del YAML**:

| Campo                | Descripción                                      |
| -------------------- | ------------------------------------------------ |
| `spec.replicas: 1`   | Número inicial de réplicas                       |
| `resources.requests` | Recursos mínimos garantizados para el contenedor |
| `resources.limits`   | Recursos máximos que puede usar el contenedor    |

> **Nota**: Definimos `resources` para que el scheduler pueda distribuir los Pods eficientemente y para prepararnos para el escalamiento automático (Lab 13).

Aplica el Deployment:

```bash
# Crear el deployment
kubectl apply -f initial/deployment-scaling.yaml
```

**Salida esperada**:

```
deployment.apps/web-app created
```

Verifica el estado:

```bash
# Ver el deployment
kubectl get deployment web-app
```

**Salida esperada**:

```
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
web-app   1/1     1            1           30s
```

```bash
# Ver los pods
kubectl get pods -l app=web-app
```

**Salida esperada**:

```
NAME                       READY   STATUS    RESTARTS   AGE
web-app-5d9d7b8c6f-abc12   1/1     Running   0          45s
```

### Paso 3: Verificar el Número Actual de Réplicas

Hay varias formas de verificar cuántas réplicas tiene un Deployment:

```bash
# Forma 1: kubectl get deployment
kubectl get deployment web-app
```

```bash
# Forma 2: Ver el campo replicas con jsonpath
kubectl get deployment web-app -o jsonpath='{.spec.replicas}'
echo ""  # Nueva línea
```

**Salida esperada**:

```
1
```

```bash
# Forma 3: Describir el deployment
kubectl describe deployment web-app | grep -E "Replicas:|Pods Status:"
```

**Salida esperada**:

```
Replicas:               1 desired | 1 updated | 1 total | 1 available | 0 unavailable
```

### Paso 4: Escalar a 5 Réplicas con kubectl scale

El comando `kubectl scale` es la forma más rápida de cambiar el número de réplicas:

```bash
# Escalar el deployment a 5 réplicas
kubectl scale deployment web-app --replicas=5
```

**Salida esperada**:

```
deployment.apps/web-app scaled
```

Observa la creación de los nuevos Pods en tiempo real:

```bash
# Ver pods actualizándose (Ctrl+C para salir)
kubectl get pods -l app=web-app -w
```

**Salida esperada** (verás algo similar):

```
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

Presiona `Ctrl+C` para salir del modo watch.

Verifica el estado final:

```bash
# Ver el deployment actualizado
kubectl get deployment web-app
```

**Salida esperada**:

```
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
web-app   5/5     5            5           3m
```

```bash
# Ver todos los pods
kubectl get pods -l app=web-app
```

**Salida esperada**:

```
NAME                       READY   STATUS    RESTARTS   AGE
web-app-5d9d7b8c6f-abc12   1/1     Running   0          3m
web-app-5d9d7b8c6f-def34   1/1     Running   0          1m
web-app-5d9d7b8c6f-ghi56   1/1     Running   0          1m
web-app-5d9d7b8c6f-jkl78   1/1     Running   0          1m
web-app-5d9d7b8c6f-mno90   1/1     Running   0          1m
```

### Paso 5: Verificar Distribución de Pods

En un clúster multi-nodo, los Pods se distribuyen automáticamente entre los nodos disponibles. En Minikube solo hay un nodo, pero el comando es útil para clústeres reales:

```bash
# Ver en qué nodo está cada pod
kubectl get pods -l app=web-app -o wide
```

**Salida esperada**:

```
NAME                       READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
web-app-5d9d7b8c6f-abc12   1/1     Running   0          4m    10.244.0.5   minikube   <none>           <none>
web-app-5d9d7b8c6f-def34   1/1     Running   0          2m    10.244.0.6   minikube   <none>           <none>
web-app-5d9d7b8c6f-ghi56   1/1     Running   0          2m    10.244.0.7   minikube   <none>           <none>
web-app-5d9d7b8c6f-jkl78   1/1     Running   0          2m    10.244.0.8   minikube   <none>           <none>
web-app-5d9d7b8c6f-mno90   1/1     Running   0          2m    10.244.0.9   minikube   <none>           <none>
```

> **Nota**: Cada Pod tiene su propia IP interna. En un clúster real con múltiples nodos, verías diferentes valores en la columna NODE.

### Paso 6: Reducir a 2 Réplicas

El escalamiento también funciona para reducir el número de réplicas (scale down):

```bash
# Reducir a 2 réplicas
kubectl scale deployment web-app --replicas=2
```

**Salida esperada**:

```
deployment.apps/web-app scaled
```

Observa cómo Kubernetes termina los Pods extras:

```bash
# Ver pods terminándose (Ctrl+C para salir)
kubectl get pods -l app=web-app -w
```

**Salida esperada** (verás algo similar):

```
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

Presiona `Ctrl+C` y verifica el estado final:

```bash
kubectl get deployment web-app
```

**Salida esperada**:

```
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
web-app   2/2     2            2           6m
```

```bash
kubectl get pods -l app=web-app
```

**Salida esperada**:

```
NAME                       READY   STATUS    RESTARTS   AGE
web-app-5d9d7b8c6f-abc12   1/1     Running   0          6m
web-app-5d9d7b8c6f-def34   1/1     Running   0          4m
```

### Paso 7: Escalar Usando kubectl patch

Otra forma de escalar es usando `kubectl patch`:

```bash
# Escalar a 4 réplicas usando patch
kubectl patch deployment web-app -p '{"spec":{"replicas":4}}'
```

**Salida esperada**:

```
deployment.apps/web-app patched
```

Verifica:

```bash
kubectl get deployment web-app
```

**Salida esperada**:

```
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
web-app   4/4     4            4           7m
```

### Paso 8: Escalar Modificando el YAML y Aplicando

La forma más recomendada en producción es modificar el archivo YAML y aplicarlo. Esto mantiene la infraestructura como código:

Usa el archivo `initial/deployment-scaled.yaml` que tiene 6 réplicas:

```bash
# Ver el contenido del archivo escalado
cat initial/deployment-scaled.yaml
```

**Contenido del archivo**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  labels:
    app: web-app
spec:
  replicas: 6
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
        - name: nginx
          image: nginx:alpine
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: "50m"
              memory: "64Mi"
            limits:
              cpu: "100m"
              memory: "128Mi"
```

Aplica el cambio:

```bash
# Aplicar el archivo con las nuevas réplicas
kubectl apply -f initial/deployment-scaled.yaml
```

**Salida esperada**:

```
deployment.apps/web-app configured
```

> **Nota**: El mensaje dice "configured" en lugar de "created" porque el Deployment ya existía y solo se actualizó.

Verifica:

```bash
kubectl get deployment web-app
```

**Salida esperada**:

```
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
web-app   6/6     6            6           8m
```

```bash
kubectl get pods -l app=web-app
```

**Salida esperada**:

```
NAME                       READY   STATUS    RESTARTS   AGE
web-app-5d9d7b8c6f-abc12   1/1     Running   0          8m
web-app-5d9d7b8c6f-def34   1/1     Running   0          6m
web-app-5d9d7b8c6f-pqr12   1/1     Running   0          1m
web-app-5d9d7b8c6f-stu34   1/1     Running   0          1m
web-app-5d9d7b8c6f-vwx56   1/1     Running   0          30s
web-app-5d9d7b8c6f-yza78   1/1     Running   0          30s
```

### Paso 9: Escalar a 0 Réplicas

Es posible escalar a 0 réplicas. Esto es útil para:

- Pausar una aplicación temporalmente sin eliminar el Deployment
- Ahorrar recursos cuando la aplicación no se necesita
- Debugging o mantenimiento

```bash
# Escalar a 0 réplicas
kubectl scale deployment web-app --replicas=0
```

**Salida esperada**:

```
deployment.apps/web-app scaled
```

Verifica:

```bash
kubectl get deployment web-app
```

**Salida esperada**:

```
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
web-app   0/0     0            0           9m
```

```bash
kubectl get pods -l app=web-app
```

**Salida esperada**:

```
No resources found in default namespace.
```

> **Importante**: El Deployment sigue existiendo, solo no tiene Pods corriendo. El ReplicaSet también permanece.

```bash
# Verificar que el deployment y replicaset siguen existiendo
kubectl get deployment,replicaset -l app=web-app
```

**Salida esperada**:

```
NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web-app   0/0     0            0           9m

NAME                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/web-app-5d9d7b8c6f   0         0         0       9m
```

### Paso 10: Restaurar las Réplicas

Vuelve a escalar para tener Pods corriendo:

```bash
# Escalar a 3 réplicas
kubectl scale deployment web-app --replicas=3
```

Verifica que los Pods se crean de nuevo:

```bash
kubectl get pods -l app=web-app
```

**Salida esperada**:

```
NAME                       READY   STATUS    RESTARTS   AGE
web-app-5d9d7b8c6f-new01   1/1     Running   0          30s
web-app-5d9d7b8c6f-new02   1/1     Running   0          30s
web-app-5d9d7b8c6f-new03   1/1     Running   0          30s
```

### Paso 11: Ver el Historial de Eventos de Escalamiento

Puedes ver los eventos relacionados con el escalamiento:

```bash
# Ver eventos del deployment
kubectl describe deployment web-app | grep -A 20 "Events:"
```

**Salida esperada** (extracto):

```
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

### Paso 12: Limpiar los Recursos

```bash
# Eliminar el deployment
kubectl delete deployment web-app
```

**Salida esperada**:

```
deployment.apps "web-app" deleted
```

Verifica que todo fue eliminado:

```bash
kubectl get all -l app=web-app
```

**Salida esperada**:

```
No resources found in default namespace.
```

## Ejercicios Adicionales

### Ejercicio 1: Escalamiento Condicional con --current-replicas

El flag `--current-replicas` permite escalar solo si el número actual de réplicas coincide con el valor especificado:

```bash
# Crear un deployment con 2 réplicas
kubectl create deployment test-app --image=nginx:alpine --replicas=2

# Esperar a que esté listo
kubectl rollout status deployment/test-app

# Intentar escalar solo si tiene 2 réplicas (debería funcionar)
kubectl scale deployment test-app --current-replicas=2 --replicas=4
echo "Resultado: $?"

# Intentar escalar solo si tiene 2 réplicas (debería fallar porque ahora tiene 4)
kubectl scale deployment test-app --current-replicas=2 --replicas=6
echo "Resultado: $?"

# Verificar
kubectl get deployment test-app

# Limpiar
kubectl delete deployment test-app
```

### Ejercicio 2: Escalar Múltiples Deployments

```bash
# Crear dos deployments
kubectl create deployment app-a --image=nginx:alpine --replicas=1
kubectl create deployment app-b --image=httpd:alpine --replicas=1

# Escalar ambos a la vez usando labels
kubectl label deployment app-a tier=frontend
kubectl label deployment app-b tier=frontend

# Ver deployments con el label
kubectl get deployments -l tier=frontend

# Escalar todos los deployments con ese label (nota: scale no soporta -l directamente)
# Pero podemos usar un loop:
for deploy in $(kubectl get deployments -l tier=frontend -o name); do
  kubectl scale $deploy --replicas=3
done

# Verificar
kubectl get deployments -l tier=frontend

# Limpiar
kubectl delete deployment app-a app-b
```

### Ejercicio 3: Monitorear el Escalamiento en Tiempo Real

```bash
# En una terminal, crear el deployment
kubectl create deployment monitor-app --image=nginx:alpine --replicas=1

# En otra terminal (o en segundo plano), observar cambios
kubectl get pods -l app=monitor-app -w &

# Escalar varias veces
kubectl scale deployment monitor-app --replicas=5
sleep 5
kubectl scale deployment monitor-app --replicas=2
sleep 5
kubectl scale deployment monitor-app --replicas=8
sleep 5

# Detener el watch
pkill -f "kubectl get pods"

# Limpiar
kubectl delete deployment monitor-app
```

### Ejercicio 4: Verificar Recursos Disponibles

Antes de escalar, es buena práctica verificar los recursos disponibles:

```bash
# Ver recursos disponibles en el nodo
kubectl describe node minikube | grep -A 10 "Allocated resources:"

# Crear deployment con recursos definidos
kubectl create deployment resource-app --image=nginx:alpine --replicas=1
kubectl set resources deployment resource-app --requests=cpu=100m,memory=128Mi

# Intentar escalar a muchas réplicas
kubectl scale deployment resource-app --replicas=20

# Ver si todos los pods se crearon o hay algunos pendientes
kubectl get pods -l app=resource-app

# Ver eventos si hay pods pendientes
kubectl get events --field-selector reason=FailedScheduling

# Limpiar
kubectl delete deployment resource-app
```

## Verificación

Antes de continuar al siguiente laboratorio, asegúrate de poder marcar todos estos puntos:

- [ ] Puedo verificar el número actual de réplicas de un Deployment
- [ ] Puedo escalar un Deployment usando `kubectl scale`
- [ ] Puedo observar la creación de nuevos Pods con `kubectl get pods -w`
- [ ] Puedo reducir el número de réplicas (scale down)
- [ ] Puedo escalar modificando el archivo YAML y aplicándolo con `kubectl apply`
- [ ] Puedo escalar a 0 réplicas sin eliminar el Deployment
- [ ] Entiendo la diferencia entre escalamiento horizontal y vertical
- [ ] Puedo ver los eventos de escalamiento con `kubectl describe deployment`

## Resumen de Comandos

| Comando                                                                   | Descripción                                  |
| ------------------------------------------------------------------------- | -------------------------------------------- |
| `kubectl scale deployment <nombre> --replicas=<N>`                        | Escalar un deployment a N réplicas           |
| `kubectl scale deployment <nombre> --replicas=<N> --current-replicas=<M>` | Escalar solo si actualmente tiene M réplicas |
| `kubectl get deployment <nombre>`                                         | Ver estado del deployment (incluye réplicas) |
| `kubectl get deployment <nombre> -o jsonpath='{.spec.replicas}'`          | Obtener solo el número de réplicas           |
| `kubectl get pods -l <label>=<valor> -w`                                  | Observar pods en tiempo real                 |
| `kubectl get pods -o wide`                                                | Ver pods con información de nodo             |
| `kubectl patch deployment <nombre> -p '{"spec":{"replicas":N}}'`          | Escalar usando patch                         |
| `kubectl apply -f <archivo.yaml>`                                         | Aplicar cambios desde archivo YAML           |
| `kubectl describe deployment <nombre>`                                    | Ver detalles y eventos del deployment        |

## Conceptos Aprendidos

1. **Escalamiento Horizontal**: Aumentar/disminuir el número de réplicas de una aplicación
2. **kubectl scale**: Comando imperativo para cambiar réplicas rápidamente
3. **Escalamiento Declarativo**: Modificar el YAML y aplicarlo para mantener infraestructura como código
4. **Scale to Zero**: Escalar a 0 réplicas pausa la aplicación sin eliminar el Deployment
5. **Observación en Tiempo Real**: Usar `-w` (watch) para ver cambios en vivo
6. **Eventos de Escalamiento**: Kubernetes registra todos los cambios de escala en los eventos

## Solución

Consulta el directorio `solution/` para ver los scripts con todos los comandos y las salidas esperadas.

## Navegación

- **Anterior**: [Lab 04: Pods y Deployments](../lab-04-pods-deployments/README.md)
- **Siguiente**: [Lab 06: YAML Manifests](../../modulo-05-kubectl-yaml/lab-06-yaml-manifests/README.md)
