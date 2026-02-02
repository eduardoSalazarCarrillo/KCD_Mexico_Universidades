# Lab 03: Cluster Exploration - Salidas Esperadas

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

## Paso 2: Explorar los Nodos del Clúster

### kubectl get nodes

```
$ kubectl get nodes
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   1d    v1.28.3
```

**Explicación de columnas**:

| Columna   | Descripción                                 |
| --------- | ------------------------------------------- |
| `NAME`    | Nombre del nodo                             |
| `STATUS`  | Estado del nodo (Ready = funcionando)       |
| `ROLES`   | Rol del nodo (control-plane = nodo maestro) |
| `AGE`     | Tiempo desde que el nodo se unió al clúster |
| `VERSION` | Versión de Kubernetes en el nodo            |

### kubectl get nodes -o wide

```
$ kubectl get nodes -o wide
NAME       STATUS   ROLES           AGE   VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
minikube   Ready    control-plane   1d    v1.28.3   192.168.49.2   <none>        Ubuntu 22.04.3 LTS   5.15.0-91-generic   docker://24.0.7
```

## Paso 3: Inspeccionar un Nodo en Detalle

### kubectl describe node minikube (extracto)

```
$ kubectl describe node minikube
Name:               minikube
Roles:              control-plane
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=minikube
                    kubernetes.io/os=linux
                    minikube.k8s.io/commit=...
                    minikube.k8s.io/name=minikube
                    minikube.k8s.io/updated_at=...
                    minikube.k8s.io/version=v1.32.0
                    node-role.kubernetes.io/control-plane=
                    node.kubernetes.io/exclude-from-external-load-balancers=
Annotations:        kubeadm.alpha.kubernetes.io/cri-socket: unix:///var/run/cri-dockerd.sock
                    node.alpha.kubernetes.io/ttl: 0
                    volumes.kubernetes.io/controller-managed-attach-detach: true
CreationTimestamp:  ...
Taints:             <none>
Unschedulable:      false
Lease:
  HolderIdentity:  minikube
  AcquireTime:     <unset>
  RenewTime:       ...
Conditions:
  Type             Status  LastHeartbeatTime  LastTransitionTime  Reason                       Message
  ----             ------  -----------------  ------------------  ------                       -------
  MemoryPressure   False   ...                ...                 KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure     False   ...                ...                 KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure      False   ...                ...                 KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready            True    ...                ...                 KubeletReady                 kubelet is posting ready status
...
```

### Sección Capacity (dentro de describe node)

```
Capacity:
  cpu:                4
  ephemeral-storage:  61255492Ki
  hugepages-1Gi:      0
  hugepages-2Mi:      0
  memory:             8145320Ki
  pods:               110
Allocatable:
  cpu:                4
  ephemeral-storage:  61255492Ki
  hugepages-1Gi:      0
  hugepages-2Mi:      0
  memory:             8145320Ki
  pods:               110
```

## Paso 4: Explorar los Namespaces

### kubectl get namespaces

```
$ kubectl get namespaces
NAME                   STATUS   AGE
default                Active   1d
kube-node-lease        Active   1d
kube-public            Active   1d
kube-system            Active   1d
kubernetes-dashboard   Active   1d
```

> **Nota**: El namespace `kubernetes-dashboard` solo aparece si has ejecutado `minikube dashboard` previamente.

## Paso 5: Explorar el Namespace kube-system

### kubectl get pods -n kube-system

```
$ kubectl get pods -n kube-system
NAME                               READY   STATUS    RESTARTS   AGE
coredns-5dd5756b68-8kxj2           1/1     Running   0          1d
etcd-minikube                      1/1     Running   0          1d
kube-apiserver-minikube            1/1     Running   0          1d
kube-controller-manager-minikube   1/1     Running   0          1d
kube-proxy-7hkxl                   1/1     Running   0          1d
kube-scheduler-minikube            1/1     Running   0          1d
storage-provisioner                1/1     Running   1          1d
```

**Explicación de los pods**:

| Pod                         | Componente         | Función                         |
| --------------------------- | ------------------ | ------------------------------- |
| `coredns-*`                 | CoreDNS            | Servidor DNS del clúster        |
| `etcd-minikube`             | etcd               | Base de datos clave-valor       |
| `kube-apiserver-minikube`   | API Server         | Punto de entrada de la API      |
| `kube-controller-manager-*` | Controller Manager | Ejecuta los controladores       |
| `kube-proxy-*`              | kube-proxy         | Gestiona reglas de red          |
| `kube-scheduler-minikube`   | Scheduler          | Asigna pods a nodos             |
| `storage-provisioner`       | Minikube Addon     | Provisiona almacenamiento local |

### kubectl get pods -n kube-system -o wide

```
$ kubectl get pods -n kube-system -o wide
NAME                               READY   STATUS    RESTARTS   AGE   IP             NODE       NOMINATED NODE   READINESS GATES
coredns-5dd5756b68-8kxj2           1/1     Running   0          1d    10.244.0.3     minikube   <none>           <none>
etcd-minikube                      1/1     Running   0          1d    192.168.49.2   minikube   <none>           <none>
kube-apiserver-minikube            1/1     Running   0          1d    192.168.49.2   minikube   <none>           <none>
kube-controller-manager-minikube   1/1     Running   0          1d    192.168.49.2   minikube   <none>           <none>
kube-proxy-7hkxl                   1/1     Running   0          1d    192.168.49.2   minikube   <none>           <none>
kube-scheduler-minikube            1/1     Running   0          1d    192.168.49.2   minikube   <none>           <none>
```

## Paso 6: Inspeccionar el API Server

### kubectl describe pod -n kube-system -l component=kube-apiserver (extracto)

```
$ kubectl describe pod -n kube-system -l component=kube-apiserver
Name:                 kube-apiserver-minikube
Namespace:            kube-system
Priority:             2000001000
Priority Class Name:  system-node-critical
Service Account:      kube-apiserver
Node:                 minikube/192.168.49.2
Start Time:           ...
Labels:               component=kube-apiserver
                      tier=control-plane
Annotations:          kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint: 192.168.49.2:8443
Status:               Running
...
Containers:
  kube-apiserver:
    Container ID:  docker://...
    Image:         registry.k8s.io/kube-apiserver:v1.28.3
    Image ID:      docker-pullable://registry.k8s.io/kube-apiserver@sha256:...
    Port:          <none>
    Host Port:     <none>
    Command:
      kube-apiserver
      --advertise-address=192.168.49.2
      --allow-privileged=true
      --authorization-mode=Node,RBAC
      --client-ca-file=/var/lib/minikube/certs/ca.crt
      --enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,...
      --enable-bootstrap-token-auth=true
      --etcd-cafile=/var/lib/minikube/certs/etcd/ca.crt
      --etcd-certfile=/var/lib/minikube/certs/apiserver-etcd-client.crt
      --etcd-keyfile=/var/lib/minikube/certs/apiserver-etcd-client.key
      --etcd-servers=https://127.0.0.1:2379
      ...
```

## Paso 7: Inspeccionar etcd

### kubectl describe pod -n kube-system -l component=etcd | grep Image:

```
$ kubectl describe pod -n kube-system -l component=etcd | grep Image:
    Image:         registry.k8s.io/etcd:3.5.9-0
    Image ID:      docker-pullable://registry.k8s.io/etcd@sha256:...
```

## Paso 8: Inspeccionar el Scheduler

### kubectl logs -n kube-system -l component=kube-scheduler --tail=10

```
$ kubectl logs -n kube-system -l component=kube-scheduler --tail=10
I0115 10:30:00.123456       1 leaderelection.go:250] attempting to acquire leader lease kube-system/kube-scheduler...
I0115 10:30:00.234567       1 leaderelection.go:260] successfully acquired lease kube-system/kube-scheduler
...
```

## Paso 10: Inspeccionar kube-proxy

### kubectl get daemonset -n kube-system kube-proxy

```
$ kubectl get daemonset -n kube-system kube-proxy
NAME         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
kube-proxy   1         1         1       1            1           kubernetes.io/os=linux   1d
```

**Explicación de columnas**:

| Columna      | Descripción                         |
| ------------ | ----------------------------------- |
| `DESIRED`    | Número deseado de pods (1 por nodo) |
| `CURRENT`    | Número actual de pods               |
| `READY`      | Pods listos                         |
| `UP-TO-DATE` | Pods actualizados                   |
| `AVAILABLE`  | Pods disponibles                    |

## Paso 11: Inspeccionar CoreDNS

### kubectl get deployment -n kube-system coredns

```
$ kubectl get deployment -n kube-system coredns
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
coredns   1/1     1            1           1d
```

### kubectl get configmap -n kube-system coredns -o yaml (extracto)

```
$ kubectl get configmap -n kube-system coredns -o yaml
apiVersion: v1
data:
  Corefile: |
    .:53 {
        errors
        health {
           lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        forward . /etc/resolv.conf {
           max_concurrent 1000
        }
        cache 30
        loop
        reload
        loadbalance
    }
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
```

## Paso 12: Inspeccionar kubelet (dentro del nodo)

### minikube ssh + systemctl status kubelet

```
$ minikube ssh
                         _             _
            _         _ ( )           ( )
  ___ ___  (_)  ___  (_)| |/')  _   _ | |_      __
/' _ ` _ `\| |/' _ `\| || , <  ( ) ( )| '_`\  /'__`\
| ( ) ( ) || || ( ) || || |\`\ | (_) || |_) )(  ___/
(_) (_) (_)(_)(_) (_)(_)(_) (_)`\___/'(_,__/'`\____)

$ systemctl status kubelet
● kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/lib/systemd/system/kubelet.service; enabled; vendor preset: enabled)
    Drop-In: /etc/systemd/system/kubelet.service.d
             └─10-kubeadm.conf
     Active: active (running) since ...
       Docs: https://kubernetes.io/docs/home/
   Main PID: 1234 (kubelet)
      Tasks: 15 (limit: 9830)
     Memory: 45.6M
        CPU: 1min 23s
     CGroup: /system.slice/kubelet.service
             └─1234 /var/lib/minikube/binaries/v1.28.3/kubelet ...

$ exit
```

## Paso 13: Explorar la API de Kubernetes

### kubectl api-resources (extracto)

```
$ kubectl api-resources | head -20
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
...
```

**Explicación de columnas**:

| Columna      | Descripción                            |
| ------------ | -------------------------------------- |
| `NAME`       | Nombre del recurso (plural)            |
| `SHORTNAMES` | Abreviaturas para usar con kubectl     |
| `APIVERSION` | Versión de API donde está el recurso   |
| `NAMESPACED` | Si el recurso pertenece a un namespace |
| `KIND`       | Tipo del recurso (singular)            |

### kubectl api-versions

```
$ kubectl api-versions
admissionregistration.k8s.io/v1
apiextensions.k8s.io/v1
apiregistration.k8s.io/v1
apps/v1
authentication.k8s.io/v1
authorization.k8s.io/v1
autoscaling/v1
autoscaling/v2
batch/v1
certificates.k8s.io/v1
coordination.k8s.io/v1
discovery.k8s.io/v1
events.k8s.io/v1
flowcontrol.apiserver.k8s.io/v1beta3
networking.k8s.io/v1
node.k8s.io/v1
policy/v1
rbac.authorization.k8s.io/v1
scheduling.k8s.io/v1
storage.k8s.io/v1
v1
```

## Paso 14: Acceder Directamente a la API

### kubectl proxy + curl

```
$ kubectl proxy &
Starting to serve on 127.0.0.1:8001

$ curl -s http://localhost:8001/api
{
  "kind": "APIVersions",
  "versions": [
    "v1"
  ],
  "serverAddressByClientCIDRs": [
    {
      "clientCIDR": "0.0.0.0/0",
      "serverAddress": "192.168.49.2:8443"
    }
  ]
}

$ curl -s http://localhost:8001/api/v1/namespaces | head -30
{
  "kind": "NamespaceList",
  "apiVersion": "v1",
  "metadata": {
    "resourceVersion": "12345"
  },
  "items": [
    {
      "metadata": {
        "name": "default",
        ...
      }
    },
    {
      "metadata": {
        "name": "kube-node-lease",
        ...
      }
    },
    ...
  ]
}
```

## Ejercicios Adicionales

### Ejercicio 4: Eventos del clúster

```
$ kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -10
NAMESPACE     LAST SEEN   TYPE      REASON                    OBJECT                                MESSAGE
kube-system   5m          Normal    Scheduled                 pod/coredns-5dd5756b68-8kxj2          Successfully assigned...
kube-system   5m          Normal    Pulled                    pod/coredns-5dd5756b68-8kxj2          Container image already present
kube-system   5m          Normal    Created                   pod/coredns-5dd5756b68-8kxj2          Created container coredns
kube-system   5m          Normal    Started                   pod/coredns-5dd5756b68-8kxj2          Started container coredns
...
```

### Ejercicio 5: Salud de los componentes

```
$ kubectl get --raw='/readyz?verbose'
[+]ping ok
[+]log ok
[+]etcd ok
[+]etcd-readiness ok
[+]informer-sync ok
[+]poststarthook/start-kube-apiserver-admission-initializer ok
[+]poststarthook/generic-apiserver-start-informers ok
[+]poststarthook/start-apiextensions-informers ok
[+]poststarthook/start-apiextensions-controllers ok
...
readyz check passed
```

## Resumen

Si todas tus salidas son similares a las mostradas en este documento, has completado exitosamente el Lab 03.

Las diferencias menores que puedes esperar:

- **Versiones**: Pueden variar según la versión de Minikube/Kubernetes
- **IPs**: La IP del nodo puede ser diferente
- **Nombres de pods**: Los sufijos aleatorios (como `-8kxj2`) serán diferentes
- **Timestamps y AGE**: Dependen de cuándo creaste el clúster
- **Recursos del nodo**: CPU y memoria dependen de tu sistema
- **Número de eventos**: Varía según la actividad del clúster

### Componentes Clave Identificados

| Componente              | Tipo           | Namespace   | Rol                        |
| ----------------------- | -------------- | ----------- | -------------------------- |
| kube-apiserver          | Static Pod     | kube-system | Punto de entrada de la API |
| etcd                    | Static Pod     | kube-system | Base de datos del clúster  |
| kube-scheduler          | Static Pod     | kube-system | Asigna pods a nodos        |
| kube-controller-manager | Static Pod     | kube-system | Ejecuta controladores      |
| kube-proxy              | DaemonSet      | kube-system | Gestiona reglas de red     |
| CoreDNS                 | Deployment     | kube-system | DNS interno del clúster    |
| kubelet                 | System Service | N/A (nodo)  | Agente del nodo            |
