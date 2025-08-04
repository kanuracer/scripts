:start
@echo off
cls
echo .
echo -----------------------------------------------------
echo regedit kontextmenue
echo kanuracer.eu
echo -----------------------------------------------------
echo .
echo regedit...
echo .
reg add "HKEY_CURRENT_USER\SOFTWARE\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
echo .
echo -----------------------------------------------------
echo Der Rechner muss neu gestartet werden!
echo Druecke eine beliebige Taste zum neustarten
echo -----------------------------------------------------
echo .
pause
shutdown -r -t 0