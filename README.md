# KCD Mexico

Repositorio destinado a la creación de material didáctico para cursos universitarios, con el objetivo de ofrecer a los estudiantes una introducción práctica y accesible a Kubernetes.

## Software Requerido

Para completar los laboratorios de este curso, necesitarás instalar el siguiente software:

### Herramientas Esenciales

| Herramienta                                          | Versión Mínima | Descripción                        |
| ---------------------------------------------------- | -------------- | ---------------------------------- |
| [Docker](https://docs.docker.com/get-docker/)        | 24.0+          | Runtime de contenedores            |
| [Minikube](https://minikube.sigs.k8s.io/docs/start/) | 1.32+          | Clúster local de Kubernetes        |
| [kubectl](https://kubernetes.io/docs/tasks/tools/)   | 1.28+          | CLI para Kubernetes                |
| [Helm](https://helm.sh/docs/intro/install/)          | 3.x            | Gestor de paquetes para Kubernetes |
| [Git](https://git-scm.com/downloads)                 | 2.x            | Control de versiones               |

### Herramientas de Cloud (Lab 18)

| Herramienta                                                  | Plataforma | Descripción                |
| ------------------------------------------------------------ | ---------- | -------------------------- |
| [gcloud](https://cloud.google.com/sdk/docs/install)          | GCP        | Google Cloud SDK           |
| [aws-cli](https://aws.amazon.com/cli/)                       | AWS        | AWS Command Line Interface |
| [eksctl](https://eksctl.io/installation/)                    | AWS        | CLI para Amazon EKS        |
| [az](https://docs.microsoft.com/cli/azure/install-azure-cli) | Azure      | Azure CLI                  |

### Utilidades del Sistema

| Herramienta     | Uso                                     |
| --------------- | --------------------------------------- |
| curl            | Pruebas de conectividad HTTP            |
| openssl         | Generación de certificados TLS (Lab 11) |
| base64          | Codificación de Secrets                 |
| Editor de texto | nano, vim, o VS Code                    |

### Instalación por Sistema Operativo

**Linux (Ubuntu/Debian):**

```bash
# Docker
sudo apt-get update
sudo apt-get install -y docker.io
sudo usermod -aG docker $USER

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**macOS:**

```bash
# Usando Homebrew
brew install docker minikube kubectl helm git
```

**Windows:**

```powershell
# Usando Chocolatey
choco install docker-desktop minikube kubernetes-cli kubernetes-helm git

# O usando winget
winget install Docker.DockerDesktop Kubernetes.minikube Kubernetes.kubectl Helm.Helm Git.Git
```

## Temario

### Nivel 1: Fundamentos

#### Módulo 1. Introducción a la Computación en la Nube y Contenedores

##### Objetivo: Comprender el contexto y la necesidad de Kubernetes.

- Evolución de la infraestructura: Bare metal → Virtualización → Contenedores
- ¿Qué es Cloud Computing? (IaaS, PaaS, SaaS)
- Problemas que resuelven los contenedores
- Introducción a Docker
- Diferencias entre contenedores y máquinas virtuales

Práctica:

- Instalación de Docker
- Creación y ejecución de un contenedor simple

#### Módulo 2. Introducción a Kubernetes

##### Objetivo: Entender qué es Kubernetes y para qué se utiliza.

- ¿Qué es Kubernetes?
- Historia y ecosistema (CNCF)
- Casos de uso en la industria
- Arquitectura general de Kubernetes
- Componentes principales del clúster

#### Módulo 3. Arquitectura de Kubernetes

##### Objetivo: Comprender cómo funciona internamente un clúster.

- Nodo Master / Control Plane
- Nodos Worker
- Componentes clave:
  - kube-apiserver
  - etcd
  - scheduler
  - controller-manager
  - kubelet y kube-proxy
- Flujo de comunicación dentro del clúster

### Nivel 2: Uso Básico

#### Módulo 4. Objetos Fundamentales de Kubernetes

##### Objetivo: Aprender los recursos básicos que maneja Kubernetes.

- Pods
- ReplicaSets
- Deployments
- Namespaces
- Labels y Selectors

Práctica:

- Creación de Pods y Deployments
- Escalamiento manual de aplicaciones

#### Módulo 5. kubectl y Archivos YAML

##### Objetivo: Manejar Kubernetes desde la línea de comandos.

- Instalación y configuración de kubectl
- Comandos básicos
- Estructura de archivos YAML
- Manifiestos declarativos
- apply vs create

Práctica:

- Despliegue de aplicaciones usando YAML
- Modificación y actualización de recursos

#### Módulo 6. Servicios y Networking en Kubernetes

##### Objetivo: Entender cómo se comunican las aplicaciones.

- Problemas de red en contenedores
- Tipos de Service:
  - ClusterIP
  - NodePort
  - LoadBalancer
- Introducción a Ingress
- DNS interno del clúster

Práctica:

- Exponer una aplicación dentro y fuera del clúster

### Nivel 3: Uso Intermedio

#### Módulo 7. Configuración y Gestión de Aplicaciones

##### Objetivo: Separar configuración del código.

- ConfigMaps
- Secrets
- Variables de entorno
- Buenas prácticas de configuración

#### Módulo 8. Almacenamiento en Kubernetes

##### Objetivo: Manejar datos persistentes.

- Volumes
- PersistentVolumes (PV)
- PersistentVolumeClaims (PVC)
- Casos de uso
- Almacenamiento local vs en la nube

Práctica:

- Despliegue de una aplicación con almacenamiento persistente

#### Módulo 9. Escalamiento y Alta Disponibilidad

##### Objetivo: Garantizar disponibilidad y rendimiento.

- Escalamiento manual y automático
- Horizontal Pod Autoscaler (HPA)
- Rolling updates
- Rollbacks
- Self-healing

### Nivel 4: Operación y Buenas Prácticas

#### Módulo 10. Seguridad en Kubernetes

##### Objetivo: Introducir conceptos clave de seguridad.

- Autenticación y autorización
- RBAC
- Service Accounts
- Buenas prácticas de seguridad
- Manejo seguro de Secrets

#### Módulo 11. Monitoreo y Logging

##### Objetivo: Observar y diagnosticar el clúster.

- Conceptos de observabilidad
- Logs de Pods
- Métricas básicas
- Introducción a Prometheus y Grafana
- Herramientas comunes del ecosistema

#### Módulo 12. Introducción a Kubernetes en la Nube

##### Objetivo: Conocer plataformas usadas en la industria.

- Kubernetes administrado vs autogestionado
- Ejemplos:
  - GKE (Google Kubernetes Engine)
  - EKS (AWS)
  - AKS (Azure)
- Costos y consideraciones

### Proyecto Final

#### Objetivo: Aplicar los conocimientos adquiridos.

- Despliegue de una aplicación completa:
  - Frontend + Backend
  - Uso de Deployments, Services y ConfigMaps
  - Escalamiento
  - Persistencia de datos
- Documentación del proyecto
- Presentación técnica
