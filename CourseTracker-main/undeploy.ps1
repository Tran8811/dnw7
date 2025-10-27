# PowerShell script xóa CourseTracker khỏi Kubernetes

Write-Host "🗑️  Xóa CourseTracker khỏi Kubernetes..." -ForegroundColor Red

# Xóa các resources
Write-Host "  - Xóa tất cả resources..." -ForegroundColor Yellow
kubectl delete -k k8s/

Write-Host ""
Write-Host "✅ Đã xóa thành công tất cả resources!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Kiểm tra lại:" -ForegroundColor Cyan
Write-Host "  - kubectl get pods" -ForegroundColor White
Write-Host "  - kubectl get services" -ForegroundColor White
Write-Host "  - kubectl get pv" -ForegroundColor White
Write-Host "  - kubectl get pvc" -ForegroundColor White
Write-Host "  - kubectl get configmap" -ForegroundColor White
