# Undeploy SSO Demo from Kubernetes
Write-Host "Undeploying SSO Demo from Kubernetes..." -ForegroundColor Red

# Delete Ingress
Write-Host "Deleting Ingress..." -ForegroundColor Yellow
kubectl delete -f ingress.yaml

# Delete Spring Boot application
Write-Host "Deleting Spring Boot application..." -ForegroundColor Yellow
kubectl delete -f spring-app-deployment.yaml

# Delete Keycloak
Write-Host "Deleting Keycloak..." -ForegroundColor Yellow
kubectl delete -f keycloak-deployment.yaml

# Delete MySQL
Write-Host "Deleting MySQL..." -ForegroundColor Yellow
kubectl delete -f mysql-deployment.yaml

# Delete ConfigMaps
Write-Host "Deleting ConfigMaps..." -ForegroundColor Yellow
kubectl delete -f spring-app-configmap.yaml
kubectl delete -f mysql-configmap.yaml

# Delete Secrets
Write-Host "Deleting Secrets..." -ForegroundColor Yellow
kubectl delete -f keycloak-secret.yaml
kubectl delete -f mysql-secret.yaml

# Delete namespace (this will delete all resources in the namespace)
Write-Host "Deleting namespace..." -ForegroundColor Yellow
kubectl delete -f namespace.yaml

Write-Host "Undeployment completed!" -ForegroundColor Green
