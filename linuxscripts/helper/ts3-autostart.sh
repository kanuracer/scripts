#!/bin/bash

# Farbige Ausgaben
log_cyan()   { echo -e "\033[36;1m$@\033[0m"; }
log_red()    { echo -e "\033[31;1m$@\033[0m"; }
log_green()  { echo -e "\033[32;1m$@\033[0m"; }

# Prüfen ob Verzeichnisargument übergeben wurde
if [ -z "$1" ]; then
    echo "Usage: ./Teamspeak3_Autostart.sh [TeamSpeak 3 Verzeichnis]"
    exit 1
fi

log_cyan "Fehlende Pakete werden gesucht und installiert..."
sleep 2
sudo apt-get install -y cron-apt
sleep 2
clear
sleep 1

log_green "______________________________________________"
log_green "**********************************************"
log_green ""
log_green "TeamSpeak 3 Verzeichnis: $1"
log_green ""
log_green "AUTOSTART: ACTIVE"