# Lab 02: Minikube Setup

## Objetivo

Configurar un entorno local de Kubernetes usando Minikube.

## Prerrequisitos

- Lab 01 completado (Docker instalado y funcionando)
- Mínimo 2GB de RAM disponible (4GB recomendado)
- 20GB de espacio en disco disponible
- Conexión a internet para descargar imágenes

## Duración

30 minutos

## Conceptos Clave

Antes de comenzar, es importante entender estos conceptos:

| Concepto     | Descripción                                                                                                                |
| ------------ | -------------------------------------------------------------------------------------------------------------------------- |
| **Minikube** | Herramienta que ejecuta un clúster de Kubernetes de un solo nodo en tu máquina local. Ideal para aprendizaje y desarrollo. |
| **kubectl**  | Herramienta de línea de comandos para interactuar con clústeres de Kubernetes. Es el cliente oficial de Kubernetes.        |
| **Clúster**  | Conjunto de máquinas (nodos) que ejecutan aplicaciones containerizadas gestionadas por Kubernetes.                         |
| **Contexto** | Configuración que define a qué clúster y con qué credenciales te conectas. Permite cambiar entre clústeres fácilmente.     |
| **Driver**   | El método que Minikube usa para crear el clúster (Docker, VirtualBox, Hyperkit, etc.).                                     |

### Kubernetes Local vs Producción

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           KUBERNETES LOCAL (Minikube)                       │
│                                                                             │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                         Tu Computadora                                 │ │
│  │                                                                        │ │
│  │    ┌──────────────────────────────────────────────────────────────┐    │ │
│  │    │              Minikube (1 nodo = Control Plane + Worker)      │    │ │
│  │    │                                                              │    │ │
│  │    │   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │    │ │
│  │    │   │  API Server │  │    etcd     │  │  Scheduler  │          │    │ │
│  │    │   └─────────────┘  └─────────────┘  └─────────────┘          │    │ │
│  │    │   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │    │ │
│  │    │   │   kubelet   │  │ kube-proxy  │  │  Tus Pods   │          │    │ │
│  │    │   └─────────────┘  └─────────────┘  └─────────────┘          │    │ │
│  │    └──────────────────────────────────────────────────────────────┘    │ │
│  │                                                                        │ │
│  │    ┌────────────────────────────────────────────────────────────┐      │ │
│  │    │  kubectl ←──────────────────────────────────────────────────┼─────┼─┤
│  │    └────────────────────────────────────────────────────────────┘      │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                        KUBERNETES PRODUCCIÓN (Cloud)                        │
│                                                                             │
│  ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐       │
│  │   Control Plane  │    │   Worker Node 1  │    │   Worker Node 2  │       │
│  │   (Gestionado)   │    │   ┌──────────┐   │    │   ┌──────────┐   │       │
│  │                  │    │   │   Pods   │   │    │   │   Pods   │   │       │
│  │  API, etcd, etc  │◄───┤   └──────────┘   │    │   └──────────┘   │  ...  │
│  │                  │    │   kubelet        │    │   kubelet        │       │
│  └──────────────────┘    └──────────────────┘    └──────────────────┘       │
│           ▲                                                                 │
│           │                                                                 │
│      kubectl (desde cualquier lugar con acceso)                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Instrucciones

### Paso 1: Verificar Docker

Antes de instalar Minikube, asegúrate de que Docker está funcionando:

```bash
docker version
docker info
```

**Salida esperada**: Deberías ver información del cliente y servidor de Docker sin errores.

### Paso 2: Instalar Minikube

#### Opción A: Linux (amd64)

```bash
# Descargar el binario
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Instalar
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Limpiar archivo descargado
rm minikube-linux-amd64
```

#### Opción A2: Linux (arm64)

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-arm64
sudo install minikube-linux-arm64 /usr/local/bin/minikube
rm minikube-linux-arm64
```

#### Opción B: macOS (Homebrew)

```bash
brew install minikube
```

#### Opción C: macOS (Binario directo)

```bash
# Para Apple Silicon (M1/M2/M3)
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-arm64
sudo install minikube-darwin-arm64 /usr/local/bin/minikube

# Para Intel
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64
sudo install minikube-darwin-amd64 /usr/local/bin/minikube
```

#### Opción D: Windows (PowerShell como Administrador)

```powershell
# Con Chocolatey
choco install minikube

# O con winget
winget install Kubernetes.minikube
```

### Paso 3: Verificar la Instalación de Minikube

```bash
minikube version
```

**Salida esperada**:

```
minikube version: v1.32.0
commit: 8220a6eb95f0a4d75f7f2d7b14cef975f050512d
```

### Paso 4: Instalar kubectl

kubectl es la herramienta de línea de comandos para interactuar con Kubernetes.

#### Opción A: Linux (amd64)

```bash
# Descargar la última versión estable
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Instalar
sudo install kubectl /usr/local/bin/kubectl

# Limpiar
rm kubectl
```

#### Opción A2: Linux (arm64)

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"
sudo install kubectl /usr/local/bin/kubectl
rm kubectl
```

#### Opción B: macOS (Homebrew)

```bash
brew install kubectl
```

#### Opción C: Windows (PowerShell como Administrador)

```powershell
# Con Chocolatey
choco install kubernetes-cli

# O con winget
winget install Kubernetes.kubectl
```

#### Alternativa: Usar kubectl incluido en Minikube

Si prefieres no instalar kubectl por separado, Minikube incluye una versión:

```bash
# Puedes usar kubectl a través de minikube
minikube kubectl -- get nodes

# O crear un alias
alias kubectl="minikube kubectl --"
```

### Paso 5: Verificar la Instalación de kubectl

```bash
kubectl version --client
```

**Salida esperada**:

```
Client Version: v1.29.0
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
```

### Paso 6: Iniciar el Clúster de Minikube

Ahora vamos a crear y arrancar un clúster local:

```bash
minikube start --driver=docker
```

**Explicación de parámetros**:

| Parámetro         | Descripción                                                        |
| ----------------- | ------------------------------------------------------------------ |
| `--driver=docker` | Usa Docker como driver (recomendado si ya tienes Docker instalado) |

**Salida esperada**:

```
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

### Paso 7: Verificar el Estado del Clúster

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

### Paso 8: Verificar la Conexión con kubectl

Ahora verifica que kubectl puede comunicarse con el clúster:

```bash
kubectl cluster-info
```

**Salida esperada**:

```
Kubernetes control plane is running at https://192.168.49.2:8443
CoreDNS is running at https://192.168.49.2:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

Ver los nodos del clúster:

```bash
kubectl get nodes
```

**Salida esperada**:

```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   2m    v1.28.3
```

Ver la versión completa:

```bash
kubectl version
```

**Salida esperada**:

```
Client Version: v1.29.0
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
Server Version: v1.28.3
```

### Paso 9: Explorar el Dashboard de Kubernetes

Minikube incluye un dashboard web para visualizar el clúster:

```bash
minikube dashboard
```

Este comando abrirá automáticamente tu navegador con el dashboard.

**Nota**: El comando bloquea la terminal mientras el dashboard está activo. Usa `Ctrl+C` para detenerlo.

Para ejecutar el dashboard en segundo plano:

```bash
minikube dashboard &
```

O solo obtener la URL sin abrir el navegador:

```bash
minikube dashboard --url
```

**Salida esperada**:

```
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

### Paso 10: Explorar Comandos Útiles de Minikube

#### Ver información del clúster

```bash
# Obtener la IP del clúster
minikube ip

# Ver configuración del clúster
minikube profile list

# Ver logs del clúster
minikube logs
```

#### Gestión del ciclo de vida

```bash
# Pausar el clúster (ahorra recursos, mantiene estado)
minikube pause

# Reanudar el clúster pausado
minikube unpause

# Detener el clúster completamente
minikube stop

# Iniciar un clúster detenido
minikube start

# Eliminar el clúster (¡cuidado! borra todo)
minikube delete
```

#### Gestión de addons

```bash
# Listar todos los addons disponibles
minikube addons list

# Habilitar un addon (ejemplo: metrics-server)
minikube addons enable metrics-server

# Deshabilitar un addon
minikube addons disable metrics-server
```

### Paso 11: Entender los Contextos de Kubernetes

kubectl usa "contextos" para saber a qué clúster conectarse:

```bash
# Ver el contexto actual
kubectl config current-context
```

**Salida esperada**:

```
minikube
```

```bash
# Ver todos los contextos configurados
kubectl config get-contexts
```

**Salida esperada**:

```
CURRENT   NAME       CLUSTER    AUTHINFO   NAMESPACE
*         minikube   minikube   minikube   default
```

```bash
# Ver la configuración completa
kubectl config view
```

## Ejercicios Adicionales

### Ejercicio 1: Habilitar el Metrics Server

El metrics-server permite ver métricas de recursos de los pods:

```bash
# Habilitar metrics-server
minikube addons enable metrics-server

# Esperar unos segundos y verificar
kubectl top nodes
kubectl top pods -A
```

### Ejercicio 2: Crear un Segundo Perfil

Minikube permite tener múltiples clústeres con diferentes configuraciones:

```bash
# Crear un nuevo perfil con más recursos
minikube start -p mi-cluster-grande --cpus=4 --memory=8192

# Ver todos los perfiles
minikube profile list

# Cambiar entre perfiles
minikube profile mi-cluster-grande
minikube profile minikube

# Eliminar el perfil adicional
minikube delete -p mi-cluster-grande
```

### Ejercicio 3: Explorar los Addons

```bash
# Ver addons disponibles
minikube addons list

# Algunos addons útiles para habilitar:
minikube addons enable ingress        # Para usar Ingress
minikube addons enable registry       # Registry local de imágenes
minikube addons enable dashboard      # Dashboard web (ya habilitado por defecto)
```

### Ejercicio 4: Conectarse al Nodo de Minikube

Puedes acceder al nodo de Minikube via SSH:

```bash
# Conectarse por SSH al nodo
minikube ssh

# Dentro del nodo, explorar:
docker ps                    # Ver contenedores del clúster
ls /var/log/containers/      # Ver logs de contenedores
exit                         # Salir
```

## Verificación

Antes de continuar al siguiente laboratorio, asegúrate de poder marcar todos estos puntos:

- [ ] Minikube está instalado y `minikube version` muestra la versión
- [ ] kubectl está instalado y `kubectl version --client` funciona
- [ ] El clúster de Minikube inicia correctamente con `minikube start`
- [ ] `minikube status` muestra todos los componentes como "Running"
- [ ] `kubectl cluster-info` muestra la información del clúster
- [ ] `kubectl get nodes` muestra el nodo minikube como "Ready"
- [ ] Puedo acceder al dashboard con `minikube dashboard`
- [ ] Entiendo la diferencia entre Minikube y un clúster de producción
- [ ] Sé cómo pausar, detener e iniciar el clúster
- [ ] Entiendo qué es un contexto de Kubernetes

## Solución de Problemas Comunes

### Error: "Exiting due to PROVIDER_DOCKER_NOT_RUNNING"

**Causa**: Docker no está corriendo.

**Solución**:

```bash
# Linux
sudo systemctl start docker

# macOS/Windows
# Abre Docker Desktop y espera a que inicie
```

### Error: "Exiting due to RSRC_INSUFFICIENT_CORES"

**Causa**: No hay suficientes CPUs disponibles.

**Solución**:

```bash
# Iniciar con menos CPUs
minikube start --cpus=1
```

### Error: "Unable to connect to the server"

**Causa**: El clúster no está corriendo o hay un problema de conexión.

**Solución**:

```bash
# Verificar estado
minikube status

# Si está detenido, iniciarlo
minikube start

# Si hay problemas, eliminar y recrear
minikube delete
minikube start
```

### kubectl muestra un contexto diferente

**Causa**: Hay múltiples clústeres configurados.

**Solución**:

```bash
# Cambiar al contexto de minikube
kubectl config use-context minikube
```

## Resumen de Comandos

| Comando                          | Descripción                        |
| -------------------------------- | ---------------------------------- |
| `minikube version`               | Muestra la versión de Minikube     |
| `minikube start`                 | Inicia el clúster                  |
| `minikube start --driver=docker` | Inicia con driver específico       |
| `minikube status`                | Muestra el estado del clúster      |
| `minikube stop`                  | Detiene el clúster                 |
| `minikube delete`                | Elimina el clúster                 |
| `minikube pause`                 | Pausa el clúster (ahorra recursos) |
| `minikube unpause`               | Reanuda el clúster pausado         |
| `minikube dashboard`             | Abre el dashboard web              |
| `minikube ip`                    | Muestra la IP del clúster          |
| `minikube ssh`                   | Conecta al nodo por SSH            |
| `minikube addons list`           | Lista addons disponibles           |
| `minikube addons enable <addon>` | Habilita un addon                  |
| `minikube logs`                  | Muestra logs del clúster           |
| `kubectl version`                | Muestra versión de kubectl         |
| `kubectl cluster-info`           | Información del clúster            |
| `kubectl get nodes`              | Lista los nodos                    |
| `kubectl config current-context` | Contexto actual                    |
| `kubectl config get-contexts`    | Lista todos los contextos          |

## Solución

Consulta el directorio `solution/` para ver los scripts con todos los comandos y las salidas esperadas.

## Navegación

- **Anterior**: [Lab 01: Docker Basics](../../modulo-01-cloud-contenedores/lab-01-docker-basics/README.md)
- **Siguiente**: [Lab 03: Cluster Exploration](../../modulo-03-arquitectura/lab-03-cluster-exploration/README.md)
