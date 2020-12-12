#!/bin/bash

#Declaración de todas las variables de utilidad
HTTPASSWD_DIR=/home/ubuntu
HTTPASSWD_USER=usuario
HTTPASSWD_PASSWD=usuario
IP_PRIVADA_MYSQL=172.31.42.252

#Habilitamos para que se muestren los comandos
set -x

#ACtualizamos los repositorios
apt update -y
apt upgrade -y

#Instalamos nginx
apt install nginx -y

#Instalamos los módulos necesarios
apt install php-fpm php-mysql php-mbstring -y

#Configuración de php-fpm
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.4/fpm/php.ini

#Reiniciamos el servicio de php-fpm
systemctl restart php7.4-fpm.service 

#Copiamos el archivo de configuración de Nginx
cp default /etc/nginx/sites-available/

#Reiniciamos el servicio de Nginx
systemctl restart nginx

#Copiamos el archivo index.php
cp index.php /var/www/html/

sed -i "s#/run/php/php7.4-fpm.sock#127.0.0.1:9000#" /etc/php/7.4/fpm/pool.d/www.conf

systemctl restart php7.4-fpm.service

#--------------------------
#INSTALACIÓN APLICACIÓN WEB| 
#--------------------------

#Vamos al directorio en el que se instalará la aplicación
cd /var/www/html

#Ejecutamos este comendo por si la carpeta de la aplicación existe, que sea eliminada
rm -rf iaw-practica-lamp

#Descargamos el repositorio
git clone https://github.com/josejuansanchez/iaw-practica-lamp.git

#Movemos el contenido del repositorio a la carpeta html
mv /var/www/html/iaw-practica-lamp/src/* /var/www/html/

#Configuramos el archivo config.php
sed -i "s/localhost/$IP_PRIVADA_MYSQL/" /var/www/html/config.php

#Quitamos los archivos que no necesitamos
rm -rf /var/www/html/index.html
rm -rf /var/www/html/iaw-practica-lamp/

#----------------------
#INSTALACIÓN PHPMYADMIN|
#----------------------
#Instalamos la utilidad unzip
apt install unzip -y

#Descargamos el código fuente de phpMyAdmin 
cd /home/ubuntu
rm -rf phpMyAdmin-5.0.4-all-languages.zip
wget https://files.phpmyadmin.net/phpMyAdmin/5.0.4/phpMyAdmin-5.0.4-all-languages.zip


#Descomprimimos el archivo .zip
unzip phpMyAdmin-5.0.4-all-languages.zip

#Borramos el archivo .zip
rm -rf phpMyAdmin-5.0.4-all-languages.zip

#Movemos el directorio de phyMyAdmin al directorio /var/www/html
mv phpMyAdmin-5.0.4-all-languages/ /var/www/html/phpmyadmin

#Cambiamos al directorio de phpmyadmin para renombrar el archivo de configuración y configurarlo
cd /var/www/html/phpmyadmin
mv config.sample.inc.php config.inc.php
sed -i "s/localhost/$IP_PRIVADA_MYSQL/" /var/www/html/phpmyadmin/config.inc.php


#Cambiamos los permisos 
chown www-data:www-data * -R
