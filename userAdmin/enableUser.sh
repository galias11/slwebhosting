#!/bin/bash

USERNAME=$1
GROUP='slwebhosting'
USER_DOMAIN=/home/admin/web-server/sites/$USERNAME.$GROUP.com

function enable_login {
    echo '--> Enabling user login...'
    (passwd -u $USERNAME) 2>/dev/null
    echo 'OK'
}

function enable_domain {
    echo '--> Enabling user domain...'
    chmod 755 $USER_DOMAIN
    echo 'OK'
}

function enable_mysql_login {
    echo '--> Enabling mysql login...'
    mysql -uroot -e "UPDATE mysql.user SET host='%' WHERE user = '$USERNAME';"
    echo 'OK'
} 

function services_restart {
    echo '--> Restarting services...'
    service apache2 restart
    service dovecot restart
    service postfix restart
    service mysql restart
    echo 'OK'
}

if [ $USERNAME ]; then
    ALREADY_EXISTS=$((id -u $USERNAME) 2>/dev/null) 
    if [ $ALREADY_EXISTS ]; then
        enable_login
        enable_domain
        enable_mysql_login
        services_restart
    else
        echo 'Error: User not exists.'
        exit 1
    fi
else
    echo 'Error: wrong usage --> [./disableUser.sh USERNAME]'
fi