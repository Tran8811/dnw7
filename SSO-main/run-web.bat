@echo off
echo ========================================
echo    SSO Web Application Quick Start
echo ========================================
echo.

:menu
echo Chon phuong phap chay:
echo 1. Docker Compose (Khong nghien)
echo 2. Local Development
echo 3. Kubernetes/ArgoCD
echo 4. Kiem tra trang thai
echo 5. Xem logs
echo 6. Dung services
echo 7. Thoat
echo.

set /p choice="Nhap lua chon (1-7): "

if "%choice%"=="1" goto docker
if "%choice%"=="2" goto local
if "%choice%"=="3" goto k8s
if "%choice%"=="4" goto status
if "%choice%"=="5" goto logs
if "%choice%"=="6" goto stop
if "%choice%"=="7" goto exit
goto menu

:docker
echo.
echo [INFO] Khoi dong voi Docker Compose...
cd SSO-main\demo1
docker-compose -f docker-compose-full.yml up -d
echo.
echo [SUCCESS] Da khoi dong thanh cong!
echo.
echo Truy cap ung dung:
echo   Spring Boot: http://localhost:8081
echo   Keycloak:    http://localhost:8080 (admin/admin123)
echo.
pause
goto menu

:local
echo.
echo [INFO] Khoi dong Local Development...
cd SSO-main\demo1
echo Dang khoi dong MySQL va Keycloak...
docker-compose up mysql keycloak -d
echo Dang khoi dong Spring Boot...
mvn spring-boot:run
pause
goto menu

:k8s
echo.
echo [INFO] Deploy len Kubernetes...
cd SSO-main\k8s
powershell -ExecutionPolicy Bypass -File .\argocd-deploy.ps1 deploy
pause
goto menu

:status
echo.
echo [INFO] Kiem tra trang thai...
cd SSO-main\demo1
echo.
echo Docker Containers:
docker-compose -f docker-compose-full.yml ps
echo.
echo Kiem tra services:
powershell -Command "try { Invoke-WebRequest -Uri 'http://localhost:8081/actuator/health' -TimeoutSec 5 | Out-Null; Write-Host 'Spring Boot: OK' -ForegroundColor Green } catch { Write-Host 'Spring Boot: Not responding' -ForegroundColor Red }"
powershell -Command "try { Invoke-WebRequest -Uri 'http://localhost:8080/realms/master' -TimeoutSec 5 | Out-Null; Write-Host 'Keycloak: OK' -ForegroundColor Green } catch { Write-Host 'Keycloak: Not responding' -ForegroundColor Red }"
pause
goto menu

:logs
echo.
echo [INFO] Hien thi logs...
cd SSO-main\demo1
echo.
echo Chon service:
echo 1. Tat ca
echo 2. MySQL
echo 3. Keycloak
echo 4. Spring Boot
echo.
set /p logchoice="Nhap lua chon (1-4): "

if "%logchoice%"=="1" docker-compose -f docker-compose-full.yml logs -f
if "%logchoice%"=="2" docker-compose -f docker-compose-full.yml logs -f mysql
if "%logchoice%"=="3" docker-compose -f docker-compose-full.yml logs -f keycloak
if "%logchoice%"=="4" docker-compose -f docker-compose-full.yml logs -f spring-app
pause
goto menu

:stop
echo.
echo [INFO] Dung tat ca services...
cd SSO-main\demo1
docker-compose -f docker-compose-full.yml down
echo [SUCCESS] Da dung thanh cong!
pause
goto menu

:exit
echo.
echo Cam on ban da su dung!
pause
exit
