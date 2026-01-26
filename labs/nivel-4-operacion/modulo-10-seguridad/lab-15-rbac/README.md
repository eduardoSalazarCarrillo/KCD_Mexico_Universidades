# Lab 15: RBAC

## Objetivo

Implementar control de acceso basado en roles.

## Prerrequisitos

- Lab 14 completado

## Duración

60 minutos

## Instrucciones

### Paso 1: Crear namespace para el laboratorio

```bash
kubectl create namespace rbac-lab
kubectl get namespace rbac-lab
```

### Paso 2: Crear un Role con permisos limitados

Crea el archivo `role-readonly.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: rbac-lab
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["pods/log"]
    verbs: ["get"]
```

```bash
kubectl apply -f role-readonly.yaml
kubectl describe role pod-reader -n rbac-lab
```

### Paso 3: Crear un Role con más permisos

Crea el archivo `role-developer.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: rbac-lab
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps"]
    verbs: ["get", "list", "watch", "create", "update", "delete"]
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch", "create", "update", "delete"]
```

```bash
kubectl apply -f role-developer.yaml
kubectl describe role developer -n rbac-lab
```

### Paso 4: Crear RoleBinding

Crea el archivo `rolebinding.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods-binding
  namespace: rbac-lab
subjects:
  - kind: User
    name: jane
    apiGroup: rbac.authorization.k8s.io
  - kind: Group
    name: developers
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

```bash
kubectl apply -f rolebinding.yaml
kubectl describe rolebinding read-pods-binding -n rbac-lab
```

### Paso 5: Verificar permisos con can-i

```bash
# Verificar si el usuario actual puede hacer algo
kubectl auth can-i create pods -n rbac-lab

# Verificar permisos de otro usuario (requiere permisos de admin)
kubectl auth can-i list pods -n rbac-lab --as=jane
kubectl auth can-i create pods -n rbac-lab --as=jane
kubectl auth can-i delete pods -n rbac-lab --as=jane

# Ver todos los permisos de un usuario
kubectl auth can-i --list -n rbac-lab --as=jane
```

### Paso 6: Crear ClusterRole

Crea el archivo `clusterrole.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: namespace-reader
rules:
  - apiGroups: [""]
    resources: ["namespaces"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list"]
```

```bash
kubectl apply -f clusterrole.yaml
kubectl describe clusterrole namespace-reader
```

### Paso 7: Crear ClusterRoleBinding

Crea el archivo `clusterrolebinding.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: namespace-reader-binding
subjects:
  - kind: Group
    name: all-users
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: namespace-reader
  apiGroup: rbac.authorization.k8s.io
```

```bash
kubectl apply -f clusterrolebinding.yaml
kubectl describe clusterrolebinding namespace-reader-binding
```

### Paso 8: Explorar roles predefinidos

```bash
# Ver ClusterRoles del sistema
kubectl get clusterroles | grep -E "^(admin|edit|view|cluster-admin)"

# Ver detalles de roles predefinidos
kubectl describe clusterrole view
kubectl describe clusterrole edit
kubectl describe clusterrole admin
kubectl describe clusterrole cluster-admin
```

## Ejercicios Adicionales

1. Crea un Role que solo permita escalar deployments
2. Configura un RoleBinding que use un ClusterRole a nivel de namespace
3. Investiga cómo usar aggregated ClusterRoles

## Verificación

- [ ] Puedo crear Roles y ClusterRoles
- [ ] Puedo crear RoleBindings y ClusterRoleBindings
- [ ] Puedo verificar permisos con can-i
- [ ] Entiendo la diferencia entre Role y ClusterRole

## Solución

Consulta el directorio `solution/` para ejemplos completos.
