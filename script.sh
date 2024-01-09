#!/bin/bash
# Este es un script que levanta la interfaz gráfica de Wordpress 

# ####################################
# ## CONFIGURACIÓN DE LAS VARIABLES ##
# ####################################

# Directorio de usuario #
HTTPASSWD_DIR=/home/root

# MySQL #
DB_ROOT_PASSWD=root
DB_NAME=wordpress_db
DB_USER=larry
DB_PASSWORD=larry
IP_BALANCEADOR=
#IP_MYSQL_SERVER=

# PhPMyAdmin #
PHPMYADMIN_PASSWD=`tr -dc A-Za-z0-9 < /dev/urandom | head -c 64`


# #################################
# ## Instalación de la pila LAMP ##
# #################################

set -x
# Actualizamos los repositorios
apt update
# Instalamos Apache 
apt install apache2 -y
# Instalamos MySQL Server 
apt install mariadb-server -y
# Instalamos módulos PHP 
apt install php libapache2-mod-php php-mysql -y
# Reiniciamos el servicio Apache 
systemctl restart apache2
# Copiamos el archivo info.php al directorio html 
cp $HTTPASSWD_DIR/info.php /var/www/html

# Configuramos las opciones de instalación de phpMyAdmin
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $PHPMYADMIN_PASSWD" |debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $PHPMYADMIN_PASSWD" | debconf-set-selections

# Instalamos phpMyAdmin 
apt install phpmyadmin php-mbstring php-zip php-gd php-json php-curl -y

# ##############################
# ## Instalación de Wordpress ##
# ##############################

# Nos movemos al raíz de Apache 
cd /var/www/html

# Descargamos la última versión de Wordpress 
wget http://wordpress.org/latest.tar.gz -P /tmp
# Eliminamos instalaciones anteriores 
rm -rf /var/www/html/wordpress
# Descomprimimos el archivo que acabamos de descargar 
tar -xzvf /tmp/latest.tar.gz -C /tmp
# Eliminamos lo que ya no necesitamos 
rm latest.tar.gz

# El contenido se ha descomprimido en una carpeta que se llama wordpress. Ahora, movemos el contenido de /tpm/wordpress a /var/www/html.
mv -f /tmp/wordpress/* /var/www/html

# Creamos la base de datos que vamos a usar con Wordpress #

# Nos aseguramos que no existe ya, y si existe la borramos
mariadb -u root <<< "DROP DATABASE IF EXISTS $DB_NAME;"
# Creamos la base de datos
mariadb -u root <<< "CREATE DATABASE $DB_NAME;"
# Nos aseguramos que no existe el usuario
mariadb -u root <<< "DROP USER IF EXISTS $DB_USER@localhost;"
# Creamos el usuario para Wordpress
mariadb -u root <<< "CREATE USER $DB_USER@localhost IDENTIFIED BY '$DB_PASSWORD';"
# Concedemos privilegios al usuario que acabamos de crear
mariadb -u root <<< "GRANT ALL PRIVILEGES ON $DB_NAME.* TO $DB_USER@localhost;"
# Aplicamos cambios
mariadb -u root <<< "FLUSH PRIVILEGES;"


# Borramos el index.html de Apache
rm -r /var/www/html/index.html


# Configuramos el archivo wp-config.php #

# Renombramos el archivo config
mv /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php

# Definimos variables dentro del archivo config
sed -i "s/database_name_here/$WORDPRESS_DB_NAME/" /var/www/html/wordpress/wp-config.php
sed -i "s/username_here/$WORDPRESS_DB_USER/" /var/www/html/wordpress/wp-config.php
sed -i "s/password_here/$WORDPRESS_DB_PASSWORD/" /var/www/html/wordpress/wp-config.php
#sed -i "s/localhost/$IP_MYSQL_SERVER/" /var/www/html/wordpress/wp-config.php

# Habilitamos el módulo rewrite (reescritura de las url)
a2enmod rewrite 

# Le damos permiso a la carpeta de wordpress
chown -R www-data:www-data /var/www/html/

# Reiniciamos Apache 
systemctl restart apache2 