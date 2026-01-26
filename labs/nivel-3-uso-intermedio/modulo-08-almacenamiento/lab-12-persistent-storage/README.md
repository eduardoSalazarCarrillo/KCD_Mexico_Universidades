# Lab 12: Persistent Storage

## Objetivo

Implementar almacenamiento persistente para aplicaciones stateful.

## Prerrequisitos

- Lab 11 completado

## Duración

75 minutos

## Instrucciones

### Paso 1: Demostrar pérdida de datos sin persistencia

```bash
# Crear pod PostgreSQL sin volumen persistente
kubectl run postgres-ephemeral --image=postgres:13-alpine \
  --env="POSTGRES_PASSWORD=secret"

# Esperar a que esté listo
kubectl wait --for=condition=Ready pod/postgres-ephemeral --timeout=60s

# Crear datos
kubectl exec -it postgres-ephemeral -- psql -U postgres -c "CREATE DATABASE testdb;"
kubectl exec -it postgres-ephemeral -- psql -U postgres -c "CREATE TABLE users (id SERIAL, name TEXT);"
kubectl exec -it postgres-ephemeral -- psql -U postgres -c "INSERT INTO users (name) VALUES ('Juan');"

# Verificar datos
kubectl exec -it postgres-ephemeral -- psql -U postgres -c "SELECT * FROM users;"

# Eliminar y recrear el pod
kubectl delete pod postgres-ephemeral
kubectl run postgres-ephemeral --image=postgres:13-alpine \
  --env="POSTGRES_PASSWORD=secret"
kubectl wait --for=condition=Ready pod/postgres-ephemeral --timeout=60s

# Los datos se perdieron
kubectl exec -it postgres-ephemeral -- psql -U postgres -c "\l"
```

### Paso 2: Crear PersistentVolume local

Crea el archivo `pv.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /data/postgres
```

```bash
kubectl apply -f pv.yaml
kubectl get pv
kubectl describe pv postgres-pv
```

### Paso 3: Crear PersistentVolumeClaim

Crea el archivo `pvc.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: manual
```

```bash
kubectl apply -f pvc.yaml
kubectl get pvc
kubectl describe pvc postgres-pvc

# Verificar que el PV está "Bound"
kubectl get pv
```

### Paso 4: Crear Deployment con volumen persistente

Crea el archivo `postgres-persistent.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:13-alpine
          env:
            - name: POSTGRES_PASSWORD
              value: secret
            - name: PGDATA
              value: /var/lib/postgresql/data/pgdata
          ports:
            - containerPort: 5432
          volumeMounts:
            - name: postgres-storage
              mountPath: /var/lib/postgresql/data
      volumes:
        - name: postgres-storage
          persistentVolumeClaim:
            claimName: postgres-pvc
```

```bash
kubectl apply -f postgres-persistent.yaml
kubectl get pods -l app=postgres
kubectl wait --for=condition=Ready pod -l app=postgres --timeout=120s
```

### Paso 5: Crear datos y verificar persistencia

```bash
# Obtener nombre del pod
POD=$(kubectl get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}')

# Crear datos
kubectl exec -it $POD -- psql -U postgres -c "CREATE DATABASE testdb;"
kubectl exec -it $POD -- psql -U postgres -c "CREATE TABLE users (id SERIAL, name TEXT);"
kubectl exec -it $POD -- psql -U postgres -c "INSERT INTO users (name) VALUES ('María'), ('Pedro');"

# Verificar
kubectl exec -it $POD -- psql -U postgres -c "SELECT * FROM users;"

# Eliminar el pod
kubectl delete pod $POD

# Esperar nuevo pod
kubectl wait --for=condition=Ready pod -l app=postgres --timeout=120s

# Verificar que los datos persisten
NEW_POD=$(kubectl get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $NEW_POD -- psql -U postgres -c "SELECT * FROM users;"
```

### Paso 6: Usar StorageClass dinámica

```bash
# Ver StorageClasses disponibles
kubectl get storageclass

# En Minikube, usar la StorageClass por defecto
```

Crea el archivo `pvc-dynamic.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
  # Sin storageClassName usa la default
```

```bash
kubectl apply -f pvc-dynamic.yaml
kubectl get pvc dynamic-pvc
kubectl get pv  # Ver PV creado dinámicamente
```

## Ejercicios Adicionales

1. Experimenta con diferentes accessModes
2. Investiga volumeClaimTemplates para StatefulSets
3. Explora diferentes tipos de StorageClass

## Verificación

- [ ] Entiendo la diferencia entre almacenamiento efímero y persistente
- [ ] Puedo crear PV y PVC manualmente
- [ ] Puedo usar PVC en Deployments
- [ ] Entiendo el aprovisionamiento dinámico

## Solución

Consulta el directorio `solution/` para configuraciones adicionales.
