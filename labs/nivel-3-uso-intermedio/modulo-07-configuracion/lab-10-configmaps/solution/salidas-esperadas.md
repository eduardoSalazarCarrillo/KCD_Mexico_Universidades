# Lab 10: ConfigMaps - Salidas Esperadas

Este documento muestra las salidas esperadas de cada comando del laboratorio para que puedas verificar que todo funciona correctamente.

## Paso 1: Crear ConfigMap desde Literales

### kubectl create configmap

```
$ kubectl create configmap app-config \
  --from-literal=APP_ENV=production \
  --from-literal=APP_DEBUG=false \
  --from-literal=LOG_LEVEL=info
configmap/app-config created
```

### kubectl get configmap app-config

```
$ kubectl get configmap app-config
NAME         DATA   AGE
app-config   3      10s
```

**Explicación de columnas**:

| Columna | Descripción                  |
| ------- | ---------------------------- |
| `NAME`  | Nombre del ConfigMap         |
| `DATA`  | Número de claves almacenadas |
| `AGE`   | Tiempo desde la creación     |

### kubectl describe configmap app-config

```
$ kubectl describe configmap app-config
Name:         app-config
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
APP_DEBUG:
----
false
APP_ENV:
----
production
LOG_LEVEL:
----
info

BinaryData
====

Events:  <none>
```

### kubectl get configmap app-config -o yaml

```yaml
$ kubectl get configmap app-config -o yaml
apiVersion: v1
data:
  APP_DEBUG: "false"
  APP_ENV: production
  LOG_LEVEL: info
kind: ConfigMap
metadata:
  creationTimestamp: "2024-01-15T10:30:00Z"
  name: app-config
  namespace: default
  resourceVersion: "12345"
  uid: abc123-def456-ghi789
```

## Paso 2: Crear ConfigMap desde Archivo

### Contenido de config.properties

```
$ cat initial/config.properties
database.host=postgres.default.svc.cluster.local
database.port=5432
database.name=myapp
cache.enabled=true
cache.ttl=3600
```

### kubectl create configmap desde archivo

```
$ kubectl create configmap app-properties --from-file=initial/config.properties
configmap/app-properties created
```

### kubectl describe configmap app-properties

```
$ kubectl describe configmap app-properties
Name:         app-properties
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
config.properties:
----
database.host=postgres.default.svc.cluster.local
database.port=5432
database.name=myapp
cache.enabled=true
cache.ttl=3600

BinaryData
====

Events:  <none>
```

> **Nota**: Cuando se usa `--from-file`, el nombre del archivo se convierte en la clave del ConfigMap.

## Paso 3: Crear ConfigMap con YAML

### kubectl apply -f configmap.yaml

```
$ kubectl apply -f initial/configmap.yaml
configmap/app-config-yaml created
```

### kubectl describe configmap app-config-yaml

```
$ kubectl describe configmap app-config-yaml
Name:         app-config-yaml
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
APP_DEBUG:
----
false
APP_ENV:
----
production
LOG_LEVEL:
----
info
nginx.conf:
----
server {
  listen 80;
  server_name localhost;
  location / {
    root /usr/share/nginx/html;
    index index.html;
  }
}

BinaryData
====

Events:  <none>
```

> **Nota**: Este ConfigMap contiene tanto valores simples como un archivo de configuración completo (nginx.conf).

## Paso 4: Usar ConfigMap como Variables de Entorno

### kubectl apply -f pod-env.yaml

```
$ kubectl apply -f initial/pod-env.yaml
pod/pod-configmap-env created
```

### Verificar variables de entorno

```
$ kubectl exec pod-configmap-env -- env | grep -E "APP_|LOG_|CUSTOM"
APP_DEBUG=false
APP_ENV=production
LOG_LEVEL=info
CUSTOM_VAR=production
```

**Explicación**:

| Variable     | Origen                                      | Descripción                        |
| ------------ | ------------------------------------------- | ---------------------------------- |
| `APP_DEBUG`  | ConfigMap `app-config` via `envFrom`        | Importado automáticamente          |
| `APP_ENV`    | ConfigMap `app-config` via `envFrom`        | Importado automáticamente          |
| `LOG_LEVEL`  | ConfigMap `app-config` via `envFrom`        | Importado automáticamente          |
| `CUSTOM_VAR` | ConfigMap `app-config-yaml` via `valueFrom` | Importado con nombre personalizado |

### printenv específico

```
$ kubectl exec pod-configmap-env -- printenv APP_ENV
production
```

```
$ kubectl exec pod-configmap-env -- printenv CUSTOM_VAR
production
```

## Paso 5: Montar ConfigMap como Volumen

### kubectl apply -f pod-volume.yaml

```
$ kubectl apply -f initial/pod-volume.yaml
pod/pod-configmap-volume created
```

### Verificar archivos montados en /etc/config

```
$ kubectl exec pod-configmap-volume -- ls -la /etc/config
total 0
drwxrwxrwx    3 root     root           100 Jan 15 10:35 .
drwxr-xr-x    1 root     root          4096 Jan 15 10:35 ..
drwxr-xr-x    2 root     root            60 Jan 15 10:35 ..2024_01_15_10_35_00.123456789
lrwxrwxrwx    1 root     root            32 Jan 15 10:35 ..data -> ..2024_01_15_10_35_00.123456789
lrwxrwxrwx    1 root     root            24 Jan 15 10:35 config.properties -> ..data/config.properties
```

> **Nota**: Kubernetes usa enlaces simbólicos para permitir actualizaciones atómicas del ConfigMap.

### cat del archivo montado

```
$ kubectl exec pod-configmap-volume -- cat /etc/config/config.properties
database.host=postgres.default.svc.cluster.local
database.port=5432
database.name=myapp
cache.enabled=true
cache.ttl=3600
```

### Verificar nginx.conf montado selectivamente

```
$ kubectl exec pod-configmap-volume -- ls -la /etc/nginx/conf.d
total 0
drwxrwxrwx    3 root     root           100 Jan 15 10:35 .
drwxr-xr-x    1 root     root          4096 Jan 15 10:35 ..
drwxr-xr-x    2 root     root            60 Jan 15 10:35 ..2024_01_15_10_35_00.987654321
lrwxrwxrwx    1 root     root            32 Jan 15 10:35 ..data -> ..2024_01_15_10_35_00.987654321
lrwxrwxrwx    1 root     root            19 Jan 15 10:35 default.conf -> ..data/default.conf
```

```
$ kubectl exec pod-configmap-volume -- cat /etc/nginx/conf.d/default.conf
server {
  listen 80;
  server_name localhost;
  location / {
    root /usr/share/nginx/html;
    index index.html;
  }
}
```

> **Nota**: Usando `items` en el volumen, solo se monta la clave especificada (`nginx.conf`) con un nombre diferente (`default.conf`).

## Paso 6: Actualizar ConfigMap y Observar Comportamiento

### kubectl patch configmap

```
$ kubectl patch configmap app-config --type merge -p '{"data":{"LOG_LEVEL":"debug"}}'
configmap/app-config patched
```

### Verificar cambio en ConfigMap

```
$ kubectl get configmap app-config -o yaml
apiVersion: v1
data:
  APP_DEBUG: "false"
  APP_ENV: production
  LOG_LEVEL: debug    # <-- Valor actualizado
kind: ConfigMap
metadata:
  name: app-config
  namespace: default
...
```

### Verificar variable de entorno (NO se actualiza)

```
$ kubectl exec pod-configmap-env -- printenv LOG_LEVEL
info
```

> **IMPORTANTE**: Las variables de entorno se establecen cuando el contenedor inicia y NO se actualizan automáticamente. El Pod debe ser recreado para ver los nuevos valores.

### Verificar volumen montado (SÍ se actualiza)

Después de esperar ~1-2 minutos, el volumen mostrará los datos actualizados:

```
$ kubectl exec pod-configmap-volume -- cat /etc/config/config.properties
database.host=postgres.default.svc.cluster.local
database.port=5432
database.name=myapp
cache.enabled=true
cache.ttl=3600
```

> **Nota**: Los volúmenes de ConfigMap se actualizan automáticamente, pero con un delay que puede ser de hasta 1-2 minutos dependiendo de la configuración del kubelet.

## Paso 7: ConfigMap Inmutable

### Crear ConfigMap inmutable

```
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config-immutable
data:
  SETTING: "valor-fijo"
immutable: true
EOF
configmap/app-config-immutable created
```

### Intentar modificar ConfigMap inmutable

```
$ kubectl patch configmap app-config-immutable --type merge -p '{"data":{"SETTING":"nuevo-valor"}}'
Error from server (Forbidden): configmaps "app-config-immutable" is immutable
```

> **Beneficios de ConfigMaps inmutables**:
>
> - Protege contra modificaciones accidentales
> - Mejora el rendimiento del clúster (no necesita monitorear cambios)
> - Útil para configuraciones que nunca deben cambiar

## Paso 8: Listar Todos los ConfigMaps

```
$ kubectl get configmaps
NAME                   DATA   AGE
app-config             3      10m
app-config-immutable   1      2m
app-config-yaml        4      8m
app-properties         1      9m
kube-root-ca.crt       1      1d
```

> **Nota**: `kube-root-ca.crt` es un ConfigMap del sistema que contiene el certificado CA del clúster.

## Paso 9: Limpiar Recursos

### Eliminar Pods

```
$ kubectl delete pod pod-configmap-env pod-configmap-volume
pod "pod-configmap-env" deleted
pod "pod-configmap-volume" deleted
```

### Eliminar ConfigMaps

```
$ kubectl delete configmap app-config app-properties app-config-yaml app-config-immutable
configmap "app-config" deleted
configmap "app-properties" deleted
configmap "app-config-yaml" deleted
configmap "app-config-immutable" deleted
```

### Verificación final

```
$ kubectl get configmaps
NAME               DATA   AGE
kube-root-ca.crt   1      1d
```

```
$ kubectl get pods
No resources found in default namespace.
```

## Ejercicios Adicionales

### Ejercicio 1: Montar clave específica con subPath

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-subpath
spec:
  containers:
    - name: app
      image: nginx:alpine
      volumeMounts:
        - name: config
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
  volumes:
    - name: config
      configMap:
        name: app-config-yaml
```

> **Nota**: `subPath` permite montar un archivo específico sin reemplazar todo el directorio.

### Ejercicio 2: ConfigMap con clave personalizada desde archivo

```
$ kubectl create configmap custom-props \
  --from-file=mi-config=initial/config.properties
configmap/custom-props created

$ kubectl describe configmap custom-props
...
Data
====
mi-config:
----
database.host=postgres.default.svc.cluster.local
...
```

### Ejercicio 3: Generar ConfigMap desde directorio

```
$ kubectl create configmap from-dir --from-file=initial/
configmap/from-dir created
```

> **Nota**: Esto crea una clave por cada archivo en el directorio.

## Resumen

Si todas tus salidas son similares a las mostradas en este documento, has completado exitosamente el Lab 10.

Las diferencias menores que puedes esperar:

- **Timestamps y AGE**: Dependen de cuándo ejecutaste los comandos
- **UIDs y resourceVersion**: Son únicos para cada recurso
- **Orden de claves**: Puede variar en la salida YAML

### Conceptos Clave Aprendidos

| Concepto          | Descripción                                                  |
| ----------------- | ------------------------------------------------------------ |
| `--from-literal`  | Crea clave/valor directamente en línea de comandos           |
| `--from-file`     | Crea clave con contenido de archivo (nombre archivo = clave) |
| `envFrom`         | Importa todas las claves como variables de entorno           |
| `valueFrom`       | Importa una clave específica como variable                   |
| `volumeMounts`    | Monta ConfigMap como archivos en el sistema de archivos      |
| `items`           | Selecciona claves específicas para montar como archivos      |
| `immutable`       | Previene modificaciones al ConfigMap                         |
| Actualización env | NO automática - requiere recrear el Pod                      |
| Actualización vol | SÍ automática - con delay de ~1-2 minutos                    |

### Comparación: Variables de Entorno vs Volúmenes

| Característica     | Variables de Entorno | Volúmenes          |
| ------------------ | -------------------- | ------------------ |
| Actualización auto | No                   | Sí (con delay)     |
| Formato            | KEY=value            | Archivos           |
| Uso típico         | Configuración simple | Archivos de config |
| Acceso en código   | `os.getenv()`        | Lectura de archivo |
