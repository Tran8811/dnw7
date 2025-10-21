# SSO Demo - Kubernetes Deployment

This directory contains Kubernetes manifests for deploying the Spring Boot SSO application with MySQL and Keycloak.

## Architecture

The deployment includes:
- **MySQL**: Database for Keycloak
- **Keycloak**: SSO provider
- **Spring Boot App**: Web application with OAuth2/OIDC integration
- **Ingress**: External access routing

## Prerequisites

- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl configured to access your cluster
- Docker installed for building the Spring Boot application image

## Quick Start

1. **Deploy the application:**
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

2. **Access the application:**
   - Add `127.0.0.1 sso-demo.local` to your `/etc/hosts` file
   - Open http://sso-demo.local in your browser
   - Keycloak admin console: http://sso-demo.local/keycloak

3. **Keycloak Setup:**
   - Username: `admin`
   - Password: `admin123`
   - Create a realm named `demo-realm`
   - Create a client named `spring-boot-oidc` with client secret `oOb2WhVNBSGxd7cgpq1bxrY3Qlrr1O1L`

## Manual Deployment

If you prefer to deploy manually:

```bash
# Create namespace
kubectl apply -f namespace.yaml

# Create secrets
kubectl apply -f mysql-secret.yaml
kubectl apply -f keycloak-secret.yaml

# Create configmaps
kubectl apply -f mysql-configmap.yaml
kubectl apply -f spring-app-configmap.yaml

# Deploy MySQL
kubectl apply -f mysql-deployment.yaml

# Wait for MySQL to be ready
kubectl wait --for=condition=ready pod -l app=mysql -n sso-demo --timeout=300s

# Deploy Keycloak
kubectl apply -f keycloak-deployment.yaml

# Wait for Keycloak to be ready
kubectl wait --for=condition=ready pod -l app=keycloak -n sso-demo --timeout=300s

# Build Spring Boot image
cd ../demo1
docker build -t spring-boot-sso-demo:latest .

# Deploy Spring Boot application
cd ../k8s
kubectl apply -f spring-app-deployment.yaml

# Deploy Ingress
kubectl apply -f ingress.yaml
```

## Cleanup

To remove all resources:

```bash
chmod +x undeploy.sh
./undeploy.sh
```

Or manually:
```bash
kubectl delete namespace sso-demo
```

## Configuration

### Secrets

- `mysql-secret.yaml`: MySQL root password and app user password
- `keycloak-secret.yaml`: Keycloak admin password

### ConfigMaps

- `mysql-configmap.yaml`: MySQL database and user configuration
- `spring-app-configmap.yaml`: Spring Boot application configuration

### Services

- `mysql`: Internal MySQL service (port 3306)
- `keycloak`: Keycloak service (port 8080)
- `spring-app`: Spring Boot application service (port 8081)

### Ingress

- Routes `/` to Spring Boot application
- Routes `/keycloak` to Keycloak admin console

## Monitoring

Check the status of your deployment:

```bash
# Check pods
kubectl get pods -n sso-demo

# Check services
kubectl get services -n sso-demo

# Check ingress
kubectl get ingress -n sso-demo

# View logs
kubectl logs -f deployment/spring-app -n sso-demo
kubectl logs -f deployment/keycloak -n sso-demo
kubectl logs -f deployment/mysql -n sso-demo
```

## Troubleshooting

1. **Pods not starting:**
   ```bash
   kubectl describe pod <pod-name> -n sso-demo
   ```

2. **Service not accessible:**
   ```bash
   kubectl get endpoints -n sso-demo
   ```

3. **Ingress not working:**
   - Ensure you have an ingress controller installed
   - Check if the hostname is correctly configured in your hosts file

4. **Database connection issues:**
   - Verify MySQL is running and accessible
   - Check Keycloak logs for database connection errors

## Scaling

To scale the Spring Boot application:

```bash
kubectl scale deployment spring-app --replicas=3 -n sso-demo
```

## Security Notes

- This is a demo setup with default passwords
- In production, use proper secrets management
- Enable TLS/SSL for all services
- Use proper RBAC configurations
- Consider using a service mesh for enhanced security



