# Lab 12: Persistent Storage - Salidas Esperadas

Este documento muestra las salidas esperadas de cada comando del laboratorio para que puedas verificar que todo funciona correctamente.

## Paso 1: Demostrar Perdida de Datos sin Persistencia

### Crear pod efimero

```
$ kubectl run postgres-ephemeral --image=postgres:13-alpine --env="POSTGRES_PASSWORD=secret"
pod/postgres-ephemeral created
```

### Esperar a que este listo

```
$ kubectl wait --for=condition=Ready pod/postgres-ephemeral --timeout=60s
pod/postgres-ephemeral condition met
```

### Crear datos

```
$ kubectl exec -it postgres-ephemeral -- psql -U postgres -c "CREATE DATABASE testdb;"
CREATE DATABASE

$ kubectl exec -it postgres-ephemeral -- psql -U postgres -c "CREATE TABLE users (id SERIAL, name TEXT);"
CREATE TABLE

$ kubectl exec -it postgres-ephemeral -- psql -U postgres -c "INSERT INTO users (name) VALUES ('Juan');"
INSERT 0 1
```

### Verificar datos

```
$ kubectl exec -it postgres-ephemeral -- psql -U postgres -c "SELECT * FROM users;"
 id | name
----+------
  1 | Juan
(1 row)
```

### Eliminar y recrear el pod

```
$ kubectl delete pod postgres-ephemeral
pod "postgres-ephemeral" deleted

$ kubectl run postgres-ephemeral --image=postgres:13-alpine --env="POSTGRES_PASSWORD=secret"
pod/postgres-ephemeral created
```

### Verificar perdida de datos

```
$ kubectl exec -it postgres-ephemeral -- psql -U postgres -c "\l"
                                 List of databases
   Name    |  Owner   | Encoding |  Collate   |   Ctype    |   Access privileges
-----------+----------+----------+------------+------------+-----------------------
 postgres  | postgres | UTF8     | en_US.utf8 | en_US.utf8 |
 template0 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
(3 rows)
```

> **Nota**: La base de datos `testdb` ya NO aparece en la lista porque se perdieron los datos.

## Paso 2: Crear PersistentVolume Local

### kubectl apply -f initial/pv.yaml

```
$ kubectl apply -f initial/pv.yaml
persistentvolume/postgres-pv created
```

### kubectl get pv

```
$ kubectl get pv
NAME          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
postgres-pv   1Gi        RWO            Retain           Available           manual                  5s
```

**Explicacion de columnas**:

| Columna          | Descripcion                                        |
| ---------------- | -------------------------------------------------- |
| `CAPACITY`       | Capacidad de almacenamiento del volumen            |
| `ACCESS MODES`   | Modos de acceso (RWO, ROX, RWX)                    |
| `RECLAIM POLICY` | Que pasa con los datos al liberar el PV            |
| `STATUS`         | Estado actual (Available, Bound, Released, Failed) |
| `CLAIM`          | PVC que tiene el volumen vinculado                 |
| `STORAGECLASS`   | Clase de almacenamiento                            |

### kubectl describe pv postgres-pv

```
$ kubectl describe pv postgres-pv
Name:            postgres-pv
Labels:          <none>
Annotations:     <none>
Finalizers:      [kubernetes.io/pv-protection]
StorageClass:    manual
Status:          Available
Claim:
Reclaim Policy:  Retain
Access Modes:    RWO
VolumeMode:      Filesystem
Capacity:        1Gi
Node Affinity:   <none>
Message:
Source:
    Type:          HostPath (bare host directory volume)
    Path:          /data/postgres
    HostPathType:
Events:            <none>
```

## Paso 3: Crear PersistentVolumeClaim

### kubectl apply -f initial/pvc.yaml

```
$ kubectl apply -f initial/pvc.yaml
persistentvolumeclaim/postgres-pvc created
```

### kubectl get pvc

```
$ kubectl get pvc
NAME           STATUS   VOLUME        CAPACITY   ACCESS MODES   STORAGECLASS   AGE
postgres-pvc   Bound    postgres-pv   1Gi        RWO            manual         5s
```

**Explicacion de columnas**:

| Columna        | Descripcion                             |
| -------------- | --------------------------------------- |
| `STATUS`       | Estado del claim (Pending, Bound, Lost) |
| `VOLUME`       | Nombre del PV vinculado                 |
| `CAPACITY`     | Capacidad asignada al claim             |
| `ACCESS MODES` | Modos de acceso solicitados             |
| `STORAGECLASS` | Clase de almacenamiento usada           |

### kubectl describe pvc postgres-pvc

```
$ kubectl describe pvc postgres-pvc
Name:          postgres-pvc
Namespace:     default
StorageClass:  manual
Status:        Bound
Volume:        postgres-pv
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      1Gi
Access Modes:  RWO
VolumeMode:    Filesystem
Used By:       <none>
Events:        <none>
```

### Verificar que el PV esta Bound

```
$ kubectl get pv
NAME          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                  STORAGECLASS   REASON   AGE
postgres-pv   1Gi        RWO            Retain           Bound    default/postgres-pvc   manual                  1m
```

> **Nota**: El estado cambio de `Available` a `Bound` y ahora muestra el claim `default/postgres-pvc`.

## Paso 4: Crear Deployment con Volumen Persistente

### kubectl apply -f initial/postgres-persistent.yaml

```
$ kubectl apply -f initial/postgres-persistent.yaml
deployment.apps/postgres created
```

### kubectl get pods -l app=postgres

```
$ kubectl get pods -l app=postgres
NAME                        READY   STATUS    RESTARTS   AGE
postgres-7d9f8b6c4d-xk2mn   1/1     Running   0          30s
```

### kubectl get pods -l app=postgres -o wide

```
$ kubectl get pods -l app=postgres -o wide
NAME                        READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
postgres-7d9f8b6c4d-xk2mn   1/1     Running   0          45s   10.244.0.5   minikube   <none>           <none>
```

## Paso 5: Crear Datos y Verificar Persistencia

### Obtener nombre del pod

```
$ POD=$(kubectl get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}')
$ echo $POD
postgres-7d9f8b6c4d-xk2mn
```

### Crear datos

```
$ kubectl exec -it $POD -- psql -U postgres -c "CREATE DATABASE testdb;"
CREATE DATABASE

$ kubectl exec -it $POD -- psql -U postgres -d testdb -c "CREATE TABLE users (id SERIAL, name TEXT);"
CREATE TABLE

$ kubectl exec -it $POD -- psql -U postgres -d testdb -c "INSERT INTO users (name) VALUES ('Maria'), ('Pedro');"
INSERT 0 2
```

### Verificar datos

```
$ kubectl exec -it $POD -- psql -U postgres -d testdb -c "SELECT * FROM users;"
 id |  name
----+--------
  1 | Maria
  2 | Pedro
(2 rows)
```

### Eliminar el pod

```
$ kubectl delete pod $POD
pod "postgres-7d9f8b6c4d-xk2mn" deleted
```

### Esperar nuevo pod y verificar persistencia

```
$ kubectl wait --for=condition=Ready pod -l app=postgres --timeout=120s
pod/postgres-7d9f8b6c4d-abc12 condition met

$ NEW_POD=$(kubectl get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}')
$ echo $NEW_POD
postgres-7d9f8b6c4d-abc12

$ kubectl exec -it $NEW_POD -- psql -U postgres -d testdb -c "SELECT * FROM users;"
 id |  name
----+--------
  1 | Maria
  2 | Pedro
(2 rows)
```

> **Nota**: Los datos persisten a pesar de haber eliminado el pod original. El nuevo pod se conecto al mismo volumen persistente.

## Paso 6: Usar StorageClass Dinamica

### kubectl get storageclass

```
$ kubectl get storageclass
NAME                 PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
standard (default)   k8s.io/minikube-hostpath   Delete          Immediate           false                  1d
```

**Explicacion**:

| Campo                  | Descripcion                                                |
| ---------------------- | ---------------------------------------------------------- |
| `PROVISIONER`          | Plugin que crea los volumenes automaticamente              |
| `RECLAIMPOLICY`        | Que pasa con el PV al eliminar el PVC                      |
| `VOLUMEBINDINGMODE`    | Cuando se vincula el PV (Immediate o WaitForFirstConsumer) |
| `ALLOWVOLUMEEXPANSION` | Si permite expandir el volumen                             |

### kubectl apply -f initial/pvc-dynamic.yaml

```
$ kubectl apply -f initial/pvc-dynamic.yaml
persistentvolumeclaim/dynamic-pvc created
```

### kubectl get pvc dynamic-pvc

```
$ kubectl get pvc dynamic-pvc
NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
dynamic-pvc   Bound    pvc-a1b2c3d4-e5f6-7890-abcd-ef1234567890   500Mi      RWO            standard       5s
```

### kubectl get pv

```
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                  STORAGECLASS   REASON   AGE
postgres-pv                                1Gi        RWO            Retain           Bound    default/postgres-pvc   manual                  10m
pvc-a1b2c3d4-e5f6-7890-abcd-ef1234567890   500Mi      RWO            Delete           Bound    default/dynamic-pvc    standard                5s
```

> **Nota**: El segundo PV fue creado automaticamente por el provisioner de Minikube. Observa que su nombre es generado automaticamente y tiene `RECLAIM POLICY: Delete`.

## Paso 7: Explorar Volumenes y Mounts

### Inspeccionar volumeMounts

```
$ kubectl describe pod -l app=postgres | grep -A 5 'Mounts:'
    Mounts:
      /var/lib/postgresql/data from postgres-storage (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-xxxxx (ro)
```

### Ver contenido del volumen

```
$ kubectl exec $POD -- ls -la /var/lib/postgresql/data/
total 8
drwxrwxrwx 3 root     root     4096 Jan 15 10:30 .
drwxr-xr-x 1 postgres postgres 4096 Jan 15 10:28 ..
drwx------ 19 postgres postgres 4096 Jan 15 10:35 pgdata

$ kubectl exec $POD -- ls -la /var/lib/postgresql/data/pgdata/
total 128
drwx------ 19 postgres postgres  4096 Jan 15 10:35 .
drwxrwxrwx  3 root     root      4096 Jan 15 10:30 ..
-rw-------  1 postgres postgres     3 Jan 15 10:30 PG_VERSION
drwx------  5 postgres postgres  4096 Jan 15 10:30 base
drwx------  2 postgres postgres  4096 Jan 15 10:35 global
drwx------  2 postgres postgres  4096 Jan 15 10:30 pg_commit_ts
drwx------  2 postgres postgres  4096 Jan 15 10:30 pg_dynshmem
...
```

## Paso 8: Entender Access Modes

### Ver Access Modes de los PVs

```
$ kubectl get pv -o custom-columns='NAME:.metadata.name,CAPACITY:.spec.capacity.storage,ACCESS MODES:.spec.accessModes,STATUS:.status.phase'
NAME                                       CAPACITY   ACCESS MODES       STATUS
postgres-pv                                1Gi        [ReadWriteOnce]    Bound
pvc-a1b2c3d4-e5f6-7890-abcd-ef1234567890   500Mi      [ReadWriteOnce]    Bound
```

### Ver PVCs con detalles

```
$ kubectl get pvc -o custom-columns='NAME:.metadata.name,STATUS:.status.phase,VOLUME:.spec.volumeName,CAPACITY:.status.capacity.storage'
NAME           STATUS   VOLUME                                     CAPACITY
dynamic-pvc    Bound    pvc-a1b2c3d4-e5f6-7890-abcd-ef1234567890   500Mi
postgres-pvc   Bound    postgres-pv                                1Gi
```

## Paso 9: Limpiar Recursos

### Eliminar Deployment

```
$ kubectl delete deployment postgres
deployment.apps "postgres" deleted
```

### Eliminar PVCs

```
$ kubectl delete pvc postgres-pvc dynamic-pvc
persistentvolumeclaim "postgres-pvc" deleted
persistentvolumeclaim "dynamic-pvc" deleted
```

### Eliminar PV

```
$ kubectl delete pv postgres-pv
persistentvolume "postgres-pv" deleted
```

### Verificacion final

```
$ kubectl get pv,pvc
No resources found
```

## Ejercicios Adicionales

### Ejercicio 1: Diferentes Access Modes

```yaml
# PV con ReadOnlyMany
apiVersion: v1
kind: PersistentVolume
metadata:
  name: shared-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadOnlyMany
  hostPath:
    path: /data/shared
```

### Ejercicio 2: StatefulSet con volumeClaimTemplates

```
$ kubectl get pvc
NAME                    STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
data-postgres-sts-0     Bound    pvc-xxx                                    1Gi        RWO            standard       1m
data-postgres-sts-1     Bound    pvc-yyy                                    1Gi        RWO            standard       1m
data-postgres-sts-2     Bound    pvc-zzz                                    1Gi        RWO            standard       1m
```

> **Nota**: Con StatefulSets, cada replica obtiene su propio PVC usando `volumeClaimTemplates`.

### Ejercicio 3: Explorar StorageClasses

```
$ kubectl describe storageclass standard
Name:                  standard
IsDefaultClass:        Yes
Annotations:           storageclass.kubernetes.io/is-default-class=true
Provisioner:           k8s.io/minikube-hostpath
Parameters:            <none>
AllowVolumeExpansion:  <unset>
MountOptions:          <none>
ReclaimPolicy:         Delete
VolumeBindingMode:     Immediate
Events:                <none>
```

## Resumen

Si todas tus salidas son similares a las mostradas en este documento, has completado exitosamente el Lab 12.

Las diferencias menores que puedes esperar:

- **Nombres de Pods**: Los sufijos aleatorios (como `-xk2mn`) seran diferentes
- **IPs**: Las IPs de los Pods variaran segun tu cluster
- **Timestamps y AGE**: Dependen de cuando ejecutaste los comandos
- **Nombres de PV dinamicos**: Son generados automaticamente con UUIDs

### Conceptos Clave Aprendidos

| Concepto              | Descripcion                                                |
| --------------------- | ---------------------------------------------------------- |
| PersistentVolume (PV) | Recurso de almacenamiento en el cluster                    |
| PersistentVolumeClaim | Solicitud de almacenamiento por una aplicacion             |
| StorageClass          | Define tipos de almacenamiento y aprovisionamiento         |
| Access Modes          | RWO (un nodo), ROX (muchos leen), RWX (muchos escriben)    |
| Reclaim Policy        | Retain (mantiene datos), Delete (elimina datos)            |
| hostPath              | Volumen que monta un directorio del nodo (solo desarrollo) |
| Dynamic Provisioning  | Creacion automatica de PVs cuando se solicita un PVC       |

### Diagrama de Relaciones

```
+----------------+     +---------------------+     +------------+
| Deployment     |---->| PersistentVolume    |<----| StorageClass|
|   postgres     |     |   Claim (PVC)       |     | (standard)  |
+----------------+     +---------------------+     +------------+
        |                       |                        |
        v                       v                        v
+----------------+     +---------------------+     +------------+
| Pod            |     | PersistentVolume    |     | Provisioner|
| (con volumen)  |     |   (PV)              |     | (crea PVs) |
+----------------+     +---------------------+     +------------+
        |                       |
        v                       v
+----------------+     +---------------------+
| volumeMount    |     | Almacenamiento      |
| /var/lib/...   |     | (hostPath, NFS, etc)|
+----------------+     +---------------------+
```
