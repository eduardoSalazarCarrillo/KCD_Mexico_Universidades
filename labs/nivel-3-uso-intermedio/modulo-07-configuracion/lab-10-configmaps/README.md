# Lab 10: ConfigMaps

## Objetivo

Externalizar configuración de aplicaciones usando ConfigMaps.

## Prerrequisitos

- Lab 09 completado

## Duración

45 minutos

## Instrucciones

### Paso 1: Crear ConfigMap desde literales

```bash
# Crear ConfigMap con valores literales
kubectl create configmap app-config \
  --from-literal=APP_ENV=production \
  --from-literal=APP_DEBUG=false \
  --from-literal=LOG_LEVEL=info

# Verificar
kubectl get configmap app-config
kubectl describe configmap app-config
kubectl get configmap app-config -o yaml
```

### Paso 2: Crear ConfigMap desde archivo

Crea el archivo `config.properties`:

```properties
database.host=postgres.default.svc.cluster.local
database.port=5432
database.name=myapp
cache.enabled=true
cache.ttl=3600
```

```bash
# Crear ConfigMap desde archivo
kubectl create configmap app-properties --from-file=config.properties

# Verificar
kubectl describe configmap app-properties
```

### Paso 3: Crear ConfigMap con YAML

Crea el archivo `configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config-yaml
data:
  APP_ENV: "production"
  APP_DEBUG: "false"
  LOG_LEVEL: "info"
  nginx.conf: |
    server {
      listen 80;
      server_name localhost;
      location / {
        root /usr/share/nginx/html;
        index index.html;
      }
    }
```

```bash
kubectl apply -f configmap.yaml
kubectl describe configmap app-config-yaml
```

### Paso 4: Usar ConfigMap como variables de entorno

Crea el archivo `pod-env.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-configmap-env
spec:
  containers:
    - name: app
      image: nginx:alpine
      envFrom:
        - configMapRef:
            name: app-config
      env:
        - name: CUSTOM_VAR
          valueFrom:
            configMapKeyRef:
              name: app-config-yaml
              key: APP_ENV
```

```bash
kubectl apply -f pod-env.yaml

# Verificar las variables de entorno
kubectl exec pod-configmap-env -- env | grep -E "APP_|LOG_|CUSTOM"
```

### Paso 5: Montar ConfigMap como volumen

Crea el archivo `pod-volume.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-configmap-volume
spec:
  containers:
    - name: app
      image: nginx:alpine
      volumeMounts:
        - name: config-volume
          mountPath: /etc/config
        - name: nginx-config
          mountPath: /etc/nginx/conf.d
  volumes:
    - name: config-volume
      configMap:
        name: app-properties
    - name: nginx-config
      configMap:
        name: app-config-yaml
        items:
          - key: nginx.conf
            path: default.conf
```

```bash
kubectl apply -f pod-volume.yaml

# Verificar los archivos montados
kubectl exec pod-configmap-volume -- ls -la /etc/config
kubectl exec pod-configmap-volume -- cat /etc/config/config.properties
kubectl exec pod-configmap-volume -- cat /etc/nginx/conf.d/default.conf
```

### Paso 6: Actualizar ConfigMap

```bash
# Editar ConfigMap
kubectl edit configmap app-config

# O actualizar con apply
kubectl apply -f configmap.yaml

# Nota: Las variables de entorno NO se actualizan automáticamente
# Los volúmenes SÍ se actualizan (con delay)
```

## Ejercicios Adicionales

1. Crea un ConfigMap inmutable con `immutable: true`
2. Monta solo ciertas claves del ConfigMap como archivos
3. Investiga cómo usar subPath para montar un archivo específico

## Verificación

- [ ] Puedo crear ConfigMaps de múltiples formas
- [ ] Puedo inyectar ConfigMaps como variables de entorno
- [ ] Puedo montar ConfigMaps como volúmenes
- [ ] Entiendo las diferencias en actualización

## Solución

Consulta el directorio `solution/` para ver ejemplos completos.
