# Deploy SSO Demo to Kubernetes
Write-Host "Deploying SSO Demo to Kubernetes..." -ForegroundColor Green

# Create namespace
Write-Host "Creating namespace..." -ForegroundColor Yellow
kubectl apply -f namespace.yaml

# Create secrets
Write-Host "Creating secrets..." -ForegroundColor Yellow
kubectl apply -f mysql-secret.yaml
kubectl apply -f keycloak-secret.yaml

# Create configmaps
Write-Host "Creating configmaps..." -ForegroundColor Yellow
kubectl apply -f mysql-configmap.yaml
kubectl apply -f spring-app-configmap.yaml

# Deploy MySQL
Write-Host "Deploying MySQL..." -ForegroundColor Yellow
kubectl apply -f mysql-deployment.yaml

# Wait for MySQL to be ready
Write-Host "Waiting for MySQL to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=mysql -n sso-demo --timeout=300s

# Deploy Keycloak
Write-Host "Deploying Keycloak..." -ForegroundColor Yellow
kubectl apply -f keycloak-deployment.yaml

# Wait for Keycloak to be ready
Write-Host "Waiting for Keycloak to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=keycloak -n sso-demo --timeout=300s

# Build and push Spring Boot application image
Write-Host "Building Spring Boot application image..." -ForegroundColor Yellow
Set-Location ../demo1
docker build -t spring-boot-sso-demo:latest .

# Deploy Spring Boot application
Write-Host "Deploying Spring Boot application..." -ForegroundColor Yellow
Set-Location ../k8s
kubectl apply -f spring-app-deployment.yaml

# Deploy Ingress
Write-Host "Deploying Ingress..." -ForegroundColor Yellow
kubectl apply -f ingress.yaml

# Wait for Spring Boot application to be ready
Write-Host "Waiting for Spring Boot application to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=spring-app -n sso-demo --timeout=300s

Write-Host "Deployment completed!" -ForegroundColor Green
Write-Host ""
Write-Host "To access the application:" -ForegroundColor Cyan
Write-Host "1. Add '127.0.0.1 sso-demo.local' to your C:\Windows\System32\drivers\etc\hosts file" -ForegroundColor White
Write-Host "2. Access the application at: http://sso-demo.local" -ForegroundColor White
Write-Host "3. Access Keycloak admin at: http://sso-demo.local/keycloak" -ForegroundColor White
Write-Host ""
Write-Host "Keycloak admin credentials:" -ForegroundColor Cyan
Write-Host "Username: admin" -ForegroundColor White
Write-Host "Password: admin123" -ForegroundColor White
Write-Host ""
Write-Host "To check the status:" -ForegroundColor Cyan
Write-Host "kubectl get pods -n sso-demo" -ForegroundColor White
Write-Host "kubectl get services -n sso-demo" -ForegroundColor White
