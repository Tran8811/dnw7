# PowerShell script triển khai CourseTracker lên Kubernetes của Docker Desktop

Write-Host "🚀 Bắt đầu triển khai CourseTracker lên Kubernetes..." -ForegroundColor Green

# Kiểm tra Docker Desktop có chạy không
Write-Host "📋 Kiểm tra Docker Desktop..." -ForegroundColor Yellow
try {
    docker info | Out-Null
    Write-Host "✅ Docker Desktop đang chạy" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker Desktop chưa chạy. Vui lòng khởi động Docker Desktop trước." -ForegroundColor Red
    exit 1
}

# Kiểm tra Kubernetes có enabled không
Write-Host "📋 Kiểm tra Kubernetes..." -ForegroundColor Yellow
try {
    kubectl cluster-info | Out-Null
    Write-Host "✅ Kubernetes đã được enable" -ForegroundColor Green
} catch {
    Write-Host "❌ Kubernetes chưa được enable trong Docker Desktop. Vui lòng enable Kubernetes trong Docker Desktop settings." -ForegroundColor Red
    exit 1
}

# Build Docker image
Write-Host "🔨 Building Docker image..." -ForegroundColor Yellow
Set-Location demo1
docker build -t coursetracker:latest .
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Lỗi khi build Docker image" -ForegroundColor Red
    exit 1
}
Set-Location ..

# Apply Kubernetes manifests
Write-Host "📦 Triển khai lên Kubernetes..." -ForegroundColor Yellow

Write-Host "  - Triển khai tất cả resources..." -ForegroundColor Cyan
kubectl apply -k k8s/

# Chờ deployment ready
Write-Host "⏳ Chờ deployment sẵn sàng..." -ForegroundColor Yellow
kubectl wait --for=condition=available --timeout=300s deployment/coursetracker-app

# Hiển thị thông tin truy cập
Write-Host ""
Write-Host "✅ Triển khai thành công!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Thông tin truy cập:" -ForegroundColor Cyan
Write-Host "  - Local URL: http://localhost:30080" -ForegroundColor White
Write-Host "  - H2 Console: http://localhost:30080/h2-console" -ForegroundColor White
Write-Host ""
Write-Host "📋 Các lệnh hữu ích:" -ForegroundColor Cyan
Write-Host "  - Xem pods: kubectl get pods" -ForegroundColor White
Write-Host "  - Xem services: kubectl get services" -ForegroundColor White
Write-Host "  - Xem logs: kubectl logs -f deployment/coursetracker-app" -ForegroundColor White
Write-Host "  - Scale deployment: kubectl scale deployment coursetracker-app --replicas=3" -ForegroundColor White
Write-Host ""
Write-Host "🗑️  Để xóa deployment: .\undeploy.ps1" -ForegroundColor Yellow
