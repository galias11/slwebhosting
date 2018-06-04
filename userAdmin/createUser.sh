#!/bin/bash

#Environment vars
WEB_HOSTING_BASE_DIR='/home/admin/web-server'
WEBHOSTING_GROUP='slwebhosting'
USER_MAILBOX=''
WEB_HOSTING_SFTP_DIR=''
TMP_CFG_FILE='/tmp/slwebhosting.conf'

function create_user {
    USER_NAME=$1
    PASSWD=$2
    echo '--> adding new user...'
    useradd -c "slwebhosting user" -m -s /bin/nologin -g $WEBHOSTING_GROUP $USER_NAME
    (echo -e "${PASSWD}\n${PASSWD}" | passwd $USER_NAME) 2>/dev/null
    usermod -G $WEBHOSTING_GROUP $USER_NAME
    echo 'OK'
}

function create_virtual_domain_conf {
    USER_NAME=$1
    USER_FILE="$WEB_HOSTING_BASE_DIR/conf/$USERNAME.com.conf"
    echo '--> creating virtual host domain file...'
    printf '<Directory "%s">\n' $WEB_HOSTING_SFTP_DIR >> $USER_FILE
	printf '  Options Indexes FollowSymLinks\n' >> $USER_FILE
	printf '  AllowOverride none\n' >> $USER_FILE
	printf '  Require all granted\n' >> $USER_FILE
    printf '</Directory>\n' >> $USER_FILE
    printf '\n' >> $USER_FILE
    printf '<VirtualHost *:80>\n' >> $USER_FILE
	printf '  ServerAdmin %s@slwebhosting.com\n' $USER_NAME >> $USER_FILE
	printf '  ServerName www.%s.%s.com\n' $USER_NAME $WEBHOSTING_GROUP >> $USER_FILE
    printf '\n' >> $USER_FILE
	printf '  #Root del sitio alojado\n' >> $USER_FILE
	printf '  DocumentRoot %s\n' $WEB_HOSTING_SFTP_DIR >> $USER_FILE
	printf '\n' >> $USER_FILE
	printf '  #Directorio del log de errores\n' >> $USER_FILE
	printf '  ErrorLog ${APACHE_LOG_DIR}/www.%s.com-error.log\n' $USER_NAME >> $USER_FILE
    printf '\n' >> $USER_FILE
	printf '  #Nivel al cual deseamos efectuar el logging\n' >> $USER_FILE
	printf '  logLevel warn\n' >> $USER_FILE
	printf '\n' >> $USER_FILE
	printf '  CustomLog ${APACHE_LOG_DIR}/www.%s.com-access.log combined\n' $USER_NAME >> $USER_FILE
    printf '\n' >> $USER_FILE
	printf '  # Disables all caching (use for development)\n' >> $USER_FILE
	printf '  <FilesMatch "\.(html|htm|js|css|json)$">\n' >> $USER_FILE
    printf '      FileETag None\n' >> $USER_FILE
    printf '      <IfModule mod_headers.c>\n' >> $USER_FILE
	printf '          Header unset ETag\n' >> $USER_FILE
	printf '          Header set Cache-Control "max-age=0, no-cache, no-store, must-revalidate"\n' >> $USER_FILE
	printf '          Header set Pragma "no-cache"\n' >> $USER_FILE
	printf '          Header set Note "CACHING IS DISABLED ON LOCALHOST"\n' >> $USER_FILE
	printf '          Header set Expires "Web, 11 Jan 1984 05:00:00 GMT"\n' >> $USER_FILE
    printf '      </IfModule>\n' >> $USER_FILE
	printf '  </FilesMatch>\n' >> $USER_FILE
    printf '\n' >> $USER_FILE
    printf '</VirtualHost>\n' >> $USER_FILE
    chown $USER_NAME $USER_FILE
    echo "OK"
}

function create_virtual_domain_dir {
    USER_NAME=$1
    USER_DIR=$WEB_HOSTING_SFTP_DIR
    echo "--> creating user domain dir..."
    mkdir $USER_DIR
    chown $USER_NAME:$WEBHOSTING_GROUP $USER_DIR
    chmod 755 $USER_DIR
    echo "OK"
}

function create_email_account {
    USER_NAME=$1
    mkdir $USER_MAILBOX
    chown $USERNAME:$WEBHOSTING_GROUP $USER_MAILBOX
}

function create_mysql_user {
    USER_NAME=$1
    PASSWD=$2
    echo '--> creating mysql database user'
    mysql -uroot -e "CREATE DATABASE $USER_NAME /*\!40100 DEFAULT CHARACTER SET utf8 */;"
    mysql -uroot -e "CREATE USER '$USER_NAME'@'%' IDENTIFIED BY '$PASSWD';"
    mysql -uroot -e "GRANT ALL PRIVILEGES ON $USER_NAME.* TO '$USER_NAME'@'%' IDENTIFIED BY '$PASSWD';"
    mysql -uroot -e "FLUSH PRIVILEGES;"
    echo 'OK'
}

function restart_services {
    service apache2 reload
    service postfix reload
    service dovecot reload
    service mysql reload
}

function send_new_user_data_mail {
    USER_NAME=$1
    PASSWD=$2
    echo '--> sending cfg file to new user...'
    printf 'Felicitaciones has creado tu usuario en: slwebhosting.com\n' > $TMP_CFG_FILE
    printf '\nLogin data (mail, sftp, mysql):\n' >> $TMP_CFG_FILE
    printf 'User: %s\n' $USER_NAME >> $TMP_CFG_FILE
    printf 'Pass: %s\n' $PASSWD >> $TMP_CFG_FILE
    printf '\nTu dominio en slwebhosting es: \nwww.%s.slwebhosting.com\n' $USER_NAME >> $TMP_CFG_FILE
    printf '\nPara acceder a tu casilla de mail, accede con tus datos a www.webmail.slwebhosting.com\n' >> $TMP_CFG_FILE
    printf '\nPara conectarte al servidor SFTP y subir datos a tu dominio:\n' >> $TMP_CFG_FILE
    printf 'sftp -P 22 %s@www.slwebhosting.com\n' $USER_NAME >> $TMP_CFG_FILE
    printf '\nPara conectarte al servidor MYSQL y gestionar tu BD:\n' >> $TMP_CFG_FILE
    printf 'mysql -h www.slwebhosting.com -u %s -p\n' $USER_NAME >> $TMP_CFG_FILE
    printf '\n\nGracias por aprobarnos... digo elegirnos :P\nEl equipo de slwebhosting\n' >> $TMP_CFG_FILE
    (echo "Bienvenido a slwebhosting!!! En el archivo adjunto encontraras todos los datos necesarios para aprobarnos... digo usar nuestros servicios" | mutt -a $TMP_CFG_FILE -s "Bienvenido a slwebhosting.com" -- $USER_NAME@slwebhosting.com) 2>/dev/null
    echo 'OK'
}

if [[ $1 && $2 ]]; then 
    USERNAME=$1
    PASSWD=$2
    ALREADY_EXISTS=$((id -u $USERNAME) 2>/dev/null) 
    if [ $ALREADY_EXISTS ]; then
        echo 'Error: User already exists.'
        exit 1
    fi
    WEB_HOSTING_SFTP_DIR="$WEB_HOSTING_BASE_DIR/sites/$USERNAME.slwebhosting.com"
    USER_MAILBOX="/home/$USERNAME/Maildir"
    create_user $USERNAME $PASSWD
    create_virtual_domain_conf $USERNAME
    create_virtual_domain_dir $USERNAME
    create_email_account
    create_mysql_user $USERNAME $PASSWD
    restart_services
    send_new_user_data_mail $USERNAME $PASSWD
else
    echo 'Error: wrong usage, should be: slwAddUser [username] [passwd]'
fi
