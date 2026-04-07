@echo off
echo ==========================================
echo    FLASHDOC — Lancement de l'environnement
echo ==========================================
echo.

echo [1/3] Activation du port forwarding USB...
adb reverse tcp:3000 tcp:3000
echo     OK - Port 3000 redirige vers le telephone

echo.
echo [2/3] Demarrage de Docker (PostgreSQL + Redis)...
cd /d D:\PROJETS\FLASHDOC-APP\backend
start "FlashDoc Docker" cmd /k "docker-compose up postgres redis"
timeout /t 5 /nobreak > nul

echo.
echo [3/3] Demarrage du backend Node.js...
start "FlashDoc Backend" cmd /k "cd /d D:\PROJETS\FLASHDOC-APP\backend && npm run dev"

echo.
echo ==========================================
echo  Environnement FlashDoc lance !
echo  Backend : http://localhost:3000/api/health
echo  Prisma Studio : npm run db:studio
echo ==========================================
pause
