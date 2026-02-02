# Labs End-to-End Validation Tracking

Este documento rastrea el estado de validación end-to-end de cada laboratorio del curso.

## Criterios de Validación

Cada laboratorio debe cumplir con los siguientes criterios para considerarse validado:

1. **README.md Ejecutable** - Las instrucciones del README.md pueden seguirse sin errores
2. **Archivos Correctos** - Los archivos en `initial/` y `solution/` son correctos y completos
3. **lab-completo.sh** - El script se ejecuta correctamente y completa el laboratorio
4. **verificar-completado.sh** - El script de verificación se ejecuta sin errores
5. **salidas-esperadas.md** - El contenido coincide con la salida de los scripts anteriores

## Herramientas de Validación

- bash
- kubectl
- minikube
- Cualquier otra herramienta de terminal/CLI que sea necesaria para terminar tu trabajo de validación

## Estado de Validación

### Leyenda

- [ ] No validado
- [x] Validado correctamente

---

## Nivel 1: Fundamentos

### Lab 01 - Docker Basics

**Ruta:** `nivel-1-fundamentos/modulo-01-cloud-contenedores/lab-01-docker-basics/`

- [x] README.md ejecutable sin errores
- [x] Archivos en `solution/` correctos
- [x] `lab-completo.sh` se ejecuta correctamente
- [x] `verificar-completado.sh` se ejecuta correctamente
- [x] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

- Validado el 2026-02-02
- Se corrigió un bug en `verificar-completado.sh`: el uso de `((CHECKS_PASSED++))` con `set -e` causaba que el script terminara prematuramente porque la expresión aritmética postfix retorna 0 cuando la variable inicial es 0. Se cambió a `((++CHECKS_PASSED))` (prefix increment) para resolver el problema.
- Todas las 11 verificaciones del script pasan correctamente
- Docker version 28.1.1 usado para la validación

---

### Lab 02 - Minikube Setup

**Ruta:** `nivel-1-fundamentos/modulo-02-intro-kubernetes/lab-02-minikube-setup/`

- [x] README.md ejecutable sin errores
- [x] Archivos en `solution/` correctos
- [x] `lab-completo.sh` se ejecuta correctamente
- [x] `verificar-completado.sh` se ejecuta correctamente
- [x] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

- Validado el 2026-02-02
- Se corrigió el mismo bug en `verificar-completado.sh` encontrado en Lab 01: el uso de `((CHECKS_PASSED++))` y `((CHECKS_TOTAL++))` con `set -e` causaba terminación prematura. Se cambió a `((++CHECKS_PASSED))` y `((++CHECKS_TOTAL))` (prefix increment).
- Se corrigió enlace de navegación en README.md: `modulo-03-arquitectura-kubernetes` → `modulo-03-arquitectura`
- Todas las 12 verificaciones del script pasan correctamente
- Minikube v1.38.0 y kubectl v1.34.0 usados para la validación

---

### Lab 03 - Cluster Exploration

**Ruta:** `nivel-1-fundamentos/modulo-03-arquitectura/lab-03-cluster-exploration/`

- [x] README.md ejecutable sin errores
- [x] Archivos en `solution/` correctos
- [x] `lab-completo.sh` se ejecuta correctamente
- [x] `verificar-completado.sh` se ejecuta correctamente
- [x] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

- Validado el 2026-02-02
- Se corrigió un bug en `verificar-completado.sh`: el comando `minikube ssh -- systemctl is-active kubelet` retorna el status con un carriage return (`\r`) al final debido al TTY, causando que la comparación `[ "$KUBELET_STATUS" = "active" ]` fallara. Se agregó `tr -d '\r'` para limpiar el output.
- Todas las 17 verificaciones del script pasan correctamente
- Minikube v1.35.0 y kubectl v1.35.0 usados para la validación
- Todos los comandos del README.md funcionan correctamente

---

## Nivel 2: Uso Básico

### Lab 04 - Pods y Deployments

**Ruta:** `nivel-2-uso-basico/modulo-04-objetos-fundamentales/lab-04-pods-deployments/`

- [x] README.md ejecutable sin errores
- [x] Archivos en `initial/` correctos
- [x] Archivos en `solution/` correctos
- [x] `lab-completo.sh` se ejecuta correctamente
- [x] `verificar-completado.sh` se ejecuta correctamente
- [x] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

- Validado el 2026-02-02
- Todas las 15 verificaciones del script pasan correctamente
- `lab-completo.sh` ejecuta todos los pasos del laboratorio sin errores
- Los archivos YAML en `initial/` son correctos y despliegan recursos como se espera
- El script de verificación NO tiene `set -e`, por lo que no presenta el bug de arithmetic increment encontrado en labs anteriores
- Navigation links en README.md apuntan a archivos válidos
- Minikube v1.38.0 y kubectl v1.34.0 usados para la validación

---

### Lab 05 - Scaling

**Ruta:** `nivel-2-uso-basico/modulo-04-objetos-fundamentales/lab-05-scaling/`

- [x] README.md ejecutable sin errores
- [x] Archivos en `initial/` correctos
- [x] Archivos en `solution/` correctos
- [x] `lab-completo.sh` se ejecuta correctamente
- [x] `verificar-completado.sh` se ejecuta correctamente
- [x] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

- Validado el 2026-02-02
- Todas las 14 verificaciones del script pasan correctamente
- `lab-completo.sh` ejecuta todos los pasos del laboratorio sin errores, incluyendo ejercicios adicionales
- Los archivos YAML en `initial/` (`deployment-scaling.yaml` y `deployment-scaled.yaml`) son correctos
- El script de verificación NO tiene `set -e`, por lo que no presenta el bug de arithmetic increment
- Navigation links en README.md apuntan a archivos válidos
- Eventos de escalamiento se registran correctamente en el deployment

---

### Lab 06 - YAML Manifests

**Ruta:** `nivel-2-uso-basico/modulo-05-kubectl-yaml/lab-06-yaml-manifests/`

- [x] README.md ejecutable sin errores
- [x] Archivos en `initial/` correctos
- [x] Archivos en `solution/` correctos
- [x] `lab-completo.sh` se ejecuta correctamente
- [x] `verificar-completado.sh` se ejecuta correctamente
- [x] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

- Validado el 2026-02-02
- Todas las 17 verificaciones del script pasan correctamente
- `lab-completo.sh` ejecuta todos los pasos del laboratorio sin errores
- Los archivos YAML en `initial/` (`pod-ejemplo.yaml` y `deployment-ejemplo.yaml`) son correctos y despliegan recursos como se espera
- El script de verificación NO tiene `set -e`, por lo que no presenta el bug de arithmetic increment encontrado en labs anteriores
- Navigation links en README.md apuntan a archivos válidos
- Recursos del lab se limpian correctamente después de la ejecución

---

### Lab 07 - Resource Updates

**Ruta:** `nivel-2-uso-basico/modulo-05-kubectl-yaml/lab-07-resource-updates/`

- [x] README.md ejecutable sin errores
- [x] Archivos en `initial/` correctos
- [x] Archivos en `solution/` correctos
- [x] `lab-completo.sh` se ejecuta correctamente
- [x] `verificar-completado.sh` se ejecuta correctamente
- [x] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

- Validado el 2026-02-02
- Se corrigió un bug en `lab-completo.sh`: el comando `kubectl rollout undo --to-revision=1` fallaba porque después de múltiples operaciones (apply, replace, set image, undo), la revisión 1 ya no existía en el historial. Se cambió para obtener dinámicamente la primera revisión disponible con `kubectl rollout history | grep -E "^[0-9]+" | head -1 | awk '{print $1}'`
- Todas las 17 verificaciones del script pasan correctamente
- Los archivos YAML en `initial/` (`app-deployment-v1.yaml` y `app-deployment-v2.yaml`) son correctos
- Navigation links en README.md apuntan a archivos válidos

---

### Lab 08 - Services

**Ruta:** `nivel-2-uso-basico/modulo-06-servicios-networking/lab-08-services/`

- [x] README.md ejecutable sin errores
- [x] Archivos en `initial/` correctos
- [x] Archivos en `solution/` correctos
- [x] `lab-completo.sh` se ejecuta correctamente
- [x] `verificar-completado.sh` se ejecuta correctamente
- [x] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

- Validado el 2026-02-02
- Se corrigió un bug en `verificar-completado.sh`: faltaba un `sleep 3` antes de la verificación de acceso via NodePort (paso 7), causando que el curl fallara porque el Service no estaba completamente operacional después de su creación. Se agregó la espera para dar tiempo a kube-proxy de configurar las reglas de iptables.
- Todas las 19 verificaciones del script pasan correctamente
- Los archivos YAML en `initial/` (`deployment-web.yaml`, `service-clusterip.yaml`, `service-nodeport.yaml`, `service-multi-selector.yaml`) son correctos
- Navigation links en README.md apuntan a archivos válidos
- Minikube v1.38.0 y kubectl v1.34.0 usados para la validación

---

### Lab 09 - Ingress

**Ruta:** `nivel-2-uso-basico/modulo-06-servicios-networking/lab-09-ingress/`

- [x] README.md ejecutable sin errores
- [x] Archivos en `initial/` correctos
- [x] Archivos en `solution/` correctos
- [x] `lab-completo.sh` se ejecuta correctamente
- [x] `verificar-completado.sh` se ejecuta correctamente
- [x] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

- Validado el 2026-02-02
- Todas las 15 verificaciones del script pasan correctamente
- El script `lab-completo.sh` tiene sintaxis correcta y no presenta errores
- Los archivos YAML en `initial/` (`apps.yaml`, `ingress-path.yaml`, `ingress-host.yaml`) son correctos y despliegan recursos como se espera
- El enrutamiento por path (`/frontend`, `/backend`) funciona correctamente con la anotación `rewrite-target`
- El enrutamiento por host (`frontend.local`, `backend.local`) funciona correctamente usando el header Host
- Navigation links en README.md apuntan a archivos válidos
- Minikube v1.38.0 y kubectl v1.34.0 usados para la validación
- No se encontraron bugs ni fueron necesarias correcciones

---

## Nivel 3: Uso Intermedio

### Lab 10 - ConfigMaps

**Ruta:** `nivel-3-uso-intermedio/modulo-07-configuracion/lab-10-configmaps/`

- [x] README.md ejecutable sin errores
- [x] Archivos en `initial/` correctos
- [x] Archivos en `solution/` correctos
- [x] `lab-completo.sh` se ejecuta correctamente
- [x] `verificar-completado.sh` se ejecuta correctamente
- [x] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

- Validado el 2026-02-02
- Todas las 19 verificaciones del script pasan correctamente
- `lab-completo.sh` ejecuta todos los pasos del laboratorio sin errores
- Los archivos YAML en `initial/` (`config.properties`, `configmap.yaml`, `pod-env.yaml`, `pod-volume.yaml`) son correctos y despliegan recursos como se espera
- El script de verificación NO tiene `set -e`, por lo que no presenta el bug de arithmetic increment encontrado en labs anteriores
- Se agregaron navigation links en README.md (faltaban): Anterior → Lab 09, Siguiente → Lab 11
- ConfigMap inmutable funciona correctamente y rechaza modificaciones
- Comportamiento de actualización (env vs volume) demostrado correctamente
- Minikube v1.38.0 y kubectl v1.34.0 usados para la validación

---

### Lab 11 - Secrets

**Ruta:** `nivel-3-uso-intermedio/modulo-07-configuracion/lab-11-secrets/`

- [x] README.md ejecutable sin errores
- [x] Archivos en `initial/` correctos
- [x] Archivos en `solution/` correctos
- [x] `lab-completo.sh` se ejecuta correctamente
- [x] `verificar-completado.sh` se ejecuta correctamente
- [x] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

- Validado el 2026-02-02
- Todas las 18 verificaciones del script pasan correctamente
- `lab-completo.sh` ejecuta todos los pasos del laboratorio sin errores
- Los archivos en `initial/` (`secret.yaml`, `pod-secret-env.yaml`, `pod-secret-volume.yaml`, `rbac-secret-reader.yaml`, `secret-tls-example.yaml`) son correctos
- El script de verificación NO tiene `set -e`, por lo que no presenta el bug de arithmetic increment
- Navigation links en README.md apuntan a archivos válidos (Lab 10 y Lab 12)
- Secret inmutable funciona correctamente y rechaza modificaciones
- Decodificación base64 funciona correctamente
- Tipos de Secrets (Opaque, dockerconfigjson) se crean y verifican correctamente
- Minikube v1.38.0 y kubectl v1.34.0 usados para la validación
- No se encontraron bugs ni fueron necesarias correcciones

---

### Lab 12 - Persistent Storage

**Ruta:** `nivel-3-uso-intermedio/modulo-08-almacenamiento/lab-12-persistent-storage/`

- [x] README.md ejecutable sin errores
- [x] Archivos en `initial/` correctos
- [x] Archivos en `solution/` correctos
- [x] `lab-completo.sh` se ejecuta correctamente
- [x] `verificar-completado.sh` se ejecuta correctamente
- [x] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

- Validado el 2026-02-02
- Todas las 21 verificaciones del script pasan correctamente
- `lab-completo.sh` ejecuta todos los pasos del laboratorio sin errores
- Los archivos YAML en `initial/` (`pv.yaml`, `pvc.yaml`, `postgres-persistent.yaml`, `pvc-dynamic.yaml`) son correctos y despliegan recursos como se espera
- El script de verificación NO tiene `set -e`, por lo que no presenta el bug de arithmetic increment encontrado en labs anteriores
- Se agregaron navigation links faltantes en README.md: Anterior → Lab 11, Siguiente → Lab 13
- La persistencia de datos funciona correctamente: datos sobreviven al eliminar y recrear el pod
- El aprovisionamiento dinámico con StorageClass default de Minikube funciona correctamente
- Minikube v1.38.0 y kubectl v1.34.0 usados para la validación

---

### Lab 13 - HPA (Horizontal Pod Autoscaler)

**Ruta:** `nivel-3-uso-intermedio/modulo-09-escalamiento/lab-13-hpa/`

- [x] README.md ejecutable sin errores
- [x] Archivos en `initial/` correctos
- [x] Archivos en `solution/` correctos
- [x] `lab-completo.sh` se ejecuta correctamente
- [x] `verificar-completado.sh` se ejecuta correctamente
- [x] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

- Validado el 2026-02-02
- Todas las 22 verificaciones del script pasan correctamente
- Se corrigió un bug en `verificar-completado.sh`: la verificación de `kubectl top pods` fallaba porque las métricas de pods recién creados no están disponibles inmediatamente. Se agregó un mecanismo de reintentos (hasta 4 intentos con 15 segundos entre cada uno) para esperar a que Metrics Server recopile las métricas.
- Los archivos YAML en `initial/` (`app-hpa.yaml`, `hpa.yaml`) son correctos y despliegan recursos como se espera
- El script de verificación NO tiene `set -e`, por lo que no presenta el bug de arithmetic increment
- Se agregaron navigation links faltantes en README.md: Anterior → Lab 12, Siguiente → Lab 14
- Metrics Server se habilita correctamente con `minikube addons enable metrics-server`
- HPA con autoscaling/v2 funciona correctamente con múltiples métricas (CPU y memoria)
- Minikube v1.38.0 y kubectl v1.34.0 usados para la validación

---

### Lab 14 - Rolling Updates

**Ruta:** `nivel-3-uso-intermedio/modulo-09-escalamiento/lab-14-rolling-updates/`

- [x] README.md ejecutable sin errores
- [x] Archivos en `initial/` correctos
- [x] Archivos en `solution/` correctos
- [x] `lab-completo.sh` se ejecuta correctamente
- [x] `verificar-completado.sh` se ejecuta correctamente
- [x] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

- Validado el 2026-02-02
- Todas las 15 verificaciones del script pasan correctamente
- `lab-completo.sh` ejecuta todos los pasos del laboratorio sin errores
- Los archivos YAML en `initial/` (`app-rolling.yaml`, `app-recreate.yaml`) son correctos y despliegan recursos como se espera
- El script de verificación NO tiene `set -e`, por lo que no presenta el bug de arithmetic increment
- Se agregaron navigation links faltantes en README.md: Anterior → Lab 13, Siguiente → Lab 15
- Rolling updates funcionan correctamente con maxSurge=1 y maxUnavailable=1
- Rollback funciona tanto a versión anterior como a revisión específica
- Pause y Resume funcionan correctamente
- Estrategia Recreate funciona correctamente
- Minikube v1.38.0 y kubectl v1.34.0 usados para la validación
- No se encontraron bugs ni fueron necesarias correcciones adicionales

---

## Nivel 4: Operación y Buenas Prácticas

### Lab 15 - RBAC

**Ruta:** `nivel-4-operacion/modulo-10-seguridad/lab-15-rbac/`

- [x] README.md ejecutable sin errores
- [x] Archivos en `initial/` correctos
- [x] Archivos en `solution/` correctos
- [x] `lab-completo.sh` se ejecuta correctamente
- [x] `verificar-completado.sh` se ejecuta correctamente
- [x] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

- Validado el 2026-02-02
- Todas las 26 verificaciones del script pasan correctamente
- Se corrigió un problema en `lab-completo.sh`: el comando `kubectl auth can-i update deployments/scale` retorna "no" incorrectamente debido a un comportamiento conocido de kubectl con subresources. Se cambió la verificación para demostrar el escalamiento real con `kubectl scale deployment --as=scaler-user` que sí funciona correctamente.
- Se actualizó `salidas-esperadas.md` para reflejar la nueva salida que demuestra el escalamiento real
- Se agregaron navigation links faltantes en README.md: Anterior → Lab 14, Siguiente → Lab 16
- Los archivos YAML en `initial/` (role-readonly.yaml, role-developer.yaml, rolebinding.yaml, rolebinding-developer.yaml, clusterrole.yaml, clusterrolebinding.yaml, role-deployment-scaler.yaml, test-deployment.yaml) son correctos
- Roles, RoleBindings, ClusterRoles y ClusterRoleBindings se crean y funcionan correctamente
- `kubectl auth can-i` funciona correctamente para permisos regulares (no subresources)
- Minikube v1.38.0 y kubectl v1.34.0 usados para la validación

---

### Lab 16 - Service Accounts

**Ruta:** `nivel-4-operacion/modulo-10-seguridad/lab-16-service-accounts/`

- [x] README.md ejecutable sin errores
- [x] Archivos en `initial/` correctos
- [x] Archivos en `solution/` correctos
- [x] `lab-completo.sh` se ejecuta correctamente
- [x] `verificar-completado.sh` se ejecuta correctamente
- [x] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

- Validado el 2026-02-02
- Todas las 23 verificaciones del script pasan correctamente
- `lab-completo.sh` ejecuta todos los pasos del laboratorio sin errores
- Los archivos YAML en `initial/` (serviceaccount.yaml, sa-rolebinding.yaml, pod-with-sa.yaml, sa-no-automount.yaml, sa-secret-reader.yaml, pod-api-access.yaml) son correctos y despliegan recursos como se espera
- ServiceAccounts se crean correctamente con vinculación a Roles via RoleBinding
- Tokens se montan automáticamente en pods y se pueden verificar
- automountServiceAccountToken: false funciona correctamente
- kubectl create token funciona para crear tokens con expiración
- Acceso directo a la API con curl desde dentro del pod funciona correctamente
- Se agregaron navigation links faltantes en README.md: Anterior → Lab 15, Siguiente → Lab 17
- Minikube v1.38.0 y kubectl v1.34.0 usados para la validación
- No se encontraron bugs ni fueron necesarias correcciones

---

### Lab 17 - Prometheus y Grafana

**Ruta:** `nivel-4-operacion/modulo-11-monitoreo/lab-17-prometheus-grafana/`

- [x] README.md ejecutable sin errores
- [x] Archivos en `initial/` correctos
- [x] Archivos en `solution/` correctos
- [x] `lab-completo.sh` se ejecuta correctamente
- [x] `verificar-completado.sh` se ejecuta correctamente
- [x] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

- Validado el 2026-02-02
- Todas las 22 verificaciones del script pasan correctamente
- Se corrigió un bug en `prometheus-values.yaml`: el archivo definía un datasource de Prometheus con `isDefault: true`, pero el chart kube-prometheus-stack ya incluye un datasource por defecto, causando que Grafana fallara con "Only one datasource per organization can be marked as default". Se eliminó la sección de datasources redundante.
- Se corrigió un bug en `verificar-completado.sh`: el label para encontrar el pod de Prometheus Operator era incorrecto (`app.kubernetes.io/name=prometheus-operator` debería ser `app.kubernetes.io/name=kube-prometheus-stack-prometheus-operator`)
- Se agregaron navigation links faltantes en README.md: Anterior → Lab 16, Siguiente → Lab 18
- kube-prometheus-stack se instala correctamente incluyendo Prometheus, Grafana, Alertmanager, Node Exporter, kube-state-metrics y Prometheus Operator
- Custom PrometheusRules (alertrule.yaml) se aplican correctamente
- Helm v3.19.2 y kubectl usados para la validación

---

### Lab 18 - Managed Kubernetes (GKE/EKS/AKS)

**Ruta:** `nivel-4-operacion/modulo-12-cloud/lab-18-managed-kubernetes/`

#### Validación General

- [x] README.md ejecutable sin errores
- [x] Archivos en `initial/` correctos
- [x] Archivos en `solution/` correctos
- [x] `lab-completo.sh` sintaxis correcta (script interactivo)
- [x] `verificar-completado.sh` sintaxis correcta (script interactivo)
- [x] `salidas-esperadas.md` documenta correctamente las salidas

#### Validación por Proveedor Cloud

##### GKE (Google Kubernetes Engine)

- [x] Herramientas instaladas (gcloud)
- [x] Autenticación con GCP
- [x] Habilitar API de Kubernetes Engine
- [x] Crear clúster GKE con Workload Identity habilitado
- [x] Verificar conexión con kubectl
- [x] Crear GCP Service Account para Workload Identity
- [x] Configurar IAM binding (workloadIdentityUser)
- [x] Probar ServiceAccount con Workload Identity
- [x] Verificar autenticación desde pod (gcloud auth list)
- [x] Eliminar clúster correctamente

##### EKS (Amazon Elastic Kubernetes Service)

- [x] Herramientas instaladas (aws, eksctl)
- [x] Autenticación con AWS
- [x] Crear clúster EKS con eksctl
- [x] Verificar conexión con kubectl
- [x] Probar ServiceAccount con IRSA (anotaciones correctas)
- [x] Token EKS montado correctamente en pods
- [x] Variables AWS\_\* inyectadas en pods con IRSA
- [x] Eliminar clúster correctamente

##### AKS (Azure Kubernetes Service)

- [x] Herramientas instaladas (az)
- [x] Autenticación con Azure
- [x] Crear grupo de recursos
- [x] Crear clúster AKS con OIDC Issuer y Workload Identity
- [x] Verificar conexión con kubectl
- [x] Crear Azure Managed Identity
- [x] Crear federated credential para ServiceAccount
- [x] Probar ServiceAccount con Azure Workload Identity
- [x] Verificar variables AZURE\_\* inyectadas en pods
- [x] Verificar token montado en /var/run/secrets/azure/tokens/
- [x] Eliminar clúster y grupo de recursos

**Notas de validación:**

- Validado el 2026-02-02 en EKS, AKS y GKE
- Se agregaron navigation links faltantes en README.md: Anterior → Lab 17, Siguiente → Proyecto Final
- GKE validado end-to-end el 2026-02-02:
  - Cluster creado: `gcloud container clusters create demo-cluster --zone us-central1-a --num-nodes 2 --machine-type e2-small --workload-pool=PROJECT_ID.svc.id.goog`
  - Kubernetes version: v1.33.5-gke.2118001
  - gcloud version: Google Cloud SDK 548.0.0
- Workload Identity funciona correctamente:
  - GCP Service Account creado con `gcloud iam service-accounts create`
  - IAM binding configurado con `gcloud iam service-accounts add-iam-policy-binding` y role `roles/iam.workloadIdentityUser`
  - K8s ServiceAccount con anotación `iam.gke.io/gcp-service-account` se crea sin errores
  - Pod usando ServiceAccount puede autenticarse con GCP APIs automáticamente
  - `gcloud auth list` dentro del pod muestra la cuenta de servicio GCP correcta
- EKS validado end-to-end:
  - Cluster creado: `eksctl create cluster --name lab18-validation --region us-east-1 --nodegroup-name workers --node-type t3.small --nodes 2`
  - Kubernetes version: v1.32.9-eks-ecaa3a6
  - eksctl version: 0.221.0
  - AWS CLI version: aws-cli/2.28.8
- IRSA funciona correctamente:
  - ServiceAccount con anotación `eks.amazonaws.com/role-arn` se crea sin errores
  - Pod usando ServiceAccount recibe variables de entorno AWS\_\* automáticamente
  - Token EKS montado en `/var/run/secrets/eks.amazonaws.com/serviceaccount/token`
- AKS validado end-to-end el 2026-02-02:
  - Cluster creado con `--enable-oidc-issuer --enable-workload-identity`
  - Kubernetes version: v1.33.6
  - Azure CLI version: 2.80.0
- Azure Workload Identity funciona correctamente:
  - Managed Identity creado y federated credential configurado
  - ServiceAccount con anotación `azure.workload.identity/client-id` y label `azure.workload.identity/use: "true"`
  - Pod recibe variables de entorno: AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_AUTHORITY_HOST, AZURE_FEDERATED_TOKEN_FILE
  - Token montado correctamente en `/var/run/secrets/azure/tokens/azure-identity-token`
- Se corrigió README.md: AKS integration ahora usa Azure Workload Identity (reemplaza legacy Pod Identity)
- Se actualizó comando `az aks create` para incluir `--enable-oidc-issuer --enable-workload-identity`
- Se mejoraron las instrucciones de README.md para incluir:
  - Secciones de REQUISITOS PREVIOS, CREAR RECURSOS y VERIFICAR para cada proveedor
  - GKE: autenticación, listado de proyectos, habilitación de API de Kubernetes Engine
  - EKS: configuración de AWS CLI, verificación de autenticación, información sobre recursos creados automáticamente
  - AKS: verificación de suscripción, listado de suscripciones, comandos de verificación de recursos
  - Limpieza detallada: comandos de verificación de eliminación y limpieza de recursos huérfanos para cada proveedor
- `aks-serviceaccount.yaml` validado - despliega correctamente ServiceAccount y Pod con Workload Identity
- Los archivos en `initial/` (`comparativa-proveedores.md`, `cuestionario-seleccion.md`, `gke-serviceaccount.yaml`, `eks-serviceaccount.yaml`, `aks-serviceaccount.yaml`) son correctos
- El script `lab-completo.sh` es interactivo y permite seleccionar una plataforma específica
- El script `verificar-completado.sh` es interactivo y verifica conocimientos teóricos
- Validación de GKE completada el 2026-02-02 - Lab 18 ahora validado en los tres proveedores (GKE, EKS, AKS)
- Se corrigió README.md: comando de creación de cluster GKE ahora incluye `--workload-pool` para habilitar Workload Identity
- Se agregaron instrucciones detalladas para configurar Workload Identity en GKE (crear GCP SA, configurar IAM binding)
- Se actualizó `lab-completo.sh` para incluir `--workload-pool` en creación de cluster GKE
- Se actualizó `salidas-esperadas.md` con ejemplos de salida para Workload Identity en GKE

---

## Proyecto Final

### Proyecto Final - Full-Stack Application

**Ruta:** `proyecto-final/`

- [x] README.md ejecutable sin errores
- [x] Archivos en `initial/` correctos
- [x] Archivos en `solution/` correctos
- [x] `lab-completo.sh` se ejecuta correctamente
- [x] `verificar-completado.sh` se ejecuta correctamente
- [x] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

- Validado el 2026-02-02
- Se corrigió bug en Dockerfiles: `npm ci` requiere `package-lock.json` que no estaba incluido. Se cambió a `npm install --omit=dev` (backend) y `npm install` (frontend) para que funcione sin lock file.
- Se corrigió bug en `verificar-completado.sh`:
  - La verificación de namespace fallaba cuando el parámetro namespace era empty string. Se agregó lógica para no usar flag `-n` al verificar namespaces.
  - Health check usaba `wget` que no está disponible en alpine node image. Se cambió a usar `node` con módulo http nativo.
  - Conectividad check usaba `wget`/`nc` que no están disponibles. Se cambió a usar `node` con módulo net nativo.
  - Se usó IPv4 explícito (127.0.0.1) en lugar de localhost para evitar problemas de resolución a IPv6.
- Se actualizaron los templates en `initial/` para reflejar el uso de `npm install` en lugar de `npm ci`.
- Se agregaron navigation links al README.md (Anterior → Lab 18).
- Re-validado el 2026-02-02:
  - Se corrigió inconsistencia en README.md: password en secrets.yaml era `supersecret` pero solution usaba `supersecret123`. Actualizado a `supersecret123`.
  - Se agregó anotación faltante `nginx.ingress.kubernetes.io/use-regex: "true"` al ejemplo de Ingress en README.md (requerida para paths con regex).
  - Se actualizó `initial/kubernetes/ingress.yaml` para incluir la anotación `use-regex` en los comentarios TODO.
- Todas las verificaciones del script pasan correctamente:
  - Namespace creado ✓
  - ConfigMaps y Secrets configurados ✓
  - PostgreSQL con StatefulSet y PVC (persistencia) ✓
  - Backend con 3 réplicas, health checks y probes ✓
  - Frontend con 3 réplicas ✓
  - Ingress con reglas para `/api` y `/` ✓
  - HPA configurado (min: 2, max: 10, CPU 70%) ✓
- Pruebas end-to-end realizadas:
  - Health check del backend funciona
  - CRUD de todos funciona (crear, leer, actualizar)
  - Ingress routing funciona (frontend en `/`, backend en `/api`)
  - Persistencia de datos verificada (datos sobreviven al eliminar pod PostgreSQL)
- Minikube v1.38.0, kubectl v1.34.0, Docker v28.1.1 usados para la validación

---

## Resumen de Validación

| Nivel                    | Labs Validados | Total Labs | Porcentaje |
| ------------------------ | -------------- | ---------- | ---------- |
| Nivel 1 - Fundamentos    | 3              | 3          | 100%       |
| Nivel 2 - Uso Básico     | 6              | 6          | 100%       |
| Nivel 3 - Uso Intermedio | 5              | 5          | 100%       |
| Nivel 4 - Operación      | 4              | 4          | 100%       |
| Proyecto Final           | 1              | 1          | 100%       |
| **Total**                | **19**         | **19**     | **100%**   |

---

## Historial de Validaciones

| Fecha      | Lab                           | Validador | Resultado        | Notas                                                                                                                                                                                                                          |
| ---------- | ----------------------------- | --------- | ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 2026-02-02 | Lab 01 - Docker Basics        | Claude    | ✓ Validado       | Se corrigió bug en verificar-completado.sh (arithmetic increment con set -e)                                                                                                                                                   |
| 2026-02-02 | Lab 02 - Minikube Setup       | Claude    | ✓ Validado       | Se corrigió mismo bug en verificar-completado.sh + enlace de navegación en README.md                                                                                                                                           |
| 2026-02-02 | Lab 03 - Cluster Exploration  | Claude    | ✓ Validado       | Se corrigió bug en verificar-completado.sh (carriage return en output de minikube ssh)                                                                                                                                         |
| 2026-02-02 | Lab 04 - Pods y Deployments   | Claude    | ✓ Validado       | Todas las 15 verificaciones pasaron. Lab funciona end-to-end sin correcciones necesarias.                                                                                                                                      |
| 2026-02-02 | Lab 05 - Scaling              | Claude    | ✓ Validado       | Todas las 14 verificaciones pasaron. Lab funciona end-to-end sin correcciones necesarias.                                                                                                                                      |
| 2026-02-02 | Lab 06 - YAML Manifests       | Claude    | ✓ Validado       | Todas las 17 verificaciones pasaron. Lab funciona end-to-end sin correcciones necesarias.                                                                                                                                      |
| 2026-02-02 | Lab 07 - Resource Updates     | Claude    | ✓ Validado       | Se corrigió bug en lab-completo.sh (rollback to-revision=1 fallaba). Todas las 17 verificaciones pasaron.                                                                                                                      |
| 2026-02-02 | Lab 08 - Services             | Claude    | ✓ Validado       | Se corrigió bug en verificar-completado.sh (faltaba sleep antes de curl a NodePort). Todas las 19 verificaciones pasaron.                                                                                                      |
| 2026-02-02 | Lab 09 - Ingress              | Claude    | ✓ Validado       | Todas las 15 verificaciones pasaron. Lab funciona end-to-end sin correcciones necesarias.                                                                                                                                      |
| 2026-02-02 | Lab 10 - ConfigMaps           | Claude    | ✓ Validado       | Todas las 19 verificaciones pasaron. Se agregaron navigation links faltantes en README.md.                                                                                                                                     |
| 2026-02-02 | Lab 11 - Secrets              | Claude    | ✓ Validado       | Todas las 18 verificaciones pasaron. Lab funciona end-to-end sin correcciones necesarias.                                                                                                                                      |
| 2026-02-02 | Lab 12 - Persistent Storage   | Claude    | ✓ Validado       | Todas las 21 verificaciones pasaron. Se agregaron navigation links faltantes en README.md.                                                                                                                                     |
| 2026-02-02 | Lab 13 - HPA                  | Claude    | ✓ Validado       | Todas las 22 verificaciones pasaron. Se corrigió bug en verificar-completado.sh (métricas de pods no disponibles inmediatamente). Se agregaron navigation links en README.md.                                                  |
| 2026-02-02 | Lab 14 - Rolling Updates      | Claude    | ✓ Validado       | Todas las 15 verificaciones pasaron. Se agregaron navigation links en README.md. Nivel 3 completado al 100%.                                                                                                                   |
| 2026-02-02 | Lab 15 - RBAC                 | Claude    | ✓ Validado       | Todas las 26 verificaciones pasaron. Se corrigió bug en lab-completo.sh (kubectl auth can-i para subresources no funciona correctamente; se cambió a demostrar escalamiento real). Se agregaron navigation links en README.md. |
| 2026-02-02 | Lab 16 - Service Accounts     | Claude    | ✓ Validado       | Todas las 23 verificaciones pasaron. Lab funciona end-to-end sin correcciones necesarias. Se agregaron navigation links en README.md.                                                                                          |
| 2026-02-02 | Lab 17 - Prometheus y Grafana | Claude    | ✓ Validado       | Todas las 22 verificaciones pasaron. Se corrigió bug en prometheus-values.yaml (datasource duplicado) y en verificar-completado.sh (label incorrecto para Prometheus Operator). Se agregaron navigation links en README.md.    |
| 2026-02-02 | Lab 18 - Managed Kubernetes   | Claude    | ✓ Validado (EKS) | Validación completa en EKS. Cluster creado y eliminado exitosamente. IRSA funciona correctamente. Se agregaron navigation links en README.md. Nivel 4 completado al 100%.                                                      |
| 2026-02-02 | Lab 18 - Managed Kubernetes   | Claude    | ✓ Validado (AKS) | Validación completa en AKS. Cluster con OIDC Issuer y Workload Identity. Federated credentials funcionan correctamente. Se corrigió README.md para usar Azure Workload Identity en lugar de legacy Pod Identity.               |
| 2026-02-02 | Lab 18 - Managed Kubernetes   | Claude    | ✓ Validado (GKE) | Validación completa en GKE. Cluster con Workload Identity Pool. GCP Service Account creado y binding IAM configurado. Pod autentica automáticamente con GCP APIs. Lab 18 ahora validado en los 3 proveedores.                  |
| 2026-02-02 | Proyecto Final                | Claude    | ✓ Validado       | Full-stack To-Do app desplegada end-to-end. Se corrigieron bugs en Dockerfiles (npm ci→npm install) y verificar-completado.sh (wget→node, namespace check). Persistencia de datos verificada. Todos los labs ahora validados.  |
| 2026-02-02 | Proyecto Final                | Claude    | ✓ Re-validado    | Se corrigió inconsistencia de password en README.md (supersecret→supersecret123). Se agregó anotación use-regex faltante en ejemplo de Ingress. Se actualizó initial/ingress.yaml con anotación en TODO.                        |
