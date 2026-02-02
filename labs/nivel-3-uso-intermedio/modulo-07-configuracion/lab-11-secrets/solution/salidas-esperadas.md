# Lab 11: Secrets - Salidas Esperadas

Este documento muestra las salidas esperadas de cada comando del laboratorio para que puedas verificar que todo funciona correctamente.

## Paso 1: Crear Secret desde Literales

### kubectl create secret generic

```
$ kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=supersecret123
secret/db-credentials created
```

### kubectl get secret db-credentials

```
$ kubectl get secret db-credentials
NAME             TYPE     DATA   AGE
db-credentials   Opaque   2      10s
```

**Explicacion de columnas**:

| Columna | Descripcion                        |
| ------- | ---------------------------------- |
| `NAME`  | Nombre del Secret                  |
| `TYPE`  | Tipo de Secret (Opaque = generico) |
| `DATA`  | Numero de claves en el Secret      |
| `AGE`   | Tiempo desde la creacion           |

### kubectl describe secret db-credentials

```
$ kubectl describe secret db-credentials
Name:         db-credentials
Namespace:    default
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
password:  15 bytes
username:  5 bytes
```

> **Nota**: `kubectl describe` NO muestra los valores, solo el tamano en bytes.

### kubectl get secret db-credentials -o yaml

```yaml
$ kubectl get secret db-credentials -o yaml
apiVersion: v1
data:
  password: c3VwZXJzZWNyZXQxMjM=
  username: YWRtaW4=
kind: Secret
metadata:
  creationTimestamp: "2024-01-15T10:00:00Z"
  name: db-credentials
  namespace: default
  resourceVersion: "12345"
  uid: abc123-def456-ghi789
type: Opaque
```

> **ADVERTENCIA**: Los valores estan en base64, que es facilmente decodificable. NO es encriptacion.

## Paso 2: Decodificar Valores

### Decodificar username

```
$ kubectl get secret db-credentials -o jsonpath='{.data.username}' | base64 -d
admin
```

### Decodificar password

```
$ kubectl get secret db-credentials -o jsonpath='{.data.password}' | base64 -d
supersecret123
```

### Decodificacion con echo

```
$ echo "YWRtaW4=" | base64 -d
admin

$ echo "c3VwZXJzZWNyZXQxMjM=" | base64 -d
supersecret123
```

> **IMPORTANTE**: Cualquier persona con acceso al Secret puede decodificar los valores. base64 es solo codificacion, NO encriptacion.

## Paso 3: Crear Secret con YAML

### Codificar valores en base64

```
$ echo -n 'api-key-1234567890' | base64
YXBpLWtleS0xMjM0NTY3ODkw

$ echo -n 'super-secret-jwt-key' | base64
c3VwZXItc2VjcmV0LWp3dC1rZXk=
```

> **Nota**: Usar `-n` con echo evita agregar un salto de linea al final.

### Contenido del archivo secret.yaml

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  # Valores codificados en base64
  api-key: YXBpLWtleS0xMjM0NTY3ODkw
  jwt-secret: c3VwZXItc2VjcmV0LWp3dC1rZXk=
stringData:
  # stringData permite valores sin codificar
  database-url: postgres://user:pass@host:5432/db
```

### kubectl apply -f secret.yaml

```
$ kubectl apply -f initial/secret.yaml
secret/app-secrets created
```

### kubectl describe secret app-secrets

```
$ kubectl describe secret app-secrets
Name:         app-secrets
Namespace:    default
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
api-key:       18 bytes
database-url:  33 bytes
jwt-secret:    20 bytes
```

### Verificar que stringData se convirtio a base64

```
$ kubectl get secret app-secrets -o jsonpath='{.data.database-url}' | base64 -d
postgres://user:pass@host:5432/db
```

> **Nota**: `stringData` se convierte automaticamente a `data` (base64) cuando se aplica el Secret.

## Paso 4: Usar Secret como Variables de Entorno

### Contenido de pod-secret-env.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-secret-env
spec:
  containers:
    - name: app
      image: nginx:alpine
      env:
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
      envFrom:
        - secretRef:
            name: app-secrets
```

### kubectl apply -f pod-secret-env.yaml

```
$ kubectl apply -f initial/pod-secret-env.yaml
pod/pod-secret-env created
```

### Verificar variables de entorno

```
$ kubectl exec pod-secret-env -- env | grep -E "DB_|api|jwt|database"
DB_USERNAME=admin
DB_PASSWORD=supersecret123
api-key=api-key-1234567890
jwt-secret=super-secret-jwt-key
database-url=postgres://user:pass@host:5432/db
```

> **ADVERTENCIA**: Las credenciales son visibles con `kubectl exec ... env`. Esto es un riesgo de seguridad.

## Paso 5: Montar Secret como Volumen

### Contenido de pod-secret-volume.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-secret-volume
spec:
  containers:
    - name: app
      image: nginx:alpine
      volumeMounts:
        - name: secret-volume
          mountPath: /etc/secrets
          readOnly: true
  volumes:
    - name: secret-volume
      secret:
        secretName: db-credentials
        defaultMode: 0400
```

### kubectl apply -f pod-secret-volume.yaml

```
$ kubectl apply -f initial/pod-secret-volume.yaml
pod/pod-secret-volume created
```

### Ver archivos montados

```
$ kubectl exec pod-secret-volume -- ls -la /etc/secrets
total 0
drwxrwxrwt    3 root     root           120 Jan 15 10:15 .
drwxr-xr-x    1 root     root          4096 Jan 15 10:15 ..
drwxr-xr-x    2 root     root            80 Jan 15 10:15 ..data
lrwxrwxrwx    1 root     root            15 Jan 15 10:15 password -> ..data/password
lrwxrwxrwx    1 root     root            15 Jan 15 10:15 username -> ..data/username
```

> **Nota**: Los archivos son symlinks a `..data/` que permite actualizaciones atomicas.

### Leer contenido de los archivos

```
$ kubectl exec pod-secret-volume -- cat /etc/secrets/username
admin

$ kubectl exec pod-secret-volume -- cat /etc/secrets/password
supersecret123
```

### Verificar permisos restrictivos

```
$ kubectl exec pod-secret-volume -- ls -la /etc/secrets/..data/
total 8
drwxr-xr-x    2 root     root            80 Jan 15 10:15 .
drwxrwxrwt    3 root     root           120 Jan 15 10:15 ..
-r--------    1 root     root            15 Jan 15 10:15 password
-r--------    1 root     root             5 Jan 15 10:15 username
```

> **Nota**: `defaultMode: 0400` hace que los archivos sean solo lectura para el propietario.

## Paso 6: Tipos de Secrets

### Secret para Docker Registry

```
$ kubectl create secret docker-registry my-registry \
  --docker-server=registry.example.com \
  --docker-username=user \
  --docker-password=pass \
  --docker-email=user@example.com
secret/my-registry created
```

### Ver el Secret docker-registry

```
$ kubectl get secret my-registry -o yaml
apiVersion: v1
data:
  .dockerconfigjson: eyJhdXRocyI6eyJyZWdpc3RyeS5leGFtcGxlLmNvbSI6eyJ1c2VybmFtZSI6InVzZXIiLCJwYXNzd29yZCI6InBhc3MiLCJlbWFpbCI6InVzZXJAZXhhbXBsZS5jb20iLCJhdXRoIjoiZFhObGNqcHdZWE56In19fQ==
kind: Secret
metadata:
  name: my-registry
  namespace: default
type: kubernetes.io/dockerconfigjson
```

### Listar todos los Secrets

```
$ kubectl get secrets
NAME             TYPE                             DATA   AGE
db-credentials   Opaque                           2      10m
app-secrets      Opaque                           3      8m
my-registry      kubernetes.io/dockerconfigjson   1      1m
```

### Tipos de Secrets comunes

| Tipo                                  | Descripcion                     | Uso                       |
| ------------------------------------- | ------------------------------- | ------------------------- |
| `Opaque`                              | Datos arbitrarios (por defecto) | Configuracion general     |
| `kubernetes.io/dockerconfigjson`      | Credenciales Docker             | Pull de imagenes privadas |
| `kubernetes.io/tls`                   | Certificados TLS                | HTTPS, Ingress            |
| `kubernetes.io/service-account-token` | Token de ServiceAccount         | Autenticacion en API      |
| `kubernetes.io/basic-auth`            | Autenticacion basica            | Usuario/password          |

## Paso 7: Buenas Practicas de Seguridad

### Verificar permisos con kubectl auth can-i

```
$ kubectl auth can-i get secrets
yes

$ kubectl auth can-i get secrets --as=system:serviceaccount:default:default
no
```

### Ejemplo de RBAC para Secrets

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    resourceNames: ["db-credentials"] # Solo este Secret
    verbs: ["get"]
```

### Resumen de buenas practicas

| Practica           | Descripcion                         |
| ------------------ | ----------------------------------- |
| RBAC               | Limitar quien puede leer Secrets    |
| No Git             | Nunca commit Secrets a repositorios |
| Sealed Secrets     | Encriptar Secrets para GitOps       |
| External Secrets   | Obtener Secrets de vaults externos  |
| Rotacion           | Cambiar Secrets periodicamente      |
| Namespaces         | Aislar Secrets por namespace        |
| Encryption at rest | Encriptar etcd                      |

## Secret Inmutable

### Crear Secret inmutable

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: immutable-secret
type: Opaque
immutable: true
data:
  api-key: c2VjcmV0LWtleS0xMjM0NQ==
```

### Intentar modificar Secret inmutable

```
$ kubectl patch secret immutable-secret -p '{"data":{"new-key":"bmV3"}}'
Error from server (Forbidden): secrets "immutable-secret" is immutable
```

> **Nota**: Los Secrets inmutables no pueden ser modificados despues de crearse.

## Comparacion: Secrets vs ConfigMaps

| Caracteristica     | ConfigMap             | Secret                 |
| ------------------ | --------------------- | ---------------------- |
| Proposito          | Configuracion general | Datos sensibles        |
| Almacenamiento     | Texto plano           | Base64 (codificado)    |
| En memoria         | No (por defecto)      | Si (tmpfs por defecto) |
| Tamano maximo      | 1 MB                  | 1 MB                   |
| Visible en logs    | Si                    | Parcialmente oculto    |
| RBAC especial      | No comun              | Recomendado            |
| Encryption at rest | No requerido          | Recomendado            |

## Limpieza

### Eliminar Pods

```
$ kubectl delete pod pod-secret-env pod-secret-volume
pod "pod-secret-env" deleted
pod "pod-secret-volume" deleted
```

### Eliminar Secrets

```
$ kubectl delete secret db-credentials app-secrets my-registry immutable-secret
secret "db-credentials" deleted
secret "app-secrets" deleted
secret "my-registry" deleted
secret "immutable-secret" deleted
```

### Verificacion final

```
$ kubectl get secrets
NAME                  TYPE                                  DATA   AGE
default-token-xxxxx   kubernetes.io/service-account-token   3      30d
```

> **Nota**: El Secret `default-token-xxxxx` es creado automaticamente por Kubernetes para el ServiceAccount default.

## Resumen

Si todas tus salidas son similares a las mostradas en este documento, has completado exitosamente el Lab 11.

### Diferencias menores esperadas

- **Timestamps**: Varian segun cuando ejecutaste los comandos
- **UIDs y resourceVersions**: Son unicos para cada recurso
- **Nombres de tokens**: Los sufijos aleatorios seran diferentes

### Conceptos Clave Aprendidos

| Concepto     | Descripcion                                           |
| ------------ | ----------------------------------------------------- |
| base64       | Codificacion, NO encriptacion - facilmente reversible |
| data         | Valores deben estar en base64                         |
| stringData   | Valores en texto plano (Kubernetes los codifica)      |
| secretKeyRef | Referencia a una clave especifica del Secret          |
| secretRef    | Referencia a todo el Secret (todas las claves)        |
| defaultMode  | Permisos de archivos cuando se monta como volumen     |
| immutable    | Secret que no puede ser modificado despues de crearse |
