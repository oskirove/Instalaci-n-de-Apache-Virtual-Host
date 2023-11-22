# Instalacion y configuración de un servidor Apache y Virtual Host

# Índice

1. [Configuración de Apache con Docker Compose](#Configuración-de-Apache-con-Docker-Compose)
2. [Configuración de DNS BIND9 en Docker Compose](#Configuración-de-DNS-BIND9-en-Docker-Compose)
3. [Creación de la Red y Asignación de Direcciones IP](#Creación-de-la-Red-y-Asignación-de-Direcciones-IP)
4. [Configuramos el Contenido de ./conf del DNS](#Configuramos-el-Contenido-de-./conf-del-DNS)
5. [Configuramos el Contenido de ./zonas del DNS](#Configuramos-el-Contenido-de-./zonas-del-DNS)
6. [Implementación del Cliente en Docker Compose](#Implementación-del-Cliente-en-Docker-Compose)
7. [Prueba Resolución de Dominios](#Prueba-Resolución-de-Dominios)

## Configuración de Apache con Docker Compose
En primer lugar debemos crear los directorios `./paginas` y `./conf` donde incluiremos los ficheros del sitio que queremos mostrar y la configuración básica de **Apache**.

Para llevar a cabo la instalación y configuración de este, el primer paso es crear nuestro fichero `docker-compose.yml`. En este archivo, incluiremos la configuración básica que consta de la definición del nombre del contenedor, la especificación de la imagen de **Apache** a utilizar, el mapeo de puertos y la configuración de volúmenes.

<sup>**A continuación, se presenta un ejemplo de cómo podría estructurarse este fichero:**</sup>

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

Después de finalizar el paso anterior, es crucial incorporar los archivos que queremos mostrar al **directorio `./paginas`**, previamente definido en los volúmenes. En mi caso, estos archivos son: `index.html`, `estilos1.css` y `script.js`.

A continuación, procedemos a añadir al **directorio `./conf`** los archivos de configuración **`httpd.conf`** y **`mime.types`** mediante los siguientes comandos:

> **docker run --rm httpd:latest cat /usr/local apache2/conf/mime.types > ./conf/mime.types**

> **docker run --rm httpd:latest cat /usr/local/apache2/conf/httpd.conf > ./conf/httpd.conf**

>[!TIP]
>Los **comandos** proporcionados anteriormente son **utilizados para extraer archivos de configuración específicos del contenedor de Apache y guardarlos localmente**. Estos comandos deben ejecutarse después de haber creado el contenedor, ya que están destinados a obtener ciertos archivos de configuración del contenedor en ejecución.

## Configuración de DNS Bind9 en Docker Compose

Una vez que hayamos configurado los parámetros básicos del **Apache**, el siguiente paso es crear dos directorios ***(en otra carpeta diferente a la del Apache)*** llamados `./conf` y `./zonas` e incorporar la configuración básica del **DNS** en nuestro fichero **`docker-compose.yml`**. Esta configuración permitirá que, en una etapa posterior, el **DNS** pueda resolver los dos dominios: ***www.fabulasoscuras.com*** y ***www.fabulasmaravillosas.com***. De esta manera, estaremos preparando nuestro sistema para manejar eficientemente estas dos direcciones web.

<sup>**A continuación, se presenta un ejemplo de cómo podría estructurarse este fichero:**</sup>

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
## Creación de la Red y Asignación de Direcciones IP

Una vez que hayamos completado el paso anterior, procederemos a crear la siguiente red en docker. Esto nos permitirá continuar con la configuración de nuestros servidores.

<sup>**A continuación, se muestra un ejemplo de como crear la red que se va a utilizar:**</sup>


> **docker network create --driver bridge --subnet 192.168.1.0/24 --ip-range 192.168.1.2/24 --gateway 192.168.1.1 practica_fabulas**

Después de crear la red **practica_fabulas**, ajustaremos el archivo **`docker-compose.yml`** para asignar una **IP** estática a cada contenedor de nuestro fichero.

<sup>**A continuación, se muestra un ejemplo de como se vería el fichero con la red y las IP configuradas:**</sup>

```yml
services:
  web:
    container_name: apache_practica
    image: httpd:latest
    ports:
      - "80:80"
    # Definimos la red y la IP que utilizará el Apache
    networks:
      practica_fabulas:
        ipv4_address: 192.168.1.3
    # Especificamos el DNS que utilizará el contenedor para resolver nombres de dominio.
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
    # Definimos la red y la IP que utilizará el DNS
    networks:
      practica_fabulas:
        ipv4_address: 192.168.1.2
    volumes:
      - ./conf:/etc/bind
      - ./zonas:/var/lib/bind

# Definimos la red que vamos a utilizar
networks:
  practica_fabulas:
    external: true
```

>[!NOTE]
>Este **`docker-compose.yml`** configura dos servicios: **web** con Apache y **DNS** con Bind9. Ambos están conectados a través de la red externa **practica_fabulas**. El servicio web usa la IP `192.168.1.3` y resuelve nombres de dominio mediante el servidor **DNS** en `192.168.1.2`. Se montan volúmenes locales para gestionar las páginas web y la configuración de Apache. El servicio **DNS**, en la IP `192.168.1.2`, permite consultas **DNS** y gestiona la configuración y zonas **DNS** mediante volúmenes locales.

## Configuramos el Contenido de `./conf` del DNS

En primer lugar vamos a comenzar creando cuatro ficheros en el directorio **`./conf`**, llamados: `named.conf`, `named.conf.default-zones`, `named.conf.local` y `named.conf.options`.
##
- En el fichero **`named.conf`**, incluiremos lo siguiente:

```bash
include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.default-zones";
```

>[!NOTE]
>El archivo **`named.conf`** contiene la **configuración principal** del servidor DNS BIND, incluyendo *opciones generales, registros de actividad, y definiciones de zonas* con sus archivos asociados.
##
- En el fichero **`named.conf.default-zones`** definiremos los siguientes parámetros:

```conf
// prime the server with knowledge of the root servers
zone "." {
	type hint;
	file "/usr/share/dns/root.hints";
};

// be authoritative for the localhost forward and reverse zones, and for
// broadcast zones as per RFC 1912

zone "localhost" {
	type master;
	file "/etc/bind/db.local";
};

zone "127.in-addr.arpa" {
	type master;
	file "/etc/bind/db.127";
};

zone "0.in-addr.arpa" {
	type master;
	file "/etc/bind/db.0";
};

zone "255.in-addr.arpa" {
	type master;
	file "/etc/bind/db.255";
};
```
>[!NOTE]
>El archivo **`named.conf.default-zones`** contiene **configuraciones predeterminadas** para zonas especiales en un servidor DNS BIND, como la **zona raíz** y las **zonas inversas** para direcciones IP privadas. Incluye definiciones para asegurar la correcta resolución de nombres y direcciones IP, proporcionando un punto de partida para la configuración del **servidor DNS**.
##
- En el fichero **`named.conf.local`** definiremos lo siguiente:

```conf
zone "fabulasoscuras.com" {
	type master;
	file "/var/lib/bind/db.fabulasoscuras.com";
	allow-query {
		any;
		};
	};

zone "fabulasmaravillosas.com" {
	type master;
	file "/var/lib/bind/db.fabulasmaravillosas.com";
	allow-query {
		any;
		};
	};
```
>[!NOTE]
>El archivo `named.conf.local` contiene **configuraciones específicas de zonas locales** para el servidor DNS BIND. En el ejemplo proporcionado, se definen dos zonas, ***fabulasoscuras.com*** y ***fabulasmaravillosas.com***, como maestras (`type master`). Cada zona tiene su **propio archivo de zona asociado** que especifica la ubicación y configuración de los registros de esa zona.
Además, se establece la permisividad para realizar consultas (`allow-query`) desde cualquier origen (`any`) en ambas zonas. Esto significa que el servidor DNS permitirá consultas de cualquier fuente para estas zonas específicas. **Estas configuraciones son típicas para configurar autoridad local sobre dominios específicos en un entorno DNS.**
##
- En el fichero **`named.conf.options`** definiremos los siguientes parámetros:

```conf
options {
	directory "/var/cache/bind";

	forwarders {
	 	8.8.8.8;
		1.1.1.1;
	 };
	 forward only;

	listen-on { any; };
	listen-on-v6 { any; };

	allow-query {
		any;
	};
};
```
>[!NOTE]
>El archivo `named.conf.options` contiene configuraciones **globales** para el servidor DNS BIND. Este incluye la **habilitación de recursión, la definición de servidores forwarders, y la configuración de opciones de seguridad como DNSSEC.** Las opciones específicas pueden variar según los requisitos y la implementación del servidor DNS.

## Configuramos el Contenido de `./zonas` del DNS

Dentro del directorio **`./zonas`** vamos a crear dos ficheros llamados `db.fabulasmaravillosas.com` y `db.fabulasoscuras.com`.

- En el fichero **`db.fabulasmaravillosas.com`** incluiremos la siguiente información:

```sql
$TTL 38400	; 10 hours 40 minutes
@		IN SOA	ns.fabulasmaravillosas.com. info.fabulasmaravillosas.com. (
				10000003   ; serial
				10800      ; refresh (3 hours)
				3600       ; retry (1 hour)
				604800     ; expire (1 week)
				38400      ; minimum (10 hours 40 minutes)
				)
@		IN NS	ns.fabulasmaravillosas.com.
ns		IN A		192.168.1.5
www		IN A		192.168.1.2
alias	IN CNAME	www
texto	IN TXT		"Hola mundo"
```
- Por otra parte en el fichero **`db.fabulasoscuras.com`** incluiremos lo siguiente:

```sql
$TTL 38400	; 10 hours 40 minutes
@		IN SOA	ns.fabulasoscuras.com. info.fabulasoscuras.com. (
				10000003   ; serial
				10800      ; refresh (3 hours)
				3600       ; retry (1 hour)
				604800     ; expire (1 week)
				38400      ; minimum (10 hours 40 minutes)
				)
@		IN NS	ns.fabulasoscuras.com.
ns		IN A		192.168.1.5
www		IN A		192.168.1.2
alias	IN CNAME	www
texto	IN TXT		"Hola mundo"
```
>[!NOTE]
>Las bases de datos de las zonas **`db.fabulasoscuras.com`** y **`db.fabulasmaravillosas.com`** definen la resolución de nombres para los dominios ***fabulasoscuras.com*** y ***fabulasmaravillosas.com***. Incluye registros **SOA** para la autoridad de la zona, **NS** para el servidor de nombres, **A** para asociar nombres de host con direcciones IP, **CNAME** para alias, y **TXT** para texto asociado. Estos registros son fundamentales para la resolución de nombres y otros servicios en el servidor DNS para el dominio mencionado.

## Implementación del Cliente en Docker Compose

El servicio **cliente** en el archivo **`docker-compose.yml`** se implementa mediante un contenedor basado en la imagen **Ubuntu**, específicamente para la arquitectura **linux/arm64**. Se asigna un nombre al contenedor **(cliente)** y se configura para tener un terminal interactivo **(`tty: true`)** y mantener abierto el canal de entrada estándar **(`stdin_open: true`)**, lo que facilita la interacción con el contenedor.

Además, se especifica la configuración del servidor **DNS** que utilizará el contenedor para **resolver nombres de dominio**. En este caso, se ha configurado con la dirección IP `192.168.1.2`. El contenedor se integra en la red denominada **practica_fabulas** y se le asigna la dirección IP `192.168.1.4` en esa red.

<sup>**A continuación, se muestra un ejemplo de como se vería el fichero con el cliente implementado:**</sup>

```yml
services:
  web:
    container_name: apache_practica
    image: httpd:latest
    ports:
      - "80:80"
    # Definimos la red y la IP que utilizará el Apache.
    networks:
      practica_fabulas:
        ipv4_address: 192.168.1.3
    # Especificamos el DNS que utilizará el contenedor para resolver nombres de dominio.
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
    # Definimos la red y la IP que utilizará el DNS.
    networks:
      practica_fabulas:
        ipv4_address: 192.168.1.2
    volumes:
      - ./conf:/etc/bind
      - ./zonas:/var/lib/bind
  cliente:
    container_name: cliente
    image: ubuntu
    platform: linux/arm64
    # Asignamos un terminal al contenedor.
    tty: true
    # Mantenemos abierto el canal de entrada estándar.
    stdin_open: true
    # Configuramos el servidor DNS que utilizará el contenedor.
    dns:
      - 192.168.1.2
    networks:
      practica_fabulas:
        ipv4_address: 192.168.1.4

# Definimos la red que vamos a utilizar.
networks:
  practica_fabulas:
    external: true
```
## Prueba Resolución de Dominios

Una vez completados todos los pasos anteriores, estaremos listos para iniciar los contenedores mediante el comando **`docker compose up`**.

Después de iniciar los tres contenedores (Apache, Bind9, Ubuntu), estaremos preparados para ejecutar el comando **`docker exec -it cliente bash`** y así abrir una terminal de bash dentro del contenedor del cliente.

Luego de acceder a la terminal de bash del **cliente**, procederemos a **instalar** los comandos `ping` y `dig` mediante el siguiente procedimiento:

<sup>**A continuación, se muestran por orden los comandos que se deben ejecutar en la terminal:**</sup>

> **`apt update`**

> **`apt upgrade`**

> **`apt install -y iputils-ping`**

> **`apt install -y dnsutils`**

Una vez hayamos **completado la instalación** de `ping` y `dig`, procederemos a **verificar** la resolución de **nombres de dominio** ejecutando el siguiente comando:

> **`dig www.fabulasoscuras.com`**

Si hemos seguido los pasos correctamente, al ejecutar el comando `dig`, deberíamos obtener una respuesta similar a la siguiente, con el dominio resuelto:

```bash
; <<>> DiG 9.18.18-0ubuntu0.22.04.1-Ubuntu <<>> www.fabulasoscuras.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 28795
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 7995a4504bdf664d01000000655df459774fa71c08476a74 (good)
;; QUESTION SECTION:
;www.fabulasoscuras.com.                IN      A

;; ANSWER SECTION:
www.fabulasoscuras.com. 38400   IN      A       192.168.1.2

;; Query time: 0 msec
;; SERVER: 127.0.0.11#53(127.0.0.11) (UDP)
;; WHEN: Wed Nov 22 12:30:17 UTC 2023
;; MSG SIZE  rcvd: 95
```
>[!NOTE]
> Si hemos seguido los pasos correctamente, al introducir ***www.fabulasmaravillosas.com*** en lugar de ***www.fabulasoscuras.com***, la resolución del dominio también se llevará a cabo de manera correcta.

>[!TIP]
> Al utilizar el comando **`dig`** para resolver un dominio, es crucial **revisar varios elementos** en la salida del comando para determinar si la resolución fue exitosa. La sección **`ANSWER`** muestra información sobre el dominio consultado, incluyendo la **dirección IP** asociada. Un código de retorno **0** al final de la salida indica una **resolución exitosa**, mientras que la sección **`AUTHORITY`** proporciona detalles sobre los servidores de nombres autoritativos, siendo otro indicador de éxito. Observar el ***tiempo de respuesta* también es importante**, ya que un **tiempo rápido** sugiere una **resolución exitosa**. **Es fundamental revisar estos elementos para evaluar la corrección de la resolución, especialmente si el dominio tiene múltiples registros.**
