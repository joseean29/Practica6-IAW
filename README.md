# PRÁCTICA 6 - IAW
En esta práctica deberá automatizar la instalación y configuración de una aplicación web LAMP en dos máquinas virtuales EC2 de Amazon Web Services (AWS), con la última versión de Ubuntu Server. En una de las máquinas deberá instalar Nginx y los módulos necesarios de PHP y en la otra máquina deberá instalar MySQL Server.

Vamos a tener la pila LEMP repartida en dos máquinas virtuales, una se encargará de gestionar las peticiones web y la otra de gestionar la base de datos.

Una vez que hayas comprobado que todos los servicios de la pila LEMP están funcionando correctamente en las dos máquinas, instala y configura la aplicación propuesta.

Ten en cuenta que tendrás que modificar la configuración de MySQL Server para que permita conexiones remotas y también tendrás que revisar los privilegios del usuario que se conecta a la base de datos de la aplicación.

Para realizar esta práctica puede utilizar los scripts de la práctica 3, pero tenga en cuenta que tendrá que reemplazar el uso del servidor web Apache HTTP Server por Nginx.

**Arquitectura de red ideal:**
![]()

# 1 LEMP Stack
## 1.1 Instalación del servidor web Nginx
```
sudo apt update
sudo apt install nginx
```

## 1.2 Instalación de php-fpm y php-mysql
### 1.2.1 php-fpm
El paquete php-fpm (PHP FastCGI Process Manager) es una implementación alternativa al PHP FastCGI con algunas características adicionales útiles para sitios web com mucho tráfico.

El uso de PHP-FPM (PHP FastCGI Process Manager) con Nginx es ideal porque permite mejorar el consumo de memoria del servidor, haciendo que el servidor tenga un bajo consumo de recursos, mejorando de esta manera su rendimiento y escalabilidad. PHP-FPM se ejecutará como un servicio independiente de Nginx que se va a encargar de interpretar las peticiones que incluyen código PHP que reciba el servidor Nginx. Cuando el servidor Nginx reciba una petición HTTP donde haya que procesar código PHP, el servidor Nginx se comunicará con PHP-FPM a través de un socket UNIX o un socket TCP/IP para recibir la respuesta del código PHP interpretado y servirla al cliente que realizó la petición.
```
sudo apt install php-fpm
```

### 1.2.2 php-mysql
El paquete php-mysql permite a PHP interaccionar con el sistema gestor de bases de datos MySQL.
```
sudo apt install php-mysql
```

## 1.3 Configuración de Nginx para comunicarse con php-fpm a través de un socket UNIX
![]()
Los sockets UNIX nos permiten realizar comunicación entre procesos, también conocida como IPC (Inter-Process Communication)), que es una función básica de los sistemas operativos que permite el intercambio de datos entre procesos de una forma eficiente. Sin embargo, los sockets TCP/IP nos permiten comunicar procesos a través de una red.

Un sockets UNIX es un tipo de archivo especial, donde los procesos pueden escribir y leer datos para comunicarse.

Los sockets UNIX tienen la ventanja que permiten realizar comunicaciones más rápidas entre los procesos, pero tienen el inconveniente de que son menos escalables que los sockets TCP/IP porque sólo permiten comunicar procesos que se están ejecutando en el mismo sistema operativo de la misma máquina.

En esta sección vamos a explicar cómo podemos configurar Nginx para que pueda comunicarse con el proceso php-fpm a través de un socket UNIX.

Editamos el archivo de configuración /etc/nginx/sites-available/default:
```
sudo nano /etc/nginx/sites-available/default
```
Realizamos los siguientes cambios:

- En la sección index añadimos el valor index.php en primer lugar para que darle prioridad respecto a los archivos index.html.
- Añadimos el bloque location ~ \.php$ indicando dónde se encuentra el archivo de configuración fastcgi-php.conf y el archivo php7.4-fpm.sock.
- Opcionalmente podemos añadir el bloque location ~ /\.ht para no permitir que un usuario pueda descargar los archivos .htaccess. Estos archivos no son procesados por Nginx, son específicos de Apache.

Un posible archivo de configuración para el servidor podría ser el siguiente:
```
server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/www/html;

        index index.php index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                try_files $uri $uri/ =404;
        }

        # pass PHP scripts to FastCGI server
        #
        location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                # With php-fpm (or other unix sockets):
                fastcgi_pass unix:/run/php/php7.4-fpm.sock;
        }

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        location ~ /\.ht {
                deny all;
        }
}
```
Podemos comprobar que la sintaxis del archivo de configuración es correcta con el comando:
```
sudo ngingx -t
```
Una vez realizados los cambios reiniciamos el servicio nginx:
```
sudo systemctl restart nginx
```

## 1.4 Comprobar que la instalación se ha realizado correctamente
Crea un archivo llamado info.php en el directorio /var/www/html.
```
sudo nano /var/www/html/info.php
```
Añade el siguiente contenido:
```
<?php

phpinfo();

?>
```
Ahora accede desde un navegador a la URL: http://IP/info.php, donde IP será la dirección IP de su máquina virtual. Por ejemplo, si la dirección IP de su máquina virtual es 192.168.22.200, la URL será: http://192.168.22.200/info.php

## 1.5 Configuración de Nginx para comunicarse con php-fpm a través de un socket TCP/IP
Los sockets TCP/IP nos permiten comunicar procesos que se pueden estar ejecutando en la misma máquina o en máquinas diferentes, a través de una red.

### 1.5.1 Opción 1: Nginx y php-fpm se ejecutan en la misma máquina
![]()

#### 1.5.1.1 Configuración de php-fmp
En primer lugar hay que modificar la directiva `listen` del archivo `/etc/php/7.4/fpm/pool.d/www.conf`.
```
sudo nano /etc/php/7.4/fpm/pool.d/www.conf
```
Si buscamos la directiva listen en el archivo de configuración nos encontramos que en la configuración por defecto está escuchando en el socket UNIX /run/php/php7.4-fpm.sock. A continuación se muestra un fragmento del archivo de configuración por defecto que hace referencia a la directiva listen.
```
; The address on which to accept FastCGI requests.
; Valid syntaxes are:
;   'ip.add.re.ss:port'    - to listen on a TCP socket to a specific IPv4 address on
;                            a specific port;
;   '[ip:6:addr:ess]:port' - to listen on a TCP socket to a specific IPv6 address on
;                            a specific port;
;   'port'                 - to listen on a TCP socket to all addresses
;                            (IPv6 and IPv4-mapped) on a specific port;
;   '/path/to/unix/socket' - to listen on a unix socket.
; Note: This value is mandatory.
listen = /run/php/php7.4-fpm.sock
```

Habrá que modificar la directiva listen por la dirección de localhost (127.0.0.1) y un puerto. En este ejemplo utilizaremos el puerto 9000. La directiva listen quedaría así:
```
listen = 127.0.0.1:9000
```

Una vez que hemos realizado las modificaciones en la configuración reiniciamos el servicio de php-fpm para que se apliquen los cambios:
```
sudo systemctl restart php7.4-fpm
```

#### 1.5.1.2 Configuración de Nginx
En este caso hay que configurar en el archivo /etc/nginx/sites-available/default que los scripts PHP se van a enviar al servidor FastCGI a través de un socket TCP/IP.
```
sudo nano /etc/nginx/sites-available/default
```

Habrá que modificar la directiva de configuración fastcgi_pass para indicar la dirección y el puerto donde se encuentra el servidor FastCGI. Por ejemplo, si el servidor FastCGI se está ejecutando en la misma máquina (127.0.0.1), en el puerto 9000 habrá que asignarle el siguiente valor:
```
fastcgi_pass 127.0.0.1:9000;
```

Un posible archivo de configuración para el servidor podría ser el siguiente:
```
server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/www/html;

        index index.php index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                try_files $uri $uri/ =404;
        }

        # pass PHP scripts to FastCGI server
        #
        location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                # With php-cgi (or other tcp sockets):
                fastcgi_pass 127.0.0.1:9000;
        }

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        location ~ /\.ht {
                deny all;
        }
}
```

Podemos comprobar que la sintaxis del archivo de configuración es correcta con el comando:
```
sudo ngingx -t
```

Una vez realizados los cambios reiniciamos el servicio nginx:
```
sudo systemctl restart nginx
```

## 1.6 Configuración de la directiva cgi.fix_pathinfo para mejorar la seguridad
Es recomendable realizar un cambio en la directiva de configuración cgi.fix_pathinfo por cuestiones de seguridad. Editamos el siguiente archivo de configuración:
```
sudo nano /etc/php/7.4/fpm/php.ini
```

Buscamos la directiva de configuración cgi.fix_pathinfo que por defecto aparece comentada con un punto y coma y con un valor igual a 1.
```
;cgi.fix_pathinfo=1
```

Eliminamos el punto y coma y la configuramos con un valor igual a 0.
```
cgi.fix_pathinfo=0
```

Una vez modificado el archivo de configuración y guardados los cambios reiniciamos el servicio php7.4-fpm.
```
sudo systemctl restart php7.4-fpm
```
