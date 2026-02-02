# Lab 02: Minikube Setup - Salidas Esperadas

Este documento muestra las salidas esperadas de cada comando del laboratorio para que puedas verificar que todo funciona correctamente.

## Paso 1: Verificar Docker

### docker version

```
$ docker version
Client: Docker Engine - Community
 Version:           24.0.7
 API version:       1.43
 ...

Server: Docker Engine - Community
 Engine:
  Version:          24.0.7
  ...
```

### docker info

```
$ docker info
Client: Docker Engine - Community
 Version:    24.0.7
 Context:    default
 ...

Server:
 Containers: 5
  Running: 2
  Paused: 0
  Stopped: 3
 Images: 10
 Server Version: 24.0.7
 ...
```

## Paso 3: Verificar Minikube

### minikube version

```
$ minikube version
minikube version: v1.32.0
commit: 8220a6eb95f0a4d75f7f2d7b14cef975f050512d
```

## Paso 5: Verificar kubectl

### kubectl version --client

```
$ kubectl version --client
Client Version: v1.29.0
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
```

## Paso 6: Iniciar el Clúster

### minikube start --driver=docker

```
$ minikube start --driver=docker
😄  minikube v1.32.0 on Ubuntu 22.04
✨  Using the docker driver based on user configuration
📌  Using Docker driver with root privileges
👍  Starting control plane node minikube in cluster minikube
🚜  Pulling base image ...
🔥  Creating docker container (CPUs=2, Memory=4000MB) ...
🐳  Preparing Kubernetes v1.28.3 on Docker 24.0.7 ...
    ▪ Generating certificates and keys ...
    ▪ Booting up control plane ...
    ▪ Configuring RBAC rules ...
🔗  Configuring bridge CNI (Container Networking Interface) ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Enabled addons: storage-provisioner, default-storageclass
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

> **Nota**: La primera vez que ejecutas `minikube start` puede tomar varios minutos mientras descarga las imágenes necesarias.

## Paso 7: Verificar Estado del Clúster

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

**Explicación de campos**:

| Campo                    | Descripción                              |
| ------------------------ | ---------------------------------------- |
| `type: Control Plane`    | Este nodo actúa como Control Plane       |
| `host: Running`          | La VM/contenedor del nodo está corriendo |
| `kubelet: Running`       | El agente de Kubernetes está activo      |
| `apiserver: Running`     | El servidor de API está respondiendo     |
| `kubeconfig: Configured` | kubectl está configurado para conectarse |

## Paso 8: Verificar Conexión con kubectl

### kubectl cluster-info

```
$ kubectl cluster-info
Kubernetes control plane is running at https://192.168.49.2:8443
CoreDNS is running at https://192.168.49.2:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

> **Nota**: La IP (192.168.49.2) puede variar según tu configuración.

### kubectl get nodes

```
$ kubectl get nodes
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   5m    v1.28.3
```

**Explicación de columnas**:

| Columna   | Descripción                                 |
| --------- | ------------------------------------------- |
| `NAME`    | Nombre del nodo                             |
| `STATUS`  | Estado del nodo (Ready = funcionando)       |
| `ROLES`   | Rol del nodo (control-plane = nodo maestro) |
| `AGE`     | Tiempo desde que el nodo se unió al clúster |
| `VERSION` | Versión de Kubernetes en el nodo            |

### kubectl version

```
$ kubectl version
Client Version: v1.29.0
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
Server Version: v1.28.3
```

> **Nota**: Es normal que las versiones del cliente y servidor difieran ligeramente. Kubernetes garantiza compatibilidad entre versiones cercanas.

## Paso 9: Dashboard de Kubernetes

### minikube dashboard --url

```
$ minikube dashboard --url
🔌  Enabling dashboard ...
    ▪ Using image docker.io/kubernetesui/dashboard:v2.7.0
    ▪ Using image docker.io/kubernetesui/metrics-scraper:v1.0.8
💡  Some dashboard features require the metrics-server addon. To enable all features please run:

        minikube addons enable metrics-server

🤔  Verifying dashboard health ...
🚀  Launching proxy ...
🤔  Verifying proxy health ...
http://127.0.0.1:43217/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/
```

> **Nota**: El puerto (43217) será diferente cada vez que ejecutes el comando.

## Paso 10: Comandos Útiles

### minikube ip

```
$ minikube ip
192.168.49.2
```

### minikube profile list

```
$ minikube profile list
|----------|-----------|---------|--------------|------|---------|---------|-------|--------|
| Profile  | VM Driver | Runtime |      IP      | Port | Version | Status  | Nodes | Active |
|----------|-----------|---------|--------------|------|---------|---------|-------|--------|
| minikube | docker    | docker  | 192.168.49.2 | 8443 | v1.28.3 | Running | 1     | *      |
|----------|-----------|---------|--------------|------|---------|---------|-------|--------|
```

### minikube addons list

```
$ minikube addons list
|-----------------------------|----------|--------------|--------------------------------|
|         ADDON NAME          | PROFILE  |    STATUS    |           MAINTAINER           |
|-----------------------------|----------|--------------|--------------------------------|
| ambassador                  | minikube | disabled     | 3rd party (Ambassador)         |
| auto-pause                  | minikube | disabled     | minikube                       |
| cloud-spanner               | minikube | disabled     | Google                         |
| csi-hostpath-driver         | minikube | disabled     | Kubernetes                     |
| dashboard                   | minikube | enabled ✓    | Kubernetes                     |
| default-storageclass        | minikube | enabled ✅   | Kubernetes                     |
| efk                         | minikube | disabled     | 3rd party (Elastic)            |
| freshpod                    | minikube | disabled     | Google                         |
| gcp-auth                    | minikube | disabled     | Google                         |
| gvisor                      | minikube | disabled     | minikube                       |
| headlamp                    | minikube | disabled     | 3rd party (Headlamp)           |
| helm-tiller                 | minikube | disabled     | 3rd party (Helm)               |
| inaccel                     | minikube | disabled     | 3rd party (InAccel)            |
| ingress                     | minikube | disabled     | Kubernetes                     |
| ingress-dns                 | minikube | disabled     | minikube                       |
| istio                       | minikube | disabled     | 3rd party (Istio)              |
| istio-provisioner           | minikube | disabled     | 3rd party (Istio)              |
| kong                        | minikube | disabled     | 3rd party (Kong HQ)            |
| kubevirt                    | minikube | disabled     | 3rd party (KubeVirt)           |
| logviewer                   | minikube | disabled     | 3rd party (unknown)            |
| metallb                     | minikube | disabled     | 3rd party (MetalLB)            |
| metrics-server              | minikube | disabled     | Kubernetes                     |
| nvidia-driver-installer     | minikube | disabled     | 3rd party (NVIDIA)             |
| nvidia-gpu-device-plugin    | minikube | disabled     | 3rd party (NVIDIA)             |
| olm                         | minikube | disabled     | 3rd party (Operator Framework) |
| pod-security-policy         | minikube | disabled     | 3rd party (unknown)            |
| portainer                   | minikube | disabled     | 3rd party (Portainer.io)       |
| registry                    | minikube | disabled     | minikube                       |
| registry-aliases            | minikube | disabled     | 3rd party (unknown)            |
| registry-creds              | minikube | disabled     | 3rd party (UPMC Enterprises)   |
| storage-provisioner         | minikube | enabled ✅   | minikube                       |
| storage-provisioner-gluster | minikube | disabled     | 3rd party (Gluster)            |
| volumesnapshots             | minikube | disabled     | Kubernetes                     |
|-----------------------------|----------|--------------|--------------------------------|
```

### minikube logs (extracto)

```
$ minikube logs | head -30
==> Audit <==

==> Last Start <==
Log file created at: 2024/01/15 10:30:00
Running on machine: minikube
Binary: Built with gc go1.21.0 for linux/amd64
...

==> container status <==
minikube: Running
```

## Paso 11: Contextos de Kubernetes

### kubectl config current-context

```
$ kubectl config current-context
minikube
```

### kubectl config get-contexts

```
$ kubectl config get-contexts
CURRENT   NAME       CLUSTER    AUTHINFO   NAMESPACE
*         minikube   minikube   minikube   default
```

**Explicación de columnas**:

| Columna     | Descripción                               |
| ----------- | ----------------------------------------- |
| `CURRENT`   | `*` indica el contexto actualmente en uso |
| `NAME`      | Nombre del contexto                       |
| `CLUSTER`   | Nombre del clúster asociado               |
| `AUTHINFO`  | Credenciales utilizadas                   |
| `NAMESPACE` | Namespace por defecto                     |

### kubectl config view (extracto)

```
$ kubectl config view
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /home/user/.minikube/ca.crt
    extensions:
    - extension:
        last-update: Mon, 15 Jan 2024 10:30:00 UTC
        provider: minikube.sigs.k8s.io
        version: v1.32.0
      name: cluster_info
    server: https://192.168.49.2:8443
  name: minikube
contexts:
- context:
    cluster: minikube
    extensions:
    - extension:
        last-update: Mon, 15 Jan 2024 10:30:00 UTC
        provider: minikube.sigs.k8s.io
        version: v1.32.0
      name: context_info
    namespace: default
    user: minikube
  name: minikube
current-context: minikube
kind: Config
preferences: {}
users:
- name: minikube
  user:
    client-certificate: /home/user/.minikube/profiles/minikube/client.crt
    client-key: /home/user/.minikube/profiles/minikube/client.key
```

## Comandos de Gestión del Ciclo de Vida

### minikube pause

```
$ minikube pause
⏸️  Pausing node minikube ...
⏯️  Paused 18 containers in: kube-system, kubernetes-dashboard, storage-gluster, istio-operator
```

### minikube unpause

```
$ minikube unpause
⏸️  Unpausing node minikube ...
⏯️  Unpaused 18 containers in: kube-system, kubernetes-dashboard, storage-gluster, istio-operator
```

### minikube stop

```
$ minikube stop
✋  Stopping node "minikube"  ...
🛑  Powering off "minikube" via SSH ...
🛑  1 node stopped.
```

### minikube delete

```
$ minikube delete
🔥  Deleting "minikube" in docker ...
🔥  Deleting container "minikube" ...
🔥  Removing /home/user/.minikube/machines/minikube ...
💀  Removed all traces of the "minikube" cluster.
```

> **Cuidado**: `minikube delete` elimina todo el clúster y todos los datos. Úsalo solo cuando quieras empezar completamente de cero.

## Resumen

Si todas tus salidas son similares a las mostradas en este documento, has completado exitosamente el Lab 02.

Las diferencias menores que puedes esperar:

- **Versiones**: Pueden variar según cuándo instalaste las herramientas
- **IPs**: La IP del clúster puede ser diferente
- **Puertos**: Los puertos del dashboard serán diferentes
- **Timestamps**: Las fechas y tiempos serán diferentes
- **Recursos**: Los valores de CPU/memoria dependen de tu sistema
