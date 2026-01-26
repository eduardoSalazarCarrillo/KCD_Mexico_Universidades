#!/bin/bash
# =============================================================================
# Lab 01: Docker Basics - Script de Solución Completa
# =============================================================================
# Este script ejecuta todos los comandos del laboratorio de forma secuencial.
# Úsalo como referencia o para verificar que completaste correctamente el lab.
#
# NOTA: Este script asume que Docker ya está instalado.
# Si no lo está, sigue primero las instrucciones de instalación del README.
# =============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo ""
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo ""
}

print_command() {
    echo -e "${YELLOW}$ $1${NC}"
}

wait_for_user() {
    echo ""
    read -p "Presiona Enter para continuar..."
    echo ""
}

# =============================================================================
# Verificar que Docker está instalado
# =============================================================================
print_step "Verificación Inicial"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker no está instalado.${NC}"
    echo "Por favor, sigue las instrucciones de instalación en el README.md"
    exit 1
fi

print_command "docker version"
docker version

echo ""
echo -e "${GREEN}✓ Docker está instalado y funcionando${NC}"

wait_for_user

# =============================================================================
# Paso 3: Ejecutar hello-world
# =============================================================================
print_step "Paso 3: Ejecutar contenedor de prueba"

print_command "docker run hello-world"
docker run hello-world

echo ""
echo -e "${GREEN}✓ Contenedor hello-world ejecutado correctamente${NC}"

wait_for_user

# =============================================================================
# Paso 4: Descargar imagen nginx:alpine
# =============================================================================
print_step "Paso 4: Descargar imagen nginx:alpine"

print_command "docker pull nginx:alpine"
docker pull nginx:alpine

echo ""
print_command "docker images"
docker images

echo ""
echo -e "${GREEN}✓ Imagen nginx:alpine descargada${NC}"

wait_for_user

# =============================================================================
# Paso 5: Ejecutar contenedor nginx
# =============================================================================
print_step "Paso 5: Ejecutar contenedor nginx"

# Limpiar contenedor previo si existe
docker rm -f mi-nginx 2>/dev/null || true

print_command "docker run --name mi-nginx -d -p 8080:80 nginx:alpine"
docker run --name mi-nginx -d -p 8080:80 nginx:alpine

echo ""
echo -e "${GREEN}✓ Contenedor mi-nginx iniciado${NC}"

wait_for_user

# =============================================================================
# Paso 6: Verificar contenedor en ejecución
# =============================================================================
print_step "Paso 6: Verificar contenedor en ejecución"

print_command "docker ps"
docker ps

echo ""
print_command "curl http://localhost:8080"
echo ""
curl -s http://localhost:8080 | head -20
echo "..."

echo ""
echo -e "${GREEN}✓ nginx está respondiendo en http://localhost:8080${NC}"

wait_for_user

# =============================================================================
# Paso 7: Explorar el contenedor
# =============================================================================
print_step "Paso 7: Explorar el contenedor"

print_command "docker logs mi-nginx"
docker logs mi-nginx

echo ""
print_command "docker exec mi-nginx nginx -v"
docker exec mi-nginx nginx -v

echo ""
print_command "docker exec mi-nginx ls /etc/nginx/"
docker exec mi-nginx ls /etc/nginx/

echo ""
print_command "docker exec mi-nginx ls /usr/share/nginx/html/"
docker exec mi-nginx ls /usr/share/nginx/html/

echo ""
echo -e "${GREEN}✓ Contenedor explorado correctamente${NC}"

wait_for_user

# =============================================================================
# Paso 8: Detener el contenedor
# =============================================================================
print_step "Paso 8: Detener el contenedor"

print_command "docker stop mi-nginx"
docker stop mi-nginx

echo ""
print_command "docker ps"
docker ps

echo ""
print_command "docker ps -a"
docker ps -a

echo ""
echo -e "${GREEN}✓ Contenedor detenido${NC}"

wait_for_user

# =============================================================================
# Paso 9: Reiniciar y eliminar
# =============================================================================
print_step "Paso 9: Reiniciar y eliminar el contenedor"

print_command "docker start mi-nginx"
docker start mi-nginx

echo ""
print_command "docker ps"
docker ps

echo ""
echo "Esperando 2 segundos..."
sleep 2

print_command "docker stop mi-nginx"
docker stop mi-nginx

print_command "docker rm mi-nginx"
docker rm mi-nginx

echo ""
print_command "docker ps -a"
docker ps -a

echo ""
echo -e "${GREEN}✓ Contenedor eliminado${NC}"

wait_for_user

# =============================================================================
# Resumen Final
# =============================================================================
print_step "Laboratorio Completado"

echo "Has completado exitosamente el Lab 01: Docker Basics"
echo ""
echo "Comandos aprendidos:"
echo "  - docker version      : Ver versión de Docker"
echo "  - docker pull         : Descargar imágenes"
echo "  - docker images       : Listar imágenes"
echo "  - docker run          : Crear y ejecutar contenedores"
echo "  - docker ps           : Listar contenedores"
echo "  - docker logs         : Ver logs"
echo "  - docker exec         : Ejecutar comandos en contenedores"
echo "  - docker stop         : Detener contenedores"
echo "  - docker start        : Iniciar contenedores detenidos"
echo "  - docker rm           : Eliminar contenedores"
echo ""
echo -e "${GREEN}¡Felicitaciones! Estás listo para el Lab 02: Minikube Setup${NC}"
