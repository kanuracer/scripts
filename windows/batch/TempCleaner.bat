@echo off
echo Hallo %Username%!
echo.
echo Du benutzt gerade den Temp-Verzeichniscleaner von kanuracer.eu
echo --------------------------------------------------------------
echo Soll dein Temp-Verzeichnis bereinigt werden?
pause
call:clean %TEMP%
IF NOT "%TEMP%" == "%TMP%" (
    call:clean %TMP%
)

pause
goto:eof

:clean
    del /q "%~1\*.*"
    FOR /D %%D IN ("%~1\*") DO (
        rmdir /s /q "%%D"
    )
goto:eof