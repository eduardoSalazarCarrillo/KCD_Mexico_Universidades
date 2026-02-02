# Laboratorios - KCD Mexico Universidades

Este documento contiene la descripción detallada de todos los laboratorios prácticos del curso de Kubernetes.

## Estructura de Cada Laboratorio

Cada laboratorio contiene:

- `README.md` - Instrucciones detalladas del laboratorio
- `initial/` - Archivos de inicio (estado inicial)
- `solution/` - Solución completa (estado final)

---

## Nivel 1: Fundamentos

### Lab 01: Docker Basics

| Atributo              | Descripción                                                  |
| --------------------- | ------------------------------------------------------------ |
| **Módulo**            | 01 - Introducción a la Computación en la Nube y Contenedores |
| **Duración Estimada** | 45 minutos                                                   |
| **Dificultad**        | Principiante                                                 |
| **Prerrequisitos**    | Ninguno                                                      |

#### Objetivo de Aprendizaje

Instalar Docker y comprender el ciclo de vida básico de un contenedor.

#### Estado Inicial

- Sistema operativo limpio sin Docker instalado
- Sin imágenes ni contenedores

#### Estado Final

- Docker instalado y funcionando
- Contenedor nginx ejecutándose
- Comprensión de comandos básicos: `docker run`, `docker ps`, `docker stop`

#### Tareas

1. Instalar Docker en el sistema
2. Verificar la instalación con `docker version`
3. Descargar y ejecutar la imagen `nginx:alpine`
4. Listar contenedores en ejecución
5. Detener y eliminar el contenedor

#### Conceptos Clave

- Imágenes vs Contenedores
- Docker Hub como registro de imágenes
- Ciclo de vida del contenedor

---

### Lab 02: Minikube Setup

| Atributo              | Descripción                    |
| --------------------- | ------------------------------ |
| **Módulo**            | 02 - Introducción a Kubernetes |
| **Duración Estimada** | 30 minutos                     |
| **Dificultad**        | Principiante                   |
| **Prerrequisitos**    | Lab 01 (Docker instalado)      |

#### Objetivo de Aprendizaje

Configurar un entorno local de Kubernetes usando Minikube.

#### Estado Inicial

- Docker instalado y funcionando
- Sin Kubernetes configurado

#### Estado Final

- Minikube instalado
- Clúster local ejecutándose
- kubectl configurado y conectado al clúster

#### Tareas

1. Instalar Minikube
2. Instalar kubectl
3. Iniciar el clúster con `minikube start`
4. Verificar el estado del clúster
5. Explorar el dashboard de Kubernetes

#### Conceptos Clave

- Kubernetes local vs producción
- Relación entre kubectl y el clúster
- Contextos de Kubernetes

---

### Lab 03: Cluster Exploration

| Atributo              | Descripción                     |
| --------------------- | ------------------------------- |
| **Módulo**            | 03 - Arquitectura de Kubernetes |
| **Duración Estimada** | 30 minutos                      |
| **Dificultad**        | Principiante                    |
| **Prerrequisitos**    | Lab 02 (Minikube funcionando)   |

#### Objetivo de Aprendizaje

Explorar los componentes internos de un clúster de Kubernetes.

#### Estado Inicial

- Clúster Minikube ejecutándose
- Sin conocimiento de la arquitectura interna

#### Estado Final

- Identificación de componentes del Control Plane
- Comprensión de la comunicación entre nodos
- Familiaridad con los namespaces del sistema

#### Tareas

1. Listar nodos del clúster con `kubectl get nodes`
2. Explorar el namespace `kube-system`
3. Identificar pods del Control Plane (api-server, etcd, scheduler, controller-manager)
4. Revisar logs de componentes críticos
5. Entender el rol de kubelet y kube-proxy

#### Conceptos Clave

- Control Plane vs Worker Nodes
- Componentes del clúster
- Namespaces del sistema

---

## Nivel 2: Uso Básico

### Lab 04: Pods y Deployments

| Atributo              | Descripción                              |
| --------------------- | ---------------------------------------- |
| **Módulo**            | 04 - Objetos Fundamentales de Kubernetes |
| **Duración Estimada** | 60 minutos                               |
| **Dificultad**        | Principiante                             |
| **Prerrequisitos**    | Lab 03                                   |

#### Objetivo de Aprendizaje

Crear y gestionar Pods y Deployments en Kubernetes.

#### Estado Inicial

- Clúster vacío (sin aplicaciones desplegadas)
- Archivos YAML base proporcionados

#### Estado Final

- Pod individual ejecutándose
- Deployment con 3 réplicas funcionando
- Comprensión de la relación Pod → ReplicaSet → Deployment

#### Tareas

1. Crear un Pod simple con `kubectl run`
2. Crear un Deployment usando archivo YAML
3. Verificar la creación de ReplicaSet automático
4. Inspeccionar los pods con `kubectl describe`
5. Eliminar un pod y observar la recreación automática

#### Conceptos Clave

- Pod como unidad mínima de despliegue
- ReplicaSet para mantener réplicas
- Deployment para gestión declarativa

---

### Lab 05: Scaling

| Atributo              | Descripción                              |
| --------------------- | ---------------------------------------- |
| **Módulo**            | 04 - Objetos Fundamentales de Kubernetes |
| **Duración Estimada** | 30 minutos                               |
| **Dificultad**        | Principiante                             |
| **Prerrequisitos**    | Lab 04                                   |

#### Objetivo de Aprendizaje

Escalar aplicaciones manualmente en Kubernetes.

#### Estado Inicial

- Deployment con 1 réplica ejecutándose

#### Estado Final

- Deployment escalado a 5 réplicas
- Comprensión del escalamiento horizontal

#### Tareas

1. Verificar el número actual de réplicas
2. Escalar el deployment a 5 réplicas con `kubectl scale`
3. Observar la creación de nuevos pods
4. Reducir a 2 réplicas
5. Modificar el YAML y aplicar cambios

#### Conceptos Clave

- Escalamiento horizontal vs vertical
- Comando `kubectl scale`
- Actualización declarativa de réplicas

---

### Lab 06: YAML Manifests

| Atributo              | Descripción                  |
| --------------------- | ---------------------------- |
| **Módulo**            | 05 - kubectl y Archivos YAML |
| **Duración Estimada** | 60 minutos                   |
| **Dificultad**        | Intermedio                   |
| **Prerrequisitos**    | Lab 05                       |

#### Objetivo de Aprendizaje

Dominar la creación y estructura de manifiestos YAML de Kubernetes.

#### Estado Inicial

- Conocimiento básico de Pods y Deployments
- Sin experiencia escribiendo YAML desde cero

#### Estado Final

- Capacidad de escribir manifiestos YAML completos
- Entendimiento de apiVersion, kind, metadata, spec
- Familiaridad con labels y selectors

#### Tareas

1. Analizar la estructura de un manifiesto existente
2. Crear un Pod desde cero en YAML
3. Crear un Deployment con labels personalizados
4. Usar `kubectl apply -f` para desplegar
5. Generar YAML con `kubectl create --dry-run=client -o yaml`

#### Conceptos Clave

- Estructura de manifiestos Kubernetes
- apiVersion y compatibilidad
- Labels y Selectors
- Dry-run para generar YAML

---

### Lab 07: Resource Updates

| Atributo              | Descripción                  |
| --------------------- | ---------------------------- |
| **Módulo**            | 05 - kubectl y Archivos YAML |
| **Duración Estimada** | 45 minutos                   |
| **Dificultad**        | Intermedio                   |
| **Prerrequisitos**    | Lab 06                       |

#### Objetivo de Aprendizaje

Modificar y actualizar recursos existentes en Kubernetes.

#### Estado Inicial

- Deployment desplegado con imagen v1
- Configuración básica

#### Estado Final

- Deployment actualizado a imagen v2
- Comprensión de `apply` vs `create` vs `replace`
- Historial de cambios disponible

#### Tareas

1. Modificar la imagen en el archivo YAML
2. Aplicar cambios con `kubectl apply`
3. Observar el rollout de la actualización
4. Usar `kubectl edit` para cambios rápidos
5. Revisar el historial con `kubectl rollout history`

#### Conceptos Clave

- Actualizaciones declarativas
- apply vs create vs replace
- Rollout y estrategias de actualización

---

### Lab 08: Services

| Atributo              | Descripción                               |
| --------------------- | ----------------------------------------- |
| **Módulo**            | 06 - Servicios y Networking en Kubernetes |
| **Duración Estimada** | 60 minutos                                |
| **Dificultad**        | Intermedio                                |
| **Prerrequisitos**    | Lab 07                                    |

#### Objetivo de Aprendizaje

Exponer aplicaciones usando diferentes tipos de Services.

#### Estado Inicial

- Deployment con pods ejecutándose
- Sin exposición externa

#### Estado Final

- Service ClusterIP para comunicación interna
- Service NodePort para acceso externo
- Comprensión de selectors y endpoints

#### Tareas

1. Crear un Service tipo ClusterIP
2. Verificar la conectividad interna entre pods
3. Crear un Service tipo NodePort
4. Acceder a la aplicación desde fuera del clúster
5. Inspeccionar endpoints con `kubectl get endpoints`

#### Conceptos Clave

- ClusterIP vs NodePort vs LoadBalancer
- Selectors en Services
- Endpoints y descubrimiento de servicios

---

### Lab 09: Ingress

| Atributo              | Descripción                               |
| --------------------- | ----------------------------------------- |
| **Módulo**            | 06 - Servicios y Networking en Kubernetes |
| **Duración Estimada** | 60 minutos                                |
| **Dificultad**        | Intermedio                                |
| **Prerrequisitos**    | Lab 08                                    |

#### Objetivo de Aprendizaje

Configurar Ingress para enrutamiento HTTP/HTTPS.

#### Estado Inicial

- Dos aplicaciones desplegadas con Services ClusterIP
- Sin acceso HTTP desde el exterior

#### Estado Final

- Ingress Controller instalado
- Reglas de Ingress configuradas
- Enrutamiento basado en path funcionando

#### Tareas

1. Habilitar el addon de Ingress en Minikube
2. Crear dos deployments con sus services
3. Configurar un Ingress con reglas de path
4. Probar el enrutamiento con curl
5. Agregar un host virtual

#### Conceptos Clave

- Ingress vs Service
- Ingress Controller
- Reglas de enrutamiento (path y host)

---

## Nivel 3: Uso Intermedio

### Lab 10: ConfigMaps

| Atributo              | Descripción                                  |
| --------------------- | -------------------------------------------- |
| **Módulo**            | 07 - Configuración y Gestión de Aplicaciones |
| **Duración Estimada** | 45 minutos                                   |
| **Dificultad**        | Intermedio                                   |
| **Prerrequisitos**    | Lab 09                                       |

#### Objetivo de Aprendizaje

Externalizar configuración de aplicaciones usando ConfigMaps.

#### Estado Inicial

- Aplicación con configuración hardcodeada
- Sin separación entre código y configuración

#### Estado Final

- ConfigMap con variables de configuración
- Aplicación consumiendo ConfigMap como variables de entorno
- ConfigMap montado como archivo de configuración

#### Tareas

1. Crear un ConfigMap desde literal con `kubectl create configmap`
2. Crear un ConfigMap desde archivo
3. Inyectar ConfigMap como variables de entorno
4. Montar ConfigMap como volumen
5. Actualizar ConfigMap y observar comportamiento

#### Conceptos Clave

- Separación de configuración y código
- Variables de entorno vs volúmenes
- Inmutabilidad y actualizaciones

---

### Lab 11: Secrets

| Atributo              | Descripción                                  |
| --------------------- | -------------------------------------------- |
| **Módulo**            | 07 - Configuración y Gestión de Aplicaciones |
| **Duración Estimada** | 45 minutos                                   |
| **Dificultad**        | Intermedio                                   |
| **Prerrequisitos**    | Lab 10                                       |

#### Objetivo de Aprendizaje

Gestionar información sensible con Kubernetes Secrets.

#### Estado Inicial

- Aplicación que necesita credenciales de base de datos
- Credenciales expuestas en archivos de configuración

#### Estado Final

- Secret con credenciales encriptadas en base64
- Aplicación consumiendo Secret de forma segura
- Comprensión de tipos de Secrets

#### Tareas

1. Crear un Secret genérico con `kubectl create secret`
2. Crear un Secret desde archivo YAML
3. Inyectar Secret como variables de entorno
4. Montar Secret como volumen
5. Entender las limitaciones de seguridad de Secrets

#### Conceptos Clave

- Secrets vs ConfigMaps
- Encoding base64 (no es encriptación)
- Tipos de Secrets (Opaque, docker-registry, tls)

---

### Lab 12: Persistent Storage

| Atributo              | Descripción                       |
| --------------------- | --------------------------------- |
| **Módulo**            | 08 - Almacenamiento en Kubernetes |
| **Duración Estimada** | 75 minutos                        |
| **Dificultad**        | Intermedio                        |
| **Prerrequisitos**    | Lab 11                            |

#### Objetivo de Aprendizaje

Implementar almacenamiento persistente para aplicaciones stateful.

#### Estado Inicial

- Base de datos PostgreSQL sin persistencia
- Datos perdidos al reiniciar el pod

#### Estado Final

- PersistentVolume configurado
- PersistentVolumeClaim vinculado
- Base de datos con datos persistentes

#### Tareas

1. Desplegar PostgreSQL sin volumen y verificar pérdida de datos
2. Crear un PersistentVolume local
3. Crear un PersistentVolumeClaim
4. Modificar el deployment para usar el PVC
5. Verificar persistencia después de eliminar y recrear el pod

#### Conceptos Clave

- PersistentVolume (PV) vs PersistentVolumeClaim (PVC)
- StorageClasses
- Access Modes (ReadWriteOnce, ReadOnlyMany, ReadWriteMany)

---

### Lab 13: Horizontal Pod Autoscaler (HPA)

| Atributo              | Descripción                             |
| --------------------- | --------------------------------------- |
| **Módulo**            | 09 - Escalamiento y Alta Disponibilidad |
| **Duración Estimada** | 60 minutos                              |
| **Dificultad**        | Avanzado                                |
| **Prerrequisitos**    | Lab 12                                  |

#### Objetivo de Aprendizaje

Configurar escalamiento automático basado en métricas.

#### Estado Inicial

- Deployment con 2 réplicas fijas
- Sin escalamiento automático

#### Estado Final

- HPA configurado (min: 2, max: 10)
- Escalamiento automático por CPU
- Metrics Server funcionando

#### Tareas

1. Habilitar Metrics Server en Minikube
2. Configurar resource requests en el deployment
3. Crear HPA con `kubectl autoscale`
4. Generar carga con herramienta de stress
5. Observar el escalamiento automático

#### Conceptos Clave

- Horizontal Pod Autoscaler
- Metrics Server
- Resource requests y limits
- Umbrales de escalamiento

---

### Lab 14: Rolling Updates y Rollbacks

| Atributo              | Descripción                             |
| --------------------- | --------------------------------------- |
| **Módulo**            | 09 - Escalamiento y Alta Disponibilidad |
| **Duración Estimada** | 45 minutos                              |
| **Dificultad**        | Intermedio                              |
| **Prerrequisitos**    | Lab 13                                  |

#### Objetivo de Aprendizaje

Implementar actualizaciones sin downtime y recuperación ante fallos.

#### Estado Inicial

- Deployment con aplicación v1 funcionando
- Sin estrategia de actualización definida

#### Estado Final

- Actualización exitosa a v2 sin downtime
- Capacidad de rollback a versión anterior
- Comprensión de estrategias de deployment

#### Tareas

1. Configurar estrategia RollingUpdate en el deployment
2. Actualizar la imagen a v2
3. Monitorear el rollout con `kubectl rollout status`
4. Simular un deployment fallido con imagen incorrecta
5. Ejecutar rollback con `kubectl rollout undo`

#### Conceptos Clave

- RollingUpdate vs Recreate
- maxSurge y maxUnavailable
- Rollout history y rollback

---

## Nivel 4: Operación y Buenas Prácticas

### Lab 15: RBAC

| Atributo              | Descripción                  |
| --------------------- | ---------------------------- |
| **Módulo**            | 10 - Seguridad en Kubernetes |
| **Duración Estimada** | 60 minutos                   |
| **Dificultad**        | Avanzado                     |
| **Prerrequisitos**    | Lab 14                       |

#### Objetivo de Aprendizaje

Implementar control de acceso basado en roles.

#### Estado Inicial

- Clúster con acceso de administrador
- Sin restricciones de permisos

#### Estado Final

- Role con permisos limitados creado
- RoleBinding vinculando usuario a Role
- Usuario con acceso restringido funcionando

#### Tareas

1. Crear un namespace para el laboratorio
2. Definir un Role con permisos de solo lectura
3. Crear un RoleBinding para un usuario
4. Probar los permisos con `kubectl auth can-i`
5. Crear un ClusterRole para permisos globales

#### Conceptos Clave

- Role vs ClusterRole
- RoleBinding vs ClusterRoleBinding
- Principio de menor privilegio

---

### Lab 16: Service Accounts

| Atributo              | Descripción                  |
| --------------------- | ---------------------------- |
| **Módulo**            | 10 - Seguridad en Kubernetes |
| **Duración Estimada** | 45 minutos                   |
| **Dificultad**        | Avanzado                     |
| **Prerrequisitos**    | Lab 15                       |

#### Objetivo de Aprendizaje

Configurar identidades para aplicaciones en el clúster.

#### Estado Inicial

- Pods usando ServiceAccount por defecto
- Sin control de permisos a nivel de aplicación

#### Estado Final

- ServiceAccount personalizado creado
- Pod usando ServiceAccount específico
- Permisos restringidos para la aplicación

#### Tareas

1. Crear un ServiceAccount personalizado
2. Vincular ServiceAccount a un Role específico
3. Configurar un Pod para usar el ServiceAccount
4. Verificar el token montado en el pod
5. Probar acceso a la API desde dentro del pod

#### Conceptos Clave

- ServiceAccount vs User Account
- Tokens de ServiceAccount
- Acceso a la API de Kubernetes desde pods

---

### Lab 17: Prometheus y Grafana

| Atributo              | Descripción              |
| --------------------- | ------------------------ |
| **Módulo**            | 11 - Monitoreo y Logging |
| **Duración Estimada** | 90 minutos               |
| **Dificultad**        | Avanzado                 |
| **Prerrequisitos**    | Lab 16                   |

#### Objetivo de Aprendizaje

Implementar monitoreo del clúster con Prometheus y visualización con Grafana.

#### Estado Inicial

- Clúster sin monitoreo
- Sin visibilidad de métricas

#### Estado Final

- Prometheus recolectando métricas
- Grafana con dashboards configurados
- Alertas básicas funcionando

#### Tareas

1. Instalar Prometheus usando Helm
2. Explorar métricas del clúster
3. Instalar Grafana
4. Importar dashboard de Kubernetes
5. Crear una alerta básica

#### Conceptos Clave

- Métricas de Kubernetes
- PromQL básico
- Dashboards y visualización
- Alertas

---

### Lab 18: Managed Kubernetes

| Atributo              | Descripción                               |
| --------------------- | ----------------------------------------- |
| **Módulo**            | 12 - Introducción a Kubernetes en la Nube |
| **Duración Estimada** | 60 minutos                                |
| **Dificultad**        | Intermedio                                |
| **Prerrequisitos**    | Lab 17                                    |

#### Objetivo de Aprendizaje

Comparar y explorar servicios de Kubernetes administrado en la nube.

#### Estado Inicial

- Experiencia solo con Minikube local
- Sin conocimiento de plataformas cloud

#### Estado Final

- Comprensión de GKE, EKS y AKS
- Conocimiento de diferencias clave
- Capacidad de elegir plataforma según necesidades

#### Tareas

1. Explorar la consola de GKE (demo/documentación)
2. Comparar características de EKS vs AKS
3. Entender modelos de precios
4. Revisar integraciones con servicios cloud
5. Discutir criterios de selección

#### Conceptos Clave

- Managed vs Self-managed Kubernetes
- Integraciones con servicios cloud (IAM, Storage, Networking)
- Consideraciones de costo

---

## Proyecto Final

| Atributo              | Descripción                       |
| --------------------- | --------------------------------- |
| **Módulo**            | Proyecto Final                    |
| **Duración Estimada** | 4-6 horas                         |
| **Dificultad**        | Avanzado                          |
| **Prerrequisitos**    | Todos los laboratorios anteriores |

#### Objetivo de Aprendizaje

Aplicar todos los conocimientos adquiridos en un proyecto integral.

#### Estado Inicial

- Código fuente de aplicación frontend (React/Vue)
- Código fuente de aplicación backend (Node.js/Python)
- Base de datos requerida (PostgreSQL)
- Sin infraestructura de Kubernetes

#### Estado Final

- Aplicación completa desplegada en Kubernetes
- Frontend accesible via Ingress
- Backend comunicándose con base de datos
- Configuración externalizada (ConfigMaps/Secrets)
- Almacenamiento persistente para la base de datos
- Escalamiento automático configurado
- Documentación completa

#### Tareas

1. **Fase 1: Containerización**
   - Crear Dockerfiles para frontend y backend
   - Construir y probar imágenes localmente

2. **Fase 2: Despliegue Básico**
   - Crear Deployments para cada componente
   - Configurar Services para comunicación

3. **Fase 3: Configuración**
   - Externalizar configuración con ConfigMaps
   - Manejar credenciales con Secrets

4. **Fase 4: Persistencia**
   - Configurar PV/PVC para PostgreSQL
   - Verificar persistencia de datos

5. **Fase 5: Networking**
   - Configurar Ingress para acceso externo
   - Implementar reglas de enrutamiento

6. **Fase 6: Escalamiento**
   - Configurar HPA para el backend
   - Realizar pruebas de carga

7. **Fase 7: Documentación**
   - Crear README del proyecto
   - Documentar arquitectura y decisiones

#### Entregables

- Código fuente en repositorio Git
- Manifiestos YAML organizados
- Diagrama de arquitectura
- Documentación técnica
- Presentación (10-15 min)

#### Criterios de Evaluación

| Criterio                       | Peso |
| ------------------------------ | ---- |
| Funcionalidad completa         | 30%  |
| Buenas prácticas de Kubernetes | 25%  |
| Documentación                  | 20%  |
| Presentación técnica           | 15%  |
| Código limpio y organizado     | 10%  |

---

## Checklist de Archivos de Laboratorio

Esta sección rastrea el progreso de creación de archivos para cada laboratorio.

### Nivel 1: Fundamentos

#### Lab 01: Docker Basics

- [x] `labs/nivel-1-fundamentos/modulo-01-cloud-contenedores/lab-01-docker-basics/README.md`
- [x] `labs/nivel-1-fundamentos/modulo-01-cloud-contenedores/lab-01-docker-basics/initial/`
- [x] `labs/nivel-1-fundamentos/modulo-01-cloud-contenedores/lab-01-docker-basics/solution/`

#### Lab 02: Minikube Setup

- [x] `labs/nivel-1-fundamentos/modulo-02-intro-kubernetes/lab-02-minikube-setup/README.md`
- [x] `labs/nivel-1-fundamentos/modulo-02-intro-kubernetes/lab-02-minikube-setup/initial/`
- [x] `labs/nivel-1-fundamentos/modulo-02-intro-kubernetes/lab-02-minikube-setup/solution/`

#### Lab 03: Cluster Exploration

- [x] `labs/nivel-1-fundamentos/modulo-03-arquitectura/lab-03-cluster-exploration/README.md`
- [x] `labs/nivel-1-fundamentos/modulo-03-arquitectura/lab-03-cluster-exploration/initial/`
- [x] `labs/nivel-1-fundamentos/modulo-03-arquitectura/lab-03-cluster-exploration/solution/`

### Nivel 2: Uso Básico

#### Lab 04: Pods y Deployments

- [ ] `labs/nivel-2-uso-basico/modulo-04-objetos-fundamentales/lab-04-pods-deployments/README.md`
- [ ] `labs/nivel-2-uso-basico/modulo-04-objetos-fundamentales/lab-04-pods-deployments/initial/`
- [ ] `labs/nivel-2-uso-basico/modulo-04-objetos-fundamentales/lab-04-pods-deployments/solution/`

#### Lab 05: Scaling

- [ ] `labs/nivel-2-uso-basico/modulo-04-objetos-fundamentales/lab-05-scaling/README.md`
- [ ] `labs/nivel-2-uso-basico/modulo-04-objetos-fundamentales/lab-05-scaling/initial/`
- [ ] `labs/nivel-2-uso-basico/modulo-04-objetos-fundamentales/lab-05-scaling/solution/`

#### Lab 06: YAML Manifests

- [ ] `labs/nivel-2-uso-basico/modulo-05-kubectl-yaml/lab-06-yaml-manifests/README.md`
- [ ] `labs/nivel-2-uso-basico/modulo-05-kubectl-yaml/lab-06-yaml-manifests/initial/`
- [ ] `labs/nivel-2-uso-basico/modulo-05-kubectl-yaml/lab-06-yaml-manifests/solution/`

#### Lab 07: Resource Updates

- [ ] `labs/nivel-2-uso-basico/modulo-05-kubectl-yaml/lab-07-resource-updates/README.md`
- [ ] `labs/nivel-2-uso-basico/modulo-05-kubectl-yaml/lab-07-resource-updates/initial/`
- [ ] `labs/nivel-2-uso-basico/modulo-05-kubectl-yaml/lab-07-resource-updates/solution/`

#### Lab 08: Services

- [ ] `labs/nivel-2-uso-basico/modulo-06-servicios-networking/lab-08-services/README.md`
- [ ] `labs/nivel-2-uso-basico/modulo-06-servicios-networking/lab-08-services/initial/`
- [ ] `labs/nivel-2-uso-basico/modulo-06-servicios-networking/lab-08-services/solution/`

#### Lab 09: Ingress

- [ ] `labs/nivel-2-uso-basico/modulo-06-servicios-networking/lab-09-ingress/README.md`
- [ ] `labs/nivel-2-uso-basico/modulo-06-servicios-networking/lab-09-ingress/initial/`
- [ ] `labs/nivel-2-uso-basico/modulo-06-servicios-networking/lab-09-ingress/solution/`

### Nivel 3: Uso Intermedio

#### Lab 10: ConfigMaps

- [ ] `labs/nivel-3-uso-intermedio/modulo-07-configuracion/lab-10-configmaps/README.md`
- [ ] `labs/nivel-3-uso-intermedio/modulo-07-configuracion/lab-10-configmaps/initial/`
- [ ] `labs/nivel-3-uso-intermedio/modulo-07-configuracion/lab-10-configmaps/solution/`

#### Lab 11: Secrets

- [ ] `labs/nivel-3-uso-intermedio/modulo-07-configuracion/lab-11-secrets/README.md`
- [ ] `labs/nivel-3-uso-intermedio/modulo-07-configuracion/lab-11-secrets/initial/`
- [ ] `labs/nivel-3-uso-intermedio/modulo-07-configuracion/lab-11-secrets/solution/`

#### Lab 12: Persistent Storage

- [ ] `labs/nivel-3-uso-intermedio/modulo-08-almacenamiento/lab-12-persistent-storage/README.md`
- [ ] `labs/nivel-3-uso-intermedio/modulo-08-almacenamiento/lab-12-persistent-storage/initial/`
- [ ] `labs/nivel-3-uso-intermedio/modulo-08-almacenamiento/lab-12-persistent-storage/solution/`

#### Lab 13: Horizontal Pod Autoscaler

- [ ] `labs/nivel-3-uso-intermedio/modulo-09-escalamiento/lab-13-hpa/README.md`
- [ ] `labs/nivel-3-uso-intermedio/modulo-09-escalamiento/lab-13-hpa/initial/`
- [ ] `labs/nivel-3-uso-intermedio/modulo-09-escalamiento/lab-13-hpa/solution/`

#### Lab 14: Rolling Updates y Rollbacks

- [ ] `labs/nivel-3-uso-intermedio/modulo-09-escalamiento/lab-14-rolling-updates/README.md`
- [ ] `labs/nivel-3-uso-intermedio/modulo-09-escalamiento/lab-14-rolling-updates/initial/`
- [ ] `labs/nivel-3-uso-intermedio/modulo-09-escalamiento/lab-14-rolling-updates/solution/`

### Nivel 4: Operación y Buenas Prácticas

#### Lab 15: RBAC

- [ ] `labs/nivel-4-operacion/modulo-10-seguridad/lab-15-rbac/README.md`
- [ ] `labs/nivel-4-operacion/modulo-10-seguridad/lab-15-rbac/initial/`
- [ ] `labs/nivel-4-operacion/modulo-10-seguridad/lab-15-rbac/solution/`

#### Lab 16: Service Accounts

- [ ] `labs/nivel-4-operacion/modulo-10-seguridad/lab-16-service-accounts/README.md`
- [ ] `labs/nivel-4-operacion/modulo-10-seguridad/lab-16-service-accounts/initial/`
- [ ] `labs/nivel-4-operacion/modulo-10-seguridad/lab-16-service-accounts/solution/`

#### Lab 17: Prometheus y Grafana

- [ ] `labs/nivel-4-operacion/modulo-11-monitoreo/lab-17-prometheus-grafana/README.md`
- [ ] `labs/nivel-4-operacion/modulo-11-monitoreo/lab-17-prometheus-grafana/initial/`
- [ ] `labs/nivel-4-operacion/modulo-11-monitoreo/lab-17-prometheus-grafana/solution/`

#### Lab 18: Managed Kubernetes

- [ ] `labs/nivel-4-operacion/modulo-12-kubernetes-nube/lab-18-managed-kubernetes/README.md`
- [ ] `labs/nivel-4-operacion/modulo-12-kubernetes-nube/lab-18-managed-kubernetes/initial/`
- [ ] `labs/nivel-4-operacion/modulo-12-kubernetes-nube/lab-18-managed-kubernetes/solution/`

### Proyecto Final

- [ ] `labs/proyecto-final/README.md`
- [ ] `labs/proyecto-final/frontend/`
- [ ] `labs/proyecto-final/backend/`
- [ ] `labs/proyecto-final/database/`
- [ ] `labs/proyecto-final/kubernetes/`

---

## Recursos Adicionales

### Herramientas Recomendadas

- [Minikube](https://minikube.sigs.k8s.io/) - Kubernetes local
- [kind](https://kind.sigs.k8s.io/) - Kubernetes in Docker
- [k9s](https://k9scli.io/) - Terminal UI para Kubernetes
- [Lens](https://k8slens.dev/) - IDE para Kubernetes

### Documentación Oficial

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

### Práctica Adicional

- [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- [Katacoda Kubernetes](https://www.katacoda.com/courses/kubernetes)
