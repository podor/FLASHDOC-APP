@echo off
echo ==========================================
echo    FLASHDOC — Connexion telephonique
echo ==========================================
echo.

:check
echo Verification des appareils connectes...
adb devices

echo.
echo Activation du tunnel sur tous les appareils...
adb -s 5f9ddcfa0404    reverse tcp:3000 tcp:3000 2>nul
adb -s 69INIFR4HI55GY7X reverse tcp:3000 tcp:3000 2>nul

echo.
echo Verification des tunnels actifs :
adb -s 5f9ddcfa0404    reverse --list
adb -s 69INIFR4HI55GY7X reverse --list

echo.
echo ==========================================
echo  IMPORTANT : A relancer a chaque fois que
echo  vous branchez ou rebranchez un telephone !
echo ==========================================
echo.
echo Appuyez sur une touche pour relancer...
pause > nul
goto check
