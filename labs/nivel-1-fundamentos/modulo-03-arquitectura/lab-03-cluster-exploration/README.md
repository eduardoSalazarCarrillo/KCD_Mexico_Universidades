# Lab 03: Cluster Exploration

## Objetivo

Explorar los componentes internos de un clúster de Kubernetes y entender cómo funcionan juntos.

## Prerrequisitos

- Lab 02 completado (Minikube funcionando)
- Clúster de Minikube ejecutándose (`minikube status` debe mostrar "Running")

## Duración

30 minutos

## Conceptos Clave

Antes de comenzar, es importante entender estos conceptos:

| Concepto               | Descripción                                                                                                     |
| ---------------------- | --------------------------------------------------------------------------------------------------------------- |
| **Control Plane**      | Conjunto de componentes que toman decisiones globales sobre el clúster (scheduling, detección de eventos, etc.) |
| **Worker Node**        | Máquina donde se ejecutan las aplicaciones (pods). Contiene kubelet, kube-proxy y el runtime de contenedores.   |
| **kube-apiserver**     | Expone la API de Kubernetes. Es el punto de entrada para todas las operaciones administrativas.                 |
| **etcd**               | Base de datos clave-valor que almacena todo el estado del clúster.                                              |
| **kube-scheduler**     | Observa pods sin nodo asignado y selecciona el mejor nodo para ejecutarlos.                                     |
| **controller-manager** | Ejecuta los procesos de control (replication controller, endpoints controller, etc.)                            |
| **kubelet**            | Agente que corre en cada nodo. Se asegura de que los contenedores estén corriendo en un Pod.                    |
| **kube-proxy**         | Proxy de red que corre en cada nodo. Mantiene las reglas de red para permitir comunicación hacia los Pods.      |
| **CoreDNS**            | Servidor DNS del clúster que permite resolución de nombres de servicios.                                        |
| **Namespace**          | Forma de dividir los recursos del clúster entre múltiples usuarios o proyectos. Proporciona aislamiento lógico. |

### Arquitectura de Kubernetes

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              CONTROL PLANE                                      │
│  ┌─────────────────────────────────────────────────────────────────────────────┐│
│  │                                                                             ││
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐  ││
│  │  │  kube-apiserver │  │      etcd       │  │      kube-scheduler         │  ││
│  │  │                 │  │                 │  │                             │  ││
│  │  │  - Punto de     │  │  - Base de      │  │  - Asigna pods a nodos      │  ││
│  │  │    entrada API  │  │    datos K/V    │  │  - Considera recursos,      │  ││
│  │  │  - Autenticación│  │  - Almacena     │  │    afinidad, taints         │  ││
│  │  │  - Autorización │  │    estado       │  │                             │  ││
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘  ││
│  │                                                                             ││
│  │  ┌─────────────────────────────────────────────────────────────────────┐    ││
│  │  │                   kube-controller-manager                           │    ││
│  │  │                                                                     │    ││
│  │  │  - Node Controller: Detecta cuando un nodo cae                      │    ││
│  │  │  - Replication Controller: Mantiene el número correcto de pods      │    ││
│  │  │  - Endpoints Controller: Llena el objeto Endpoints                  │    ││
│  │  │  - Service Account & Token Controllers                              │    ││
│  │  └─────────────────────────────────────────────────────────────────────┘    ││
│  │                                                                             ││
│  └─────────────────────────────────────────────────────────────────────────────┘│
│                                      │                                          │
│                                      │ API calls                                │
│                                      ▼                                          │
└─────────────────────────────────────────────────────────────────────────────────┘

                                       │
                                       │
                                       ▼

┌─────────────────────────────────────────────────────────────────────────────────┐
│                              WORKER NODE(S)                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐│
│  │                                                                             ││
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐  ││
│  │  │     kubelet     │  │   kube-proxy    │  │   Container Runtime         │  ││
│  │  │                 │  │                 │  │   (containerd/Docker)       │  ││
│  │  │  - Registra el  │  │  - Reglas de    │  │                             │  ││
│  │  │    nodo con     │  │    iptables/    │  │  - Ejecuta los              │  ││
│  │  │    API Server   │  │    IPVS         │  │    contenedores             │  ││
│  │  │  - Ejecuta pods │  │  - Load balance │  │                             │  ││
│  │  │  - Reporta      │  │    de Services  │  │                             │  ││
│  │  │    estado       │  │                 │  │                             │  ││
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘  ││
│  │                                                                             ││
│  │  ┌───────────────────────────────────────────────────────────────────────┐  ││
│  │  │                              PODS                                     │  ││
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │  ││
│  │  │  │    Pod A    │  │    Pod B    │  │    Pod C    │  │     ...     │   │  ││
│  │  │  │ (tu app)    │  │ (tu app)    │  │ (tu app)    │  │             │   │  ││
│  │  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘   │  ││
│  │  └───────────────────────────────────────────────────────────────────────┘  ││
│  │                                                                             ││
│  └─────────────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Flujo de Comunicación

```
Usuario/CI/CD
     │
     │ kubectl apply -f deployment.yaml
     ▼
┌──────────────┐
│ kube-apiserver│──────────────────────┐
└──────────────┘                       │
     │                                 │ Almacena
     │ Notifica                        │ estado
     ▼                                 ▼
┌──────────────┐                 ┌──────────┐
│  scheduler   │                 │   etcd   │
└──────────────┘                 └──────────┘
     │
     │ Asigna pod a nodo
     ▼
┌──────────────┐
│   kubelet    │ (en el nodo asignado)
└──────────────┘
     │
     │ Ejecuta contenedor
     ▼
┌──────────────┐
│   Pod        │
└──────────────┘
```

## Instrucciones

### Paso 1: Verificar que el Clúster está Funcionando

Antes de explorar, asegúrate de que tu clúster está corriendo:

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

### Paso 2: Explorar los Nodos del Clúster

En Kubernetes, un **nodo** es una máquina (física o virtual) donde corren los pods.

```bash
# Listar nodos del clúster
kubectl get nodes
```

**Salida esperada**:

```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   1d    v1.28.3
```

> **Nota**: En Minikube, solo hay un nodo que actúa como Control Plane y Worker al mismo tiempo.

Ver más detalles del nodo:

```bash
# Información extendida
kubectl get nodes -o wide
```

**Salida esperada**:

```
NAME       STATUS   ROLES           AGE   VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
minikube   Ready    control-plane   1d    v1.28.3   192.168.49.2   <none>        Ubuntu 22.04.3 LTS   5.15.0-91-generic  docker://24.0.7
```

**Explicación de columnas**:

| Columna             | Descripción                                       |
| ------------------- | ------------------------------------------------- |
| `INTERNAL-IP`       | IP del nodo dentro de la red del clúster          |
| `EXTERNAL-IP`       | IP externa (solo en clouds, `<none>` en Minikube) |
| `OS-IMAGE`          | Sistema operativo del nodo                        |
| `KERNEL-VERSION`    | Versión del kernel de Linux                       |
| `CONTAINER-RUNTIME` | Runtime usado para contenedores                   |

### Paso 3: Inspeccionar un Nodo en Detalle

```bash
# Ver información detallada del nodo
kubectl describe node minikube
```

Este comando muestra mucha información. Observa estas secciones importantes:

**Sección Conditions** - Estado actual del nodo:

```
Conditions:
  Type             Status  ...  Reason                       Message
  ----             ------       ------                       -------
  MemoryPressure   False        KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure     False        KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure      False        KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready            True         KubeletReady                 kubelet is posting ready status
```

**Sección Capacity vs Allocatable** - Recursos del nodo:

```
Capacity:
  cpu:                4
  memory:             8145320Ki
  pods:               110
Allocatable:
  cpu:                4
  memory:             8145320Ki
  pods:               110
```

**Sección Pods** - Pods actualmente corriendo en el nodo:

```
Non-terminated Pods:          (8 in total)
  Namespace    Name                                CPU Requests  CPU Limits  Memory Requests  Memory Limits
  ---------    ----                                ------------  ----------  ---------------  -------------
  kube-system  coredns-5dd5756b68-xxxxx            100m (2%)     0 (0%)      70Mi (0%)        170Mi (2%)
  ...
```

### Paso 4: Explorar los Namespaces

Los namespaces dividen el clúster en entornos virtuales separados:

```bash
# Listar todos los namespaces
kubectl get namespaces
```

**Salida esperada**:

```
NAME                   STATUS   AGE
default                Active   1d
kube-node-lease        Active   1d
kube-public            Active   1d
kube-system            Active   1d
kubernetes-dashboard   Active   1d
```

**Explicación de namespaces del sistema**:

| Namespace              | Descripción                                                                             |
| ---------------------- | --------------------------------------------------------------------------------------- |
| `default`              | Namespace por defecto donde se crean recursos si no especificas otro                    |
| `kube-system`          | Contiene los componentes del sistema de Kubernetes                                      |
| `kube-public`          | Legible por todos los usuarios, incluso no autenticados. Reservado para uso del sistema |
| `kube-node-lease`      | Contiene objetos Lease para el heartbeat de los nodos                                   |
| `kubernetes-dashboard` | Contiene el dashboard web (si está habilitado)                                          |

### Paso 5: Explorar el Namespace kube-system

Aquí es donde viven los componentes críticos de Kubernetes:

```bash
# Ver todos los pods del sistema
kubectl get pods -n kube-system
```

**Salida esperada**:

```
NAME                               READY   STATUS    RESTARTS   AGE
coredns-5dd5756b68-xxxxx           1/1     Running   0          1d
etcd-minikube                      1/1     Running   0          1d
kube-apiserver-minikube            1/1     Running   0          1d
kube-controller-manager-minikube   1/1     Running   0          1d
kube-proxy-xxxxx                   1/1     Running   0          1d
kube-scheduler-minikube            1/1     Running   0          1d
storage-provisioner                1/1     Running   0          1d
```

Ver con más detalle:

```bash
# Información extendida de los pods del sistema
kubectl get pods -n kube-system -o wide
```

**Salida esperada**:

```
NAME                               READY   STATUS    RESTARTS   AGE   IP             NODE
coredns-5dd5756b68-xxxxx           1/1     Running   0          1d    10.244.0.3     minikube
etcd-minikube                      1/1     Running   0          1d    192.168.49.2   minikube
kube-apiserver-minikube            1/1     Running   0          1d    192.168.49.2   minikube
kube-controller-manager-minikube   1/1     Running   0          1d    192.168.49.2   minikube
kube-proxy-xxxxx                   1/1     Running   0          1d    192.168.49.2   minikube
kube-scheduler-minikube            1/1     Running   0          1d    192.168.49.2   minikube
```

> **Observa**: Los componentes del Control Plane (etcd, apiserver, controller-manager, scheduler) tienen la IP del nodo (`192.168.49.2`), mientras que CoreDNS tiene una IP de pod (`10.244.0.x`).

### Paso 6: Inspeccionar el API Server

El API Server es el punto de entrada a Kubernetes:

```bash
# Ver detalles del pod del API Server
kubectl describe pod -n kube-system -l component=kube-apiserver
```

Observa en la salida:

- **Image**: La imagen de contenedor que usa
- **Port**: El puerto donde escucha (generalmente 6443)
- **Args**: Los argumentos con los que se inició

```bash
# Ver los logs del API Server
kubectl logs -n kube-system -l component=kube-apiserver --tail=20
```

### Paso 7: Inspeccionar etcd

etcd es la base de datos del clúster:

```bash
# Ver detalles del pod de etcd
kubectl describe pod -n kube-system -l component=etcd
```

Busca información sobre:

- **Volúmenes montados**: Donde se almacenan los datos
- **Puerto**: Generalmente 2379 (client) y 2380 (peer)

```bash
# Ver logs de etcd
kubectl logs -n kube-system -l component=etcd --tail=20
```

### Paso 8: Inspeccionar el Scheduler

El scheduler decide en qué nodo correr cada pod:

```bash
# Ver detalles del scheduler
kubectl describe pod -n kube-system -l component=kube-scheduler
```

```bash
# Ver logs del scheduler
kubectl logs -n kube-system -l component=kube-scheduler --tail=20
```

### Paso 9: Inspeccionar el Controller Manager

Ejecuta los controladores que regulan el estado del clúster:

```bash
# Ver detalles del controller-manager
kubectl describe pod -n kube-system -l component=kube-controller-manager
```

```bash
# Ver logs del controller-manager
kubectl logs -n kube-system -l component=kube-controller-manager --tail=20
```

### Paso 10: Inspeccionar kube-proxy

kube-proxy maneja las reglas de red en cada nodo:

```bash
# Ver el DaemonSet de kube-proxy
kubectl get daemonset -n kube-system kube-proxy
```

**Salida esperada**:

```
NAME         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
kube-proxy   1         1         1       1            1           <none>          1d
```

> **Nota**: Un DaemonSet asegura que un pod corra en cada nodo del clúster.

```bash
# Ver detalles del DaemonSet
kubectl describe daemonset -n kube-system kube-proxy
```

### Paso 11: Inspeccionar CoreDNS

CoreDNS proporciona resolución de nombres dentro del clúster:

```bash
# Ver el deployment de CoreDNS
kubectl get deployment -n kube-system coredns
```

**Salida esperada**:

```
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
coredns   1/1     1            1           1d
```

```bash
# Ver la configuración de CoreDNS
kubectl get configmap -n kube-system coredns -o yaml
```

### Paso 12: Inspeccionar kubelet (desde dentro del nodo)

El kubelet corre como servicio en el nodo, no como pod:

```bash
# Conectarse al nodo de Minikube
minikube ssh
```

Dentro del nodo:

```bash
# Ver estado del kubelet
systemctl status kubelet

# Ver configuración del kubelet
cat /var/lib/kubelet/config.yaml | head -30

# Ver procesos de contenedores corriendo
docker ps

# Salir del nodo
exit
```

### Paso 13: Explorar la API de Kubernetes

La API de Kubernetes expone todos los recursos disponibles:

```bash
# Ver todos los tipos de recursos disponibles
kubectl api-resources | head -30
```

**Salida esperada (extracto)**:

```
NAME                              SHORTNAMES   APIVERSION                        NAMESPACED   KIND
bindings                                       v1                                true         Binding
configmaps                        cm           v1                                true         ConfigMap
endpoints                         ep           v1                                true         Endpoints
events                            ev           v1                                true         Event
namespaces                        ns           v1                                false        Namespace
nodes                             no           v1                                false        Node
pods                              po           v1                                true         Pod
...
```

```bash
# Ver las versiones de API disponibles
kubectl api-versions
```

**Salida esperada**:

```
admissionregistration.k8s.io/v1
apiextensions.k8s.io/v1
apiregistration.k8s.io/v1
apps/v1
...
v1
```

### Paso 14: Acceder Directamente a la API

```bash
# Iniciar un proxy a la API (ejecutar en una terminal)
kubectl proxy &
```

**Salida esperada**:

```
Starting to serve on 127.0.0.1:8001
```

```bash
# Consultar la API directamente
curl http://localhost:8001/api/v1/namespaces
```

```bash
# Ver información del clúster via API
curl http://localhost:8001/api
```

```bash
# Detener el proxy
pkill -f "kubectl proxy"
```

## Ejercicios Adicionales

### Ejercicio 1: Encontrar la Versión de etcd

```bash
# Pista: busca en la descripción del pod de etcd
kubectl describe pod -n kube-system -l component=etcd | grep Image:
```

### Ejercicio 2: Identificar Cuántos Pods de CoreDNS Hay

```bash
# Ver las réplicas de CoreDNS
kubectl get deployment -n kube-system coredns

# ¿Por qué solo hay 1 réplica en Minikube?
# En producción típicamente hay 2+ para alta disponibilidad
```

### Ejercicio 3: Revisar Logs del Controller Manager

```bash
# Ver los últimos 50 logs del controller-manager
kubectl logs -n kube-system -l component=kube-controller-manager --tail=50

# Buscar mensajes relacionados con "sync" o "controller"
kubectl logs -n kube-system -l component=kube-controller-manager | grep -i "controller" | tail -20
```

### Ejercicio 4: Explorar Eventos del Clúster

```bash
# Ver eventos recientes en todo el clúster
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -20

# Ver eventos solo del namespace kube-system
kubectl get events -n kube-system --sort-by='.lastTimestamp'
```

### Ejercicio 5: Verificar la Salud de los Componentes

```bash
# Verificar el estado de los componentes del control plane
kubectl get componentstatuses
```

> **Nota**: Este comando está deprecado en versiones nuevas, pero sigue funcionando en muchos clústeres.

```bash
# Alternativa moderna: verificar endpoints de salud
kubectl get --raw='/readyz?verbose'
kubectl get --raw='/livez?verbose'
kubectl get --raw='/healthz?verbose'
```

## Verificación

Antes de continuar al siguiente laboratorio, asegúrate de poder marcar todos estos puntos:

- [ ] Puedo listar y describir nodos con `kubectl get nodes` y `kubectl describe node`
- [ ] Entiendo la diferencia entre Control Plane y Worker Nodes
- [ ] Puedo listar los namespaces y entiendo el propósito de `kube-system`
- [ ] Identifico los pods del Control Plane: api-server, etcd, scheduler, controller-manager
- [ ] Sé ver logs de componentes con `kubectl logs -n kube-system`
- [ ] Entiendo que kube-proxy corre como DaemonSet (uno por nodo)
- [ ] Entiendo que kubelet corre como servicio del sistema, no como pod
- [ ] Puedo acceder al nodo de Minikube con `minikube ssh`
- [ ] Puedo explorar la API con `kubectl api-resources` y `kubectl api-versions`
- [ ] Entiendo el flujo de comunicación cuando se crea un recurso

## Resumen de Comandos

| Comando                                          | Descripción                            |
| ------------------------------------------------ | -------------------------------------- |
| `kubectl get nodes`                              | Listar nodos del clúster               |
| `kubectl get nodes -o wide`                      | Listar nodos con información extendida |
| `kubectl describe node <nombre>`                 | Ver detalles de un nodo                |
| `kubectl get namespaces`                         | Listar namespaces                      |
| `kubectl get pods -n <namespace>`                | Listar pods en un namespace            |
| `kubectl get pods -n kube-system`                | Ver pods del sistema                   |
| `kubectl describe pod -n <ns> -l <label>`        | Describir pods por label               |
| `kubectl logs -n <ns> -l <label>`                | Ver logs de pods por label             |
| `kubectl get daemonset -n kube-system`           | Listar DaemonSets del sistema          |
| `kubectl get deployment -n kube-system`          | Listar Deployments del sistema         |
| `kubectl get configmap -n <ns> <nombre> -o yaml` | Ver ConfigMap en formato YAML          |
| `kubectl api-resources`                          | Listar todos los tipos de recursos     |
| `kubectl api-versions`                           | Listar versiones de API disponibles    |
| `kubectl get events -A`                          | Ver eventos de todos los namespaces    |
| `kubectl proxy`                                  | Iniciar proxy a la API                 |
| `minikube ssh`                                   | Conectarse al nodo de Minikube         |

## Solución

Consulta el directorio `solution/` para ver los scripts con todos los comandos y las salidas esperadas.

## Navegación

- **Anterior**: [Lab 02: Minikube Setup](../../modulo-02-intro-kubernetes/lab-02-minikube-setup/README.md)
- **Siguiente**: [Lab 04: Pods y Deployments](../../../nivel-2-uso-basico/modulo-04-objetos-fundamentales/lab-04-pods-deployments/README.md)
