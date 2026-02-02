# Lab 09: Ingress - Salidas Esperadas

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

## Paso 2: Habilitar el Ingress Controller en Minikube

### minikube addons enable ingress

```
$ minikube addons enable ingress
💡  ingress is an addon maintained by Kubernetes. For any concerns contact minikube on GitHub.
🔎  Verifying ingress addon...
🌟  The 'ingress' addon is enabled
```

### kubectl get pods -n ingress-nginx

```
$ kubectl get pods -n ingress-nginx
NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-xxxxx        0/1     Completed   0          1m
ingress-nginx-admission-patch-xxxxx         0/1     Completed   0          1m
ingress-nginx-controller-xxxxxxxxxx-xxxxx   1/1     Running     0          1m
```

**Explicación de pods**:

| Pod                              | Descripción                                      |
| -------------------------------- | ------------------------------------------------ |
| `ingress-nginx-admission-create` | Job que crea recursos de admisión (Completed)    |
| `ingress-nginx-admission-patch`  | Job que parchea recursos de admisión (Completed) |
| `ingress-nginx-controller`       | El controlador principal del Ingress (Running)   |

### kubectl wait --namespace ingress-nginx...

```
$ kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
pod/ingress-nginx-controller-xxxxxxxxxx-xxxxx condition met
```

## Paso 3: Desplegar las Aplicaciones de Ejemplo

### kubectl apply -f initial/apps.yaml

```
$ kubectl apply -f initial/apps.yaml
deployment.apps/app-frontend created
service/frontend-svc created
deployment.apps/app-backend created
service/backend-svc created
```

### kubectl get deployments

```
$ kubectl get deployments
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
app-backend    2/2     2            2           30s
app-frontend   2/2     2            2           30s
```

### kubectl get services

```
$ kubectl get services
NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
backend-svc    ClusterIP   10.96.123.45     <none>        80/TCP    30s
frontend-svc   ClusterIP   10.96.234.56     <none>        80/TCP    30s
kubernetes     ClusterIP   10.96.0.1        <none>        443/TCP   1d
```

> **Nota**: Las direcciones CLUSTER-IP serán diferentes en tu entorno.

### kubectl get pods -l 'app in (frontend, backend)'

```
$ kubectl get pods -l 'app in (frontend, backend)'
NAME                            READY   STATUS    RESTARTS   AGE
app-backend-7d8f9c6b5d-abc12    1/1     Running   0          30s
app-backend-7d8f9c6b5d-def34    1/1     Running   0          30s
app-frontend-5f6g7h8i9j-ghi56   1/1     Running   0          30s
app-frontend-5f6g7h8i9j-jkl78   1/1     Running   0          30s
```

## Paso 4: Crear Ingress con Reglas de Path

### kubectl apply -f initial/ingress-path.yaml

```
$ kubectl apply -f initial/ingress-path.yaml
ingress.networking.k8s.io/app-ingress created
```

### kubectl get ingress

```
$ kubectl get ingress
NAME          CLASS   HOSTS   ADDRESS        PORTS   AGE
app-ingress   nginx   *       192.168.49.2   80      30s
```

**Explicación de columnas**:

| Columna   | Descripción                                         |
| --------- | --------------------------------------------------- |
| `NAME`    | Nombre del Ingress                                  |
| `CLASS`   | IngressClass que maneja este Ingress (nginx)        |
| `HOSTS`   | Hosts configurados (\* = todos)                     |
| `ADDRESS` | IP donde el Ingress está escuchando                 |
| `PORTS`   | Puertos disponibles (80 HTTP, 443 HTTPS si hay TLS) |
| `AGE`     | Tiempo desde que se creó                            |

> **Nota**: El ADDRESS puede tardar unos segundos en aparecer.

### kubectl describe ingress app-ingress

```
$ kubectl describe ingress app-ingress
Name:             app-ingress
Labels:           <none>
Namespace:        default
Address:          192.168.49.2
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  *
              /frontend   frontend-svc:80 (10.244.0.5:80,10.244.0.6:80)
              /backend    backend-svc:80 (10.244.0.7:80,10.244.0.8:80)
Annotations:  nginx.ingress.kubernetes.io/rewrite-target: /
Events:
  Type    Reason  Age   From                      Message
  ----    ------  ----  ----                      -------
  Normal  Sync    30s   nginx-ingress-controller  Scheduled for sync
```

**Secciones importantes**:

| Sección         | Descripción                                    |
| --------------- | ---------------------------------------------- |
| `Ingress Class` | El Ingress Controller que maneja este Ingress  |
| `Rules`         | Reglas de enrutamiento (Host, Path, Backend)   |
| `Backends`      | IPs de los pods que reciben el tráfico         |
| `Annotations`   | Configuración adicional del Ingress Controller |
| `Events`        | Historial de eventos del Ingress               |

## Paso 5: Probar el Enrutamiento por Path

### minikube ip

```
$ minikube ip
192.168.49.2
```

### curl http://$(minikube ip)/frontend

```
$ curl http://192.168.49.2/frontend
<!DOCTYPE html>
<html>
<head><title>Frontend App</title></head>
<body>
<h1>Frontend Application</h1>
<p>Hostname: app-frontend-5f6g7h8i9j-ghi56</p>
<p>Esta es la aplicacion FRONTEND servida por NGINX</p>
</body>
</html>
```

### curl http://$(minikube ip)/backend

```
$ curl http://192.168.49.2/backend
<!DOCTYPE html>
<html>
<head><title>Backend App</title></head>
<body>
<h1>Backend Application</h1>
<p>Hostname: app-backend-7d8f9c6b5d-abc12</p>
<p>Esta es la aplicacion BACKEND servida por Apache HTTPD</p>
</body>
</html>
```

> **Nota**: El Hostname mostrará diferentes pods en cada petición debido al balanceo de carga.

## Paso 6: Crear Ingress con Reglas de Host

### kubectl apply -f initial/ingress-host.yaml

```
$ kubectl apply -f initial/ingress-host.yaml
ingress.networking.k8s.io/app-ingress-host created
```

### kubectl get ingress

```
$ kubectl get ingress
NAME               CLASS   HOSTS                         ADDRESS        PORTS   AGE
app-ingress        nginx   *                             192.168.49.2   80      5m
app-ingress-host   nginx   frontend.local,backend.local  192.168.49.2   80      30s
```

> **Observa**: El Ingress `app-ingress-host` muestra los hosts específicos configurados.

## Paso 7: Configurar /etc/hosts

### echo "$(minikube ip) frontend.local backend.local" | sudo tee -a /etc/hosts

```
$ echo "$(minikube ip) frontend.local backend.local" | sudo tee -a /etc/hosts
192.168.49.2 frontend.local backend.local
```

### tail -2 /etc/hosts

```
$ tail -2 /etc/hosts
# Minikube Ingress Lab
192.168.49.2 frontend.local backend.local
```

## Paso 8: Probar el Enrutamiento por Host

### curl http://frontend.local

```
$ curl http://frontend.local
<!DOCTYPE html>
<html>
<head><title>Frontend App</title></head>
<body>
<h1>Frontend Application</h1>
<p>Hostname: app-frontend-5f6g7h8i9j-jkl78</p>
<p>Esta es la aplicacion FRONTEND servida por NGINX</p>
</body>
</html>
```

### curl http://backend.local

```
$ curl http://backend.local
<!DOCTYPE html>
<html>
<head><title>Backend App</title></head>
<body>
<h1>Backend Application</h1>
<p>Hostname: app-backend-7d8f9c6b5d-def34</p>
<p>Esta es la aplicacion BACKEND servida por Apache HTTPD</p>
</body>
</html>
```

### Alternativa: curl -H "Host: frontend.local" http://$(minikube ip)

```
$ curl -H "Host: frontend.local" http://192.168.49.2
<!DOCTYPE html>
<html>
<head><title>Frontend App</title></head>
<body>
<h1>Frontend Application</h1>
<p>Hostname: app-frontend-5f6g7h8i9j-ghi56</p>
<p>Esta es la aplicacion FRONTEND servida por NGINX</p>
</body>
</html>
```

> **Tip**: Usar el header Host con curl funciona sin necesidad de modificar `/etc/hosts`.

## Paso 9: Explorar Anotaciones del Ingress Controller

### kubectl get configmap -n ingress-nginx

```
$ kubectl get configmap -n ingress-nginx
NAME                       DATA   AGE
ingress-nginx-controller   1      10m
kube-root-ca.crt           1      10m
```

## Paso 10: Ver Logs del Ingress Controller

### kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=20

```
$ kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=20
192.168.49.1 - - [01/Jan/2024:12:00:00 +0000] "GET /frontend HTTP/1.1" 200 250 "-" "curl/7.81.0" 84 0.002 [default-frontend-svc-80] [] 10.244.0.5:80 250 0.002 200 abc123
192.168.49.1 - - [01/Jan/2024:12:00:05 +0000] "GET /backend HTTP/1.1" 200 248 "-" "curl/7.81.0" 83 0.003 [default-backend-svc-80] [] 10.244.0.7:80 248 0.003 200 def456
192.168.49.1 - - [01/Jan/2024:12:00:10 +0000] "GET / HTTP/1.1" 200 250 "-" "curl/7.81.0" 90 0.002 [default-frontend-svc-80] [] 10.244.0.6:80 250 0.002 200 ghi789
```

**Formato del log**:

```
IP_CLIENTE - - [TIMESTAMP] "MÉTODO PATH PROTOCOLO" STATUS BYTES "REFERER" "USER_AGENT" REQUEST_LENGTH REQUEST_TIME [UPSTREAM_NAME] [ALT_UPSTREAM] UPSTREAM_ADDR UPSTREAM_RESPONSE_LENGTH UPSTREAM_RESPONSE_TIME UPSTREAM_STATUS REQUEST_ID
```

## Paso 11: Limpiar los Recursos

### kubectl delete ingress app-ingress app-ingress-host

```
$ kubectl delete ingress app-ingress app-ingress-host
ingress.networking.k8s.io "app-ingress" deleted
ingress.networking.k8s.io "app-ingress-host" deleted
```

### kubectl delete -f initial/apps.yaml

```
$ kubectl delete -f initial/apps.yaml
deployment.apps "app-frontend" deleted
service "frontend-svc" deleted
deployment.apps "app-backend" deleted
service "backend-svc" deleted
```

### kubectl get ingress (después de limpiar)

```
$ kubectl get ingress
No resources found in default namespace.
```

### kubectl get deployments (después de limpiar)

```
$ kubectl get deployments
No resources found in default namespace.
```

### kubectl get services (después de limpiar)

```
$ kubectl get services
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   1d
```

> **Nota**: El service `kubernetes` es un servicio del sistema que siempre existe.

## Resumen

Si todas tus salidas son similares a las mostradas en este documento, has completado exitosamente el Lab 09.

Las diferencias menores que puedes esperar:

- **Nombres de pods**: Los sufijos aleatorios serán diferentes
- **IPs**: Las direcciones IP de los pods y del Ingress variarán
- **Timestamps**: Dependen de cuándo ejecutaste los comandos
- **ADDRESS del Ingress**: La IP depende de tu configuración de Minikube

### Conceptos Clave Demostrados

| Concepto           | Demostración                                               |
| ------------------ | ---------------------------------------------------------- |
| Ingress Controller | Habilitado con `minikube addons enable ingress`            |
| Path-based routing | `/frontend` → frontend-svc, `/backend` → backend-svc       |
| Host-based routing | frontend.local → frontend-svc, backend.local → backend-svc |
| Rewrite-target     | El path se reescribe antes de enviarlo al backend          |
| IngressClass       | `nginx` especifica qué controlador usar                    |
| Annotations        | Configuran comportamiento específico del controlador       |

### Troubleshooting Común

| Problema                                    | Solución                                                       |
| ------------------------------------------- | -------------------------------------------------------------- |
| ADDRESS no aparece en `kubectl get ingress` | Espera unos segundos o verifica que el controller está Running |
| curl no conecta                             | Verifica la IP con `minikube ip`, prueba `minikube tunnel`     |
| 404 en las rutas                            | Verifica que los services y deployments existen                |
| 503 Service Unavailable                     | Los pods pueden no estar listos, espera y reintenta            |
| /etc/hosts no funciona                      | Verifica que usaste sudo y la IP correcta                      |
