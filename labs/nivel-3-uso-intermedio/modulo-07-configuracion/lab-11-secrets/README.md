# Lab 11: Secrets

## Objetivo

Gestionar información sensible con Kubernetes Secrets.

## Prerrequisitos

- Lab 10 completado

## Duración

45 minutos

## Instrucciones

### Paso 1: Crear Secret desde literales

```bash
# Crear Secret genérico
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=supersecret123

# Verificar (nota: los valores están en base64)
kubectl get secret db-credentials
kubectl describe secret db-credentials
kubectl get secret db-credentials -o yaml
```

### Paso 2: Decodificar valores

```bash
# Los valores están en base64, no encriptados
kubectl get secret db-credentials -o jsonpath='{.data.username}' | base64 -d
kubectl get secret db-credentials -o jsonpath='{.data.password}' | base64 -d
```

### Paso 3: Crear Secret con YAML

Crea el archivo `secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  # Valores en base64: echo -n "valor" | base64
  api-key: YXBpLWtleS0xMjM0NTY3ODkw
  jwt-secret: c3VwZXItc2VjcmV0LWp3dC1rZXk=
stringData:
  # stringData permite valores sin codificar
  database-url: postgres://user:pass@host:5432/db
```

```bash
kubectl apply -f secret.yaml
kubectl describe secret app-secrets
```

### Paso 4: Usar Secret como variables de entorno

Crea el archivo `pod-secret-env.yaml`:

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

```bash
kubectl apply -f pod-secret-env.yaml

# Verificar (sensible!)
kubectl exec pod-secret-env -- env | grep -E "DB_|api|jwt|database"
```

### Paso 5: Montar Secret como volumen

Crea el archivo `pod-secret-volume.yaml`:

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
        defaultMode: 0400 # Permisos restrictivos
```

```bash
kubectl apply -f pod-secret-volume.yaml

# Verificar
kubectl exec pod-secret-volume -- ls -la /etc/secrets
kubectl exec pod-secret-volume -- cat /etc/secrets/username
```

### Paso 6: Tipos de Secrets

```bash
# Secret para Docker Registry
kubectl create secret docker-registry my-registry \
  --docker-server=registry.example.com \
  --docker-username=user \
  --docker-password=pass \
  --docker-email=user@example.com

# Secret TLS
kubectl create secret tls my-tls \
  --cert=path/to/cert.pem \
  --key=path/to/key.pem

# Ver tipos disponibles
kubectl get secrets
```

### Paso 7: Buenas prácticas de seguridad

```yaml
# Limitar acceso con RBAC
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    resourceNames: ["db-credentials"] # Solo este secret
    verbs: ["get"]
```

## Ejercicios Adicionales

1. Crea un Secret inmutable
2. Investiga sealed-secrets para GitOps
3. Experimenta con external-secrets operator

## Verificación

- [ ] Puedo crear Secrets de múltiples formas
- [ ] Entiendo que base64 NO es encriptación
- [ ] Puedo usar Secrets como env vars y volúmenes
- [ ] Conozco los diferentes tipos de Secrets

## Solución

Consulta el directorio `solution/` para ejemplos avanzados.
