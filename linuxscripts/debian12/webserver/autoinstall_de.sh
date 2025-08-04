#!/bin/bash

# Funktion zur ÃœberprÃ¼fung der Debian-Version
check_debian_version() {
    debian_version=$(cat /etc/os-release | grep '^VERSION_ID=' | cut -d '=' -f 2 | tr -d '"')
    if [ "$debian_version" = "12" ]; then
        echo "Debian 12 erkannt."
        set_debian_12_sources
    else
        echo "Fehler: Das Skript unterstÃ¼tzt nur Debian 12."
        exit 1
    fi
}

# Funktion zum Einrichten der Debian 12 Sources-Liste
set_debian_12_sources() {
    cat <<EOF > /etc/apt/sources.list
deb http://deb.debian.org/debian bookworm contrib main non-free-firmware
deb http://deb.debian.org/debian bookworm-updates contrib main non-free-firmware
deb http://deb.debian.org/debian bookworm-backports contrib main non-free-firmware
deb http://deb.debian.org/debian-security bookworm-security contrib main non-free-firmware
EOF
}

# Funktion zum Aktualisieren der Paketquellen und Upgrade
update_and_upgrade() {
    apt update
    apt upgrade -y
    clear
}

# Funktion zur Installation von AbhÃ¤ngigkeiten
install_abhaengigkeiten() {
    apt install -y unzip
    clear
}

# Funktion zum Fragen des Benutzers
ask_user() {
    clear
    echo "Gib ein root Passwort für MariaDB ein:"
    read -s mariadb_password

    echo""
    read -p "Bitte gebe die gewünschte phpMyAdmin-Version ein (z.B. 5.1.2 oder Enter für die Standardversion 5.2.1): " phpmyadmin_version
    phpmyadmin_version=${phpmyadmin_version:-5.2.1}

    echo ""
    read -p "Gib deine E-Mail-Adresse für den Let's Encrypt-Zertifikatserneuerungsprozess ein: " email_address
    
    echo ""
    read -p "Bitte gebe deine Domain ein (z.B. example.com): " domain_name
    clear
}

# Funktion zur Installation von Apache2 und PHP
install_apache2_php() {
    apt install -y apache2 php php-cli php-curl php-gd php-intl php-json php-mbstring php-mysql php-opcache php-readline php-xml php-xsl php-zip php-bz2 libapache2-mod-php
    clear
}

# Funktion zur Installation von MariaDB und automatischen Antworten
install_mariadb() {
    # Installiere MariaDB
    export DEBIAN_FRONTEND=noninteractive
    apt install -y mariadb-server

    # Automatische Antworten wÃ¤hrend der MariaDB-Installation
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

# Funktion zur Installation von phpMyAdmin
install_phpmyadmin() {
    cd /usr/share && wget "https://files.phpmyadmin.net/phpMyAdmin/$phpmyadmin_version/phpMyAdmin-$phpmyadmin_version-all-languages.zip"
    unzip "phpMyAdmin-$phpmyadmin_version-all-languages.zip"
    rm "phpMyAdmin-$phpmyadmin_version-all-languages.zip"
    mv "phpMyAdmin-$phpmyadmin_version-all-languages" phpmyadmin
    chmod -R 0755 phpmyadmin

    # Erstelle Apache-Konfiguration fÃ¼r phpMyAdmin
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

    # Aktiviere die phpMyAdmin-Konfiguration
    a2enconf phpmyadmin

    # Lade die Apache-Konfiguration neu
    systemctl reload apache2
    clear
}

# Funktion zur Erstellung eines neuen MySQL-Nutzers
create_mysql_user() {
    mysql_username="admin"
    mysql_mariadb_password=$(generate_random_password)

    # LÃ¶sche den Benutzer, falls er bereits vorhanden ist
    mysql -u root <<MYSQL_SCRIPT
DROP USER IF EXISTS '$mysql_username'@'localhost';
MYSQL_SCRIPT

    # Erstelle den neuen Benutzer
    mysql -u root <<MYSQL_SCRIPT
CREATE USER '$mysql_username'@'localhost' IDENTIFIED BY '$mysql_mariadb_password';
GRANT ALL PRIVILEGES ON *.* TO '$mysql_username'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

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

# Funktion zum Generieren eines zufälligen Passworts
generate_random_password() {
    openssl rand -base64 16
}

# Funktion zur Erstellung eines neuen MySQL-Nutzers für WordPress
create_mysql_wordpress_user() {
    mysql_username="wordpress"
    mysql_wordpress_password=$(generate_random_password)

    # Lösche den Benutzer, falls er bereits vorhanden ist
    mysql -u root <<MYSQL_SCRIPT
DROP USER IF EXISTS '$mysql_username'@'localhost';
MYSQL_SCRIPT

    # Erstelle den neuen Benutzer
    mysql -u root <<MYSQL_SCRIPT
CREATE USER '$mysql_username'@'localhost' IDENTIFIED BY '$mysql_wordpress_password';
GRANT ALL PRIVILEGES ON *.* TO '$mysql_username'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

    #echo "WordPress Datenbanknutzer: $mysql_username Passwort: $mysql_wordpress_password"
    clear
}

create_mysql_wordpress_database() {
    mysql_database="wordpress"

    # Erstelle die Datenbank
    mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS $mysql_database;
MYSQL_SCRIPT

    # Weise dem Nutzer "wordpress" alle Rechte auf die Datenbank "wordpress" zu
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

    # Lösche den Benutzer, falls er bereits vorhanden ist
    mysql -u root <<MYSQL_SCRIPT
DROP USER IF EXISTS '$mysql_nextcloud_username'@'localhost';
MYSQL_SCRIPT

    # Erstelle den neuen Benutzer
    mysql -u root <<MYSQL_SCRIPT
CREATE USER '$mysql_nextcloud_username'@'localhost' IDENTIFIED BY '$mysql_nextcloud_password';
GRANT ALL PRIVILEGES ON nextcloud.* TO '$mysql_nextcloud_username'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

    #echo "Nextcloud MariaDB Nutzer: $mysql_nextcloud_username Passwort: $mysql_nextcloud_password"
    clear
}

create_nextcloud_mysql_database() {
    mysql_nextcloud_database="nextcloud"

    # Erstelle die Datenbank, falls sie noch nicht existiert
    mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS $mysql_nextcloud_database;
MYSQL_SCRIPT

    #echo "Nextcloud Datenbank erstellt: $mysql_nextcloud_database"
    clear
}

install_certbot() {
    apt install -y certbot python3-certbot-apache
    clear
}

# Funktion zum Konfigurieren des Zertifikats mit Let's Encrypt
configure_ssl_certificate() {
    local domain_name="$1"
    local email_address="$2"

    # Zertifikatserstellung und Apache-Konfiguration
    certbot --apache --non-interactive --agree-tos --domains "$domain_name" --email "$email_address"

    # Apache-Neustart nach der Konfiguration
    systemctl restart apache2
    # Gibt das Zertifikatserstellungsprotokoll aus
    echo "$certbot_output"
    clear
}

setup_certbot_renewal_cronjob() {
    local cronjob_cmd="certbot renew --quiet"
    local cronjob_schedule="0 0 */80 * *"

    (crontab -l 2>/dev/null; echo "$cronjob_schedule $cronjob_cmd") | crontab -
}

setup_auto_updates_cronjob() {
    local cronjob_cmd="apt update && apt upgrade -y"
    local cronjob_schedule="0 0 * * 1" # Einmal pro Woche, Montag um 00:00 Uhr

    (crontab -l 2>/dev/null; echo "$cronjob_schedule $cronjob_cmd") | crontab -
}

finish_install() {
	clear
	    echo "---------------------------------------"
	    echo "---------------MariaDB-----------------"
	    echo "Admin Nutzer: admin"
	    echo "Passwort: $mysql_mariadb_password"
	    echo ""
	    echo "---------------------------------------"
	    echo "--------------Wordpress----------------"
	    echo "https://$domain_name"
	    echo "DB-Nutzer: wordpress"
	    echo "DB-Name: wordpress"
	    echo "Passwort: $mysql_wordpress_password"
	    echo ""
	    echo "---------------------------------------"
	    echo "---------------Nextcloud----------------"
	echo "https://$domain_name/nextcloud"
    	echo "DB-Nutzer: nextcloud"
    	echo "DB-Name: nextcloud"
    	echo "Passwort: $mysql_nextcloud_password"
        echo ""
    	echo "---------------------------------------"
        echo "---------------Cronjobs----------------"
    	echo "Systemupdates: nach 7 Tagen"
    	echo "Certbot renew: nach 80 Tagen"
    	echo "---------------------------------------"
	    echo ""
	



	echo "Installationen wurden erfolgreich abgeschlossen."
}

# Aufruf der ÃœberprÃ¼fungsfunktion
check_debian_version

# Fragen des Benutzers
ask_user

# Einrichten der Paketquellen
echo "Aktualisiere die Paketquellen ..."
update_and_upgrade

# Installation von AbhÃ¤ngigkeiten
echo "Installiere AbhÃ¤ngigkeiten ..."
install_abhaengigkeiten

# Installation von Apache2 und PHP
echo "Installiere Apache2 und PHP ..."
install_apache2_php

# Installation von MariaDB
echo "Installiere MariaDB ..."
install_mariadb $mariadb_password

# Installation von phpMyAdmin
echo "Installiere phpMyAdmin ..."
install_phpmyadmin

# Erstelle einen neuen MySQL-Nutzer
echo "Erstelle neuen MySQL-Adminuser"
create_mysql_user

# Installation von WordPress
echo "Installiere Wordpress"
install_wordpress

# Erstelle einen neuen MySQL-Nutzer für WordPress
create_mysql_wordpress_user

# Erstelle die Datenbank "wordpress" und weise dem Nutzer "wordpress" alle Rechte zu
create_mysql_wordpress_database

# Installation von Nextcloud
echo "Installiere Nextcloud ..."
install_nextcloud

# Erstelle einen neuen MySQL-Nutzer für Nextcloud
create_nextcloud_mysql_user

# Erstelle die Nextcloud-Datenbank
create_nextcloud_mysql_database

echo "Installiere Let's Encrypt (certbot) ..."
install_certbot

echo "Konfiguriere SSL/TLS-Zertifikat für die Domain $domain_name..."
configure_ssl_certificate $domain_name $email_address

# Erstelle den Cron-Job für die Zertifikatserneuerung
echo "Erstelle Cron-Job für Zertifikatserneuerung alle 80 Tage ..."
setup_certbot_renewal_cronjob

# Erstelle den Cron-Job für automatische Updates
echo "Erstelle Cron-Job für automatische Updates einmal pro Woche ..."
setup_auto_updates_cronjob

# Ende
finish_install