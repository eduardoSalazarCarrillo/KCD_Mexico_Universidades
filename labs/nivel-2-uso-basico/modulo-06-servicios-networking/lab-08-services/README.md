# Lab 08: Services

## Objetivo

Exponer aplicaciones usando diferentes tipos de Services en Kubernetes, entendiendo cómo funcionan los selectores, endpoints y la comunicación interna y externa del clúster.

## Prerrequisitos

- Lab 07 completado (Resource Updates)
- Clúster de Minikube ejecutándose (`minikube status` debe mostrar "Running")

## Duración

60 minutos

## Conceptos Clave

Antes de comenzar, es importante entender estos conceptos:

| Concepto         | Descripción                                                                                                                |
| ---------------- | -------------------------------------------------------------------------------------------------------------------------- |
| **Service**      | Abstracción que define un conjunto lógico de Pods y una política para acceder a ellos. Proporciona una IP estable y DNS.   |
| **ClusterIP**    | Tipo de Service por defecto. Expone el Service en una IP interna del clúster. Solo accesible desde dentro del clúster.     |
| **NodePort**     | Expone el Service en un puerto estático de cada nodo. Accesible desde fuera del clúster usando `<NodeIP>:<NodePort>`.      |
| **LoadBalancer** | Expone el Service externamente usando el balanceador de carga del proveedor cloud. En Minikube requiere `minikube tunnel`. |
| **Selector**     | Define qué Pods son parte del Service. El Service enruta tráfico solo a Pods que coinciden con los labels del selector.    |
| **Endpoints**    | Lista de IPs de los Pods que coinciden con el selector del Service. Kubernetes los actualiza automáticamente.              |
| **targetPort**   | Puerto en el que el contenedor escucha. El Service redirige tráfico a este puerto.                                         |
| **port**         | Puerto en el que el Service escucha dentro del clúster.                                                                    |
| **nodePort**     | Puerto expuesto en cada nodo (rango 30000-32767). Solo aplica para Services tipo NodePort o LoadBalancer.                  |
| **DNS interno**  | Kubernetes provee DNS interno. Los Services son accesibles por `<service-name>.<namespace>.svc.cluster.local`.             |

### Arquitectura de Services

```
                                    FUERA DEL CLÚSTER
                                           │
                     ┌─────────────────────┴─────────────────────┐
                     │                                           │
                     ▼                                           ▼
              NodePort :30080                            LoadBalancer
              (cualquier nodo)                           (IP externa)
                     │                                           │
                     └─────────────────────┬─────────────────────┘
                                           │
═══════════════════════════════════════════╪═══════════════════════════════════════
                                           │
                                    DENTRO DEL CLÚSTER
                                           │
                                           ▼
                              ┌────────────────────────┐
                              │   Service (ClusterIP)  │
                              │   web-service:80       │
                              │   10.96.100.50:80      │
                              └────────────┬───────────┘
                                           │
                              ┌────────────┴───────────┐
                              │       Endpoints        │
                              │  10.244.0.5:80         │
                              │  10.244.0.6:80         │
                              │  10.244.0.7:80         │
                              └────────────┬───────────┘
                                           │
                    ┌──────────────────────┼──────────────────────┐
                    │                      │                      │
                    ▼                      ▼                      ▼
             ┌───────────┐          ┌───────────┐          ┌───────────┐
             │   Pod 1   │          │   Pod 2   │          │   Pod 3   │
             │ app: web  │          │ app: web  │          │ app: web  │
             │ :80       │          │ :80       │          │ :80       │
             └───────────┘          └───────────┘          └───────────┘
```

### Tipos de Services Comparados

| Característica | ClusterIP          | NodePort                    | LoadBalancer            |
| -------------- | ------------------ | --------------------------- | ----------------------- |
| Acceso interno | Sí                 | Sí                          | Sí                      |
| Acceso externo | No                 | Sí (via NodeIP:NodePort)    | Sí (via IP del LB)      |
| IP asignada    | IP interna         | IP interna + puerto en nodo | IP interna + IP externa |
| Caso de uso    | Comunicación intra | Desarrollo, testing         | Producción en cloud     |
| Requiere cloud | No                 | No                          | Sí (o minikube tunnel)  |

### Flujo de Tráfico

```
                    ┌─────────────────────────────────────────────────────────┐
                    │                    CLIENTE                               │
                    └─────────────────────────┬───────────────────────────────┘
                                              │
                                              │ 1. Request a Service IP/DNS
                                              ▼
                    ┌─────────────────────────────────────────────────────────┐
                    │                   kube-proxy                             │
                    │                                                          │
                    │  - Mantiene reglas de iptables/IPVS                      │
                    │  - Intercepta tráfico hacia Service IPs                  │
                    │  - Balancea carga entre Endpoints                        │
                    └─────────────────────────┬───────────────────────────────┘
                                              │
                                              │ 2. Selecciona un Pod (round-robin)
                                              ▼
                    ┌─────────────────────────────────────────────────────────┐
                    │                      POD                                 │
                    │                  (Endpoint)                              │
                    └─────────────────────────────────────────────────────────┘
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

### Paso 2: Crear el Deployment Base

Primero crearemos un Deployment que servirá como backend para nuestros Services. Usa el archivo `initial/deployment-web.yaml`:

```bash
# Ver el contenido del archivo
cat initial/deployment-web.yaml
```

**Contenido del archivo**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  labels:
    app: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
        version: v1
    spec:
      containers:
        - name: nginx
          image: nginx:alpine
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 100m
              memory: 128Mi
```

**Explicación**:

| Campo               | Descripción                                         |
| ------------------- | --------------------------------------------------- |
| `replicas: 3`       | Tres Pods para demostrar balanceo de carga          |
| `labels: app: web`  | Label que usarán los Services para seleccionar Pods |
| `containerPort: 80` | Puerto donde nginx escucha                          |
| `resources`         | Límites de recursos para buenas prácticas           |

Aplica el Deployment:

```bash
kubectl apply -f initial/deployment-web.yaml
```

**Salida esperada**:

```
deployment.apps/web-app created
```

Verifica que los Pods están corriendo:

```bash
kubectl get pods -l app=web -o wide
```

**Salida esperada**:

```
NAME                       READY   STATUS    RESTARTS   AGE   IP           NODE
web-app-6d8f7b9c5d-abc12   1/1     Running   0          30s   10.244.0.5   minikube
web-app-6d8f7b9c5d-def34   1/1     Running   0          30s   10.244.0.6   minikube
web-app-6d8f7b9c5d-ghi56   1/1     Running   0          30s   10.244.0.7   minikube
```

> **Nota**: Observa las IPs de los Pods (10.244.0.x). Estas IPs son efímeras y cambian si los Pods se recrean. Por eso necesitamos Services.

### Paso 3: Problema sin Services - IPs Efímeras

Vamos a demostrar por qué necesitamos Services. Las IPs de los Pods son temporales:

```bash
# Obtener la IP de un Pod
POD_IP=$(kubectl get pod -l app=web -o jsonpath='{.items[0].status.podIP}')
echo "IP del Pod: $POD_IP"

# Eliminar el Pod
POD_NAME=$(kubectl get pod -l app=web -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD_NAME

# Esperar a que se cree el nuevo Pod
sleep 5

# Ver la nueva IP
kubectl get pods -l app=web -o wide
```

> **Observa**: El nuevo Pod tiene una IP diferente. Si una aplicación dependiera de esa IP, fallaría.

### Paso 4: Crear un Service ClusterIP

El Service ClusterIP proporciona una IP estable para acceder a los Pods internamente. Usa el archivo `initial/service-clusterip.yaml`:

```bash
cat initial/service-clusterip.yaml
```

**Contenido del archivo**:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-clusterip
  labels:
    app: web
spec:
  type: ClusterIP
  selector:
    app: web
  ports:
    - name: http
      port: 80
      targetPort: 80
      protocol: TCP
```

**Explicación del YAML**:

| Campo        | Descripción                                              |
| ------------ | -------------------------------------------------------- |
| `type`       | `ClusterIP` (valor por defecto si se omite)              |
| `selector`   | Selecciona Pods con label `app: web`                     |
| `port`       | Puerto donde el Service escucha (80)                     |
| `targetPort` | Puerto del contenedor al que se redirige el tráfico (80) |
| `protocol`   | Protocolo de red (TCP por defecto)                       |

Aplica el Service:

```bash
kubectl apply -f initial/service-clusterip.yaml
```

**Salida esperada**:

```
service/web-clusterip created
```

Verifica el Service:

```bash
kubectl get service web-clusterip
```

**Salida esperada**:

```
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
web-clusterip   ClusterIP   10.96.100.50    <none>        80/TCP    30s
```

> **Nota**: La `CLUSTER-IP` es estable y no cambia aunque los Pods se recreen.

### Paso 5: Inspeccionar los Endpoints

Los Endpoints son las IPs de los Pods que coinciden con el selector del Service:

```bash
# Ver los endpoints del Service
kubectl get endpoints web-clusterip
```

**Salida esperada**:

```
NAME            ENDPOINTS                                      AGE
web-clusterip   10.244.0.5:80,10.244.0.6:80,10.244.0.7:80      1m
```

> **Observa**: Los endpoints coinciden con las IPs de los Pods.

Ver más detalles:

```bash
kubectl describe endpoints web-clusterip
```

**Salida esperada**:

```
Name:         web-clusterip
Namespace:    default
Labels:       app=web
Annotations:  endpoints.kubernetes.io/last-change-trigger-time: ...
Subsets:
  Addresses:          10.244.0.5,10.244.0.6,10.244.0.7
  NotReadyAddresses:  <none>
  Ports:
    Name  Port  Protocol
    ----  ----  --------
    http  80    TCP
```

### Paso 6: Probar la Conectividad Interna (ClusterIP)

Para probar el Service desde dentro del clúster, creamos un Pod temporal:

```bash
# Crear un pod de prueba con herramientas de red
kubectl run test-client --image=busybox:1.36 --rm -it --restart=Never -- sh
```

Dentro del Pod, ejecuta estos comandos:

```bash
# Probar conexión usando el nombre del Service
wget -qO- http://web-clusterip

# Probar usando el FQDN (Fully Qualified Domain Name)
wget -qO- http://web-clusterip.default.svc.cluster.local

# Ver la resolución DNS
nslookup web-clusterip

# Probar múltiples veces para ver el balanceo de carga
for i in 1 2 3 4 5; do wget -qO- http://web-clusterip 2>&1 | head -1; done

# Salir del pod
exit
```

**Salida esperada del wget**:

```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
</html>
```

**Salida esperada del nslookup**:

```
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      web-clusterip
Address 1: 10.96.100.50 web-clusterip.default.svc.cluster.local
```

### Paso 7: Crear un Service NodePort

El Service NodePort expone la aplicación en un puerto de cada nodo, permitiendo acceso externo. Usa el archivo `initial/service-nodeport.yaml`:

```bash
cat initial/service-nodeport.yaml
```

**Contenido del archivo**:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-nodeport
  labels:
    app: web
spec:
  type: NodePort
  selector:
    app: web
  ports:
    - name: http
      port: 80
      targetPort: 80
      nodePort: 30080
      protocol: TCP
```

**Explicación**:

| Campo      | Descripción                                           |
| ---------- | ----------------------------------------------------- |
| `type`     | `NodePort` - expone en puerto del nodo                |
| `nodePort` | Puerto 30080 en cada nodo (rango válido: 30000-32767) |
| `port`     | Puerto interno del Service (80)                       |

Aplica el Service:

```bash
kubectl apply -f initial/service-nodeport.yaml
```

**Salida esperada**:

```
service/web-nodeport created
```

Verifica el Service:

```bash
kubectl get service web-nodeport
```

**Salida esperada**:

```
NAME           TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
web-nodeport   NodePort   10.96.150.75    <none>        80:30080/TCP   30s
```

> **Nota**: `PORT(S)` muestra `80:30080/TCP`, indicando que el puerto 80 del Service está mapeado al puerto 30080 del nodo.

### Paso 8: Acceder desde Fuera del Clúster (NodePort)

Con Minikube, podemos acceder al Service NodePort de varias formas:

**Opción 1: Usando minikube service**

```bash
# Obtener la URL de acceso
minikube service web-nodeport --url
```

**Salida esperada**:

```
http://192.168.49.2:30080
```

**Opción 2: Manualmente con la IP del nodo**

```bash
# Obtener la IP del nodo
MINIKUBE_IP=$(minikube ip)
echo "IP de Minikube: $MINIKUBE_IP"

# Acceder al Service
curl http://$MINIKUBE_IP:30080
```

**Salida esperada**:

```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
</html>
```

**Opción 3: Abrir en el navegador**

```bash
# Abre automáticamente el navegador
minikube service web-nodeport
```

### Paso 9: Crear un Service con kubectl expose

Además de archivos YAML, puedes crear Services rápidamente con `kubectl expose`:

```bash
# Crear un Service ClusterIP rápidamente
kubectl expose deployment web-app --name=web-exposed --port=8080 --target-port=80
```

**Salida esperada**:

```
service/web-exposed exposed
```

Verifica el Service:

```bash
kubectl get service web-exposed
```

**Salida esperada**:

```
NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
web-exposed   ClusterIP   10.96.200.25    <none>        8080/TCP   30s
```

> **Nota**: Este Service escucha en puerto 8080 pero redirige al puerto 80 del contenedor.

Describe el Service para ver más detalles:

```bash
kubectl describe service web-exposed
```

**Salida esperada**:

```
Name:              web-exposed
Namespace:         default
Labels:            app=web
Annotations:       <none>
Selector:          app=web
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.96.200.25
IPs:               10.96.200.25
Port:              <unset>  8080/TCP
TargetPort:        80/TCP
Endpoints:         10.244.0.5:80,10.244.0.6:80,10.244.0.7:80
Session Affinity:  None
Events:            <none>
```

### Paso 10: Comparar Todos los Services

Veamos todos los Services creados:

```bash
kubectl get services
```

**Salida esperada**:

```
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kubernetes      ClusterIP   10.96.0.1       <none>        443/TCP        1d
web-clusterip   ClusterIP   10.96.100.50    <none>        80/TCP         10m
web-exposed     ClusterIP   10.96.200.25    <none>        8080/TCP       2m
web-nodeport    NodePort    10.96.150.75    <none>        80:30080/TCP   5m
```

Ver los endpoints de todos los Services:

```bash
kubectl get endpoints
```

**Salida esperada**:

```
NAME            ENDPOINTS                                      AGE
kubernetes      192.168.49.2:8443                              1d
web-clusterip   10.244.0.5:80,10.244.0.6:80,10.244.0.7:80      10m
web-exposed     10.244.0.5:80,10.244.0.6:80,10.244.0.7:80      2m
web-nodeport    10.244.0.5:80,10.244.0.6:80,10.244.0.7:80      5m
```

> **Observa**: Los tres Services apuntan a los mismos Pods porque tienen el mismo selector (`app: web`).

### Paso 11: Verificar el Balanceo de Carga

Para demostrar el balanceo de carga, modificaremos cada Pod para que responda con su nombre:

```bash
# Obtener nombres de los pods
PODS=$(kubectl get pods -l app=web -o jsonpath='{.items[*].metadata.name}')

# Modificar el index.html de cada pod para identificarlo
for POD in $PODS; do
  kubectl exec $POD -- sh -c "echo '<h1>Pod: $POD</h1>' > /usr/share/nginx/html/index.html"
done
```

Ahora prueba múltiples requests para ver el balanceo:

```bash
# Hacer 10 requests y ver qué pod responde
for i in $(seq 1 10); do
  curl -s http://$(minikube ip):30080 2>/dev/null
done
```

**Salida esperada** (los pods se alternan):

```html
<h1>Pod: web-app-6d8f7b9c5d-abc12</h1>
<h1>Pod: web-app-6d8f7b9c5d-def34</h1>
<h1>Pod: web-app-6d8f7b9c5d-ghi56</h1>
<h1>Pod: web-app-6d8f7b9c5d-abc12</h1>
...
```

### Paso 12: Escalar el Deployment y Observar los Endpoints

Cuando escalamos el Deployment, los endpoints del Service se actualizan automáticamente:

```bash
# Ver endpoints actuales
kubectl get endpoints web-clusterip

# Escalar a 5 réplicas
kubectl scale deployment web-app --replicas=5

# Esperar a que los pods estén listos
kubectl rollout status deployment web-app

# Ver los nuevos endpoints
kubectl get endpoints web-clusterip
```

**Salida esperada**:

```
NAME            ENDPOINTS                                                        AGE
web-clusterip   10.244.0.5:80,10.244.0.6:80,10.244.0.7:80,10.244.0.8:80,10.244.0.9:80   15m
```

> **Observa**: Ahora hay 5 endpoints, uno por cada Pod.

Escalar de vuelta a 3:

```bash
kubectl scale deployment web-app --replicas=3
```

### Paso 13: Selector con Múltiples Labels

Crea un Service que seleccione Pods con múltiples labels. Usa el archivo `initial/service-multi-selector.yaml`:

```bash
cat initial/service-multi-selector.yaml
```

**Contenido**:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-v1-only
spec:
  type: ClusterIP
  selector:
    app: web
    version: v1
  ports:
    - port: 80
      targetPort: 80
```

```bash
kubectl apply -f initial/service-multi-selector.yaml
kubectl get endpoints web-v1-only
```

> **Nota**: Este Service solo selecciona Pods que tienen AMBOS labels: `app: web` Y `version: v1`.

### Paso 14: Limpiar Recursos

Elimina todos los recursos creados:

```bash
# Eliminar Services
kubectl delete service web-clusterip web-nodeport web-exposed web-v1-only

# Eliminar Deployment
kubectl delete deployment web-app
```

**Salida esperada**:

```
service "web-clusterip" deleted
service "web-nodeport" deleted
service "web-exposed" deleted
service "web-v1-only" deleted
deployment.apps "web-app" deleted
```

Verifica que todo fue eliminado:

```bash
kubectl get all
```

**Salida esperada**:

```
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   1d
```

## Ejercicios Adicionales

### Ejercicio 1: Service Headless (clusterIP: None)

Un Service headless no tiene ClusterIP y permite acceso directo a los Pods:

```bash
# Recrear el deployment
kubectl apply -f initial/deployment-web.yaml

# Crear Service headless
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: web-headless
spec:
  clusterIP: None
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
EOF

# Verificar que no tiene ClusterIP
kubectl get service web-headless

# Probar la resolución DNS (devuelve IPs de todos los Pods)
kubectl run test-dns --image=busybox:1.36 --rm -it --restart=Never -- nslookup web-headless

# Limpiar
kubectl delete service web-headless
kubectl delete deployment web-app
```

### Ejercicio 2: Service tipo LoadBalancer con Minikube Tunnel

```bash
# Recrear deployment
kubectl apply -f initial/deployment-web.yaml

# Crear Service LoadBalancer
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: web-loadbalancer
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
EOF

# Ver el Service (EXTERNAL-IP estará en <pending>)
kubectl get service web-loadbalancer

# En otra terminal, ejecutar minikube tunnel (requiere sudo)
# minikube tunnel

# Después del tunnel, EXTERNAL-IP tendrá una IP
kubectl get service web-loadbalancer

# Limpiar
kubectl delete service web-loadbalancer
kubectl delete deployment web-app
```

### Ejercicio 3: ExternalName Service

Un Service ExternalName permite referenciar servicios externos:

```bash
# Crear un Service que apunte a un dominio externo
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: external-api
spec:
  type: ExternalName
  externalName: api.example.com
EOF

# Ver el Service
kubectl get service external-api

# Este Service no tiene ClusterIP ni endpoints
kubectl describe service external-api

# Limpiar
kubectl delete service external-api
```

### Ejercicio 4: Generar YAML de Service con dry-run

```bash
# Generar YAML de un Service sin crearlo
kubectl create service clusterip my-service --tcp=80:8080 --dry-run=client -o yaml

# Generar YAML de NodePort
kubectl create service nodeport my-nodeport --tcp=80:8080 --node-port=30100 --dry-run=client -o yaml
```

## Verificación

Antes de continuar al siguiente laboratorio, asegúrate de poder marcar todos estos puntos:

- [ ] Entiendo la diferencia entre ClusterIP, NodePort y LoadBalancer
- [ ] Puedo crear un Service ClusterIP y acceder desde dentro del clúster
- [ ] Puedo crear un Service NodePort y acceder desde fuera del clúster
- [ ] Entiendo cómo funcionan los selectores en Services
- [ ] Puedo inspeccionar endpoints y entiendo qué representan
- [ ] Sé que los endpoints se actualizan automáticamente al escalar Pods
- [ ] Puedo crear Services usando archivos YAML y `kubectl expose`
- [ ] Entiendo el DNS interno del clúster (`<service>.<namespace>.svc.cluster.local`)
- [ ] Puedo usar `minikube service` para acceder a Services NodePort
- [ ] Entiendo el balanceo de carga que realizan los Services

## Resumen de Comandos

| Comando                                       | Descripción                        |
| --------------------------------------------- | ---------------------------------- |
| `kubectl get services`                        | Listar todos los Services          |
| `kubectl get svc`                             | Listar Services (forma corta)      |
| `kubectl get service <nombre>`                | Ver un Service específico          |
| `kubectl describe service <nombre>`           | Ver detalles de un Service         |
| `kubectl get endpoints`                       | Listar todos los Endpoints         |
| `kubectl get endpoints <nombre>`              | Ver Endpoints de un Service        |
| `kubectl describe endpoints <nombre>`         | Ver detalles de Endpoints          |
| `kubectl expose deployment <name> --port=<p>` | Crear Service rápidamente          |
| `kubectl delete service <nombre>`             | Eliminar un Service                |
| `minikube service <nombre> --url`             | Obtener URL de un Service NodePort |
| `minikube service <nombre>`                   | Abrir Service en navegador         |
| `minikube ip`                                 | Obtener IP del nodo Minikube       |
| `kubectl run --rm -it --image=busybox -- sh`  | Pod temporal para pruebas de red   |

## Conceptos Aprendidos

1. **Service**: Abstracción que proporciona IP estable y DNS para acceder a Pods
2. **ClusterIP**: Acceso interno únicamente, IP estable dentro del clúster
3. **NodePort**: Acceso externo via `<NodeIP>:<NodePort>`
4. **LoadBalancer**: Acceso externo via balanceador de carga del cloud
5. **Selector**: Define qué Pods pertenecen al Service usando labels
6. **Endpoints**: IPs de Pods que coinciden con el selector
7. **DNS interno**: Services accesibles por nombre dentro del clúster
8. **Balanceo de carga**: kube-proxy distribuye tráfico entre Pods

## Solución

Consulta el directorio `solution/` para ver los scripts con todos los comandos y las salidas esperadas.

## Navegación

- **Anterior**: [Lab 07: Resource Updates](../../modulo-05-kubectl-yaml/lab-07-resource-updates/README.md)
- **Siguiente**: [Lab 09: Ingress](../lab-09-ingress/README.md)
