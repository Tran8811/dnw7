# Check status of SSO Demo deployment
Write-Host "Checking SSO Demo deployment status..." -ForegroundColor Cyan

Write-Host "`n=== Namespace ===" -ForegroundColor Yellow
kubectl get namespace sso-demo

Write-Host "`n=== Pods ===" -ForegroundColor Yellow
kubectl get pods -n sso-demo

Write-Host "`n=== Services ===" -ForegroundColor Yellow
kubectl get services -n sso-demo

Write-Host "`n=== Ingress ===" -ForegroundColor Yellow
kubectl get ingress -n sso-demo

Write-Host "`n=== ConfigMaps ===" -ForegroundColor Yellow
kubectl get configmaps -n sso-demo

Write-Host "`n=== Secrets ===" -ForegroundColor Yellow
kubectl get secrets -n sso-demo

Write-Host "`n=== Pod Logs (last 10 lines) ===" -ForegroundColor Yellow
Write-Host "MySQL:" -ForegroundColor Green
kubectl logs -l app=mysql -n sso-demo --tail=10

Write-Host "`nKeycloak:" -ForegroundColor Green
kubectl logs -l app=keycloak -n sso-demo --tail=10

Write-Host "`nSpring App:" -ForegroundColor Green
kubectl logs -l app=spring-app -n sso-demo --tail=10
