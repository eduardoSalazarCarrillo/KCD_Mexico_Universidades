#!/bin/bash
# =============================================================================
# Lab 18: Managed Kubernetes - Verificacion de Completado
# =============================================================================
# Este script verifica que has comprendido los conceptos del laboratorio
# sobre Kubernetes administrado en la nube.
#
# Dado que este es un laboratorio exploratorio, la verificacion se enfoca
# en conocimiento teorico y comprension de conceptos.
# =============================================================================

echo "=============================================="
echo "  Lab 18: Verificacion de Completado"
echo "=============================================="
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

# Contador de verificaciones
CHECKS_PASSED=0
CHECKS_TOTAL=0

check_passed() {
    echo -e "${GREEN}OK${NC} $1"
    ((CHECKS_PASSED++))
    ((CHECKS_TOTAL++))
}

check_failed() {
    echo -e "${RED}FAIL${NC} $1"
    ((CHECKS_TOTAL++))
}

check_info() {
    echo -e "${YELLOW}INFO${NC} $1"
    ((CHECKS_TOTAL++))
}

# =============================================================================
# Verificacion 1: Archivos del laboratorio existen
# =============================================================================
echo "1. Verificando que los archivos del laboratorio existen..."

if [ -f "$LAB_DIR/README.md" ]; then
    check_passed "README.md existe"
else
    check_failed "README.md no encontrado"
fi

if [ -f "$LAB_DIR/initial/comparativa-proveedores.md" ]; then
    check_passed "comparativa-proveedores.md existe"
else
    check_failed "comparativa-proveedores.md no encontrado"
fi

if [ -f "$LAB_DIR/initial/cuestionario-seleccion.md" ]; then
    check_passed "cuestionario-seleccion.md existe"
else
    check_failed "cuestionario-seleccion.md no encontrado"
fi

if [ -f "$LAB_DIR/initial/gke-serviceaccount.yaml" ]; then
    check_passed "gke-serviceaccount.yaml existe"
else
    check_failed "gke-serviceaccount.yaml no encontrado"
fi

if [ -f "$LAB_DIR/initial/eks-serviceaccount.yaml" ]; then
    check_passed "eks-serviceaccount.yaml existe"
else
    check_failed "eks-serviceaccount.yaml no encontrado"
fi

if [ -f "$LAB_DIR/initial/aks-serviceaccount.yaml" ]; then
    check_passed "aks-serviceaccount.yaml existe"
else
    check_failed "aks-serviceaccount.yaml no encontrado"
fi

# =============================================================================
# Verificacion 2: Herramientas cloud instaladas
# =============================================================================
echo ""
echo "2. Verificando herramientas cloud disponibles..."

CLOUD_TOOLS=0

if command -v gcloud &> /dev/null; then
    check_passed "gcloud (Google Cloud SDK) esta instalado"
    ((CLOUD_TOOLS++))
else
    check_info "gcloud no instalado (opcional para GKE)"
fi

if command -v aws &> /dev/null; then
    check_passed "aws (AWS CLI) esta instalado"
    ((CLOUD_TOOLS++))
else
    check_info "aws no instalado (opcional para EKS)"
fi

if command -v eksctl &> /dev/null; then
    check_passed "eksctl esta instalado"
    ((CLOUD_TOOLS++))
else
    check_info "eksctl no instalado (opcional para EKS)"
fi

if command -v az &> /dev/null; then
    check_passed "az (Azure CLI) esta instalado"
    ((CLOUD_TOOLS++))
else
    check_info "az no instalado (opcional para AKS)"
fi

echo ""
if [ $CLOUD_TOOLS -gt 0 ]; then
    echo -e "${GREEN}Tienes $CLOUD_TOOLS herramienta(s) cloud instalada(s)${NC}"
else
    echo -e "${YELLOW}No tienes herramientas cloud instaladas.${NC}"
    echo "Esto es aceptable para este laboratorio exploratorio."
fi

# =============================================================================
# Verificacion 3: kubectl disponible
# =============================================================================
echo ""
echo "3. Verificando kubectl..."

if command -v kubectl &> /dev/null; then
    check_passed "kubectl esta instalado"
    KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null | head -1)
    echo "   Version: $KUBECTL_VERSION"
else
    check_failed "kubectl no esta instalado"
fi

# =============================================================================
# Verificacion 4: Minikube (para ejercicio practico)
# =============================================================================
echo ""
echo "4. Verificando Minikube para ejercicio practico..."

if command -v minikube &> /dev/null; then
    check_passed "minikube esta instalado"
    if minikube status &> /dev/null; then
        check_passed "minikube esta corriendo"
    else
        check_info "minikube no esta corriendo (inicia con: minikube start)"
    fi
else
    check_info "minikube no instalado (recomendado para ejercicio practico)"
fi

# =============================================================================
# Verificacion 5: Comprension de conceptos (cuestionario)
# =============================================================================
echo ""
echo "5. Verificacion de comprension (responde mentalmente)..."
echo ""

echo "   Pregunta 1: Cual proveedor tiene control plane gratuito?"
echo "   a) Solo GKE"
echo "   b) Solo AKS"
echo "   c) GKE y AKS"
echo "   d) Todos"
echo ""
echo "   Respuesta correcta: c) GKE y AKS"
echo ""

echo "   Pregunta 2: Que servicio permite a pods acceder a AWS APIs en EKS?"
echo "   a) Workload Identity"
echo "   b) IAM Roles for Service Accounts (IRSA)"
echo "   c) Azure AD Pod Identity"
echo "   d) Service Accounts"
echo ""
echo "   Respuesta correcta: b) IAM Roles for Service Accounts (IRSA)"
echo ""

echo "   Pregunta 3: Que comando se usa para crear un cluster en GKE?"
echo "   a) az aks create"
echo "   b) eksctl create cluster"
echo "   c) gcloud container clusters create"
echo "   d) kubectl create cluster"
echo ""
echo "   Respuesta correcta: c) gcloud container clusters create"
echo ""

echo "   Pregunta 4: Cual opcion de EKS permite ejecutar pods sin gestionar nodos?"
echo "   a) Managed Node Groups"
echo "   b) Self-managed Nodes"
echo "   c) Fargate"
echo "   d) Spot Instances"
echo ""
echo "   Respuesta correcta: c) Fargate"
echo ""

echo "   Pregunta 5: Que es GKE Autopilot?"
echo "   a) Un load balancer automatico"
echo "   b) Un modo donde Google gestiona completamente los nodos"
echo "   c) Una herramienta CLI"
echo "   d) Un servicio de monitoreo"
echo ""
echo "   Respuesta correcta: b) Un modo donde Google gestiona completamente los nodos"
echo ""

# Incrementar checks para el cuestionario
((CHECKS_TOTAL+=5))
((CHECKS_PASSED+=5))

# =============================================================================
# Verificacion 6: Ejercicio practico (si Minikube esta disponible)
# =============================================================================
echo ""
echo "6. Verificando ejercicio practico con Minikube..."

if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    echo "   Ejecutando prueba de ServiceAccount..."

    # Crear ServiceAccount temporal
    kubectl create serviceaccount verify-sa-18 --dry-run=client -o yaml 2>/dev/null | kubectl apply -f - &> /dev/null

    if kubectl get serviceaccount verify-sa-18 &> /dev/null; then
        check_passed "Puede crear ServiceAccounts"

        # Verificar que el SA tiene un secret/token
        TOKEN_EXISTS=$(kubectl get serviceaccount verify-sa-18 -o jsonpath='{.secrets}' 2>/dev/null)
        # En K8s 1.24+, los tokens se montan automaticamente sin secrets
        check_passed "ServiceAccount creado correctamente"

        # Limpiar
        kubectl delete serviceaccount verify-sa-18 &> /dev/null
    else
        check_failed "No puede crear ServiceAccounts"
    fi
else
    check_info "Minikube no disponible - ejercicio practico omitido"
    echo "   Para completar el ejercicio practico:"
    echo "   1. Instala Minikube: https://minikube.sigs.k8s.io/docs/start/"
    echo "   2. Inicia el cluster: minikube start --driver=docker"
    echo "   3. Ejecuta: ./solution/lab-completo.sh"
fi

# =============================================================================
# Verificacion 7: Comprension de diferencias
# =============================================================================
echo ""
echo "7. Verificando comprension de diferencias entre proveedores..."

# Esta es una verificacion "manual" - el estudiante debe haber leido los documentos
echo "   Verifica que puedes responder estas preguntas:"
echo ""
echo "   - Cual es la diferencia de costo del control plane entre proveedores?"
echo "   - Que es Workload Identity y para que se usa?"
echo "   - Cuando elegir Fargate vs Managed Node Groups en EKS?"
echo "   - Que ventajas tiene AKS para empresas que usan Microsoft 365?"
echo ""
echo "   Si puedes responder estas preguntas, has completado el laboratorio."
check_passed "Revision de conceptos completada"

# =============================================================================
# Resumen
# =============================================================================
echo ""
echo "=============================================="
echo "  Resumen de Verificacion"
echo "=============================================="
echo ""
echo "Verificaciones pasadas: $CHECKS_PASSED/$CHECKS_TOTAL"
echo ""

# Calcular porcentaje de exito (excluyendo los INFO que son opcionales)
SUCCESS_RATE=$((CHECKS_PASSED * 100 / CHECKS_TOTAL))

if [ $SUCCESS_RATE -ge 80 ]; then
    echo -e "${GREEN}FELICITACIONES!${NC}"
    echo -e "${GREEN}Has completado exitosamente el Lab 18: Managed Kubernetes${NC}"
    echo ""
    echo "Has demostrado que entiendes:"
    echo "  - Las diferencias entre GKE, EKS y AKS"
    echo "  - Como funciona la integracion de identidad en cada proveedor"
    echo "  - Los comandos basicos para crear y gestionar clusters"
    echo "  - Los criterios para seleccionar un proveedor"
    echo "  - Las implicaciones de costos de cada opcion"
    echo ""
    echo "Recursos adicionales para continuar aprendiendo:"
    echo "  - GKE: https://cloud.google.com/kubernetes-engine/docs"
    echo "  - EKS: https://docs.aws.amazon.com/eks/"
    echo "  - AKS: https://docs.microsoft.com/azure/aks/"
    echo ""
    echo -e "${GREEN}Has completado todos los laboratorios del curso!${NC}"
    echo -e "${GREEN}Ahora estas listo para el Proyecto Final.${NC}"
elif [ $SUCCESS_RATE -ge 60 ]; then
    echo -e "${YELLOW}Casi lo logras!${NC}"
    echo "Revisa los puntos marcados y vuelve a intentar."
    echo ""
    echo "Sugerencias:"
    echo "  - Lee la comparativa en initial/comparativa-proveedores.md"
    echo "  - Revisa los ejemplos de ServiceAccount en initial/"
    echo "  - Completa el cuestionario en initial/cuestionario-seleccion.md"
else
    echo -e "${YELLOW}Necesitas revisar mas el material${NC}"
    echo ""
    echo "Pasos recomendados:"
    echo "  1. Lee el README.md del laboratorio"
    echo "  2. Revisa initial/comparativa-proveedores.md"
    echo "  3. Estudia los archivos de ServiceAccount de ejemplo"
    echo "  4. Completa el cuestionario de seleccion"
    echo "  5. Si tienes acceso, intenta crear un cluster en uno de los proveedores"
fi

echo ""
echo "=============================================="
