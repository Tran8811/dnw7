#!/bin/bash

# Deploy SSO Demo to Kubernetes
echo "Deploying SSO Demo to Kubernetes..."

# Create namespace
echo "Creating namespace..."
kubectl apply -f namespace.yaml

# Create secrets
echo "Creating secrets..."
kubectl apply -f mysql-secret.yaml
kubectl apply -f keycloak-secret.yaml

# Create configmaps
echo "Creating configmaps..."
kubectl apply -f mysql-configmap.yaml
kubectl apply -f spring-app-configmap.yaml

# Deploy MySQL
echo "Deploying MySQL..."
kubectl apply -f mysql-deployment.yaml

# Wait for MySQL to be ready
echo "Waiting for MySQL to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql -n sso-demo --timeout=300s

# Deploy Keycloak
echo "Deploying Keycloak..."
kubectl apply -f keycloak-deployment.yaml

# Wait for Keycloak to be ready
echo "Waiting for Keycloak to be ready..."
kubectl wait --for=condition=ready pod -l app=keycloak -n sso-demo --timeout=300s

# Build and push Spring Boot application image
echo "Building Spring Boot application image..."
cd ../demo1
docker build -t spring-boot-sso-demo:latest .

# Deploy Spring Boot application
echo "Deploying Spring Boot application..."
cd ../k8s
kubectl apply -f spring-app-deployment.yaml

# Deploy Ingress
echo "Deploying Ingress..."
kubectl apply -f ingress.yaml

# Wait for Spring Boot application to be ready
echo "Waiting for Spring Boot application to be ready..."
kubectl wait --for=condition=ready pod -l app=spring-app -n sso-demo --timeout=300s

echo "Deployment completed!"
echo ""
echo "To access the application:"
echo "1. Add '127.0.0.1 sso-demo.local' to your /etc/hosts file"
echo "2. Access the application at: http://sso-demo.local"
echo "3. Access Keycloak admin at: http://sso-demo.local/keycloak"
echo ""
echo "Keycloak admin credentials:"
echo "Username: admin"
echo "Password: admin123"
echo ""
echo "To check the status:"
echo "kubectl get pods -n sso-demo"
echo "kubectl get services -n sso-demo"



