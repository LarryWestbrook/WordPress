# Wordpress

![image](/img/mejores-plugins-wordpress.jpeg)

# Índice

* 1. Instalación de WordPress en una instancia EC2 de AWS
  - 1.1. ¿Qué es un Sistema de Gestión de Contenidos (CMS - Content Management System)?
  - 1.2. ¿Qué es WordPress?
  - 1.3. Instalación de WordPress en el directorio raíz
  - 1.4. Instalación de WordPress en su propio directorio
  - 1.5. Configuración de las security keys de WordPress
  - 1.6. Tareas a realizar
  - 1.7. Entregables
    - 1.7.1. Documento técnico
    - 1.7.2. Scripts de Bash

* 2. Referencias

* 3. Licencia

# 1. Instalación de WordPress en una instancia EC2 de AWS

En esta práctica tendremos que realizar la instalación de WordPress en una instancia EC2 de Amazon Web Services (AWS).

Amazon Web Services (AWS) es una colección de servicios de computación en la nube pública que en conjunto forman una plataforma de computación en la nube, ofrecidas a través de Internet por Amazon.

## 1.1. ¿Qué es un Sistema de Gestión de Contenidos (CMS - Content Management System)?

Un Sistema de Gestión de Contenidos (CMS) es un software que permite a los usuarios crear, editar y gestionar de una forma sencilla el contenido de un sitio web. Algunos ejemplos de CMS son: WordPress, Joomla y Drupal.

## 1.2. ¿Qué es WordPress?

WordPress es un sistema de gestión de contenidos (CMS) muy utilizado para crear sitios webs y blogs. Es software libre y gratuito, y está desarrollado en PHP. Además cuenta con una gran cantidad de plugins y temas que permiten añadir nuevas sus funcionalidades y personalizar su diseño de una forma muy sencilla.

## 1.3. Instalación de WordPress en el directorio raíz
En esta sección se explica los pasos que hay que llevar a cabo para instalar WordPress en directorio raíz de Apache. Por ejemplo: `/var/www/html`.

1. Descargamos la última versión de WordPress con el comando `wget`.

```sh
wget http://wordpress.org/latest.tar.gz -P /tmp
```

El parámetro `-P` indica la ruta donde se guardará el archivo.

2. Descomprimimos el archivo `.tar.gz` que acabamos de descargar con el comando `tar`.

```sh
tar -xzvf /tmp/latest.tar.gz -C /tmp
```

Utilizamos los siguientes parámetros:

- `-x`: Indica que queremos extraer el contenido del archivo.
- `-z`: Indica que queremos descomprimir el archivo.
- `-v`: Habilita el modo verboso para mostrar por pantalla el proceso de descompresión.
- `-f`: Se utiliza para indicar cuál es el nombre del archivo de entrada.
- `-C`: Se utiliza para indicar cuál es el diretorio destino.

3. El contenido se ha descomprimido en una carpeta que se llama wordpress. Ahora, movemos el contenido de `/tpm/wordpress` a `/var/www/html`.

```sh
mv -f /tmp/wordpress/* /var/www/html
```

4. Creamos la base de datos y el usuario para WordPress.

```sh
mysql -u root <<< "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME"
mysql -u root <<< "CREATE DATABASE $WORDPRESS_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
mysql -u root <<< "CREATE USER $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$WORDPRESS_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
```

Ten en cuenta que las variables `$WORDPRESS_DB_NAME`, `$WORDPRESS_DB_USER`, `$WORDPRESS_DB_PASSWORD` y `$IP_CLIENTE_MYSQL` estarán definidas en el archivo `.env`.

El valor de la variable $IP_CLIENTE_MYSQL puede ser:

- `localhost`: Para permitir que el usuario sólo puede conectarse desde el servidor MySQL.
- `%`: Para permitir que el usuario pueda conectarse desde cualquier dirección IP.
- Una dirección IP concreta. Para permitir que el usuario pueda conectarse desde una dirección IP concreta. Ejemplo: `172.31.80.67`.
- Una dirección IP con un comodín. Para permitir que el usuario pueda conectarse desde rango de direcciones IPs. Ejemplo: `172.31.%`.

5. Creamos un archivo de configuración `wp-config.php` a partir del archivo de ejemplo `wp-config-sample.php`.

```sh
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
```

6. En este paso tenemos que configurar las variables de configuración del archivo de configuración de WordPress. El contenido original del archivo `wp-config.php` será similar a este:

```sh
// ** Database settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'database_name_here' );

/** Database username */
define( 'DB_USER', 'username_here' );

/** Database password */
define( 'DB_PASSWORD', 'password_here' );

/** Database hostname */
define( 'DB_HOST', 'localhost' );

/** Database charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );

/** The database collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );
```

Por lo tanto, lo que haremos será reemplazar el texto `database_name_here`, `username_here`, `password_here` y `localhost` por los valores de las variables `$WORDPRESS_DB_NAME`, `$WORDPRESS_DB_USER`, `$WORDPRESS_DB_PASSWORD` y `$WORDPRESS_DB_HOST` respectivamente.

Para realizar este paso utilizaremos el comando `sed`.

```sh
sed -i "s/database_name_here/$WORDPRESS_DB_NAME/" /var/www/html/wp-config.php
sed -i "s/username_here/$WORDPRESS_DB_USER/" /var/www/html/wp-config.php
sed -i "s/password_here/$WORDPRESS_DB_PASSWORD/" /var/www/html/wp-config.php
sed -i "s/localhost/$WORDPRESS_DB_HOST/" /var/www/html/wp-config.php
```

Tenga en cuenta que las variables `$WORDPRESS_DB_NAME`, `$WORDPRESS_DB_USER`, `$WORDPRESS_DB_PASSWORD` y `$WORDPRESS_DB_HOST` estarán definidas en el archivo `.env`.

7. Cambiamos el propietario y el grupo al directorio `/var/www/html`.

```sh
chown -R www-data:www-data /var/www/html/
```

8. Preparamos la configuración para los enlaces permanentes de WordPress. En este paso tendremos que crear un archivo `.htaccess` en el directorio `/var/www/html` con un contenido similar a este.

```sh
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
```

Por lo tanto, este archivo hará que todas las peticiones que llegen a este directorio, si no son un archivo o un directorio entonces se redirigen a `index.php`.

9. Habilitamos el módulo `mod_rewrite` de Apache.

```sh
a2enmod rewrite
```

10. Después de habilitar el módulo deberá reiniciar el servicio de Apache.

```sh
sudo systemctl restart apache2
```

## 1.4 Instalación de WordPress en su propio directorio

En esta sección se explica los pasos que hay que llevar a cabo para instalar WordPress en su propio directorio. Por ejemplo: `/var/www/html/wordpress`.

1. Descargamos la última versión de WordPress con el comando `wget`.

```sh
wget http://wordpress.org/latest.tar.gz -P /tmp
```

El parámetro `-P` indica la ruta donde se guardará el archivo.

2. Descomprimimos el archivo `.tar.gz` que acabamos de descargar con el comando `tar`.

```sh
tar -xzvf /tmp/latest.tar.gz -C /tmp
```

3. El contenido se ha descomprimido en una carpeta que se llama wordpress. Ahora, movemos el contenido de `/tpm/wordpress` a `/var/www/html`.

```sh
mv -f /tmp/wordpress /var/www/html
```

4. Creamos la base de datos y el usuario para WordPress.

```sh
mysql -u root <<< "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME"
mysql -u root <<< "CREATE DATABASE $WORDPRESS_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
mysql -u root <<< "CREATE USER $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$WORDPRESS_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
```

5. Creamos un archivo de configuración `wp-config.php` a partir del archivo de ejemplo `wp-config-sample.php`.

```sh
cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php
```

6. Reemplazamos el texto del archivo de configuracion visto anteriormente con el comando `sed`.

```sh
sed -i "s/database_name_here/$WORDPRESS_DB_NAME/" /var/www/html/wordpress/wp-config.php
sed -i "s/username_here/$WORDPRESS_DB_USER/" /var/www/html/wordpress/wp-config.php
sed -i "s/password_here/$WORDPRESS_DB_PASSWORD/" /var/www/html/wordpress/wp-config.php
sed -i "s/localhost/$WORDPRESS_DB_HOST/" /var/www/html/wordpress/wp-config.php
```

7. Cuando realizamos la instalación de WordPress en su propio directorio, es necesario configurar estas dos variables de configuración:

- Dirección de WordPress (`WP_SITEURL`): Es la URL que incluye el directorio donde está instalado el código fuente de WordPress.
- Dirección del sitio (`WP_HOME`): Es la URL que queremos que usen los usuarios para acceder a WordPress.

Las variables de Dirección de WordPress (`WP_SITEURL`) y Dirección del sitio (`WP_HOME`) se pueden configurar:

- Desde la sección de Ajustes -> Generales del panel de administración de WordPress.
- Desde el archivo de configuración `wp-config.php`.

Si hemos realizado la instalación de WordPress en el directorio wordpress tendremos que asignarles los siguientes valores:

- Dirección de WordPress (`WP_SITEURL`): `https://NOMBRE_DE_DOMINIO/wordpress`
- Dirección del sitio (`WP_HOME`): `https://NOMBRE_DE_DOMINIO`

Donde `NOMBRE_DEL_DOMINIO` será el nombre de dominio que ha reservado para su sitio web. Observa que hemos utilizado https, porque su sitio web tendrá que utilizar un certificado HTTPS.

Si quiere realizar pruebas sin tener un nombre de dominio, puede hacerlas utilizando en su lugar la dirección IP púbica del servidor web.

- Dirección de WordPress (`WP_SITEURL`): `http://IP_PUBLICA_SERVIDOR_WEB/wordpress`
- Dirección del sitio (`WP_HOME`): `http://IP_PUBLICA_SERVIDOR_WEB`

Para automatizar la configuración de las variables `WP_SITEURL` y `WP_HOME` podemos utilizar el comando `sed`.

```sh
sed -i "/DB_COLLATE/a define('WP_SITEURL', 'https://$CERTIFICATE_DOMAIN/wordpress');" /var/www/html/wordpress/wp-config.php
sed -i "/WP_SITEURL/a define('WP_HOME', 'https://$CERTIFICATE_DOMAIN');" /var/www/html/wordpress/wp-config.php
```

Ten en cuenta que la variable `$CERTIFICATE_DOMAIN` estará definida en el archivo `.env`.

8. Copiamos el archivo `var/www/html/wordpress/index.php` a `/var/www/html`.

```sh
cp /var/www/html/wordpress/index.php /var/www/html
```

9. El contenido original del archivo `index.php` será similar a este:

```sh
/** Loads the WordPress Environment and Template */
require( dirname( __FILE__ ) . '/wp-blog-header.php' );
```

Y tenemos que reemplazarlo por este otro:

```sh
/** Loads the WordPress Environment and Template */
require( dirname( __FILE__ ) . '/wordpress/wp-blog-header.php' );
```

Donde wordpress es el directorio donde se encuentra el código fuente de WordPress que hemos descomprimido en pasos anteriores.

Por lo tanto, para realizar este paso utilizaremos el comando sed.

```sh
sed -i "s#wp-blog-header.php#wordpress/wp-blog-header.php#" /var/www/html/index.php 
```

10. Preparamos la configuración para los enlaces permanentes de WordPress. En este paso tendremos que crear un archivo `.htaccess` en el directorio `/var/www/html` con un contenido similar a este.

```sh
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
```

11. Habilitamos el módulo `mod_rewrite` de Apache.

```sh
a2enmod rewrite
```

12. Después de habilitar el módulo deberá reiniciar el servicio de Apache.

```sh
sudo systemctl restart apache2
```

## 1.5 Configuración de las security keys de WordPress

El archivo de configuración `wp-config.php` de WordPress incluye una sección para configurar unas security keys que se utilizan para mejorar la seguridad de las sesiones y generar cookies seguras.

Se recomienda que cada instalación genere unas claves que sean únicas para esa instalación.

1. En primer lugar, eliminamos los valores por defecto de las security keys que aparecen en el archivo de configuración.

```sh
sed -i "/AUTH_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/SECURE_AUTH_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/LOGGED_IN_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/NONCE_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/AUTH_SALT/d" /var/www/html/wordpress/wp-config.php
sed -i "/SECURE_AUTH_SALT/d" /var/www/html/wordpress/wp-config.php
sed -i "/LOGGED_IN_SALT/d" /var/www/html/wordpress/wp-config.php
sed -i "/NONCE_SALT/d" /var/www/html/wordpress/wp-config.php
```

2. Vamos a hacer uso de la API que nos ofrece WordPress para generar unas security keys. La URL de la API es:

- https://api.wordpress.org/secret-key/1.1/salt/

Hacemos una llamada a la API de wordpress para obtener las security keys y almacenamos el resultado en una variable de entorno.

```sh
SECURITY_KEYS=$(curl https://api.wordpress.org/secret-key/1.1/salt/)
```

3. Las nuevas security keys que acabamos de generar pueden contener el carácter `/` y este carácter puede darnos problemas a la hora de utilizar el comando `sed` para añadirlas al archivo de configuración.

Para evitar posibles problemas con el carácter `/` vamos a reemplazarlo por el carácter `_`.

```sh
SECURITY_KEYS=$(echo $SECURITY_KEYS | tr / _)
```

4. Añadimos las security keys al archivo de configuración.

```sh
sed -i "/@-/a $SECURITY_KEYS" /var/www/html/wordpress/wp-config.php
```

5. Cambiamos el propietario y el grupo al directorio /var/www/html.

```sh
chown -R www-data:www-data /var/www/html/
```

# 2 Referencias

- [Amazon Web Services](https://aws.amazon.com/es/)
- [Amazon Web Services en Wikipedia](https://es.wikipedia.org/wiki/Amazon_Web_Services)
- [¿Qué es Amazon EC2?.](https://docs.aws.amazon.com/es_es/AWSEC2/latest/UserGuide/concepts.html)

# 3 Licencia

[image](/img/licencia.png)