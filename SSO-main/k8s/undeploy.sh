#!/bin/bash

# Undeploy SSO Demo from Kubernetes
echo "Undeploying SSO Demo from Kubernetes..."

# Delete Ingress
echo "Deleting Ingress..."
kubectl delete -f ingress.yaml

# Delete Spring Boot application
echo "Deleting Spring Boot application..."
kubectl delete -f spring-app-deployment.yaml

# Delete Keycloak
echo "Deleting Keycloak..."
kubectl delete -f keycloak-deployment.yaml

# Delete MySQL
echo "Deleting MySQL..."
kubectl delete -f mysql-deployment.yaml

# Delete ConfigMaps
echo "Deleting ConfigMaps..."
kubectl delete -f spring-app-configmap.yaml
kubectl delete -f mysql-configmap.yaml

# Delete Secrets
echo "Deleting Secrets..."
kubectl delete -f keycloak-secret.yaml
kubectl delete -f mysql-secret.yaml

# Delete namespace (this will delete all resources in the namespace)
echo "Deleting namespace..."
kubectl delete -f namespace.yaml

echo "Undeployment completed!"



