# Lab 17: Prometheus y Grafana

## Objetivo

Implementar monitoreo del clúster con Prometheus y visualización con Grafana.

## Prerrequisitos

- Lab 16 completado
- Helm instalado (o se instalará durante el lab)

## Duración

90 minutos

## Instrucciones

### Paso 1: Instalar Helm

```bash
# En Linux/macOS
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verificar instalación
helm version
```

### Paso 2: Agregar repositorio de Prometheus

```bash
# Agregar repositorio
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Ver charts disponibles
helm search repo prometheus-community
```

### Paso 3: Instalar Prometheus Stack

```bash
# Crear namespace
kubectl create namespace monitoring

# Instalar kube-prometheus-stack (incluye Prometheus, Grafana, Alertmanager)
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.retention=24h \
  --set grafana.adminPassword=admin123

# Verificar instalación
kubectl get pods -n monitoring
kubectl get services -n monitoring
```

### Paso 4: Acceder a Prometheus

```bash
# Port-forward a Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &

# Abrir http://localhost:9090 en el navegador
```

### Paso 5: Explorar métricas

En la interfaz de Prometheus, prueba estas queries:

```promql
# Uso de CPU por pod
sum(rate(container_cpu_usage_seconds_total{namespace="default"}[5m])) by (pod)

# Memoria usada por pod
sum(container_memory_working_set_bytes{namespace="default"}) by (pod)

# Número de pods por namespace
count by (namespace) (kube_pod_info)

# Pods no Ready
sum by (namespace, pod) (kube_pod_status_phase{phase!="Running"})
```

### Paso 6: Acceder a Grafana

```bash
# Port-forward a Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &

# Abrir http://localhost:3000
# Usuario: admin
# Contraseña: admin123 (o la que configuraste)
```

### Paso 7: Explorar dashboards predefinidos

1. En Grafana, ve a Dashboards → Browse
2. Explora los dashboards incluidos:
   - Kubernetes / Compute Resources / Cluster
   - Kubernetes / Compute Resources / Namespace (Pods)
   - Kubernetes / Networking / Pod
   - Node Exporter / Nodes

### Paso 8: Crear un dashboard simple

1. Click en "+" → "New Dashboard"
2. Add visualization
3. Configura la query:

```promql
sum(rate(container_cpu_usage_seconds_total{namespace="default"}[5m])) by (pod)
```

4. Configura el panel:
   - Title: "CPU Usage by Pod"
   - Legend: {{pod}}
5. Save dashboard

### Paso 9: Configurar alertas

Crea el archivo `alertrule.yaml`:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: custom-alerts
  namespace: monitoring
  labels:
    release: prometheus
spec:
  groups:
    - name: pod-alerts
      rules:
        - alert: PodNotReady
          expr: kube_pod_status_phase{phase!="Running",phase!="Succeeded"} > 0
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "Pod {{ $labels.pod }} not ready"
            description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} has been in {{ $labels.phase }} state for more than 5 minutes."
        - alert: HighMemoryUsage
          expr: (container_memory_working_set_bytes / container_spec_memory_limit_bytes) > 0.8
          for: 2m
          labels:
            severity: warning
          annotations:
            summary: "High memory usage on {{ $labels.pod }}"
```

```bash
kubectl apply -f alertrule.yaml

# Verificar
kubectl get prometheusrules -n monitoring
```

### Paso 10: Ver métricas desde kubectl

```bash
# Métricas de nodos
kubectl top nodes

# Métricas de pods
kubectl top pods -A

# Métricas de un pod específico
kubectl top pod <pod-name>
```

## Ejercicios Adicionales

1. Crea un dashboard para monitorear una aplicación específica
2. Configura una alerta por uso excesivo de CPU
3. Explora Alertmanager para configurar notificaciones

## Verificación

- [ ] Prometheus está recolectando métricas
- [ ] Puedo hacer queries en PromQL
- [ ] Grafana muestra dashboards correctamente
- [ ] Entiendo cómo crear alertas

## Limpieza

```bash
# Eliminar el stack de monitoreo
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring
```

## Solución

Consulta el directorio `solution/` para configuraciones adicionales.
