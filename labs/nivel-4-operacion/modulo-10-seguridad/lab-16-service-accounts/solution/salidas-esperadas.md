# Lab 16: Service Accounts - Salidas Esperadas

Este documento muestra las salidas esperadas de cada comando del laboratorio para que puedas verificar que todo funciona correctamente.

## Paso 1: Explorar ServiceAccount por defecto

### kubectl get serviceaccounts

```
$ kubectl get serviceaccounts
NAME      SECRETS   AGE
default   0         30d
```

**Nota**: En Kubernetes 1.24+, la columna SECRETS muestra 0 porque los tokens ya no se crean automaticamente como Secrets.

### kubectl describe serviceaccount default

```
$ kubectl describe serviceaccount default
Name:                default
Namespace:           default
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   <none>
Tokens:              <none>
Events:              <none>
```

**Explicacion de campos**:

| Campo                | Descripcion                                   |
| -------------------- | --------------------------------------------- |
| `Name`               | Nombre del ServiceAccount                     |
| `Namespace`          | Namespace donde existe                        |
| `Image pull secrets` | Secrets para descargar imagenes privadas      |
| `Mountable secrets`  | Secrets que este SA puede montar              |
| `Tokens`             | Secrets de token asociados (legacy, pre-1.24) |

## Paso 2: Crear ServiceAccount personalizado

### Contenido de serviceaccount.yaml

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  namespace: default
```

### kubectl apply -f serviceaccount.yaml

```
$ kubectl apply -f initial/serviceaccount.yaml
serviceaccount/app-service-account created
```

### kubectl describe serviceaccount app-service-account

```
$ kubectl describe serviceaccount app-service-account
Name:                app-service-account
Namespace:           default
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   <none>
Tokens:              <none>
Events:              <none>
```

### kubectl get serviceaccounts

```
$ kubectl get serviceaccounts
NAME                  SECRETS   AGE
app-service-account   0         10s
default               0         30d
```

## Paso 3: Vincular ServiceAccount a un Role

### Contenido de sa-rolebinding.yaml

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-manager
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "create", "delete"]
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-sa-binding
subjects:
  - kind: ServiceAccount
    name: app-service-account
    namespace: default
roleRef:
  kind: Role
  name: pod-manager
  apiGroup: rbac.authorization.k8s.io
```

### kubectl apply -f sa-rolebinding.yaml

```
$ kubectl apply -f initial/sa-rolebinding.yaml
role.rbac.authorization.k8s.io/pod-manager created
rolebinding.rbac.authorization.k8s.io/app-sa-binding created
```

### kubectl describe role pod-manager

```
$ kubectl describe role pod-manager
Name:         pod-manager
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources   Non-Resource URLs  Resource Names  Verbs
  ---------   -----------------  --------------  -----
  configmaps  []                 []              [get list]
  pods        []                 []              [get list create delete]
```

### kubectl describe rolebinding app-sa-binding

```
$ kubectl describe rolebinding app-sa-binding
Name:         app-sa-binding
Labels:       <none>
Annotations:  <none>
Role:
  Kind:  Role
  Name:  pod-manager
Subjects:
  Kind            Name                 Namespace
  ----            ----                 ---------
  ServiceAccount  app-service-account  default
```

### Verificar permisos

```
$ kubectl auth can-i list pods --as=system:serviceaccount:default:app-service-account
yes

$ kubectl auth can-i list configmaps --as=system:serviceaccount:default:app-service-account
yes

$ kubectl auth can-i list secrets --as=system:serviceaccount:default:app-service-account
no
```

## Paso 4: Crear Pod con ServiceAccount

### Contenido de pod-with-sa.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-sa
spec:
  serviceAccountName: app-service-account
  containers:
    - name: app
      image: bitnami/kubectl:latest
      command: ["sleep", "3600"]
```

### kubectl apply -f pod-with-sa.yaml

```
$ kubectl apply -f initial/pod-with-sa.yaml
pod/pod-with-sa created
```

### Verificar ServiceAccount del Pod

```
$ kubectl get pod pod-with-sa -o yaml | grep serviceAccountName
  serviceAccountName: app-service-account
```

## Paso 5: Verificar token montado en el pod

### Ver archivos montados

```
$ kubectl exec pod-with-sa -- ls -la /var/run/secrets/kubernetes.io/serviceaccount/
total 0
drwxrwxrwt    3 root     root           140 Jan 15 10:00 .
drwxr-xr-x    3 root     root            60 Jan 15 10:00 ..
drwxr-xr-x    2 root     root           100 Jan 15 10:00 ..data
lrwxrwxrwx    1 root     root            13 Jan 15 10:00 ca.crt -> ..data/ca.crt
lrwxrwxrwx    1 root     root            16 Jan 15 10:00 namespace -> ..data/namespace
lrwxrwxrwx    1 root     root            12 Jan 15 10:00 token -> ..data/token
```

**Archivos montados**:

| Archivo     | Descripcion                             |
| ----------- | --------------------------------------- |
| `ca.crt`    | Certificado CA del cluster              |
| `namespace` | Namespace donde corre el pod            |
| `token`     | Token JWT para autenticacion con la API |

### Ver contenido del namespace

```
$ kubectl exec pod-with-sa -- cat /var/run/secrets/kubernetes.io/serviceaccount/namespace
default
```

### Ver el token (primeros caracteres)

```
$ kubectl exec pod-with-sa -- cat /var/run/secrets/kubernetes.io/serviceaccount/token | head -c 50
eyJhbGciOiJSUzI1NiIsImtpZCI6IjVtNEp...
```

> **Nota**: El token es un JWT (JSON Web Token) firmado por el cluster.

## Paso 6: Acceder a la API desde el pod

### Listar pods desde dentro del pod

```
$ kubectl exec pod-with-sa -- kubectl get pods
NAME          READY   STATUS    RESTARTS   AGE
pod-with-sa   1/1     Running   0          5m
```

### Listar configmaps

```
$ kubectl exec pod-with-sa -- kubectl get configmaps
NAME               DATA   AGE
kube-root-ca.crt   1      30d
```

### Intentar listar secrets (deberia fallar)

```
$ kubectl exec pod-with-sa -- kubectl get secrets
Error from server (Forbidden): secrets is forbidden: User "system:serviceaccount:default:app-service-account" cannot list resource "secrets" in API group "" in the namespace "default"
```

### Intentar listar deployments (deberia fallar)

```
$ kubectl exec pod-with-sa -- kubectl get deployments
Error from server (Forbidden): deployments.apps is forbidden: User "system:serviceaccount:default:app-service-account" cannot list resource "deployments" in API group "apps" in the namespace "default"
```

> **Importante**: El ServiceAccount solo tiene los permisos definidos en el Role.

## Paso 7: ServiceAccount sin montar token automatico

### Contenido de sa-no-automount.yaml

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: restricted-sa
automountServiceAccountToken: false
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-restricted-sa
spec:
  serviceAccountName: restricted-sa
  containers:
    - name: app
      image: nginx:alpine
```

### kubectl apply -f sa-no-automount.yaml

```
$ kubectl apply -f initial/sa-no-automount.yaml
serviceaccount/restricted-sa created
pod/pod-restricted-sa created
```

### Verificar que NO hay token montado

```
$ kubectl exec pod-restricted-sa -- ls /var/run/secrets/kubernetes.io/serviceaccount/ 2>/dev/null
ls: /var/run/secrets/kubernetes.io/serviceaccount/: No such file or directory
```

> **Buena practica**: Usar `automountServiceAccountToken: false` para pods que no necesitan acceder a la API de Kubernetes.

## Paso 8: Crear token manualmente

### Crear token con duracion especifica

```
$ kubectl create token app-service-account --duration=1h
eyJhbGciOiJSUzI1NiIsImtpZCI6IjVtNEpTa0...
```

### Usar el token para autenticarse

```
$ TOKEN=$(kubectl create token app-service-account)
$ kubectl get pods --token=$TOKEN
NAME                READY   STATUS    RESTARTS   AGE
pod-with-sa         1/1     Running   0          10m
pod-restricted-sa   1/1     Running   0          5m
```

### Tipos de tokens en Kubernetes

| Tipo             | Descripcion                                |
| ---------------- | ------------------------------------------ |
| Legacy tokens    | Secrets creados automaticamente (pre-1.24) |
|                  | Sin expiracion, menos seguros              |
| Bound tokens     | TokenRequest API (Kubernetes 1.20+)        |
|                  | Tiempo limitado, audience binding          |
| Projected tokens | Montados en pods via projected volume      |
|                  | Rotan automaticamente cada hora            |

## Acceso directo a la API con curl

### Desde dentro del pod

```bash
# Obtener pods usando curl
curl -s \
  --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  https://kubernetes.default.svc/api/v1/namespaces/default/pods
```

**Salida esperada (JSON)**:

```json
{
  "kind": "PodList",
  "apiVersion": "v1",
  "metadata": {
    "resourceVersion": "12345"
  },
  "items": [
    {
      "metadata": {
        "name": "pod-with-sa",
        ...
      }
    }
  ]
}
```

## ServiceAccount vs User Account

| Caracteristica | ServiceAccount                    | User Account                  |
| -------------- | --------------------------------- | ----------------------------- |
| Proposito      | Procesos en pods                  | Usuarios humanos              |
| Scope          | Namespace                         | Cluster                       |
| Creacion       | API de Kubernetes                 | Externo (certificados, OIDC)  |
| Nombre formato | system:serviceaccount:<ns>:<name> | Usuario definido externamente |
| Autenticacion  | Token JWT                         | Certificados, tokens, etc.    |

## Limpieza

### Eliminar Pods

```
$ kubectl delete pod pod-with-sa pod-restricted-sa
pod "pod-with-sa" deleted
pod "pod-restricted-sa" deleted
```

### Eliminar ServiceAccounts

```
$ kubectl delete serviceaccount app-service-account restricted-sa
serviceaccount "app-service-account" deleted
serviceaccount "restricted-sa" deleted
```

### Eliminar Role y RoleBinding

```
$ kubectl delete role pod-manager
role.rbac.authorization.k8s.io "pod-manager" deleted

$ kubectl delete rolebinding app-sa-binding
rolebinding.rbac.authorization.k8s.io "app-sa-binding" deleted
```

### Verificacion final

```
$ kubectl get serviceaccounts
NAME      SECRETS   AGE
default   0         30d
```

## Resumen

Si todas tus salidas son similares a las mostradas en este documento, has completado exitosamente el Lab 16.

### Diferencias menores esperadas

- **Timestamps**: Varian segun cuando ejecutaste los comandos
- **Tokens**: Son unicos para cada ejecucion
- **Nombres de recursos**: Pueden tener sufijos diferentes

### Conceptos Clave Aprendidos

| Concepto                        | Descripcion                                      |
| ------------------------------- | ------------------------------------------------ |
| ServiceAccount                  | Identidad para aplicaciones/pods en Kubernetes   |
| serviceAccountName              | Campo en Pod spec para especificar el SA         |
| automountServiceAccountToken    | Controla si el token se monta automaticamente    |
| system:serviceaccount:<ns>:<sa> | Formato completo del nombre del SA               |
| Token projected volume          | Tokens rotados automaticamente, montados en pods |
| kubectl create token            | Crear tokens con expiracion especifica           |

### Buenas Practicas

1. **No usar default**: Crear ServiceAccounts especificos por aplicacion
2. **Minimo privilegio**: Solo asignar los permisos necesarios
3. **Deshabilitar automount**: Si el pod no necesita acceso a la API
4. **Tokens cortos**: Usar tokens con expiracion cuando sea posible
5. **RBAC especifico**: Un Role por ServiceAccount es ideal
