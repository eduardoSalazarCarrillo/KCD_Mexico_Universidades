# Lab 03: Cluster Exploration

## Objetivo

Explorar los componentes internos de un clúster de Kubernetes.

## Prerrequisitos

- Lab 02 completado (Minikube funcionando)

## Duración

30 minutos

## Instrucciones

### Paso 1: Explorar los nodos

```bash
# Listar nodos
kubectl get nodes

# Ver detalles del nodo
kubectl describe node minikube

# Información en formato wide
kubectl get nodes -o wide
```

### Paso 2: Explorar namespaces del sistema

```bash
# Listar todos los namespaces
kubectl get namespaces

# Ver pods en kube-system
kubectl get pods -n kube-system
```

### Paso 3: Identificar componentes del Control Plane

```bash
# Ver todos los pods del sistema con más detalle
kubectl get pods -n kube-system -o wide

# Componentes a identificar:
# - coredns (DNS del clúster)
# - etcd (base de datos)
# - kube-apiserver (API)
# - kube-controller-manager
# - kube-scheduler
# - kube-proxy
```

### Paso 4: Inspeccionar componentes individuales

```bash
# Ver detalles del API Server
kubectl describe pod -n kube-system -l component=kube-apiserver

# Ver logs del scheduler
kubectl logs -n kube-system -l component=kube-scheduler

# Ver configuración de etcd
kubectl describe pod -n kube-system -l component=etcd
```

### Paso 5: Entender kube-proxy y kubelet

```bash
# Ver kube-proxy (DaemonSet)
kubectl get daemonset -n kube-system kube-proxy
kubectl describe daemonset -n kube-system kube-proxy

# Kubelet corre fuera del clúster, pero podemos ver su estado
minikube ssh
systemctl status kubelet
exit
```

### Paso 6: Explorar la API de Kubernetes

```bash
# Ver recursos disponibles en la API
kubectl api-resources

# Ver versiones de la API
kubectl api-versions

# Acceder directamente a la API
kubectl proxy &
curl http://localhost:8001/api/v1/namespaces
```

## Ejercicios Adicionales

1. Encuentra qué versión de etcd está corriendo
2. Identifica cuántos pods de CoreDNS hay y por qué
3. Revisa los logs del controller-manager

## Verificación

- [ ] Puedo identificar todos los componentes del Control Plane
- [ ] Entiendo la diferencia entre Control Plane y Worker Nodes
- [ ] Sé dónde encontrar logs de cada componente
- [ ] Comprendo el rol de cada namespace del sistema

## Diagrama de Referencia

```
┌─────────────────────────────────────────────────────────┐
│                     Control Plane                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ kube-apiserver│  │   etcd      │  │  scheduler   │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │            controller-manager                     │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                     Worker Node                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   kubelet    │  │  kube-proxy  │  │   Pods       │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Solución

Consulta el directorio `solution/` para ver las salidas esperadas.
