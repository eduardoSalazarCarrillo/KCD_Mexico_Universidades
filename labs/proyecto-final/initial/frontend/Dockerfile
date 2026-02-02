# TODO: Completar el Dockerfile multi-stage para el frontend
#
# Stage 1: Build
# - Usar node:18-alpine como imagen base
# - Establecer /app como directorio de trabajo
# - Copiar package*.json
# - Ejecutar npm ci
# - Copiar el resto del código
# - Ejecutar npm run build
#
# Stage 2: Production
# - Usar nginx:alpine como imagen base
# - Copiar los archivos compilados desde el stage de build
# - Copiar la configuración de nginx
# - Exponer puerto 80

FROM node:18-alpine AS build
# TODO: Agregar instrucciones de build

FROM nginx:alpine
# TODO: Copiar archivos y configuración
EXPOSE 80
