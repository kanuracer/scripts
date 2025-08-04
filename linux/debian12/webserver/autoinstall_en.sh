#!/bin/bash
# check debian version; only deb12 supported
check_debian_version() {
    debian_version=$(cat /etc/os-release | grep '^VERSION_ID=' | cut -d '=' -f 2 | tr -d '"')
    if [ "$debian_version" = "12" ]; then
        echo "Debian 12 detected."
        set_debian_12_sources
        else
        echo "Error: The script only supports Debian 10 or Debian 11."
        exit 1
    fi
}

# set Debian 12 sources.list
set_debian_12_sources() {
    cat <<EOF > /etc/apt/sources.list
deb http://deb.debian.org/debian bookworm contrib main non-free-firmware
deb http://deb.debian.org/debian bookworm-updates contrib main non-free-firmware
deb http://deb.debian.org/debian bookworm-backports contrib main non-free-firmware
deb http://deb.debian.org/debian-security bookworm-security contrib main non-free-firmware
EOF
}

# function for update
update_and_upgrade() {
    apt update
    apt upgrade -y
    clear
}

# install unzip
install_abhaengigkeiten() {
    apt install -y unzip
    clear
}

# function for userstuff
ask_user() {
    clear
    echo "Please enter a root password for MariaDB:"
    read -s mariadb_password

    echo""
    read -p "Please enter the desired phpMyAdmin version (e.g., 5.1.2 or press Enter for the default version 5.2.1): " phpmyadmin_version
    phpmyadmin_version=${phpmyadmin_version:-5.2.1}

    echo ""
    read -p "Please enter your email address for the Let's Encrypt certificate renewal process: " email_address
    
    echo ""
    read -p "Please enter your domain name (e.g., example.com): " domain_name
    clear
}

# install apache & php
install_apache2_php() {
    apt install -y apache2 php php-cli php-curl php-gd php-intl php-json php-mbstring php-mysql php-opcache php-readline php-xml php-xsl php-zip php-bz2 libapache2-mod-php
    clear
}

# install mariadb
install_mariadb() {
    # Installiere MariaDB
    export DEBIAN_FRONTEND=noninteractive
    apt install -y mariadb-server

    # insert input from user
    mariadb_password=$1
    expect -f - <<-EOF
        spawn mysql_secure_installation
        expect "Enter current password for root (enter for none):"
        send "\r"
        expect "Switch to unix_socket authentication \\\[Y/n\\\]"
        send "Y\r"
        expect "Change the root password? \\\[Y/n\\\]"
        send "Y\r"
        expect "New password:"
        send "$mariadb_password\r"
        expect "Re-enter new password:"
        send "$mariadb_password\r"
        expect "Remove anonymous users? \\\[Y/n\\\]"
        send "Y\r"
        expect "Disallow root login remotely? \\\[Y/n\\\]"
        send "Y\r"
        expect "Remove test database and access to it? \\\[Y/n\\\]"
        send "Y\r"
        expect "Reload privilege tables now? \\\[Y/n\\\]"
        send "Y\r"
        expect eof
EOF

    unset DEBIAN_FRONTEND
    clear
}

# install phpmyadmin
install_phpmyadmin() {
    cd /usr/share && wget "https://files.phpmyadmin.net/phpMyAdmin/$phpmyadmin_version/phpMyAdmin-$phpmyadmin_version-all-languages.zip"
    unzip "phpMyAdmin-$phpmyadmin_version-all-languages.zip"
    rm "phpMyAdmin-$phpmyadmin_version-all-languages.zip"
    mv "phpMyAdmin-$phpmyadmin_version-all-languages" phpmyadmin
    chmod -R 0755 phpmyadmin

    # create phpmyadmin conf
    cat <<EOF > /etc/apache2/conf-available/phpmyadmin.conf
# phpMyAdmin Apache configuration
Alias /phpmyadmin /usr/share/phpmyadmin
<Directory /usr/share/phpmyadmin>
Options SymLinksIfOwnerMatch
DirectoryIndex index.php
</Directory>
# Disallow web access to directories that don't need it
<Directory /usr/share/phpmyadmin/templates>
Require all denied
</Directory>
<Directory /usr/share/phpmyadmin/libraries>
Require all denied
</Directory>
<Directory /usr/share/phpmyadmin/setup/lib>
Require all denied
</Directory>
EOF

    # activate phpmyadmin conf
    a2enconf phpmyadmin

    # restart apache2
    systemctl reload apache2
    clear
}

# create default mysql user
create_mysql_user() {
    mysql_username="admin"
    mysql_mariadb_password=$(generate_random_password)

    # drop user if exist
    mysql -u root <<MYSQL_SCRIPT
DROP USER IF EXISTS '$mysql_username'@'localhost';
MYSQL_SCRIPT

    # create new superuser
    mysql -u root <<MYSQL_SCRIPT
CREATE USER '$mysql_username'@'localhost' IDENTIFIED BY '$mysql_mariadb_password';
GRANT ALL PRIVILEGES ON *.* TO '$mysql_username'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

    #testfunction for correct installation
    #echo "MariaDB Nutzer: $mysql_username Passwort: $mysql_mariadb_password"
    clear
}

install_wordpress() {
    cd /var/www/html
    wget -q "https://de.wordpress.org/latest-de_DE.zip"
    unzip -q latest-de_DE.zip
    rm latest-de_DE.zip
    cp -ar /var/www/html/wordpress/* /var/www/html/
    rm -r wordpress/
    chown www-data:www-data -R *
    find . -type d -exec chmod 755 {} \;
    find . -type f -exec chmod 644 {} \;
    clear
}

# generate random pw
generate_random_password() {
    openssl rand -base64 16
}

# create wordpress user 
create_mysql_wordpress_user() {
    mysql_username="wordpress"
    mysql_wordpress_password=$(generate_random_password)

    # drop user if exist
    mysql -u root <<MYSQL_SCRIPT
DROP USER IF EXISTS '$mysql_username'@'localhost';
MYSQL_SCRIPT

    # create new user
    mysql -u root <<MYSQL_SCRIPT
CREATE USER '$mysql_username'@'localhost' IDENTIFIED BY '$mysql_wordpress_password';
GRANT ALL PRIVILEGES ON *.* TO '$mysql_username'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

    #testfunction for correct installation
    #echo "WordPress Datenbanknutzer: $mysql_username Passwort: $mysql_wordpress_password"
    clear
}

create_mysql_wordpress_database() {
    mysql_database="wordpress"

    # create db for wordpress
    mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS $mysql_database;
MYSQL_SCRIPT

    # grant ALL PRIVILEGES on wordpress
    mysql -u root <<MYSQL_SCRIPT
GRANT ALL PRIVILEGES ON $mysql_database.* TO 'wordpress'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT
}

install_nextcloud() {
    cd /var/www/html
    wget https://download.nextcloud.com/server/releases/latest.tar.bz2
    tar xfvj latest.tar.bz2
    rm latest.tar.bz2
    a2enmod rewrite
    systemctl restart apache2
    chown -R www-data:www-data /var/www/html/nextcloud/
    clear
}

create_nextcloud_mysql_user() {
    mysql_nextcloud_username="nextcloud"
    mysql_nextcloud_password=$(openssl rand -base64 16)

    # 
    mysql -u root <<MYSQL_SCRIPT
DROP USER IF EXISTS '$mysql_nextcloud_username'@'localhost';
MYSQL_SCRIPT

    # create new user
    mysql -u root <<MYSQL_SCRIPT
CREATE USER '$mysql_nextcloud_username'@'localhost' IDENTIFIED BY '$mysql_nextcloud_password';
GRANT ALL PRIVILEGES ON nextcloud.* TO '$mysql_nextcloud_username'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

    #testfunction for correct installation    
    #echo "Nextcloud MariaDB Nutzer: $mysql_nextcloud_username Passwort: $mysql_nextcloud_password"
    clear
}

create_nextcloud_mysql_database() {
    mysql_nextcloud_database="nextcloud"

    # create db if not exist
    mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS $mysql_nextcloud_database;
MYSQL_SCRIPT

    #testfunction for correct installation
    #echo "Nextcloud Datenbank erstellt: $mysql_nextcloud_database"
    clear
}

install_certbot() {
    apt install -y certbot python3-certbot-apache
    clear
}

# Let's Encrypt
configure_ssl_certificate() {
    local domain_name="$1"
    local email_address="$2"

    # create certificate
    certbot --apache --non-interactive --agree-tos --domains "$domain_name" --email "$email_address"

    # restart apache2
    systemctl restart apache2
    # cert log
    echo "$certbot_output"
    clear
}

setup_certbot_renewal_cronjob() {
    local cronjob_cmd="certbot renew --quiet"
    local cronjob_schedule="0 0 */80 * *" #cronjob for certrenew every 80 days

    (crontab -l 2>/dev/null; echo "$cronjob_schedule $cronjob_cmd") | crontab -
}

setup_auto_updates_cronjob() {
    local cronjob_cmd="apt update && apt upgrade -y"
    local cronjob_schedule="0 0 * * 1" # cronjob for server autoupdate every monday 00:00

    (crontab -l 2>/dev/null; echo "$cronjob_schedule $cronjob_cmd") | crontab -
}

finish_install() {
	clear
	    echo "---------------------------------------"
	    echo "---------------MariaDB-----------------"
	    echo "Admin User: admin"
	    echo "Password: $mysql_mariadb_password"
	    echo ""
	    echo "---------------------------------------"
	    echo "--------------Wordpress----------------"
	    echo "https://$domain_name"
	    echo "DB-User: wordpress"
	    echo "DB-Name: wordpress"
	    echo "Password: $mysql_wordpress_password"
	    echo ""
	    echo "---------------------------------------"
	    echo "---------------Nextcloud----------------"
	echo "https://$domain_name/nextcloud"
    	echo "DB-User: nextcloud"
    	echo "DB-Name: nextcloud"
    	echo "Password: $mysql_nextcloud_password"
        echo ""
    	echo "---------------------------------------"
        echo "---------------Cronjobs----------------"
    	echo "System updates: Every 7 days"
    	echo "Certbot renew: Every 80 days"
    	echo "---------------------------------------"
	    echo ""



	echo "Installations completed successfully."
}

# check debian version
check_debian_version

# userinput
ask_user

# update
echo "Update server ..."
update_and_upgrade

# install dependencies
echo "Installing dependencies ..."
install_abhaengigkeiten

# Installing Apache2 and PHP
echo "Installing Apache2 and PHP ..."
install_apache2_php

# Installing MariaDB
echo "Installing MariaDB ..."
install_mariadb $mariadb_password

# Installing phpMyAdmin
echo "Installing phpMyAdmin ..."
install_phpmyadmin

# create new MySQL-Adminuser
echo "create new MySQL-Adminuser"
create_mysql_user

# Installing Wordpress
echo "Installing Wordpress"
install_wordpress

# new mysql user for wordpress
create_mysql_wordpress_user

# create wordpress db
create_mysql_wordpress_database

# installing Nextcloud
echo "Installing Nextcloud ..."
install_nextcloud

# create new mysql user for nextcloud
create_nextcloud_mysql_user

# create new db for nextcloud
create_nextcloud_mysql_database

echo "Installing Let's Encrypt (certbot) ..."
install_certbot

echo "Configuring SSL/TLS certificate for the domain $domain_name ..."
configure_ssl_certificate $domain_name $email_address

# cert renew cron
echo "Creating a cron job for certificate renewal every 80 days..."
setup_certbot_renewal_cronjob

# cron for autoupdate
echo "Creating a cron job for automatic updates once per week..."
setup_auto_updates_cronjob

# Ende
finish_install