# Comparativa de Proveedores de Kubernetes Administrado

Este documento sirve como referencia para comparar los principales proveedores de Kubernetes administrado.

## Tabla Comparativa General

| Caracteristica          | GKE (Google)               | EKS (AWS)                 | AKS (Azure)           |
| ----------------------- | -------------------------- | ------------------------- | --------------------- |
| **Proveedor**           | Google Cloud Platform      | Amazon Web Services       | Microsoft Azure       |
| **Costo Control Plane** | Gratuito (Autopilot: pago) | ~$0.10/hora (~$73/mes)    | Gratuito              |
| **Versiones K8s**       | Ultimas disponibles        | Ultimas disponibles       | Ultimas disponibles   |
| **Auto-upgrade**        | Si (configurable)          | Parcial (requiere config) | Si (configurable)     |
| **Networking**          | VPC-native                 | VPC CNI (aws-vpc-k8s-cni) | Azure CNI o Kubenet   |
| **Integracion IAM**     | Google IAM                 | AWS IAM                   | Azure AD / Azure RBAC |
| **CLI principal**       | gcloud                     | eksctl / aws              | az                    |
| **Console Web**         | Cloud Console              | AWS Console               | Azure Portal          |
| **Tiempo de creacion**  | ~5-10 min                  | ~15-20 min                | ~8-15 min             |
| **GPU Support**         | Si                         | Si                        | Si                    |
| **Windows Containers**  | Si (en preview)            | Si                        | Si                    |

## Servicios de Almacenamiento Integrados

| Servicio           | GKE                 | EKS              | AKS            |
| ------------------ | ------------------- | ---------------- | -------------- |
| **Block Storage**  | Persistent Disk     | EBS              | Azure Disk     |
| **File Storage**   | Filestore           | EFS              | Azure Files    |
| **Object Storage** | Cloud Storage (GCS) | S3               | Blob Storage   |
| **CSI Drivers**    | GCE PD CSI          | EBS CSI, EFS CSI | Azure Disk CSI |

## Servicios de Red Integrados

| Servicio          | GKE                  | EKS             | AKS                 |
| ----------------- | -------------------- | --------------- | ------------------- |
| **Load Balancer** | Cloud Load Balancing | ELB / ALB / NLB | Azure Load Balancer |
| **DNS**           | Cloud DNS            | Route 53        | Azure DNS           |
| **CDN**           | Cloud CDN            | CloudFront      | Azure CDN           |
| **Service Mesh**  | Anthos Service Mesh  | App Mesh        | Open Service Mesh   |

## Opciones de Nodos

### GKE

- **Standard**: Nodos gestionados por el usuario
- **Autopilot**: Nodos completamente gestionados por Google
- **Node Auto-provisioning**: Crea nodos automaticamente segun demanda

### EKS

- **Managed Node Groups**: Nodos EC2 gestionados por AWS
- **Self-managed Nodes**: Nodos EC2 gestionados por el usuario
- **Fargate**: Serverless (sin gestion de nodos)

### AKS

- **System Node Pools**: Para componentes del sistema
- **User Node Pools**: Para cargas de trabajo del usuario
- **Virtual Nodes**: Usando Azure Container Instances (serverless)

## Modelos de Precios Estimados (USD/mes)

> **Nota**: Los precios son aproximados y varian por region. Consulta las calculadoras oficiales.

### Cluster Pequeno (3 nodos, desarrollo)

| Componente            | GKE           | EKS           | AKS           |
| --------------------- | ------------- | ------------- | ------------- |
| Control Plane         | $0            | ~$73          | $0            |
| 3 nodos (2 vCPU, 8GB) | ~$150-200     | ~$150-200     | ~$150-200     |
| **Total aproximado**  | **~$150-200** | **~$220-270** | **~$150-200** |

### Cluster Mediano (6 nodos, produccion)

| Componente             | GKE           | EKS           | AKS           |
| ---------------------- | ------------- | ------------- | ------------- |
| Control Plane          | $0            | ~$73          | $0            |
| 6 nodos (4 vCPU, 16GB) | ~$500-600     | ~$500-600     | ~$500-600     |
| Load Balancer          | ~$20-30       | ~$20-30       | ~$20-30       |
| **Total aproximado**   | **~$520-630** | **~$590-700** | **~$520-630** |

## Calculadoras de Precios Oficiales

- **GKE**: https://cloud.google.com/products/calculator
- **EKS**: https://calculator.aws/
- **AKS**: https://azure.microsoft.com/pricing/calculator/

## Certificaciones y Conformidad

Todos los proveedores principales ofrecen:

- SOC 1, 2, 3
- ISO 27001
- PCI DSS
- HIPAA (con configuracion adicional)
- FedRAMP

## Recursos Adicionales

### Documentacion Oficial

- GKE: https://cloud.google.com/kubernetes-engine/docs
- EKS: https://docs.aws.amazon.com/eks/
- AKS: https://docs.microsoft.com/azure/aks/

### Tutoriales Interactivos

- GKE: https://cloud.google.com/kubernetes-engine/docs/tutorials
- EKS: https://eksworkshop.com/
- AKS: https://docs.microsoft.com/learn/paths/intro-to-kubernetes-on-azure/
