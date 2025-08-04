# Automatisiertes Setup-Skript für Debian 12 für Apache2, PHP, MariaDB, phpmyadmin, WordPress, Nextcloud, Lets Encrypt,…

Dieses Bash-Skript installiert und konfiguriert eine vollständige LAMP-Stack-Umgebung (Apache, MariaDB, PHP) auf einem Debian 12-Server. Es installiert außerdem phpMyAdmin, WordPress und Nextcloud, richtet SSL-Zertifikate mit Let's Encrypt ein und erstellt automatisierte Cronjobs für Updates und Zertifikatserneuerung.

## Features

### Debian 12 Erkennung
Das Skript prüft, ob Debian 12 verwendet wird, bevor es fortfährt.

### Automatische Paketquellen-Aktualisierung
Setzt die passenden Debian 12 Repositories und führt ein Systemupdate durch.

### Apache & PHP Installation
Installiert Apache2 und alle benötigten PHP-Erweiterungen.

### MariaDB Installation & Konfiguration
Installiert MariaDB, sichert die Installation und erstellt Benutzer für WordPress & Nextcloud.

### phpMyAdmin Installation
Lädt phpMyAdmin herunter und konfiguriert es für den Apache-Server.

### WordPress & Nextcloud Installation
Automatische Installation und Datenbankeinrichtung für beide Plattformen.

### SSL-Zertifikat mit Let's Encrypt
Automatisches Erstellen und Konfigurieren von SSL-Zertifikaten für eine sichere HTTPS-Verbindung.

### Cronjobs für Wartung
Automatische Einrichtung von Cronjobs für Systemupdates und SSL-Zertifikatserneuerung.

## Voraussetzungen
- Ein frisches Debian 12 System
- Root-Zugriff
- Eine registrierte Domain für das SSL-Zertifikat

## Installation & Nutzung

1. Lade das Skript herunter:
   ```bash
   wget https://github.com/kanuracer/linuxscripts/tree/main/debian12/autoinstallscripts/webstuff/autoinstall_de.sh
   chmod +x autoinstall_de.sh
   ```

2. Führe das Skript als Root aus:
   ```bash
   sudo ./autoinstall_de.sh
   ```

3. Folge den Anweisungen zur Eingabe von:
   - MariaDB Root-Passwort
   - phpMyAdmin-Version
   - E-Mail für Let's Encrypt
   - Domain-Name

## Nach der Installation

Nach erfolgreicher Ausführung sind folgende Dienste eingerichtet:

- **phpMyAdmin**: `https://yourdomain.com/phpmyadmin`
- **WordPress**: `https://yourdomain.com`
- **Nextcloud**: `https://yourdomain.com/nextcloud`

Datenbank-Benutzer und Passwörter werden während des Setups automatisch generiert und im Terminal angezeigt.


---

# Automated Setup Script for Debian 12

This Bash script installs and configures a full LAMP stack environment (Apache, MariaDB, PHP) on a Debian 12 server. It also installs phpMyAdmin, WordPress, and Nextcloud, sets up SSL certificates with Let's Encrypt, and creates automated cron jobs for updates and certificate renewal.

## Features

### Debian 12 Detection
The script checks if Debian 12 is in use before proceeding.

### Automatic Repository Update
Configures the correct Debian 12 repositories and updates the system.

### Apache & PHP Installation
Installs Apache2 and all necessary PHP extensions.

### MariaDB Installation & Configuration
Installs MariaDB, secures the installation, and creates users for WordPress & Nextcloud.

### phpMyAdmin Installation
Downloads and configures phpMyAdmin for Apache.

### WordPress & Nextcloud Installation
Automatic installation and database setup for both platforms.

### SSL Certificate with Let's Encrypt
Automatically generates and configures SSL certificates for secure HTTPS connections.

### Maintenance Cron Jobs
Automatically sets up cron jobs for system updates and SSL certificate renewal.

## Requirements
- A fresh Debian 12 system
- Root access
- A registered domain for the SSL certificate

## Installation & Usage

1. Download the script:
   ```bash
   wget https://github.com/kanuracer/linuxscripts/tree/main/debian12/autoinstallscripts/webstuff/autoinstall_en.sh
   chmod +x autoinstall_en.sh
   ```

2. Run the script as root:
   ```bash
   sudo ./autoinstall_en.sh
   ```

3. Follow the prompts to enter:
   - MariaDB root password
   - phpMyAdmin version
   - Email for Let's Encrypt
   - Domain name

## After Installation

Once successfully executed, the following services are set up:

- **phpMyAdmin**: `https://yourdomain.com/phpmyadmin`
- **WordPress**: `https://yourdomain.com`
- **Nextcloud**: `https://yourdomain.com/nextcloud`

Database users and passwords are automatically generated during setup and displayed in the terminal.


