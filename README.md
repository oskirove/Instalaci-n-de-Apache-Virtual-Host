# Instalacion y configuración de un servidor Apache y Virtual Host

### Configuración de Apache con Docker Compose
En primer lugar debemos crear los directorios `./paginas` y `./conf` donde incluiremos los ficheros del sitio que queremos mostrar y la configuración de básica de **Apache**.

Para llevar a cabo la instalación y configuración de este, el primer paso es crear nuestro archivo `docker-compose.yml`. En este archivo, incluiremos la configuración básica que consta de la definición del nombre del contenedor, la especificación de la imagen de **Apache** a utilizar, el mapeo de puertos y la configuración de volúmenes.

<sup>*A continuación, se presenta un ejemplo de cómo podría estructurarse este archivo:*</sup>

```yml
services:
  web:
    container_name: apache_practica
    image: httpd:latest
    ports:
      - "80:80"
    volumes:
      - ./paginas:/usr/local/apache2/htdocs
      - ./conf:/usr/local/apache2/conf:rw
```

Después de finalizar el paso anterior, es crucial incorporar los archivos que queremos mostrar al **directorio `./paginas`**, previamente definido en los volúmenes. En mi caso, estos archivos son: `index.html`, `estilos.css` y `script.js`.

A continuación, procedemos a añadir al **directorio `./conf`** los archivos de configuración **`httpd.conf`** y **`mime.types`** mediante los siguientes comandos:

> `docker run --rm httpd:latest cat /usr/local apache2/conf/mime.types > ./conf/mime.types`

> `docker run --rm httpd:latest cat /usr/local/apache2/conf/httpd.conf > miconf.conf`

>[!TIP]
>Los **comandos** proporcionados anteriormente son **utilizados para extraer archivos de configuración específicos del contenedor de Apache y guardarlos localmente**. Estos comandos deben ejecutarse después de haber creado el contenedor, ya que están destinados a obtener ciertos archivos de configuración del contenedor en ejecución.

