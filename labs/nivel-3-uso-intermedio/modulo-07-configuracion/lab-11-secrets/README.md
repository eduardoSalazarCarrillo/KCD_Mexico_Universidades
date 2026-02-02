# Lab 11: Secrets

## Objetivo

Gestionar informacion sensible con Kubernetes Secrets, entendiendo las diferencias con ConfigMaps, los tipos de Secrets disponibles, y las mejores practicas de seguridad.

## Prerrequisitos

- Lab 10 completado (ConfigMaps)
- Cluster de Minikube ejecutandose (`minikube status` debe mostrar "Running")

## Duracion

45 minutos

## Conceptos Clave

Antes de comenzar, es importante entender estos conceptos:

| Concepto          | Descripcion                                                                                            |
| ----------------- | ------------------------------------------------------------------------------------------------------ |
| **Secret**        | Objeto de Kubernetes para almacenar datos sensibles como passwords, tokens, o claves.                  |
| **base64**        | Codificacion (NO encriptacion) usada para almacenar valores en Secrets. Facilmente reversible.         |
| **data**          | Campo donde los valores DEBEN estar codificados en base64.                                             |
| **stringData**    | Campo alternativo que acepta valores en texto plano (Kubernetes los codifica automaticamente).         |
| **Opaque**        | Tipo de Secret por defecto para datos arbitrarios.                                                     |
| **secretKeyRef**  | Referencia a una clave especifica de un Secret para inyectar como variable de entorno.                 |
| **secretRef**     | Referencia a un Secret completo para inyectar todas sus claves como variables de entorno.              |
| **defaultMode**   | Permisos de archivo cuando un Secret se monta como volumen (ej: 0400 = solo lectura para propietario). |

### Secrets vs ConfigMaps

| Caracteristica     | ConfigMap              | Secret                           |
| ------------------ | ---------------------- | -------------------------------- |
| Proposito          | Configuracion general  | Datos sensibles (passwords, etc) |
| Almacenamiento     | Texto plano            | Base64 (codificado)              |
| Montaje en memoria | No (disco)             | Si (tmpfs por defecto)           |
| Visible en `describe` | Si (valores visibles) | No (solo muestra bytes)        |
| RBAC especial      | No es comun            | Altamente recomendado            |

### Arquitectura de Secrets

```
                           CREACION DE SECRETS
                                   |
         +-------------------------+-------------------------+
         |                         |                         |
         v                         v                         v
    kubectl create            kubectl apply              Desde archivo
    --from-literal            -f secret.yaml             --from-file
         |                         |                         |
         +------------+------------+------------+------------+
                      |                         |
                      v                         v
               +-----------+             +-----------+
               |   data    |             | stringData|
               | (base64)  |             | (plano)   |
               +-----------+             +-----------+
                      |                         |
                      +------------+------------+
                                   |
                                   v
                      +------------------------+
                      |       SECRET           |
                      |  (almacenado en etcd)  |
                      +------------------------+
                                   |
         +-------------------------+-------------------------+
         |                                                   |
         v                                                   v
+------------------+                              +------------------+
| Variables de     |                              | Volumen montado  |
| entorno (env)    |                              | (/etc/secrets)   |
+------------------+                              +------------------+
         |                                                   |
         v                                                   v
+------------------+                              +------------------+
| Pod accede via   |                              | Pod lee archivos |
| $VAR_NAME        |                              | cat /etc/secrets |
+------------------+                              +------------------+
```

### Tipos de Secrets

| Tipo                                  | Uso                              | Creacion                          |
| ------------------------------------- | -------------------------------- | --------------------------------- |
| `Opaque`                              | Datos genericos                  | `kubectl create secret generic`   |
| `kubernetes.io/dockerconfigjson`      | Credenciales de Docker registry  | `kubectl create secret docker-registry` |
| `kubernetes.io/tls`                   | Certificados TLS                 | `kubectl create secret tls`       |
| `kubernetes.io/service-account-token` | Tokens de ServiceAccount         | Automatico                        |
| `kubernetes.io/basic-auth`            | Usuario/password                 | YAML con type especificado        |

## Instrucciones

### Paso 1: Crear Secret desde Literales

La forma mas rapida de crear un Secret es usando `--from-literal`:

```bash
# Crear Secret generico con credenciales de base de datos
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=supersecret123

# Verificar que se creo
kubectl get secret db-credentials
```

**Salida esperada**:

```
NAME             TYPE     DATA   AGE
db-credentials   Opaque   2      10s
```

Inspeccionar el Secret:

```bash
# Ver detalles (NO muestra valores, solo bytes)
kubectl describe secret db-credentials

# Ver el YAML completo (valores en base64)
kubectl get secret db-credentials -o yaml
```

**Salida esperada de describe**:

```
Name:         db-credentials
Namespace:    default
Type:         Opaque

Data
====
password:  15 bytes
username:  5 bytes
```

> **Nota**: `kubectl describe` oculta los valores, pero `kubectl get -o yaml` los muestra en base64.

### Paso 2: Decodificar Valores (Demostrar que base64 NO es encriptacion)

Los valores en un Secret estan codificados en base64, que es **facilmente reversible**:

```bash
# Decodificar el username
kubectl get secret db-credentials -o jsonpath='{.data.username}' | base64 -d
echo ""  # Nueva linea

# Decodificar el password
kubectl get secret db-credentials -o jsonpath='{.data.password}' | base64 -d
echo ""
```

**Salida esperada**:

```
admin
supersecret123
```

> **IMPORTANTE**: Cualquier persona con acceso de lectura al Secret puede decodificar los valores. base64 es **codificacion**, NO **encriptacion**.

### Paso 3: Crear Secret con YAML

Para tener los Secrets versionados (aunque encriptados con herramientas como sealed-secrets), usa archivos YAML.

Primero, veamos como codificar valores en base64:

```bash
# Codificar valores (usar -n para evitar salto de linea)
echo -n 'api-key-1234567890' | base64
echo -n 'super-secret-jwt-key' | base64
```

**Salida esperada**:

```
YXBpLWtleS0xMjM0NTY3ODkw
c3VwZXItc2VjcmV0LWp3dC1rZXk=
```

Ver el archivo `initial/secret.yaml`:

```bash
cat initial/secret.yaml
```

**Contenido del archivo**:

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

**Explicacion**:

| Campo        | Descripcion                                                      |
| ------------ | ---------------------------------------------------------------- |
| `data`       | Valores DEBEN estar en base64                                    |
| `stringData` | Valores en texto plano (Kubernetes los codifica automaticamente) |

Aplicar el Secret:

```bash
kubectl apply -f initial/secret.yaml

# Verificar que stringData se convirtio a data
kubectl get secret app-secrets -o jsonpath='{.data.database-url}' | base64 -d
echo ""
```

**Salida esperada**:

```
secret/app-secrets created
postgres://user:pass@host:5432/db
```

### Paso 4: Usar Secret como Variables de Entorno

Ver el archivo `initial/pod-secret-env.yaml`:

```bash
cat initial/pod-secret-env.yaml
```

**Contenido del archivo**:

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
        # Variable individual desde una clave del Secret
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
      # Todas las claves del Secret como variables
      envFrom:
        - secretRef:
            name: app-secrets
```

**Explicacion**:

| Campo          | Descripcion                                        |
| -------------- | -------------------------------------------------- |
| `secretKeyRef` | Inyecta UNA clave especifica como variable         |
| `secretRef`    | Inyecta TODAS las claves del Secret como variables |

Aplicar y verificar:

```bash
kubectl apply -f initial/pod-secret-env.yaml

# Esperar a que el pod este listo
kubectl wait --for=condition=Ready pod/pod-secret-env --timeout=60s

# Verificar las variables de entorno (SENSIBLE!)
kubectl exec pod-secret-env -- env | grep -E "DB_|api|jwt|database"
```

**Salida esperada**:

```
DB_USERNAME=admin
DB_PASSWORD=supersecret123
api-key=api-key-1234567890
jwt-secret=super-secret-jwt-key
database-url=postgres://user:pass@host:5432/db
```

> **ADVERTENCIA**: Las credenciales son visibles con `kubectl exec ... env`. Esto es un riesgo de seguridad que debes considerar.

### Paso 5: Montar Secret como Volumen

Ver el archivo `initial/pod-secret-volume.yaml`:

```bash
cat initial/pod-secret-volume.yaml
```

**Contenido del archivo**:

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
        defaultMode: 0400  # Solo lectura para propietario
```

**Explicacion**:

| Campo         | Descripcion                                            |
| ------------- | ------------------------------------------------------ |
| `secretName`  | Nombre del Secret a montar                             |
| `defaultMode` | Permisos de archivo (0400 = -r--------)                |
| `readOnly`    | Montar como solo lectura (buena practica de seguridad) |

Aplicar y verificar:

```bash
kubectl apply -f initial/pod-secret-volume.yaml

# Esperar a que el pod este listo
kubectl wait --for=condition=Ready pod/pod-secret-volume --timeout=60s

# Ver los archivos montados
kubectl exec pod-secret-volume -- ls -la /etc/secrets

# Leer el contenido
kubectl exec pod-secret-volume -- cat /etc/secrets/username
kubectl exec pod-secret-volume -- cat /etc/secrets/password
```

**Salida esperada**:

```
lrwxrwxrwx    1 root root   15 Jan 15 10:15 password -> ..data/password
lrwxrwxrwx    1 root root   15 Jan 15 10:15 username -> ..data/username

admin
supersecret123
```

> **Nota**: Los archivos son symlinks a `..data/` que permite actualizaciones atomicas cuando el Secret cambia.

### Paso 6: Tipos de Secrets

Kubernetes soporta varios tipos de Secrets para diferentes casos de uso:

#### Secret para Docker Registry

```bash
kubectl create secret docker-registry my-registry \
  --docker-server=registry.example.com \
  --docker-username=user \
  --docker-password=pass \
  --docker-email=user@example.com

# Ver el tipo
kubectl get secret my-registry -o jsonpath='{.type}'
```

**Salida esperada**:

```
kubernetes.io/dockerconfigjson
```

#### Ver todos los Secrets

```bash
kubectl get secrets
```

**Salida esperada**:

```
NAME             TYPE                             DATA   AGE
db-credentials   Opaque                           2      10m
app-secrets      Opaque                           3      8m
my-registry      kubernetes.io/dockerconfigjson   1      30s
```

### Paso 7: Buenas Practicas de Seguridad

Ver el ejemplo de RBAC en `initial/rbac-secret-reader.yaml`:

```bash
cat initial/rbac-secret-reader.yaml
```

**Contenido**:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    resourceNames: ["db-credentials"]  # Solo este Secret
    verbs: ["get"]
```

Verificar permisos actuales:

```bash
# Tu usuario actual puede leer secrets?
kubectl auth can-i get secrets

# El ServiceAccount default puede?
kubectl auth can-i get secrets --as=system:serviceaccount:default:default
```

#### Resumen de Buenas Practicas

| Practica                | Descripcion                                                |
| ----------------------- | ---------------------------------------------------------- |
| **RBAC**                | Limitar quien puede leer Secrets                           |
| **No Git**              | NUNCA hacer commit de Secrets a repositorios               |
| **Sealed Secrets**      | Encriptar Secrets para poder versionar de forma segura     |
| **External Secrets**    | Obtener Secrets desde vaults externos (HashiCorp, AWS, etc)|
| **Rotacion**            | Cambiar Secrets periodicamente                             |
| **Namespaces**          | Aislar Secrets por namespace                               |
| **Encryption at rest**  | Habilitar encriptacion de etcd                             |

### Paso 8: Limpiar Recursos

```bash
# Eliminar pods
kubectl delete pod pod-secret-env pod-secret-volume

# Eliminar secrets
kubectl delete secret db-credentials app-secrets my-registry

# Verificar
kubectl get pods
kubectl get secrets
```

## Ejercicios Adicionales

### Ejercicio 1: Secret Inmutable

Los Secrets inmutables no pueden ser modificados despues de crearse:

```bash
# Crear Secret inmutable
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: immutable-secret
type: Opaque
immutable: true
data:
  api-key: c2VjcmV0LWtleS0xMjM0NQ==
EOF

# Intentar modificarlo (fallara)
kubectl patch secret immutable-secret -p '{"data":{"new-key":"bmV3"}}'

# Limpiar
kubectl delete secret immutable-secret
```

### Ejercicio 2: Investigar Sealed Secrets

[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) permite encriptar Secrets para poder hacer commit de forma segura a Git:

```bash
# Instalar kubeseal (solo referencia)
# brew install kubeseal  # macOS
# wget ... # Linux

# Proceso:
# 1. Crear Secret normal
# 2. Encriptarlo con kubeseal
# 3. Hacer commit del SealedSecret
# 4. El controlador en el cluster lo desencripta
```

### Ejercicio 3: External Secrets Operator

[External Secrets Operator](https://external-secrets.io/) permite sincronizar Secrets desde proveedores externos:

- AWS Secrets Manager
- HashiCorp Vault
- Google Secret Manager
- Azure Key Vault

## Verificacion

Antes de continuar al siguiente laboratorio, asegurate de poder marcar todos estos puntos:

- [ ] Puedo crear Secrets con `kubectl create secret generic --from-literal`
- [ ] Puedo crear Secrets desde archivos YAML con `data` y `stringData`
- [ ] Entiendo que base64 es CODIFICACION, no encriptacion
- [ ] Puedo decodificar valores con `base64 -d`
- [ ] Puedo inyectar Secrets como variables de entorno (`secretKeyRef`, `secretRef`)
- [ ] Puedo montar Secrets como volumenes con permisos restrictivos
- [ ] Conozco los diferentes tipos de Secrets (Opaque, dockerconfigjson, tls)
- [ ] Entiendo las buenas practicas de seguridad para Secrets
- [ ] Se la diferencia entre Secrets y ConfigMaps

## Resumen de Comandos

| Comando                                                | Descripcion                              |
| ------------------------------------------------------ | ---------------------------------------- |
| `kubectl create secret generic <n> --from-literal=k=v` | Crear Secret desde valores literales     |
| `kubectl create secret generic <n> --from-file=<f>`    | Crear Secret desde archivo               |
| `kubectl create secret docker-registry <n> ...`        | Crear Secret para Docker registry        |
| `kubectl create secret tls <n> --cert=<c> --key=<k>`   | Crear Secret TLS                         |
| `kubectl get secrets`                                  | Listar todos los Secrets                 |
| `kubectl get secret <nombre> -o yaml`                  | Ver Secret en formato YAML               |
| `kubectl describe secret <nombre>`                     | Ver detalles (sin valores)               |
| `kubectl get secret <n> -o jsonpath='{.data.k}'`       | Obtener valor especifico (en base64)     |
| `... \| base64 -d`                                     | Decodificar valor base64                 |
| `echo -n 'valor' \| base64`                            | Codificar valor a base64                 |
| `kubectl delete secret <nombre>`                       | Eliminar un Secret                       |

## Conceptos Aprendidos

1. **Secret**: Objeto para almacenar datos sensibles en Kubernetes
2. **base64**: Codificacion (NO encriptacion) usada en el campo `data`
3. **stringData**: Campo que acepta valores sin codificar
4. **secretKeyRef**: Inyectar una clave como variable de entorno
5. **secretRef**: Inyectar todas las claves como variables
6. **Tipos de Secrets**: Opaque, dockerconfigjson, tls, etc.
7. **Seguridad**: RBAC, encryption at rest, sealed-secrets

## Solucion

Consulta el directorio `solution/` para ver:
- `lab-completo.sh` - Script con todos los comandos
- `verificar-completado.sh` - Script de verificacion
- `salidas-esperadas.md` - Outputs esperados de cada comando

## Navegacion

- **Anterior**: [Lab 10: ConfigMaps](../lab-10-configmaps/README.md)
- **Siguiente**: [Lab 12: Persistent Storage](../../modulo-08-almacenamiento/lab-12-persistent-storage/README.md)
