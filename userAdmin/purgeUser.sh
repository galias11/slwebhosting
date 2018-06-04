#!/bin/bash

#environment vars
DOMAIN_CONF_FILE_PATH='/home/admin/web-server/conf'
DOMAIN_CONF_FILE_PREFIX='.com.conf'
DOMAIN_DIR_PATH='/home/admin/web-server/sites'
DOMAIN_DIR_PREFIX='.slwebhosting.com'
HOME_PATH='/home'

USERNAME=$1

function delete_domain_conf_file {
    echo '--> Removing user domain conf file'
    rm $DOMAIN_CONF_FILE_PATH/$USERNAME$DOMAIN_CONF_FILE_PREFIX
    echo 'OK'
}

function delete_domain_dir {
    echo '--> Removing user domain dir'
    rm -r $DOMAIN_DIR_PATH/$USERNAME$DOMAIN_DIR_PREFIX
    echo 'OK'
}

function delete_user_dir {
    echo '--> Removing user dir'
    rm -r $HOME_PATH/$USERNAME
    echo 'OK'
}

function delete_mysql_user {
    echo '--> Removing user data from database server'
    mysql -uroot -e "DROP USER '$USERNAME'@'%';"
    mysql -uroot -e "DROP DATABASE $USERNAME;"
    mysql -uroot -e "FLUSH PRIVILEGES;"
    echo 'OK'
}

function delete_user {
    echo '--> Deleting user from system'
    userdel $USERNAME
    echo 'OK'
}

function restart_services {
    service apache2 reload
    service postfix reload
    service dovecot reload
    service mysql reload
}


if [ $USERNAME ]; then
    ALREADY_EXISTS=$((id -u $USERNAME) 2>/dev/null) 
    if [ $ALREADY_EXISTS ]; then
        delete_mysql_user
        delete_domain_conf_file
        delete_domain_dir
        delete_user_dir
        delete_user
        restart_services
    else
        echo 'Error: User not exists.'
        exit 1
    fi
else
    echo 'Error: wrong usage --> [./purgeUser.sh USERNAME]'
fi