# Lab 08: Services - Salidas Esperadas

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

## Paso 2: Crear el Deployment Base

### kubectl apply -f initial/deployment-web.yaml

```
$ kubectl apply -f initial/deployment-web.yaml
deployment.apps/web-app created
```

### kubectl get pods -l app=web -o wide

```
$ kubectl get pods -l app=web -o wide
NAME                       READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
web-app-6d8f7b9c5d-abc12   1/1     Running   0          30s   10.244.0.5   minikube   <none>           <none>
web-app-6d8f7b9c5d-def34   1/1     Running   0          30s   10.244.0.6   minikube   <none>           <none>
web-app-6d8f7b9c5d-ghi56   1/1     Running   0          30s   10.244.0.7   minikube   <none>           <none>
```

**Explicación de columnas**:

| Columna  | Descripción                                          |
| -------- | ---------------------------------------------------- |
| `NAME`   | Nombre del Pod (incluye hash del ReplicaSet)         |
| `READY`  | Contenedores listos / Total de contenedores          |
| `STATUS` | Estado del Pod (Running, Pending, ContainerCreating) |
| `IP`     | IP interna del Pod (efímera, cambia si se recrea)    |
| `NODE`   | Nodo donde corre el Pod                              |

## Paso 4: Crear Service ClusterIP

### kubectl apply -f initial/service-clusterip.yaml

```
$ kubectl apply -f initial/service-clusterip.yaml
service/web-clusterip created
```

### kubectl get service web-clusterip

```
$ kubectl get service web-clusterip
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
web-clusterip   ClusterIP   10.96.100.50    <none>        80/TCP    30s
```

**Explicación de columnas**:

| Columna       | Descripción                                         |
| ------------- | --------------------------------------------------- |
| `TYPE`        | Tipo de Service (ClusterIP, NodePort, LoadBalancer) |
| `CLUSTER-IP`  | IP interna estable del Service                      |
| `EXTERNAL-IP` | IP externa (solo para LoadBalancer)                 |
| `PORT(S)`     | Puerto(s) expuesto(s) por el Service                |

## Paso 5: Inspeccionar Endpoints

### kubectl get endpoints web-clusterip

```
$ kubectl get endpoints web-clusterip
NAME            ENDPOINTS                                      AGE
web-clusterip   10.244.0.5:80,10.244.0.6:80,10.244.0.7:80      1m
```

### kubectl describe endpoints web-clusterip

```
$ kubectl describe endpoints web-clusterip
Name:         web-clusterip
Namespace:    default
Labels:       app=web
Annotations:  endpoints.kubernetes.io/last-change-trigger-time: 2024-01-15T10:30:00Z
Subsets:
  Addresses:          10.244.0.5,10.244.0.6,10.244.0.7
  NotReadyAddresses:  <none>
  Ports:
    Name  Port  Protocol
    ----  ----  --------
    http  80    TCP

Events:  <none>
```

**Explicación**:

| Campo               | Descripción                                      |
| ------------------- | ------------------------------------------------ |
| `Addresses`         | IPs de Pods listos que coinciden con el selector |
| `NotReadyAddresses` | IPs de Pods que aún no están listos              |
| `Ports`             | Puertos disponibles en los endpoints             |

## Paso 6: Probar Conectividad Interna

### wget desde pod de prueba

```
$ kubectl exec test-client -- wget -qO- http://web-clusterip
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>
...
</body>
</html>
```

### nslookup del Service

```
$ kubectl exec test-client -- nslookup web-clusterip
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      web-clusterip
Address 1: 10.96.100.50 web-clusterip.default.svc.cluster.local
```

**Explicación**:

- El servidor DNS es CoreDNS (10.96.0.10)
- El Service resuelve a su ClusterIP (10.96.100.50)
- El FQDN es `web-clusterip.default.svc.cluster.local`

## Paso 7: Crear Service NodePort

### kubectl apply -f initial/service-nodeport.yaml

```
$ kubectl apply -f initial/service-nodeport.yaml
service/web-nodeport created
```

### kubectl get service web-nodeport

```
$ kubectl get service web-nodeport
NAME           TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
web-nodeport   NodePort   10.96.150.75    <none>        80:30080/TCP   30s
```

**Explicación de PORT(S)**:

- `80:30080/TCP` significa:
  - Puerto 80: puerto del Service dentro del clúster
  - Puerto 30080: puerto expuesto en cada nodo
  - TCP: protocolo

## Paso 8: Acceder desde Fuera del Clúster

### minikube service web-nodeport --url

```
$ minikube service web-nodeport --url
http://192.168.49.2:30080
```

### minikube ip

```
$ minikube ip
192.168.49.2
```

### curl al NodePort

```
$ curl http://192.168.49.2:30080
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
</body>
</html>
```

## Paso 9: Crear Service con kubectl expose

### kubectl expose

```
$ kubectl expose deployment web-app --name=web-exposed --port=8080 --target-port=80
service/web-exposed exposed
```

### kubectl get service web-exposed

```
$ kubectl get service web-exposed
NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
web-exposed   ClusterIP   10.96.200.25    <none>        8080/TCP   30s
```

### kubectl describe service web-exposed

```
$ kubectl describe service web-exposed
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

**Explicación**:

| Campo              | Descripción                                     |
| ------------------ | ----------------------------------------------- |
| `Port`             | Puerto donde escucha el Service (8080)          |
| `TargetPort`       | Puerto del contenedor (80)                      |
| `Endpoints`        | IPs de los Pods backend                         |
| `Session Affinity` | Afinidad de sesión (None = sin sticky sessions) |

## Paso 10: Comparar Todos los Services

### kubectl get services

```
$ kubectl get services
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kubernetes      ClusterIP   10.96.0.1       <none>        443/TCP        1d
web-clusterip   ClusterIP   10.96.100.50    <none>        80/TCP         10m
web-exposed     ClusterIP   10.96.200.25    <none>        8080/TCP       2m
web-nodeport    NodePort    10.96.150.75    <none>        80:30080/TCP   5m
```

### kubectl get endpoints

```
$ kubectl get endpoints
NAME            ENDPOINTS                                      AGE
kubernetes      192.168.49.2:8443                              1d
web-clusterip   10.244.0.5:80,10.244.0.6:80,10.244.0.7:80      10m
web-exposed     10.244.0.5:80,10.244.0.6:80,10.244.0.7:80      2m
web-nodeport    10.244.0.5:80,10.244.0.6:80,10.244.0.7:80      5m
```

> **Nota**: Los tres Services tienen los mismos endpoints porque comparten el mismo selector (`app: web`).

## Paso 11: Verificar Balanceo de Carga

### Múltiples requests

```
$ for i in $(seq 1 5); do curl -s http://192.168.49.2:30080; done
<h1>Pod: web-app-6d8f7b9c5d-abc12</h1>
<h1>Pod: web-app-6d8f7b9c5d-ghi56</h1>
<h1>Pod: web-app-6d8f7b9c5d-def34</h1>
<h1>Pod: web-app-6d8f7b9c5d-abc12</h1>
<h1>Pod: web-app-6d8f7b9c5d-def34</h1>
```

> **Nota**: Las respuestas provienen de diferentes Pods, demostrando el balanceo de carga.

## Paso 12: Escalar y Observar Endpoints

### Antes de escalar (3 réplicas)

```
$ kubectl get endpoints web-clusterip
NAME            ENDPOINTS                                      AGE
web-clusterip   10.244.0.5:80,10.244.0.6:80,10.244.0.7:80      15m
```

### kubectl scale

```
$ kubectl scale deployment web-app --replicas=5
deployment.apps/web-app scaled
```

### Después de escalar (5 réplicas)

```
$ kubectl get endpoints web-clusterip
NAME            ENDPOINTS                                                        AGE
web-clusterip   10.244.0.5:80,10.244.0.6:80,10.244.0.7:80,10.244.0.8:80,10.244.0.9:80   15m
```

> **Nota**: Los endpoints se actualizan automáticamente cuando se escala el Deployment.

## Paso 13: Service con Múltiples Labels

### kubectl apply -f initial/service-multi-selector.yaml

```
$ kubectl apply -f initial/service-multi-selector.yaml
service/web-v1-only created
```

### kubectl get service web-v1-only

```
$ kubectl get service web-v1-only
NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
web-v1-only   ClusterIP   10.96.175.30    <none>        80/TCP    30s
```

### kubectl get endpoints web-v1-only

```
$ kubectl get endpoints web-v1-only
NAME          ENDPOINTS                                      AGE
web-v1-only   10.244.0.5:80,10.244.0.6:80,10.244.0.7:80      30s
```

> **Nota**: Este Service solo selecciona Pods con labels `app: web` Y `version: v1`.

## Paso 14: Limpiar Recursos

### kubectl delete services

```
$ kubectl delete service web-clusterip web-nodeport web-exposed web-v1-only
service "web-clusterip" deleted
service "web-nodeport" deleted
service "web-exposed" deleted
service "web-v1-only" deleted
```

### kubectl delete deployment

```
$ kubectl delete deployment web-app
deployment.apps "web-app" deleted
```

### Verificación final

```
$ kubectl get all
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   1d
```

## Ejercicios Adicionales

### Ejercicio 1: Service Headless

```
$ kubectl get service web-headless
NAME           TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
web-headless   ClusterIP   None         <none>        80/TCP    30s
```

```
$ kubectl run test-dns --image=busybox:1.36 --rm -it --restart=Never -- nslookup web-headless
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      web-headless
Address 1: 10.244.0.5 web-app-6d8f7b9c5d-abc12
Address 2: 10.244.0.6 web-app-6d8f7b9c5d-def34
Address 3: 10.244.0.7 web-app-6d8f7b9c5d-ghi56
```

> **Nota**: Un Service headless (`clusterIP: None`) resuelve directamente a las IPs de los Pods.

### Ejercicio 2: LoadBalancer con Minikube Tunnel

```
$ kubectl get service web-loadbalancer
NAME               TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
web-loadbalancer   LoadBalancer   10.96.180.50    <pending>     80:31234/TCP   30s
```

Después de ejecutar `minikube tunnel`:

```
$ kubectl get service web-loadbalancer
NAME               TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)        AGE
web-loadbalancer   LoadBalancer   10.96.180.50    10.96.180.50   80:31234/TCP   1m
```

### Ejercicio 3: ExternalName Service

```
$ kubectl get service external-api
NAME           TYPE           CLUSTER-IP   EXTERNAL-IP       PORT(S)   AGE
external-api   ExternalName   <none>       api.example.com   <none>    30s
```

> **Nota**: Un Service ExternalName no tiene ClusterIP ni endpoints, solo un alias DNS.

## Resumen

Si todas tus salidas son similares a las mostradas en este documento, has completado exitosamente el Lab 08.

Las diferencias menores que puedes esperar:

- **IPs**: ClusterIP y Pod IPs varían según tu clúster
- **Nombres de Pods**: Los sufijos aleatorios (como `-abc12`) serán diferentes
- **Timestamps y AGE**: Dependen de cuándo ejecutaste los comandos
- **Puerto NodePort**: Si no especificas, Kubernetes asigna uno aleatorio en 30000-32767

### Conceptos Clave Aprendidos

| Concepto     | Descripción                                            |
| ------------ | ------------------------------------------------------ |
| ClusterIP    | IP estable para acceso interno al clúster              |
| NodePort     | Puerto en cada nodo para acceso externo (30000-32767)  |
| LoadBalancer | IP externa via balanceador de carga del cloud          |
| Selector     | Labels que definen qué Pods pertenecen al Service      |
| Endpoints    | IPs de Pods que coinciden con el selector              |
| DNS interno  | `<service>.<namespace>.svc.cluster.local`              |
| Balanceo     | kube-proxy distribuye tráfico entre Pods (round-robin) |
