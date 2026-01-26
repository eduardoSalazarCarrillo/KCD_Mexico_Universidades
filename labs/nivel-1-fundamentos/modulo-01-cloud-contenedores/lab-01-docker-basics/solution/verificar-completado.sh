#!/bin/bash
# =============================================================================
# Lab 01: Docker Basics - Verificación de Completado
# =============================================================================
# Este script verifica que has completado correctamente el laboratorio
# verificando que puedes ejecutar los comandos principales de Docker.
# =============================================================================

set -e

echo "=============================================="
echo "  Lab 01: Verificación de Completado"
echo "=============================================="
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Contador de verificaciones
CHECKS_PASSED=0
CHECKS_TOTAL=0

check_passed() {
    echo -e "${GREEN}✓${NC} $1"
    ((CHECKS_PASSED++))
    ((CHECKS_TOTAL++))
}

check_failed() {
    echo -e "${RED}✗${NC} $1"
    ((CHECKS_TOTAL++))
}

# =============================================================================
# Verificación 1: Docker instalado
# =============================================================================
echo "1. Verificando instalación de Docker..."

if docker version &> /dev/null; then
    check_passed "docker version funciona correctamente"
else
    check_failed "docker version falló"
    echo "   Docker no está instalado o el daemon no está corriendo"
    exit 1
fi

# =============================================================================
# Verificación 2: Puede descargar imágenes
# =============================================================================
echo ""
echo "2. Verificando capacidad de descargar imágenes..."

if docker pull alpine:latest &> /dev/null; then
    check_passed "docker pull funciona correctamente"
else
    check_failed "docker pull falló"
fi

# =============================================================================
# Verificación 3: Puede listar imágenes
# =============================================================================
echo ""
echo "3. Verificando listado de imágenes..."

if docker images | grep -q "alpine"; then
    check_passed "docker images muestra la imagen descargada"
else
    check_failed "docker images no muestra la imagen alpine"
fi

# =============================================================================
# Verificación 4: Puede ejecutar contenedores
# =============================================================================
echo ""
echo "4. Verificando ejecución de contenedores..."

# Limpiar contenedor de prueba previo si existe
docker rm -f test-lab01 &> /dev/null || true

if docker run --name test-lab01 -d alpine sleep 30 &> /dev/null; then
    check_passed "docker run funciona correctamente"
else
    check_failed "docker run falló"
fi

# =============================================================================
# Verificación 5: Puede listar contenedores
# =============================================================================
echo ""
echo "5. Verificando listado de contenedores..."

if docker ps | grep -q "test-lab01"; then
    check_passed "docker ps muestra el contenedor en ejecución"
else
    check_failed "docker ps no muestra el contenedor"
fi

# =============================================================================
# Verificación 6: Puede ver logs
# =============================================================================
echo ""
echo "6. Verificando acceso a logs..."

if docker logs test-lab01 &> /dev/null; then
    check_passed "docker logs funciona correctamente"
else
    check_failed "docker logs falló"
fi

# =============================================================================
# Verificación 7: Puede ejecutar comandos en contenedor
# =============================================================================
echo ""
echo "7. Verificando ejecución de comandos en contenedor..."

if docker exec test-lab01 echo "test" &> /dev/null; then
    check_passed "docker exec funciona correctamente"
else
    check_failed "docker exec falló"
fi

# =============================================================================
# Verificación 8: Puede detener contenedores
# =============================================================================
echo ""
echo "8. Verificando detención de contenedores..."

if docker stop test-lab01 &> /dev/null; then
    check_passed "docker stop funciona correctamente"
else
    check_failed "docker stop falló"
fi

# =============================================================================
# Verificación 9: docker ps -a muestra contenedor detenido
# =============================================================================
echo ""
echo "9. Verificando listado de contenedores detenidos..."

if docker ps -a | grep -q "test-lab01"; then
    check_passed "docker ps -a muestra el contenedor detenido"
else
    check_failed "docker ps -a no muestra el contenedor detenido"
fi

# =============================================================================
# Verificación 10: Puede eliminar contenedores
# =============================================================================
echo ""
echo "10. Verificando eliminación de contenedores..."

if docker rm test-lab01 &> /dev/null; then
    check_passed "docker rm funciona correctamente"
else
    check_failed "docker rm falló"
fi

# Verificar que ya no existe
if ! docker ps -a | grep -q "test-lab01"; then
    check_passed "El contenedor fue eliminado correctamente"
else
    check_failed "El contenedor aún existe después de rm"
fi

# =============================================================================
# Limpieza
# =============================================================================
echo ""
echo "Limpiando imagen de prueba..."
docker rmi alpine:latest &> /dev/null || true

# =============================================================================
# Resumen
# =============================================================================
echo ""
echo "=============================================="
echo "  Resumen de Verificación"
echo "=============================================="
echo ""
echo "Verificaciones pasadas: $CHECKS_PASSED/$CHECKS_TOTAL"
echo ""

if [ $CHECKS_PASSED -eq $CHECKS_TOTAL ]; then
    echo -e "${GREEN}¡FELICITACIONES!${NC}"
    echo -e "${GREEN}Has completado exitosamente el Lab 01: Docker Basics${NC}"
    echo ""
    echo "Estás listo para continuar con el Lab 02: Minikube Setup"
else
    FAILED=$((CHECKS_TOTAL - CHECKS_PASSED))
    echo -e "${YELLOW}Algunas verificaciones fallaron ($FAILED de $CHECKS_TOTAL)${NC}"
    echo "Revisa los puntos marcados con ✗ y vuelve a intentar"
fi

echo ""
echo "=============================================="
