# Lab 17: Prometheus y Grafana - Salidas Esperadas

Este documento muestra las salidas esperadas de cada comando del laboratorio para que puedas verificar que todo funciona correctamente.

## Paso 1: Instalar Helm

### helm version

```
$ helm version
version.BuildInfo{Version:"v3.14.0", GitCommit:"...", GitTreeState:"clean", GoVersion:"go1.21.6"}
```

## Paso 2: Agregar Repositorio de Prometheus

### helm repo add prometheus-community

```
$ helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
"prometheus-community" has been added to your repositories
```

### helm repo update

```
$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "prometheus-community" chart repository
Update Complete. ⎈Happy Helming!⎈
```

### helm search repo prometheus-community

```
$ helm search repo prometheus-community | head -10
NAME                                                    CHART VERSION   APP VERSION     DESCRIPTION
prometheus-community/alertmanager                       1.9.0           v0.27.0         The Alertmanager handles alerts sent by client ...
prometheus-community/alertmanager-snmp-notifier         0.2.1           v1.5.0          The SNMP Notifier handles alerts coming from ...
prometheus-community/kube-prometheus-stack              56.6.2          v0.71.2         kube-prometheus-stack collects Kubernetes ...
prometheus-community/kube-state-metrics                 5.16.4          2.10.1          Install kube-state-metrics to generate ...
prometheus-community/prometheus                         25.13.0         v2.50.1         Prometheus is a monitoring system and time ...
prometheus-community/prometheus-adapter                 4.9.0           v0.11.2         A Helm chart for k8s prometheus adapter
prometheus-community/prometheus-blackbox-exporter       8.12.0          v0.24.0         Prometheus Blackbox Exporter
prometheus-community/prometheus-cloudwatch-exporter     0.25.3          0.15.5          A Helm chart for prometheus cloudwatch-exporter
prometheus-community/prometheus-consul-exporter         1.0.0           0.4.0           A Helm chart for the Prometheus Consul Exporter
```

## Paso 3: Instalar Prometheus Stack

### kubectl create namespace monitoring

```
$ kubectl create namespace monitoring
namespace/monitoring created
```

### helm install prometheus

```
$ helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.retention=24h \
  --set grafana.adminPassword=admin123

NAME: prometheus
LAST DEPLOYED: Mon Jan 15 10:00:00 2024
NAMESPACE: monitoring
STATUS: deployed
REVISION: 1
NOTES:
kube-prometheus-stack has been installed. Check its status by running:
  kubectl --namespace monitoring get pods -l "release=prometheus"

Visit https://github.com/prometheus-operator/kube-prometheus for instructions on how to create & configure Alertmanager and Prometheus instances using the Operator.
```

### kubectl get pods -n monitoring

```
$ kubectl get pods -n monitoring
NAME                                                     READY   STATUS    RESTARTS   AGE
alertmanager-prometheus-kube-prometheus-alertmanager-0   2/2     Running   0          5m
prometheus-grafana-5d8f4f4f4f-abc12                      3/3     Running   0          5m
prometheus-kube-prometheus-operator-7f7f7f7f7f-def34     1/1     Running   0          5m
prometheus-kube-state-metrics-8g8g8g8g8g-ghi56           1/1     Running   0          5m
prometheus-prometheus-kube-prometheus-prometheus-0       2/2     Running   0          5m
prometheus-prometheus-node-exporter-jkl78                1/1     Running   0          5m
```

**Explicación de pods**:

| Pod                                                  | Descripción                              |
| ---------------------------------------------------- | ---------------------------------------- |
| `alertmanager-prometheus-kube-prometheus-*`          | Maneja y enruta alertas                  |
| `prometheus-grafana-*`                               | Interfaz de visualización                |
| `prometheus-kube-prometheus-operator-*`              | Operador que gestiona Prometheus         |
| `prometheus-kube-state-metrics-*`                    | Expone métricas del estado de Kubernetes |
| `prometheus-prometheus-kube-prometheus-prometheus-*` | Servidor principal de Prometheus         |
| `prometheus-prometheus-node-exporter-*`              | Métricas del sistema operativo           |

### kubectl get services -n monitoring

```
$ kubectl get services -n monitoring
NAME                                        TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
alertmanager-operated                       ClusterIP   None             <none>        9093/TCP,9094/TCP,9094/UDP   5m
prometheus-grafana                          ClusterIP   10.96.100.1      <none>        80/TCP                       5m
prometheus-kube-prometheus-alertmanager     ClusterIP   10.96.100.2      <none>        9093/TCP,8080/TCP            5m
prometheus-kube-prometheus-operator         ClusterIP   10.96.100.3      <none>        443/TCP                      5m
prometheus-kube-prometheus-prometheus       ClusterIP   10.96.100.4      <none>        9090/TCP,8080/TCP            5m
prometheus-kube-state-metrics               ClusterIP   10.96.100.5      <none>        8080/TCP                     5m
prometheus-operated                         ClusterIP   None             <none>        9090/TCP                     5m
prometheus-prometheus-node-exporter         ClusterIP   10.96.100.6      <none>        9100/TCP                     5m
```

## Paso 4: Acceder a Prometheus

### kubectl port-forward

```
$ kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &
Forwarding from 127.0.0.1:9090 -> 9090
Forwarding from [::1]:9090 -> 9090
```

Después puedes abrir http://localhost:9090 en tu navegador.

## Paso 5: Explorar Métricas

### Ejemplos de queries PromQL

**Uso de CPU por pod:**

```promql
sum(rate(container_cpu_usage_seconds_total{namespace="default"}[5m])) by (pod)
```

Resultado:

```
{pod="nginx-deployment-abc12"}    0.015
{pod="web-app-def34"}             0.008
```

**Memoria usada por pod:**

```promql
sum(container_memory_working_set_bytes{namespace="default"}) by (pod)
```

Resultado:

```
{pod="nginx-deployment-abc12"}    52428800    # ~50MB
{pod="web-app-def34"}             31457280    # ~30MB
```

**Número de pods por namespace:**

```promql
count by (namespace) (kube_pod_info)
```

Resultado:

```
{namespace="default"}        5
{namespace="kube-system"}    8
{namespace="monitoring"}     6
{namespace="demo-app"}       5
```

**Pods no Ready:**

```promql
sum by (namespace, pod) (kube_pod_status_phase{phase!="Running"})
```

## Paso 6: Acceder a Grafana

### kubectl port-forward a Grafana

```
$ kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &
Forwarding from 127.0.0.1:3000 -> 3000
Forwarding from [::1]:3000 -> 3000
```

### Credenciales

- **URL**: http://localhost:3000
- **Usuario**: admin
- **Contraseña**: admin123

## Paso 7: Dashboards Predefinidos en Grafana

### Dashboards incluidos en kube-prometheus-stack:

1. **Kubernetes / Compute Resources / Cluster**
   - CPU, memoria y ancho de banda de red a nivel de clúster
   - Uso de recursos por namespace

2. **Kubernetes / Compute Resources / Namespace (Pods)**
   - Métricas detalladas por namespace
   - CPU y memoria por pod

3. **Kubernetes / Networking / Pod**
   - Tráfico de red entrante/saliente por pod
   - Bytes recibidos y transmitidos

4. **Node Exporter / Nodes**
   - Métricas del sistema operativo
   - CPU, memoria, disco, red del nodo

5. **CoreDNS**
   - Métricas del servicio DNS
   - Latencia y errores de resolución

## Paso 9: Configurar Alertas

### kubectl apply -f alertrule.yaml

```
$ kubectl apply -f alertrule.yaml
prometheusrule.monitoring.coreos.com/custom-alerts created
```

### kubectl get prometheusrules -n monitoring

```
$ kubectl get prometheusrules -n monitoring
NAME                                                              AGE
custom-alerts                                                     1m
prometheus-kube-prometheus-alertmanager.rules                     10m
prometheus-kube-prometheus-config-reloaders                       10m
prometheus-kube-prometheus-etcd                                   10m
prometheus-kube-prometheus-general.rules                          10m
prometheus-kube-prometheus-k8s.rules                              10m
prometheus-kube-prometheus-kube-apiserver-availability.rules      10m
prometheus-kube-prometheus-kube-apiserver-burnrate.rules          10m
prometheus-kube-prometheus-kube-apiserver-histogram.rules         10m
prometheus-kube-prometheus-kube-apiserver-slos                    10m
prometheus-kube-prometheus-kube-prometheus-general.rules          10m
prometheus-kube-prometheus-kube-prometheus-node-recording.rules   10m
prometheus-kube-prometheus-kube-scheduler.rules                   10m
prometheus-kube-prometheus-kube-state-metrics                     10m
prometheus-kube-prometheus-kubelet.rules                          10m
prometheus-kube-prometheus-kubernetes-apps                        10m
prometheus-kube-prometheus-kubernetes-resources                   10m
prometheus-kube-prometheus-kubernetes-storage                     10m
prometheus-kube-prometheus-kubernetes-system                      10m
prometheus-kube-prometheus-kubernetes-system-apiserver            10m
prometheus-kube-prometheus-kubernetes-system-controller-manager   10m
prometheus-kube-prometheus-kubernetes-system-kube-proxy           10m
prometheus-kube-prometheus-kubernetes-system-kubelet              10m
prometheus-kube-prometheus-kubernetes-system-scheduler            10m
prometheus-kube-prometheus-node-exporter                          10m
prometheus-kube-prometheus-node-exporter.rules                    10m
prometheus-kube-prometheus-node-network                           10m
prometheus-kube-prometheus-node.rules                             10m
prometheus-kube-prometheus-prometheus                             10m
prometheus-kube-prometheus-prometheus-operator                    10m
```

### Ver alertas en Prometheus UI

Navega a http://localhost:9090/alerts para ver todas las alertas configuradas.

```
Alerts (127)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pod-alerts (2)
├── PodNotReady (0 active)
│   expr: kube_pod_status_phase{phase!="Running",phase!="Succeeded"} > 0
│   for: 5m
│   labels: severity: warning
│
└── PodRestartingTooMuch (0 active)
    expr: increase(kube_pod_container_status_restarts_total[1h]) > 5
    for: 10m
    labels: severity: warning

resource-alerts (2)
├── HighMemoryUsage (0 active)
└── HighCPUUsage (0 active)

node-alerts (2)
├── NodeMemoryPressure (0 active)
└── NodeDiskPressure (0 active)

deployment-alerts (2)
├── DeploymentReplicasUnavailable (0 active)
└── DeploymentReplicasMismatch (0 active)
```

## Paso 10: Ver Métricas con kubectl

### kubectl top nodes

```
$ kubectl top nodes
NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
minikube   456m         22%    2048Mi          52%
```

### kubectl top pods -n monitoring

```
$ kubectl top pods -n monitoring
NAME                                                     CPU(cores)   MEMORY(bytes)
alertmanager-prometheus-kube-prometheus-alertmanager-0   2m           32Mi
prometheus-grafana-5d8f4f4f4f-abc12                      5m           128Mi
prometheus-kube-prometheus-operator-7f7f7f7f7f-def34     3m           48Mi
prometheus-kube-state-metrics-8g8g8g8g8g-ghi56           2m           32Mi
prometheus-prometheus-kube-prometheus-prometheus-0       45m          512Mi
prometheus-prometheus-node-exporter-jkl78                1m           16Mi
```

### kubectl top pods -n demo-app

```
$ kubectl top pods -n demo-app
NAME                           CPU(cores)   MEMORY(bytes)
backend-api-7f7f7f7f7f-abc12   1m           8Mi
backend-api-7f7f7f7f7f-def34   1m           8Mi
traffic-generator              2m           4Mi
web-app-8g8g8g8g8g-ghi56       3m           12Mi
web-app-8g8g8g8g8g-jkl78       2m           12Mi
web-app-8g8g8g8g8g-mno90       3m           12Mi
```

## Acceso a Alertmanager

### kubectl port-forward a Alertmanager

```
$ kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093 &
Forwarding from 127.0.0.1:9093 -> 9093
Forwarding from [::1]:9093 -> 9093
```

Navega a http://localhost:9093 para ver la interfaz de Alertmanager.

## Limpieza

### helm uninstall prometheus

```
$ helm uninstall prometheus -n monitoring
release "prometheus" uninstalled
```

### kubectl delete namespace monitoring

```
$ kubectl delete namespace monitoring
namespace "monitoring" deleted
```

### kubectl delete -f sample-app.yaml

```
$ kubectl delete -f sample-app.yaml
namespace "demo-app" deleted
deployment.apps "web-app" deleted
service "web-app" deleted
deployment.apps "backend-api" deleted
service "backend-api" deleted
pod "traffic-generator" deleted
```

## Resumen

Si todas tus salidas son similares a las mostradas en este documento, has completado exitosamente el Lab 17.

Las diferencias menores que puedes esperar:

- **Nombres de pods**: Los sufijos aleatorios serán diferentes
- **Valores de métricas**: Variarán según la carga real en tu sistema
- **IPs de servicios**: Las ClusterIPs serán asignadas dinámicamente
- **Versiones**: Las versiones de los charts pueden ser más recientes

### Componentes del Stack de Monitoreo

| Componente         | Puerto | Descripción                               |
| ------------------ | ------ | ----------------------------------------- |
| Prometheus         | 9090   | Recolección de métricas y queries         |
| Grafana            | 3000   | Visualización y dashboards                |
| Alertmanager       | 9093   | Gestión de alertas y notificaciones       |
| Node Exporter      | 9100   | Métricas del sistema operativo            |
| kube-state-metrics | 8080   | Métricas del estado de objetos Kubernetes |

### Queries PromQL Útiles

| Query                                                                       | Descripción                  |
| --------------------------------------------------------------------------- | ---------------------------- |
| `up`                                                                        | Targets que Prometheus puede |
| `container_cpu_usage_seconds_total`                                         | Uso de CPU por contenedor    |
| `container_memory_working_set_bytes`                                        | Memoria usada por contenedor |
| `kube_pod_info`                                                             | Información de pods          |
| `kube_deployment_status_replicas_available`                                 | Réplicas disponibles         |
| `sum(rate(container_cpu_usage_seconds_total{namespace="X"}[5m])) by (pod)`  | CPU por pod en namespace X   |
| `sum(container_memory_working_set_bytes{namespace="X"}) by (pod)`           | Memoria por pod en namespace |
| `count by (namespace) (kube_pod_info)`                                      | Conteo de pods por namespace |
| `kube_pod_status_phase{phase!="Running"}`                                   | Pods no en estado Running    |
| `increase(kube_pod_container_status_restarts_total{namespace="X"}[1h]) > 0` | Reinicios en última hora     |
