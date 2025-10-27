# Script để chạy SSO Web Application
# Sử dụng: .\run-web.ps1 [command]

param(
    [Parameter(Position=0)]
    [ValidateSet("docker", "local", "k8s", "stop", "logs", "status", "setup")]
    [string]$Command = "docker"
)

$ProjectRoot = "SSO-main\demo1"

# Colors
function Write-Info { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Blue }
function Write-Success { param($msg) Write-Host "[SUCCESS] $msg" -ForegroundColor Green }
function Write-Warning { param($msg) Write-Host "[WARNING] $msg" -ForegroundColor Yellow }
function Write-Error { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }

# Function to check Docker
function Test-Docker {
    try {
        docker --version | Out-Null
        docker-compose --version | Out-Null
        Write-Success "Docker và Docker Compose đã sẵn sàng"
        return $true
    }
    catch {
        Write-Error "Docker hoặc Docker Compose chưa được cài đặt"
        Write-Host "Vui lòng cài đặt Docker Desktop từ: https://www.docker.com/products/docker-desktop"
        return $false
    }
}

# Function to check Java
function Test-Java {
    try {
        $javaVersion = java -version 2>&1 | Select-String "version"
        Write-Success "Java đã sẵn sàng: $javaVersion"
        return $true
    }
    catch {
        Write-Warning "Java chưa được cài đặt hoặc không có trong PATH"
        return $false
    }
}

# Function to check Maven
function Test-Maven {
    try {
        mvn --version | Out-Null
        Write-Success "Maven đã sẵn sàng"
        return $true
    }
    catch {
        Write-Warning "Maven chưa được cài đặt hoặc không có trong PATH"
        return $false
    }
}

# Function to run with Docker Compose
function Start-DockerCompose {
    Write-Info "🚀 Khởi động SSO Application với Docker Compose..."
    
    if (-not (Test-Docker)) { return }
    
    Set-Location $ProjectRoot
    
    Write-Info "Đang khởi động MySQL..."
    docker-compose -f docker-compose-full.yml up mysql -d
    
    Write-Info "Đang khởi động Keycloak..."
    docker-compose -f docker-compose-full.yml up keycloak -d
    
    Write-Info "Đang khởi động Spring Boot..."
    docker-compose -f docker-compose-full.yml up spring-app -d
    
    Write-Success "✅ Tất cả services đã được khởi động!"
    Write-Host ""
    Write-Host "🌐 Truy cập ứng dụng:"
    Write-Host "   Spring Boot App: http://localhost:8081"
    Write-Host "   Keycloak Admin:  http://localhost:8080 (admin/admin123)"
    Write-Host ""
    Write-Host "📋 Để xem logs: .\run-web.ps1 logs"
    Write-Host "📋 Để dừng: .\run-web.ps1 stop"
}

# Function to run locally
function Start-Local {
    Write-Info "🚀 Khởi động SSO Application local development..."
    
    if (-not (Test-Java)) { 
        Write-Error "Cần Java để chạy local development"
        return 
    }
    
    if (-not (Test-Maven)) { 
        Write-Error "Cần Maven để chạy local development"
        return 
    }
    
    Set-Location $ProjectRoot
    
    Write-Info "Đang khởi động MySQL và Keycloak với Docker..."
    docker-compose up mysql keycloak -d
    
    Write-Info "Đang khởi động Spring Boot với Maven..."
    mvn spring-boot:run
}

# Function to run on Kubernetes
function Start-Kubernetes {
    Write-Info "🚀 Deploy SSO Application lên Kubernetes với ArgoCD..."
    
    Set-Location "SSO-main\k8s"
    
    if (Test-Path ".\argocd-deploy.ps1") {
        .\argocd-deploy.ps1 deploy
    } else {
        Write-Error "Script ArgoCD không tìm thấy"
    }
}

# Function to stop services
function Stop-Services {
    Write-Info "🛑 Dừng tất cả services..."
    
    Set-Location $ProjectRoot
    
    Write-Info "Dừng Docker Compose services..."
    docker-compose -f docker-compose-full.yml down
    
    Write-Success "✅ Tất cả services đã được dừng"
}

# Function to show logs
function Show-Logs {
    Write-Info "📋 Hiển thị logs..."
    
    Set-Location $ProjectRoot
    
    Write-Host "Chọn service để xem logs:"
    Write-Host "1. Tất cả services"
    Write-Host "2. MySQL"
    Write-Host "3. Keycloak"
    Write-Host "4. Spring Boot"
    
    $choice = Read-Host "Nhập lựa chọn (1-4)"
    
    switch ($choice) {
        "1" { docker-compose -f docker-compose-full.yml logs -f }
        "2" { docker-compose -f docker-compose-full.yml logs -f mysql }
        "3" { docker-compose -f docker-compose-full.yml logs -f keycloak }
        "4" { docker-compose -f docker-compose-full.yml logs -f spring-app }
        default { Write-Error "Lựa chọn không hợp lệ" }
    }
}

# Function to show status
function Show-Status {
    Write-Info "📊 Trạng thái services..."
    
    Set-Location $ProjectRoot
    
    Write-Host "🐳 Docker Containers:"
    docker-compose -f docker-compose-full.yml ps
    
    Write-Host ""
    Write-Host "🌐 Services Status:"
    
    # Check Spring Boot
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8081/actuator/health" -TimeoutSec 5
        Write-Success "Spring Boot: ✅ Running (http://localhost:8081)"
    }
    catch {
        Write-Warning "Spring Boot: ❌ Not responding"
    }
    
    # Check Keycloak
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/realms/master" -TimeoutSec 5
        Write-Success "Keycloak: ✅ Running (http://localhost:8080)"
    }
    catch {
        Write-Warning "Keycloak: ❌ Not responding"
    }
    
    # Check MySQL
    $mysqlContainer = docker ps --filter "name=demo1_mysql" --format "{{.Status}}"
    if ($mysqlContainer) {
        Write-Success "MySQL: ✅ $mysqlContainer"
    } else {
        Write-Warning "MySQL: ❌ Not running"
    }
}

# Function to setup environment
function Initialize-Setup {
    Write-Info "🔧 Thiết lập môi trường..."
    
    # Check Docker
    if (Test-Docker) {
        Write-Success "✅ Docker: OK"
    } else {
        Write-Error "❌ Docker: Cần cài đặt"
    }
    
    # Check Java
    if (Test-Java) {
        Write-Success "✅ Java: OK"
    } else {
        Write-Warning "⚠️ Java: Cần cài đặt cho local development"
    }
    
    # Check Maven
    if (Test-Maven) {
        Write-Success "✅ Maven: OK"
    } else {
        Write-Warning "⚠️ Maven: Cần cài đặt cho local development"
    }
    
    # Check kubectl
    try {
        kubectl version --client | Out-Null
        Write-Success "✅ kubectl: OK"
    }
    catch {
        Write-Warning "⚠️ kubectl: Cần cài đặt cho Kubernetes deployment"
    }
    
    Write-Host ""
    Write-Host "📋 Hướng dẫn cài đặt:"
    Write-Host "1. Docker Desktop: https://www.docker.com/products/docker-desktop"
    Write-Host "2. Java 17+: https://adoptium.net/"
    Write-Host "3. Maven: https://maven.apache.org/download.cgi"
    Write-Host "4. kubectl: https://kubernetes.io/docs/tasks/tools/"
}

# Main function
function Main {
    Write-Host "🎯 SSO Web Application Runner" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host ""
    
    switch ($Command) {
        "docker" {
            Start-DockerCompose
        }
        "local" {
            Start-Local
        }
        "k8s" {
            Start-Kubernetes
        }
        "stop" {
            Stop-Services
        }
        "logs" {
            Show-Logs
        }
        "status" {
            Show-Status
        }
        "setup" {
            Initialize-Setup
        }
        default {
            Write-Host "Usage: .\run-web.ps1 [command]"
            Write-Host ""
            Write-Host "Commands:"
            Write-Host "  docker  - Chạy với Docker Compose (khuyến nghị)"
            Write-Host "  local   - Chạy local development"
            Write-Host "  k8s     - Deploy lên Kubernetes"
            Write-Host "  stop    - Dừng tất cả services"
            Write-Host "  logs    - Xem logs"
            Write-Host "  status  - Kiểm tra trạng thái"
            Write-Host "  setup   - Kiểm tra môi trường"
            Write-Host ""
            Write-Host "Examples:"
            Write-Host "  .\run-web.ps1 docker    # Chạy với Docker"
            Write-Host "  .\run-web.ps1 status   # Kiểm tra trạng thái"
            Write-Host "  .\run-web.ps1 logs     # Xem logs"
        }
    }
}

# Run main function
Main
