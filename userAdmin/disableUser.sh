#!/bin/bash

USERNAME=$1
GROUP='slwebhosting'
USER_DOMAIN=/home/admin/web-server/sites/$USERNAME.$GROUP.com

function disable_login {
    echo '--> Disabling user login...'
    (passwd -l $USERNAME) 2>/dev/null
    echo 'OK'
}

function disable_domain {
    echo '--> Disabling user domain...'
    chmod 000 $USER_DOMAIN
    echo 'OK'
}

function disable_mysql_login {
    echo '--> Disabling mysql login...'
    mysql -uroot -e "UPDATE mysql.user SET host='!' WHERE user = '$USERNAME';"
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
        disable_login
        disable_domain
        disable_mysql_login
        services_restart
    else
        echo 'Error: User not exists.'
        exit 1
    fi
else
    echo 'Error: wrong usage --> [./disableUser.sh USERNAME]'
fi