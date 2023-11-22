# Instalacion y configuración de un servidor Apache y Virtual Host

### Configuración de Apache con Docker Compose
En primer lugar debemos crear los directorios `./paginas` y `./conf` donde incluiremos los ficheros del sitio que queremos mostrar y la configuración de básica de **Apache**.

Para llevar a cabo la instalación y configuración de este, el primer paso es crear nuestro fichero `docker-compose.yml`. En este archivo, incluiremos la configuración básica que consta de la definición del nombre del contenedor, la especificación de la imagen de **Apache** a utilizar, el mapeo de puertos y la configuración de volúmenes.

<sup>A continuación, se presenta un **ejemplo** de cómo podría estructurarse este fichero:</sup>

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

> **`docker run --rm httpd:latest cat /usr/local apache2/conf/mime.types > ./conf/mime.types`**

> **`docker run --rm httpd:latest cat /usr/local/apache2/conf/httpd.conf > miconf.conf`**

>[!TIP]
>Los **comandos** proporcionados anteriormente son **utilizados para extraer archivos de configuración específicos del contenedor de Apache y guardarlos localmente**. Estos comandos deben ejecutarse después de haber creado el contenedor, ya que están destinados a obtener ciertos archivos de configuración del contenedor en ejecución.

### Configuración de DNS BIND9 en Docker Compose

Una vez que hayamos configurado los parámetros básicos del **Apache**, el siguiente paso es crear dos directorios ***(en otra carpeta diferente a la del Apache)*** llamados `./conf` y `./zonas` e incorporar la configuración básica del **DNS** en nuestro fichero **`docker-compose.yml`**. Esta configuración permitirá que, en una etapa posterior, el **DNS** pueda resolver los dos dominios: ***www.fabulasoscuras.com*** y ***www.fabulasmaravillosas.com***. De esta manera, estaremos preparando nuestro sistema para manejar eficientemente estas dos direcciones web.

<sup>A continuación, se presenta un **ejemplo** de cómo podría estructurarse este fichero:</sup>

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
DNS:
    container_name: DNS_bind9
    image: ubuntu/bind9
    platform: linux/arm64
    ports:
      - "53:53"
    volumes:
      - ./conf:/etc/bind
      - ./zonas:/var/lib/bind
```
### Creación de la Red y Asignación de Direcciones IP

Una vez que hayamos completado el paso anterior, procederemos a crear la siguiente red en docker. Esto nos permitirá continuar con la configuración de nuestros servidores.

<sup>A continuación, se muestra un **ejemplo** de como crear la red que se va a utilizar:</sup>


> **`docker network create --driver bridge --subnet 192.168.1.0/24 --ip-range 192.168.1.2/24 --gateway 192.168.1.1 practica_fabulas`**

Después de crear la red **practica_fabulas**, ajustaremos el archivo **`docker-compose.yml`** para asignar una **IP** estática a cada contenedor de nuestro fichero.

<sup>A continuación, se muestra un **ejemplo** de como se vería el fichero con la red y las IP confiuradas:</sup>

```yml
services:
  web:
    container_name: apache_practica
    image: httpd:latest
    ports:
      - "80:80"
    #Definimos la red y la IP que utilizará el Apache
    networks:
      practica_fabulas:
        ipv4_address: 192.168.1.3
    #Especificamos el DNS que utilizará el contenedor para resolver nombres de dominio.
    dns:
      - 192.168.1.2
    volumes:
      - ./paginas:/usr/local/apache2/htdocs
      - ./conf:/usr/local/apache2/conf:rw
DNS:
    container_name: DNS_bind9
    image: ubuntu/bind9
    platform: linux/arm64
    ports:
      - "53:53"
    #Definimos la red y la IP que utilizará el DNS
    networks:
      practica_fabulas:
        ipv4_address: 192.168.1.2
    volumes:
      - ./conf:/etc/bind
      - ./zonas:/var/lib/bind

#Definimos la red que vamos a utilizar
networks:
  practica_fabulas:
    external: true
```

>[!NOTE]
>Este **`docker-compose.yml`** configura dos servicios: **web** con Apache y **DNS** con Bind9. Ambos están conectados a través de la red externa **practica_fabulas**. El servicio web usa la IP `192.168.1.3` y resuelve nombres de dominio mediante el servidor **DNS** en `192.168.1.2`. Se montan volúmenes locales para gestionar las páginas web y la configuración de Apache. El servicio **DNS**, en la IP `192.168.1.2`, permite consultas **DNS** y gestiona la configuración y zonas **DNS** mediante volúmenes locales.