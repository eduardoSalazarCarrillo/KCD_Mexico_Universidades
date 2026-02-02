# Lab 15: RBAC - Salidas Esperadas

Este documento muestra las salidas esperadas de cada comando del laboratorio para que puedas verificar que todo funciona correctamente.

## Paso 1: Crear Namespace para el Laboratorio

### kubectl create namespace

```
$ kubectl create namespace rbac-lab
namespace/rbac-lab created
```

### kubectl get namespace rbac-lab

```
$ kubectl get namespace rbac-lab
NAME       STATUS   AGE
rbac-lab   Active   5s
```

## Paso 2: Crear Role con Permisos de Solo Lectura

### kubectl apply -f role-readonly.yaml

```
$ kubectl apply -f initial/role-readonly.yaml
role.rbac.authorization.k8s.io/pod-reader created
```

### kubectl describe role pod-reader

```
$ kubectl describe role pod-reader -n rbac-lab
Name:         pod-reader
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources  Non-Resource URLs  Resource Names  Verbs
  ---------  -----------------  --------------  -----
  pods/log   []                 []              [get]
  pods       []                 []              [get list watch]
```

**Explicacion de columnas**:

| Columna             | Descripcion                                 |
| ------------------- | ------------------------------------------- |
| `Resources`         | Tipos de recursos a los que aplica la regla |
| `Non-Resource URLs` | URLs que no son recursos (ej: /healthz)     |
| `Resource Names`    | Nombres especificos de recursos (si aplica) |
| `Verbs`             | Acciones permitidas                         |

## Paso 3: Crear Role Developer

### kubectl apply -f role-developer.yaml

```
$ kubectl apply -f initial/role-developer.yaml
role.rbac.authorization.k8s.io/developer created
```

### kubectl describe role developer

```
$ kubectl describe role developer -n rbac-lab
Name:         developer
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources         Non-Resource URLs  Resource Names  Verbs
  ---------         -----------------  --------------  -----
  configmaps        []                 []              [get list watch create update delete]
  pods              []                 []              [get list watch create update delete]
  services          []                 []              [get list watch create update delete]
  deployments.apps  []                 []              [get list watch create update delete]
```

> **Nota**: El Role `developer` tiene permisos CRUD completos para varios recursos.

## Paso 4: Crear RoleBinding

### kubectl apply -f rolebinding.yaml

```
$ kubectl apply -f initial/rolebinding.yaml
rolebinding.rbac.authorization.k8s.io/read-pods-binding created
```

### kubectl describe rolebinding read-pods-binding

```
$ kubectl describe rolebinding read-pods-binding -n rbac-lab
Name:         read-pods-binding
Labels:       <none>
Annotations:  <none>
Role:
  Kind:  Role
  Name:  pod-reader
Subjects:
  Kind   Name        Namespace
  ----   ----        ---------
  User   jane
  Group  developers
```

**Componentes del RoleBinding**:

| Componente | Descripcion                              |
| ---------- | ---------------------------------------- |
| `Role`     | El Role que define los permisos          |
| `Subjects` | Usuarios/Grupos que reciben los permisos |

### kubectl get rolebindings

```
$ kubectl get rolebindings -n rbac-lab
NAME                 ROLE               AGE
read-pods-binding    Role/pod-reader    30s
developer-binding    Role/developer     10s
```

## Paso 5: Verificar Permisos con kubectl auth can-i

### Permisos del usuario actual (admin)

```
$ kubectl auth can-i create pods -n rbac-lab
yes

$ kubectl auth can-i delete deployments -n rbac-lab
yes
```

### Permisos de 'jane' (pod-reader)

```
$ kubectl auth can-i list pods -n rbac-lab --as=jane
yes

$ kubectl auth can-i create pods -n rbac-lab --as=jane
no

$ kubectl auth can-i delete pods -n rbac-lab --as=jane
no

$ kubectl auth can-i get pods/log -n rbac-lab --as=jane
yes
```

> **Explicacion**: Jane tiene el Role `pod-reader`, que solo permite ver pods y sus logs.

### Permisos de 'john' (developer)

```
$ kubectl auth can-i create pods -n rbac-lab --as=john
yes

$ kubectl auth can-i create deployments -n rbac-lab --as=john
yes

$ kubectl auth can-i delete services -n rbac-lab --as=john
yes
```

> **Explicacion**: John tiene el Role `developer`, que permite operaciones CRUD.

### Listar todos los permisos de un usuario

```
$ kubectl auth can-i --list -n rbac-lab --as=jane
Resources                                       Non-Resource URLs   Resource Names   Verbs
selfsubjectaccessreviews.authorization.k8s.io   []                  []               [create]
selfsubjectrulesreviews.authorization.k8s.io    []                  []               [create]
pods                                            []                  []               [get list watch]
pods/log                                        []                  []               [get]
                                                [/api/*]            []               [get]
                                                [/api]              []               [get]
...
```

## Paso 6: Crear ClusterRole

### kubectl apply -f clusterrole.yaml

```
$ kubectl apply -f initial/clusterrole.yaml
clusterrole.rbac.authorization.k8s.io/namespace-reader created
```

### kubectl describe clusterrole namespace-reader

```
$ kubectl describe clusterrole namespace-reader
Name:         namespace-reader
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources   Non-Resource URLs  Resource Names  Verbs
  ---------   -----------------  --------------  -----
  namespaces  []                 []              [get list watch]
  nodes       []                 []              [get list]
```

**Diferencia Role vs ClusterRole**:

| Aspecto    | Role                        | ClusterRole              |
| ---------- | --------------------------- | ------------------------ |
| Scope      | Un namespace                | Todo el cluster          |
| Metadata   | Tiene `namespace`           | NO tiene `namespace`     |
| Recursos   | Solo recursos con namespace | Cualquier recurso        |
| Uso tipico | Permisos de aplicacion      | Permisos administrativos |

## Paso 7: Crear ClusterRoleBinding

### kubectl apply -f clusterrolebinding.yaml

```
$ kubectl apply -f initial/clusterrolebinding.yaml
clusterrolebinding.rbac.authorization.k8s.io/namespace-reader-binding created
```

### kubectl describe clusterrolebinding namespace-reader-binding

```
$ kubectl describe clusterrolebinding namespace-reader-binding
Name:         namespace-reader-binding
Labels:       <none>
Annotations:  <none>
Role:
  Kind:  ClusterRole
  Name:  namespace-reader
Subjects:
  Kind   Name       Namespace
  ----   ----       ---------
  Group  all-users
```

### Verificar permisos globales

```
$ kubectl auth can-i list namespaces --as=bob --as-group=all-users
yes

$ kubectl auth can-i get nodes --as=bob --as-group=all-users
yes
```

## Paso 8: Explorar Roles Predefinidos

### ClusterRoles del sistema

```
$ kubectl get clusterroles | grep -E "^(admin|edit|view|cluster-admin)"
admin                                                          2024-01-15T10:00:00Z
cluster-admin                                                  2024-01-15T10:00:00Z
edit                                                           2024-01-15T10:00:00Z
view                                                           2024-01-15T10:00:00Z
```

### Resumen de roles predefinidos

| ClusterRole     | Descripcion                               |
| --------------- | ----------------------------------------- |
| `view`          | Solo lectura de la mayoria de recursos    |
| `edit`          | Lectura/escritura, pero no RBAC ni quotas |
| `admin`         | Todo en un namespace, incluyendo RBAC     |
| `cluster-admin` | TODOS los permisos en TODO el cluster     |

### kubectl describe clusterrole cluster-admin

```
$ kubectl describe clusterrole cluster-admin
Name:         cluster-admin
Labels:       kubernetes.io/bootstrapping=rbac-defaults
Annotations:  rbac.authorization.kubernetes.io/autoupdate: true
PolicyRule:
  Resources  Non-Resource URLs  Resource Names  Verbs
  ---------  -----------------  --------------  -----
  *.*        []                 []              [*]
             [*]                []              [*]
```

> **ADVERTENCIA**: `cluster-admin` tiene acceso a TODOS los recursos con TODOS los verbos. Usar con extremo cuidado.

## Paso 9: Probar Permisos con Recursos Reales

### Desplegar aplicacion de prueba

```
$ kubectl apply -f initial/test-deployment.yaml
deployment.apps/nginx-test created

$ kubectl get pods -n rbac-lab
NAME                          READY   STATUS    RESTARTS   AGE
nginx-test-7d4f8b7b9c-abc12   1/1     Running   0          30s
nginx-test-7d4f8b7b9c-def34   1/1     Running   0          30s
```

### Simular acciones como 'jane' (pod-reader)

```
$ kubectl get pods -n rbac-lab --as=jane
NAME                          READY   STATUS    RESTARTS   AGE
nginx-test-7d4f8b7b9c-abc12   1/1     Running   0          1m
nginx-test-7d4f8b7b9c-def34   1/1     Running   0          1m

$ kubectl run test-pod --image=nginx -n rbac-lab --as=jane
Error from server (Forbidden): pods is forbidden: User "jane" cannot create resource "pods" in API group "" in the namespace "rbac-lab"
```

### Simular acciones como 'john' (developer)

```
$ kubectl run john-pod --image=nginx:alpine -n rbac-lab --as=john
pod/john-pod created

$ kubectl get pods -n rbac-lab --as=john
NAME                          READY   STATUS    RESTARTS   AGE
john-pod                      1/1     Running   0          10s
nginx-test-7d4f8b7b9c-abc12   1/1     Running   0          2m
nginx-test-7d4f8b7b9c-def34   1/1     Running   0          2m

$ kubectl delete pod john-pod -n rbac-lab --as=john
pod "john-pod" deleted
```

## Paso 10: Role para Escalar Deployments

### Verificar permisos del scaler-user

```
$ kubectl auth can-i get deployments -n rbac-lab --as=scaler-user
yes

$ kubectl auth can-i delete deployments -n rbac-lab --as=scaler-user
no

$ kubectl auth can-i create pods -n rbac-lab --as=scaler-user
no
```

### Probar escalamiento real como scaler-user

```
$ kubectl scale deployment nginx-test -n rbac-lab --replicas=4 --as=scaler-user
deployment.apps/nginx-test scaled

$ kubectl get deployment nginx-test -n rbac-lab
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
nginx-test   4/4     4            4           2m
```

> **Principio de menor privilegio**: El `scaler-user` puede escalar deployments, pero no crear ni eliminar recursos.

## Paso 11: Ver todos los Roles y Bindings

### Roles en el namespace

```
$ kubectl get roles -n rbac-lab
NAME                 CREATED AT
pod-reader           2024-01-15T10:00:00Z
developer            2024-01-15T10:01:00Z
deployment-scaler    2024-01-15T10:05:00Z
```

### RoleBindings en el namespace

```
$ kubectl get rolebindings -n rbac-lab
NAME                 ROLE                     AGE
read-pods-binding    Role/pod-reader          10m
developer-binding    Role/developer           9m
scaler-binding       Role/deployment-scaler   5m
```

## Limpieza

### Eliminar recursos

```
$ kubectl delete namespace rbac-lab
namespace "rbac-lab" deleted

$ kubectl delete clusterrole namespace-reader
clusterrole.rbac.authorization.k8s.io "namespace-reader" deleted

$ kubectl delete clusterrolebinding namespace-reader-binding
clusterrolebinding.rbac.authorization.k8s.io "namespace-reader-binding" deleted
```

> **Nota**: Al eliminar el namespace, todos los Roles y RoleBindings dentro de el tambien se eliminan.

## Resumen

Si todas tus salidas son similares a las mostradas en este documento, has completado exitosamente el Lab 15.

### Diferencias menores esperadas

- **Timestamps**: Varian segun cuando ejecutaste los comandos
- **Nombres de pods**: Los sufijos aleatorios seran diferentes
- **Orden de recursos**: Puede variar

### Conceptos Clave Aprendidos

| Concepto           | Descripcion                                          |
| ------------------ | ---------------------------------------------------- |
| Role               | Define permisos en UN namespace                      |
| ClusterRole        | Define permisos a nivel de cluster                   |
| RoleBinding        | Vincula Role/ClusterRole a usuarios en un namespace  |
| ClusterRoleBinding | Vincula ClusterRole globalmente                      |
| apiGroups          | Grupo de API ("" = core, "apps" = deployments, etc.) |
| resources          | Tipos de recursos (pods, services, deployments)      |
| verbs              | Acciones (get, list, watch, create, update, delete)  |
| --as               | Impersonar usuario para verificar permisos           |
| --as-group         | Impersonar grupo para verificar permisos             |

### Matriz de Permisos del Lab

| Usuario/Grupo | Pods (rbac-lab) | Deployments (rbac-lab) | Namespaces (global) |
| ------------- | --------------- | ---------------------- | ------------------- |
| jane          | get,list,watch  | -                      | -                   |
| john          | CRUD            | CRUD                   | -                   |
| scaler-user   | -               | get,list,scale         | -                   |
| all-users     | -               | -                      | get,list,watch      |
