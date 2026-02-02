# Lab 01: Docker Basics - Salidas Esperadas

Este documento muestra las salidas esperadas de cada comando del laboratorio para que puedas verificar que todo funciona correctamente.

## Paso 3: Verificar la Instalación

### docker version

```
$ docker version
Client: Docker Engine - Community
 Version:           24.0.7
 API version:       1.43
 Go version:        go1.20.10
 Git commit:        afdd53b
 Built:             Thu Oct 26 09:07:41 2023
 OS/Arch:           linux/amd64
 Context:           default

Server: Docker Engine - Community
 Engine:
  Version:          24.0.7
  API version:      1.43 (minimum version 1.12)
  Go version:       go1.20.10
  Git commit:       311b9ff
  Built:            Thu Oct 26 09:07:41 2023
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          1.6.24
  GitCommit:        61f9fd88f79f081d64d6fa3bb1a0dc71ec870523
 runc:
  Version:          1.1.9
  GitCommit:        v1.1.9-0-gccaecfc
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0
```

> **Nota**: Las versiones específicas pueden variar según tu instalación.

### docker run hello-world

```
$ docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
c1ec31eb5944: Pull complete
Digest: sha256:d211f485f2dd1dee407a80973c8f129f00d54604d2c90732e8e320e5038a0348
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```

## Paso 4: Descargar la Imagen nginx:alpine

### docker pull nginx:alpine

```
$ docker pull nginx:alpine
alpine: Pulling from library/nginx
8a49fdb3b6a5: Pull complete
8fbc6d90cc2f: Pull complete
01fc38cd0ca7: Pull complete
ded461530571: Pull complete
d1e1c1e7f47f: Pull complete
de2a0ec5d6a6: Pull complete
e6c75a94d4f6: Pull complete
f2c2eb87c4b8: Pull complete
Digest: sha256:a5127daff3d6f4606be3100a252419bfa84fd6ee5cd74d0feaca1a5068f97dcf
Status: Downloaded newer image for nginx:alpine
docker.io/library/nginx:alpine
```

### docker images

```
$ docker images
REPOSITORY    TAG       IMAGE ID       CREATED        SIZE
nginx         alpine    a6eb2a334a9f   2 weeks ago    42.6MB
hello-world   latest    d2c94e258dcb   8 months ago   13.3kB
```

## Paso 5: Ejecutar un Contenedor nginx

### docker run --name mi-nginx -d -p 8080:80 nginx:alpine

```
$ docker run --name mi-nginx -d -p 8080:80 nginx:alpine
a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2g3h4
```

> **Nota**: El ID mostrado será diferente en cada ejecución.

## Paso 6: Verificar el Contenedor en Ejecución

### docker ps

```
$ docker ps
CONTAINER ID   IMAGE          COMMAND                  CREATED          STATUS          PORTS                  NAMES
a1b2c3d4e5f6   nginx:alpine   "/docker-entrypoint.…"   10 seconds ago   Up 9 seconds    0.0.0.0:8080->80/tcp   mi-nginx
```

### curl http://localhost:8080

```
$ curl http://localhost:8080
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

## Paso 7: Explorar el Contenedor

### docker logs mi-nginx

```
$ docker logs mi-nginx
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Sourcing /docker-entrypoint.d/15-local-resolvers.envsh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
```

### docker exec -it mi-nginx sh (dentro del contenedor)

```
/ # nginx -v
nginx version: nginx/1.25.3

/ # ls /etc/nginx/
conf.d          fastcgi_params  mime.types      modules         nginx.conf      scgi_params     uwsgi_params

/ # ls /usr/share/nginx/html/
50x.html    index.html

/ # exit
```

### docker inspect mi-nginx (extracto)

```json
$ docker inspect mi-nginx
[
    {
        "Id": "a1b2c3d4e5f6...",
        "Created": "2024-01-15T10:30:00.000000000Z",
        "Path": "/docker-entrypoint.sh",
        "Args": [
            "nginx",
            "-g",
            "daemon off;"
        ],
        "State": {
            "Status": "running",
            "Running": true,
            ...
        },
        "Image": "sha256:a6eb2a334a9f...",
        "Name": "/mi-nginx",
        "NetworkSettings": {
            "Ports": {
                "80/tcp": [
                    {
                        "HostIp": "0.0.0.0",
                        "HostPort": "8080"
                    }
                ]
            },
            ...
        },
        ...
    }
]
```

## Paso 8: Detener el Contenedor

### docker stop mi-nginx

```
$ docker stop mi-nginx
mi-nginx
```

### docker ps (después de detener)

```
$ docker ps
CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES
```

### docker ps -a (mostrando contenedor detenido)

```
$ docker ps -a
CONTAINER ID   IMAGE          COMMAND                  CREATED         STATUS                      PORTS   NAMES
a1b2c3d4e5f6   nginx:alpine   "/docker-entrypoint.…"   5 minutes ago   Exited (0) 30 seconds ago           mi-nginx
d2e3f4g5h6i7   hello-world    "/hello"                 10 minutes ago  Exited (0) 10 minutes ago           gracious_newton
```

## Paso 9: Reiniciar y Eliminar

### docker start mi-nginx

```
$ docker start mi-nginx
mi-nginx
```

### docker ps (después de reiniciar)

```
$ docker ps
CONTAINER ID   IMAGE          COMMAND                  CREATED         STATUS          PORTS                  NAMES
a1b2c3d4e5f6   nginx:alpine   "/docker-entrypoint.…"   6 minutes ago   Up 5 seconds    0.0.0.0:8080->80/tcp   mi-nginx
```

### docker stop mi-nginx && docker rm mi-nginx

```
$ docker stop mi-nginx
mi-nginx
$ docker rm mi-nginx
mi-nginx
```

### docker ps -a (después de eliminar)

```
$ docker ps -a
CONTAINER ID   IMAGE         COMMAND    CREATED          STATUS                      PORTS   NAMES
d2e3f4g5h6i7   hello-world   "/hello"   15 minutes ago   Exited (0) 15 minutes ago           gracious_newton
```

> **Nota**: El contenedor `mi-nginx` ya no aparece en la lista.

## Paso 10: Limpieza (Opcional)

### docker rmi nginx:alpine

```
$ docker rmi nginx:alpine
Untagged: nginx:alpine
Untagged: nginx@sha256:a5127daff3d6f4606be3100a252419bfa84fd6ee5cd74d0feaca1a5068f97dcf
Deleted: sha256:a6eb2a334a9f...
Deleted: sha256:...
```

### docker rmi hello-world

```
$ docker rmi hello-world
Untagged: hello-world:latest
Untagged: hello-world@sha256:d211f485f2dd1dee407a80973c8f129f00d54604d2c90732e8e320e5038a0348
Deleted: sha256:d2c94e258dcb...
Deleted: sha256:...
```

### docker images (después de limpieza)

```
$ docker images
REPOSITORY   TAG   IMAGE ID   CREATED   SIZE
```

## Resumen

Si todas tus salidas son similares a las mostradas en este documento, has completado exitosamente el Lab 01.

Las diferencias menores que puedes esperar:

- **IDs de contenedor/imagen**: Serán diferentes en cada sistema
- **Versiones**: Pueden variar según la versión de Docker instalada
- **Timestamps**: Las fechas y tiempos serán diferentes
- **Nombres aleatorios**: Contenedores sin nombre asignado tendrán nombres generados automáticamente
