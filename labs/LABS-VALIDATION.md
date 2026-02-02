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

- [ ] README.md ejecutable sin errores
- [ ] Archivos en `initial/` correctos
- [ ] Archivos en `solution/` correctos
- [ ] `lab-completo.sh` se ejecuta correctamente
- [ ] `verificar-completado.sh` se ejecuta correctamente
- [ ] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

---

### Lab 11 - Secrets

**Ruta:** `nivel-3-uso-intermedio/modulo-07-configuracion/lab-11-secrets/`

- [ ] README.md ejecutable sin errores
- [ ] Archivos en `initial/` correctos
- [ ] Archivos en `solution/` correctos
- [ ] `lab-completo.sh` se ejecuta correctamente
- [ ] `verificar-completado.sh` se ejecuta correctamente
- [ ] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

---

### Lab 12 - Persistent Storage

**Ruta:** `nivel-3-uso-intermedio/modulo-08-almacenamiento/lab-12-persistent-storage/`

- [ ] README.md ejecutable sin errores
- [ ] Archivos en `initial/` correctos
- [ ] Archivos en `solution/` correctos
- [ ] `lab-completo.sh` se ejecuta correctamente
- [ ] `verificar-completado.sh` se ejecuta correctamente
- [ ] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

---

### Lab 13 - HPA (Horizontal Pod Autoscaler)

**Ruta:** `nivel-3-uso-intermedio/modulo-09-escalamiento/lab-13-hpa/`

- [ ] README.md ejecutable sin errores
- [ ] Archivos en `initial/` correctos
- [ ] Archivos en `solution/` correctos
- [ ] `lab-completo.sh` se ejecuta correctamente
- [ ] `verificar-completado.sh` se ejecuta correctamente
- [ ] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

---

### Lab 14 - Rolling Updates

**Ruta:** `nivel-3-uso-intermedio/modulo-09-escalamiento/lab-14-rolling-updates/`

- [ ] README.md ejecutable sin errores
- [ ] Archivos en `initial/` correctos
- [ ] Archivos en `solution/` correctos
- [ ] `lab-completo.sh` se ejecuta correctamente
- [ ] `verificar-completado.sh` se ejecuta correctamente
- [ ] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

---

## Nivel 4: Operación y Buenas Prácticas

### Lab 15 - RBAC

**Ruta:** `nivel-4-operacion/modulo-10-seguridad/lab-15-rbac/`

- [ ] README.md ejecutable sin errores
- [ ] Archivos en `initial/` correctos
- [ ] Archivos en `solution/` correctos
- [ ] `lab-completo.sh` se ejecuta correctamente
- [ ] `verificar-completado.sh` se ejecuta correctamente
- [ ] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

---

### Lab 16 - Service Accounts

**Ruta:** `nivel-4-operacion/modulo-10-seguridad/lab-16-service-accounts/`

- [ ] README.md ejecutable sin errores
- [ ] Archivos en `initial/` correctos
- [ ] Archivos en `solution/` correctos
- [ ] `lab-completo.sh` se ejecuta correctamente
- [ ] `verificar-completado.sh` se ejecuta correctamente
- [ ] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

---

### Lab 17 - Prometheus y Grafana

**Ruta:** `nivel-4-operacion/modulo-11-monitoreo/lab-17-prometheus-grafana/`

- [ ] README.md ejecutable sin errores
- [ ] Archivos en `initial/` correctos
- [ ] Archivos en `solution/` correctos
- [ ] `lab-completo.sh` se ejecuta correctamente
- [ ] `verificar-completado.sh` se ejecuta correctamente
- [ ] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

---

### Lab 18 - Managed Kubernetes (GKE/EKS/AKS)

**Ruta:** `nivel-4-operacion/modulo-12-cloud/lab-18-managed-kubernetes/`

- [ ] README.md ejecutable sin errores
- [ ] Archivos en `initial/` correctos
- [ ] Archivos en `solution/` correctos
- [ ] `lab-completo.sh` se ejecuta correctamente
- [ ] `verificar-completado.sh` se ejecuta correctamente
- [ ] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

---

## Proyecto Final

### Proyecto Final - Full-Stack Application

**Ruta:** `proyecto-final/`

- [ ] README.md ejecutable sin errores
- [ ] Archivos en `initial/` correctos
- [ ] Archivos en `solution/` correctos
- [ ] `lab-completo.sh` se ejecuta correctamente
- [ ] `verificar-completado.sh` se ejecuta correctamente
- [ ] `salidas-esperadas.md` coincide con salida de scripts

**Notas de validación:**

---

## Resumen de Validación

| Nivel | Labs Validados | Total Labs | Porcentaje |
| ----- | -------------- | ---------- | ---------- |
| Nivel 1 - Fundamentos | 3 | 3 | 100% |
| Nivel 2 - Uso Básico | 6 | 6 | 100% |
| Nivel 3 - Uso Intermedio | 0 | 5 | 0% |
| Nivel 4 - Operación | 0 | 4 | 0% |
| Proyecto Final | 0 | 1 | 0% |
| **Total** | **9** | **19** | **47%** |

---

## Historial de Validaciones

| Fecha | Lab | Validador | Resultado | Notas |
| ----- | --- | --------- | --------- | ----- |
| 2026-02-02 | Lab 01 - Docker Basics | Claude | ✓ Validado | Se corrigió bug en verificar-completado.sh (arithmetic increment con set -e) |
| 2026-02-02 | Lab 02 - Minikube Setup | Claude | ✓ Validado | Se corrigió mismo bug en verificar-completado.sh + enlace de navegación en README.md |
| 2026-02-02 | Lab 03 - Cluster Exploration | Claude | ✓ Validado | Se corrigió bug en verificar-completado.sh (carriage return en output de minikube ssh) |
| 2026-02-02 | Lab 04 - Pods y Deployments | Claude | ✓ Validado | Todas las 15 verificaciones pasaron. Lab funciona end-to-end sin correcciones necesarias. |
| 2026-02-02 | Lab 05 - Scaling | Claude | ✓ Validado | Todas las 14 verificaciones pasaron. Lab funciona end-to-end sin correcciones necesarias. |
| 2026-02-02 | Lab 06 - YAML Manifests | Claude | ✓ Validado | Todas las 17 verificaciones pasaron. Lab funciona end-to-end sin correcciones necesarias. |
| 2026-02-02 | Lab 07 - Resource Updates | Claude | ✓ Validado | Se corrigió bug en lab-completo.sh (rollback to-revision=1 fallaba). Todas las 17 verificaciones pasaron. |
| 2026-02-02 | Lab 08 - Services | Claude | ✓ Validado | Se corrigió bug en verificar-completado.sh (faltaba sleep antes de curl a NodePort). Todas las 19 verificaciones pasaron. |
| 2026-02-02 | Lab 09 - Ingress | Claude | ✓ Validado | Todas las 15 verificaciones pasaron. Lab funciona end-to-end sin correcciones necesarias. |
