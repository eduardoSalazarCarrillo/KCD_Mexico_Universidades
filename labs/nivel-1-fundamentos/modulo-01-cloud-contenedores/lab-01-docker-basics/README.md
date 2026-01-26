# Lab 01: Docker Basics

## Objetivo

Instalar Docker y comprender el ciclo de vida básico de un contenedor.

## Prerrequisitos

- Ninguno
- Sistema operativo: Linux (Ubuntu/Debian recomendado), macOS o Windows con WSL2
- Acceso a terminal con privilegios de administrador

## Duración

45 minutos

## Conceptos Clave

Antes de comenzar, es importante entender estos conceptos:

| Concepto          | Descripción                                                                                                                |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------- |
| **Imagen**        | Plantilla de solo lectura con instrucciones para crear un contenedor. Es como una "receta" o "snapshot" de una aplicación. |
| **Contenedor**    | Instancia ejecutable de una imagen. Es un proceso aislado que ejecuta la aplicación.                                       |
| **Docker Hub**    | Registro público de imágenes donde puedes encontrar imágenes oficiales y de la comunidad.                                  |
| **Ciclo de vida** | created → running → paused → stopped → deleted                                                                             |

### Imágenes vs Contenedores

```
┌─────────────────────────────────────────────────────────────┐
│                        IMAGEN                               │
│  (Plantilla inmutable - como una clase en programación)     │
│                                                             │
│   nginx:alpine                                              │
│   ┌─────────────────────────────────────────────────────┐   │
│   │  - Sistema operativo Alpine Linux                   │   │
│   │  - Servidor web nginx instalado                     │   │
│   │  - Archivos de configuración                        │   │
│   └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ docker run
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      CONTENEDOR(ES)                         │
│  (Instancias ejecutables - como objetos en programación)    │
│                                                             │
│   ┌───────────────┐  ┌───────────────┐  ┌───────────────┐   │
│   │ contenedor-1  │  │ contenedor-2  │  │ contenedor-3  │   │
│   │   (running)   │  │   (stopped)   │  │   (running)   │   │
│   └───────────────┘  └───────────────┘  └───────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Instrucciones

### Paso 1: Verificar el Estado Inicial

Antes de instalar Docker, verifica si ya está instalado:

```bash
docker --version
```

Si recibes un error como `command not found`, significa que Docker no está instalado y debes continuar con el Paso 2.

Si Docker ya está instalado, puedes saltar al Paso 3.

### Paso 2: Instalar Docker

#### Opción A: Ubuntu/Debian

```bash
# Actualizar el índice de paquetes
sudo apt-get update

# Instalar dependencias necesarias
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Agregar la clave GPG oficial de Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Configurar el repositorio
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Agregar tu usuario al grupo docker (para ejecutar sin sudo)
sudo usermod -aG docker $USER
```

> **Importante**: Después de agregar tu usuario al grupo docker, necesitas cerrar sesión y volver a iniciarla, o ejecutar `newgrp docker` para que los cambios surtan efecto.

#### Opción B: Fedora/RHEL/CentOS

```bash
# Instalar el repositorio de Docker
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

# Instalar Docker Engine
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Iniciar y habilitar el servicio
sudo systemctl start docker
sudo systemctl enable docker

# Agregar tu usuario al grupo docker
sudo usermod -aG docker $USER
```

#### Opción C: macOS

1. Descarga Docker Desktop desde [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)
2. Abre el archivo `.dmg` descargado
3. Arrastra Docker al directorio de Aplicaciones
4. Abre Docker desde Aplicaciones y espera a que inicie

#### Opción D: Windows (con WSL2)

1. Asegúrate de tener WSL2 habilitado (`wsl --install` en PowerShell como administrador)
2. Descarga Docker Desktop desde [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)
3. Ejecuta el instalador y sigue las instrucciones
4. Reinicia el sistema si es necesario
5. Abre Docker Desktop y espera a que inicie

### Paso 3: Verificar la Instalación

Verifica que Docker está correctamente instalado:

```bash
docker version
```

**Salida esperada** (las versiones pueden variar):

```
Client: Docker Engine - Community
 Version:           24.0.7
 API version:       1.43
 Go version:        go1.20.10
 ...

Server: Docker Engine - Community
 Engine:
  Version:          24.0.7
  API version:      1.43 (minimum version 1.12)
  ...
```

Ejecuta el contenedor de prueba oficial:

```bash
docker run hello-world
```

**Salida esperada**:

```
Hello from Docker!
This message shows that your installation appears to be working correctly.
...
```

### Paso 4: Descargar la Imagen nginx:alpine

Descarga la imagen de nginx usando la variante Alpine (más ligera, ~40MB vs ~180MB):

```bash
docker pull nginx:alpine
```

**Salida esperada**:

```
alpine: Pulling from library/nginx
...
Status: Downloaded newer image for nginx:alpine
docker.io/library/nginx:alpine
```

Verifica que la imagen se descargó:

```bash
docker images
```

**Salida esperada**:

```
REPOSITORY    TAG       IMAGE ID       CREATED        SIZE
nginx         alpine    a6eb2a334a9f   2 weeks ago    42.6MB
hello-world   latest    d2c94e258dcb   8 months ago   13.3kB
```

### Paso 5: Ejecutar un Contenedor nginx

Ejecuta un contenedor basado en la imagen nginx:alpine:

```bash
docker run --name mi-nginx -d -p 8080:80 nginx:alpine
```

**Explicación de los parámetros**:

| Parámetro         | Descripción                                               |
| ----------------- | --------------------------------------------------------- |
| `--name mi-nginx` | Asigna el nombre "mi-nginx" al contenedor                 |
| `-d`              | Ejecuta en segundo plano (detached mode)                  |
| `-p 8080:80`      | Mapea el puerto 8080 del host al puerto 80 del contenedor |
| `nginx:alpine`    | Imagen a utilizar                                         |

**Salida esperada** (un ID de contenedor):

```
a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6
```

### Paso 6: Verificar el Contenedor en Ejecución

Lista los contenedores en ejecución:

```bash
docker ps
```

**Salida esperada**:

```
CONTAINER ID   IMAGE          COMMAND                  CREATED          STATUS          PORTS                  NAMES
a1b2c3d4e5f6   nginx:alpine   "/docker-entrypoint.…"   10 seconds ago   Up 9 seconds    0.0.0.0:8080->80/tcp   mi-nginx
```

Prueba que nginx está funcionando:

```bash
curl http://localhost:8080
```

**Salida esperada** (página HTML de bienvenida de nginx):

```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
</html>
```

También puedes abrir `http://localhost:8080` en tu navegador.

### Paso 7: Explorar el Contenedor

Ver los logs del contenedor:

```bash
docker logs mi-nginx
```

Inspeccionar detalles del contenedor:

```bash
docker inspect mi-nginx
```

Ejecutar un shell dentro del contenedor:

```bash
docker exec -it mi-nginx sh
```

**Dentro del contenedor**, explora:

```bash
# Ver la versión de nginx
nginx -v

# Ver los archivos de configuración
ls /etc/nginx/

# Ver el contenido web
cat /usr/share/nginx/html/index.html

# Salir del contenedor
exit
```

### Paso 8: Detener el Contenedor

Detén el contenedor:

```bash
docker stop mi-nginx
```

Verifica que ya no está en ejecución:

```bash
docker ps
```

**Salida esperada** (lista vacía o sin mi-nginx):

```
CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES
```

Ver todos los contenedores (incluyendo detenidos):

```bash
docker ps -a
```

**Salida esperada**:

```
CONTAINER ID   IMAGE          COMMAND                  CREATED         STATUS                      PORTS   NAMES
a1b2c3d4e5f6   nginx:alpine   "/docker-entrypoint.…"   5 minutes ago   Exited (0) 30 seconds ago           mi-nginx
```

### Paso 9: Reiniciar y Eliminar el Contenedor

Reinicia el contenedor detenido:

```bash
docker start mi-nginx
```

Verifica que está corriendo nuevamente:

```bash
docker ps
```

Ahora detén y elimina el contenedor:

```bash
docker stop mi-nginx
docker rm mi-nginx
```

Verifica que fue eliminado:

```bash
docker ps -a
```

El contenedor `mi-nginx` ya no debería aparecer en la lista.

### Paso 10: Limpieza (Opcional)

Si deseas eliminar las imágenes descargadas:

```bash
# Eliminar la imagen de nginx
docker rmi nginx:alpine

# Eliminar la imagen hello-world
docker rmi hello-world
```

Verificar que las imágenes fueron eliminadas:

```bash
docker images
```

## Ejercicios Adicionales

### Ejercicio 1: Ejecutar en modo interactivo

Ejecuta un contenedor de Alpine Linux en modo interactivo y explora el sistema de archivos:

```bash
docker run -it alpine sh
```

Dentro del contenedor, prueba algunos comandos:

```bash
cat /etc/os-release
ls /
whoami
exit
```

### Ejercicio 2: Personalizar el contenido de nginx

Crea una página HTML personalizada y móntala en el contenedor:

```bash
# Crear el archivo HTML
echo "<html><body><h1>Hola desde Docker!</h1><p>Mi primer contenedor personalizado</p></body></html>" > mi-pagina.html

# Ejecutar nginx con el archivo montado
docker run --name nginx-custom -d -p 8081:80 \
  -v $(pwd)/mi-pagina.html:/usr/share/nginx/html/index.html \
  nginx:alpine

# Verificar
curl http://localhost:8081

# Limpieza
docker stop nginx-custom && docker rm nginx-custom
rm mi-pagina.html
```

### Ejercicio 3: Múltiples contenedores

Ejecuta dos servidores web diferentes simultáneamente:

```bash
# Servidor nginx en puerto 8080
docker run -d --name web1 -p 8080:80 nginx:alpine

# Servidor httpd (Apache) en puerto 8081
docker run -d --name web2 -p 8081:80 httpd:alpine

# Verificar ambos
curl http://localhost:8080
curl http://localhost:8081

# Ver ambos contenedores
docker ps

# Limpieza
docker stop web1 web2
docker rm web1 web2
```

### Ejercicio 4: Monitorear recursos

Mientras un contenedor está corriendo, observa el uso de recursos:

```bash
docker run -d --name mi-nginx -p 8080:80 nginx:alpine
docker stats mi-nginx
# Presiona Ctrl+C para salir
```

## Verificación

Antes de continuar al siguiente laboratorio, asegúrate de poder marcar todos estos puntos:

- [ ] Docker está instalado y `docker version` muestra información del cliente y servidor
- [ ] Puedo descargar imágenes con `docker pull`
- [ ] Puedo listar imágenes con `docker images`
- [ ] Puedo ejecutar contenedores con `docker run`
- [ ] Puedo listar contenedores con `docker ps` y `docker ps -a`
- [ ] Puedo ver logs con `docker logs`
- [ ] Puedo ejecutar comandos dentro de un contenedor con `docker exec`
- [ ] Puedo detener contenedores con `docker stop`
- [ ] Puedo iniciar contenedores detenidos con `docker start`
- [ ] Puedo eliminar contenedores con `docker rm`
- [ ] Entiendo la diferencia entre una imagen y un contenedor
- [ ] Puedo acceder a una aplicación web corriendo en un contenedor

## Resumen de Comandos

| Comando                              | Descripción                          |
| ------------------------------------ | ------------------------------------ |
| `docker version`                     | Muestra la versión de Docker         |
| `docker pull <imagen>`               | Descarga una imagen desde Docker Hub |
| `docker images`                      | Lista las imágenes locales           |
| `docker run <imagen>`                | Crea y ejecuta un contenedor         |
| `docker run -d`                      | Ejecuta en segundo plano (detached)  |
| `docker run -p host:container`       | Mapea puertos                        |
| `docker run --name <nombre>`         | Asigna nombre al contenedor          |
| `docker run -it`                     | Modo interactivo con terminal        |
| `docker ps`                          | Lista contenedores en ejecución      |
| `docker ps -a`                       | Lista todos los contenedores         |
| `docker logs <contenedor>`           | Muestra los logs                     |
| `docker exec -it <contenedor> <cmd>` | Ejecuta un comando en el contenedor  |
| `docker stop <contenedor>`           | Detiene un contenedor                |
| `docker start <contenedor>`          | Inicia un contenedor detenido        |
| `docker rm <contenedor>`             | Elimina un contenedor                |
| `docker rmi <imagen>`                | Elimina una imagen                   |
| `docker stats <contenedor>`          | Muestra uso de recursos              |

## Solución

Consulta el directorio `solution/` para ver los scripts con todos los comandos y las salidas esperadas.

## Próximo Laboratorio

[Lab 02: Minikube Setup](../../modulo-02-intro-kubernetes/lab-02-minikube-setup/README.md) - Configuración de un clúster local de Kubernetes
