#!/bin/bash

# ArgoCD Deployment Script for SSO Demo
# This script helps deploy and troubleshoot the SSO application on ArgoCD

set -e

NAMESPACE="sso-demo"
ARGOCD_NAMESPACE="argocd"
APP_NAME="sso-demo-app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    print_success "kubectl is available"
}

# Function to check if ArgoCD is installed
check_argocd() {
    if ! kubectl get namespace $ARGOCD_NAMESPACE &> /dev/null; then
        print_error "ArgoCD namespace not found. Please install ArgoCD first."
        exit 1
    fi
    
    if ! kubectl get pods -n $ARGOCD_NAMESPACE | grep -q "argocd-server"; then
        print_error "ArgoCD server is not running"
        exit 1
    fi
    
    print_success "ArgoCD is installed and running"
}

# Function to validate YAML files
validate_yaml() {
    print_status "Validating YAML files..."
    
    local yaml_dir="SSO-main/k8s"
    
    if [ ! -d "$yaml_dir" ]; then
        print_error "YAML directory not found: $yaml_dir"
        exit 1
    fi
    
    # Validate each YAML file
    for file in "$yaml_dir"/*.yaml; do
        if [ -f "$file" ]; then
            print_status "Validating $(basename "$file")..."
            kubectl apply --dry-run=client -f "$file" > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                print_success "$(basename "$file") is valid"
            else
                print_error "$(basename "$file") has validation errors"
                kubectl apply --dry-run=client -f "$file"
                exit 1
            fi
        fi
    done
    
    print_success "All YAML files are valid"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if namespace exists
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        print_warning "Namespace $NAMESPACE already exists"
    else
        print_status "Creating namespace $NAMESPACE..."
        kubectl create namespace $NAMESPACE
        print_success "Namespace $NAMESPACE created"
    fi
    
    # Check if secrets exist
    if kubectl get secret mysql-secret -n $NAMESPACE &> /dev/null; then
        print_success "MySQL secret exists"
    else
        print_warning "MySQL secret not found. Creating..."
        kubectl apply -f SSO-main/k8s/mysql-secret.yaml
    fi
    
    if kubectl get secret keycloak-secret -n $NAMESPACE &> /dev/null; then
        print_success "Keycloak secret exists"
    else
        print_warning "Keycloak secret not found. Creating..."
        kubectl apply -f SSO-main/k8s/keycloak-secret.yaml
    fi
}

# Function to deploy ArgoCD application
deploy_argocd_app() {
    print_status "Deploying ArgoCD application..."
    
    # Check if application already exists
    if kubectl get application $APP_NAME -n $ARGOCD_NAMESPACE &> /dev/null; then
        print_warning "ArgoCD application $APP_NAME already exists"
        read -p "Do you want to update it? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            kubectl apply -f SSO-main/sso-argocd-app.yaml
            print_success "ArgoCD application updated"
        else
            print_status "Skipping ArgoCD application update"
        fi
    else
        kubectl apply -f SSO-main/sso-argocd-app.yaml
        print_success "ArgoCD application created"
    fi
}

# Function to monitor deployment
monitor_deployment() {
    print_status "Monitoring deployment progress..."
    
    # Wait for ArgoCD to sync
    print_status "Waiting for ArgoCD sync..."
    kubectl wait --for=condition=Synced application/$APP_NAME -n $ARGOCD_NAMESPACE --timeout=300s
    
    # Monitor pods
    print_status "Monitoring pods..."
    
    # MySQL
    print_status "Waiting for MySQL to be ready..."
    kubectl wait --for=condition=ready pod -l app=mysql -n $NAMESPACE --timeout=300s
    print_success "MySQL is ready"
    
    # Keycloak
    print_status "Waiting for Keycloak to be ready..."
    kubectl wait --for=condition=ready pod -l app=keycloak -n $NAMESPACE --timeout=300s
    print_success "Keycloak is ready"
    
    # Spring Boot
    print_status "Waiting for Spring Boot to be ready..."
    kubectl wait --for=condition=ready pod -l app=spring-app -n $NAMESPACE --timeout=300s
    print_success "Spring Boot is ready"
}

# Function to check application health
check_health() {
    print_status "Checking application health..."
    
    # Check MySQL
    local mysql_pod=$(kubectl get pods -l app=mysql -n $NAMESPACE -o jsonpath='{.items[0].metadata.name}')
    if kubectl exec $mysql_pod -n $NAMESPACE -- mysqladmin ping -h localhost &> /dev/null; then
        print_success "MySQL is healthy"
    else
        print_error "MySQL health check failed"
        return 1
    fi
    
    # Check Keycloak
    if kubectl get pods -l app=keycloak -n $NAMESPACE | grep -q "Running"; then
        print_success "Keycloak is running"
    else
        print_error "Keycloak is not running"
        return 1
    fi
    
    # Check Spring Boot
    if kubectl get pods -l app=spring-app -n $NAMESPACE | grep -q "Running"; then
        print_success "Spring Boot is running"
    else
        print_error "Spring Boot is not running"
        return 1
    fi
}

# Function to show application status
show_status() {
    print_status "Application Status:"
    echo
    
    print_status "Pods:"
    kubectl get pods -n $NAMESPACE
    echo
    
    print_status "Services:"
    kubectl get services -n $NAMESPACE
    echo
    
    print_status "Ingress:"
    kubectl get ingress -n $NAMESPACE
    echo
    
    print_status "ArgoCD Application:"
    kubectl get application $APP_NAME -n $ARGOCD_NAMESPACE
    echo
    
    print_status "Application Health:"
    kubectl get application $APP_NAME -n $ARGOCD_NAMESPACE -o jsonpath='{.status.health.status}'
    echo
}

# Function to show logs
show_logs() {
    local component=$1
    
    case $component in
        mysql)
            print_status "MySQL logs:"
            kubectl logs -l app=mysql -n $NAMESPACE --tail=50
            ;;
        keycloak)
            print_status "Keycloak logs:"
            kubectl logs -l app=keycloak -n $NAMESPACE --tail=50
            ;;
        spring)
            print_status "Spring Boot logs:"
            kubectl logs -l app=spring-app -n $NAMESPACE --tail=50
            ;;
        all)
            show_logs mysql
            echo
            show_logs keycloak
            echo
            show_logs spring
            ;;
        *)
            print_error "Invalid component. Use: mysql, keycloak, spring, or all"
            ;;
    esac
}

# Function to troubleshoot
troubleshoot() {
    print_status "Running troubleshooting checks..."
    
    # Check events
    print_status "Recent events:"
    kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' --tail=10
    echo
    
    # Check resource usage
    print_status "Resource usage:"
    kubectl top pods -n $NAMESPACE 2>/dev/null || print_warning "Metrics server not available"
    echo
    
    # Check ArgoCD sync status
    print_status "ArgoCD sync status:"
    kubectl get application $APP_NAME -n $ARGOCD_NAMESPACE -o jsonpath='{.status.sync.status}'
    echo
    
    # Check for failed pods
    local failed_pods=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase=Failed -o name)
    if [ -n "$failed_pods" ]; then
        print_error "Failed pods found:"
        echo "$failed_pods"
        echo
        print_status "Pod descriptions:"
        for pod in $failed_pods; do
            kubectl describe $pod -n $NAMESPACE
        done
    else
        print_success "No failed pods found"
    fi
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up..."
    
    read -p "Are you sure you want to delete the application? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl delete application $APP_NAME -n $ARGOCD_NAMESPACE
        print_success "ArgoCD application deleted"
        
        read -p "Do you want to delete the namespace as well? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            kubectl delete namespace $NAMESPACE
            print_success "Namespace deleted"
        fi
    else
        print_status "Cleanup cancelled"
    fi
}

# Main function
main() {
    local action=${1:-deploy}
    
    case $action in
        deploy)
            print_status "Starting deployment..."
            check_kubectl
            check_argocd
            validate_yaml
            check_prerequisites
            deploy_argocd_app
            monitor_deployment
            check_health
            show_status
            print_success "Deployment completed successfully!"
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs ${2:-all}
            ;;
        troubleshoot)
            troubleshoot
            ;;
        cleanup)
            cleanup
            ;;
        *)
            echo "Usage: $0 {deploy|status|logs|troubleshoot|cleanup}"
            echo
            echo "Commands:"
            echo "  deploy       - Deploy the application to ArgoCD"
            echo "  status       - Show application status"
            echo "  logs [comp]  - Show logs (mysql|keycloak|spring|all)"
            echo "  troubleshoot - Run troubleshooting checks"
            echo "  cleanup      - Clean up the application"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
