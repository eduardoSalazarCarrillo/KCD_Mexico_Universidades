# Lab 02: Minikube Setup

## Objetivo

Configurar un entorno local de Kubernetes usando Minikube.

## Prerrequisitos

- Lab 01 completado (Docker instalado y funcionando)
- Mínimo 2GB de RAM disponible
- 20GB de espacio en disco

## Duración

30 minutos

## Instrucciones

### Paso 1: Instalar Minikube

#### Linux

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

#### macOS

```bash
brew install minikube
```

#### Windows (PowerShell como Admin)

```powershell
choco install minikube
```

### Paso 2: Instalar kubectl

#### Linux

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/kubectl
```

#### macOS

```bash
brew install kubectl
```

#### Windows

```powershell
choco install kubernetes-cli
```

### Paso 3: Iniciar el clúster

```bash
# Iniciar Minikube con Docker como driver
minikube start --driver=docker

# Verificar el estado
minikube status
```

### Paso 4: Verificar kubectl

```bash
# Ver información del clúster
kubectl cluster-info

# Ver nodos del clúster
kubectl get nodes

# Ver la versión
kubectl version
```

### Paso 5: Explorar el Dashboard

```bash
# Abrir el dashboard de Kubernetes
minikube dashboard
```

### Paso 6: Comandos útiles de Minikube

```bash
# Pausar el clúster (ahorra recursos)
minikube pause

# Reanudar
minikube unpause

# Detener completamente
minikube stop

# Eliminar el clúster
minikube delete

# Ver addons disponibles
minikube addons list
```

## Ejercicios Adicionales

1. Habilita el addon `metrics-server`
2. Explora los diferentes drivers disponibles
3. Crea un segundo perfil de Minikube con diferente configuración

## Verificación

- [ ] Minikube está instalado
- [ ] kubectl está instalado y configurado
- [ ] El clúster inicia correctamente
- [ ] Puedo acceder al dashboard

## Solución

Consulta el directorio `solution/` para ver configuraciones adicionales.
