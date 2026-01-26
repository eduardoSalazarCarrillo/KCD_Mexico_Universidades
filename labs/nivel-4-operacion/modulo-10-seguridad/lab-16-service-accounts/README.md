# Lab 16: Service Accounts

## Objetivo

Configurar identidades para aplicaciones en el clúster.

## Prerrequisitos

- Lab 15 completado

## Duración

45 minutos

## Instrucciones

### Paso 1: Explorar ServiceAccount por defecto

```bash
# Ver ServiceAccounts en el namespace actual
kubectl get serviceaccounts

# Describir el ServiceAccount default
kubectl describe serviceaccount default

# Ver el token asociado
kubectl get secrets
```

### Paso 2: Crear ServiceAccount personalizado

Crea el archivo `serviceaccount.yaml`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  namespace: default
```

```bash
kubectl apply -f serviceaccount.yaml
kubectl describe serviceaccount app-service-account
```

### Paso 3: Vincular ServiceAccount a un Role

Crea el archivo `sa-rolebinding.yaml`:

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

```bash
kubectl apply -f sa-rolebinding.yaml
```

### Paso 4: Crear Pod con ServiceAccount

Crea el archivo `pod-with-sa.yaml`:

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

```bash
kubectl apply -f pod-with-sa.yaml
kubectl describe pod pod-with-sa | grep -A5 "Service Account"
```

### Paso 5: Verificar token montado en el pod

```bash
# Ver el token montado
kubectl exec pod-with-sa -- ls -la /var/run/secrets/kubernetes.io/serviceaccount/

# Ver el contenido del token
kubectl exec pod-with-sa -- cat /var/run/secrets/kubernetes.io/serviceaccount/token

# Ver el namespace
kubectl exec pod-with-sa -- cat /var/run/secrets/kubernetes.io/serviceaccount/namespace
```

### Paso 6: Acceder a la API desde el pod

```bash
# Entrar al pod
kubectl exec -it pod-with-sa -- /bin/bash

# Dentro del pod, usar kubectl (usa el ServiceAccount automáticamente)
kubectl get pods
kubectl get configmaps

# Esto debería fallar (no tenemos permisos)
kubectl get secrets
kubectl get deployments

# Salir
exit
```

### Paso 7: Crear ServiceAccount sin montar token automático

Crea el archivo `sa-no-automount.yaml`:

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

```bash
kubectl apply -f sa-no-automount.yaml

# Verificar que no hay token montado
kubectl exec pod-restricted-sa -- ls /var/run/secrets/kubernetes.io/serviceaccount/ 2>/dev/null || echo "No token mounted"
```

### Paso 8: Crear token manualmente (Kubernetes 1.24+)

```bash
# Crear token con duración específica
kubectl create token app-service-account --duration=1h

# Usar el token para autenticarse
TOKEN=$(kubectl create token app-service-account)
kubectl get pods --token=$TOKEN
```

## Ejercicios Adicionales

1. Crea un ServiceAccount para una aplicación que lea secrets
2. Investiga las diferencias entre tokens legacy y bound tokens
3. Configura un pod que acceda a la API de Kubernetes

## Verificación

- [ ] Puedo crear ServiceAccounts
- [ ] Puedo vincular ServiceAccounts a Roles
- [ ] Puedo usar ServiceAccounts en pods
- [ ] Entiendo cómo funcionan los tokens

## Solución

Consulta el directorio `solution/` para ejemplos avanzados.
