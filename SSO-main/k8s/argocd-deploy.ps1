# ArgoCD Deployment Script for SSO Demo (PowerShell)
# This script helps deploy and troubleshoot the SSO application on ArgoCD

param(
    [Parameter(Position=0)]
    [ValidateSet("deploy", "status", "logs", "troubleshoot", "cleanup")]
    [string]$Action = "deploy",
    
    [Parameter(Position=1)]
    [ValidateSet("mysql", "keycloak", "spring", "all")]
    [string]$Component = "all"
)

$NAMESPACE = "sso-demo"
$ARGOCD_NAMESPACE = "argocd"
$APP_NAME = "sso-demo-app"

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Function to check if kubectl is available
function Test-Kubectl {
    try {
        kubectl version --client | Out-Null
        Write-Success "kubectl is available"
        return $true
    }
    catch {
        Write-Error "kubectl is not installed or not in PATH"
        return $false
    }
}

# Function to check if ArgoCD is installed
function Test-ArgoCD {
    try {
        $null = kubectl get namespace $ARGOCD_NAMESPACE
        $argocdPods = kubectl get pods -n $ARGOCD_NAMESPACE -o json | ConvertFrom-Json
        $serverPod = $argocdPods.items | Where-Object { $_.metadata.name -like "*argocd-server*" }
        
        if ($serverPod) {
            Write-Success "ArgoCD is installed and running"
            return $true
        } else {
            Write-Error "ArgoCD server is not running"
            return $false
        }
    }
    catch {
        Write-Error "ArgoCD namespace not found. Please install ArgoCD first."
        return $false
    }
}

# Function to validate YAML files
function Test-YamlFiles {
    Write-Status "Validating YAML files..."
    
    $yamlDir = "SSO-main\k8s"
    
    if (-not (Test-Path $yamlDir)) {
        Write-Error "YAML directory not found: $yamlDir"
        return $false
    }
    
    $yamlFiles = Get-ChildItem -Path $yamlDir -Filter "*.yaml"
    
    foreach ($file in $yamlFiles) {
        Write-Status "Validating $($file.Name)..."
        try {
            kubectl apply --dry-run=client -f $file.FullName | Out-Null
            Write-Success "$($file.Name) is valid"
        }
        catch {
            Write-Error "$($file.Name) has validation errors"
            kubectl apply --dry-run=client -f $file.FullName
            return $false
        }
    }
    
    Write-Success "All YAML files are valid"
    return $true
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-Status "Checking prerequisites..."
    
    # Check if namespace exists
    try {
        $null = kubectl get namespace $NAMESPACE
        Write-Warning "Namespace $NAMESPACE already exists"
    }
    catch {
        Write-Status "Creating namespace $NAMESPACE..."
        kubectl create namespace $NAMESPACE
        Write-Success "Namespace $NAMESPACE created"
    }
    
    # Check if secrets exist
    try {
        $null = kubectl get secret mysql-secret -n $NAMESPACE
        Write-Success "MySQL secret exists"
    }
    catch {
        Write-Warning "MySQL secret not found. Creating..."
        kubectl apply -f "SSO-main\k8s\mysql-secret.yaml"
    }
    
    try {
        $null = kubectl get secret keycloak-secret -n $NAMESPACE
        Write-Success "Keycloak secret exists"
    }
    catch {
        Write-Warning "Keycloak secret not found. Creating..."
        kubectl apply -f "SSO-main\k8s\keycloak-secret.yaml"
    }
}

# Function to deploy ArgoCD application
function Deploy-ArgoCDApp {
    Write-Status "Deploying ArgoCD application..."
    
    try {
        $null = kubectl get application $APP_NAME -n $ARGOCD_NAMESPACE
        Write-Warning "ArgoCD application $APP_NAME already exists"
        $update = Read-Host "Do you want to update it? (y/n)"
        if ($update -eq "y" -or $update -eq "Y") {
            kubectl apply -f "SSO-main\sso-argocd-app.yaml"
            Write-Success "ArgoCD application updated"
        } else {
            Write-Status "Skipping ArgoCD application update"
        }
    }
    catch {
        kubectl apply -f "SSO-main\sso-argocd-app.yaml"
        Write-Success "ArgoCD application created"
    }
}

# Function to monitor deployment
function Watch-Deployment {
    Write-Status "Monitoring deployment progress..."
    
    # Wait for ArgoCD to sync
    Write-Status "Waiting for ArgoCD sync..."
    kubectl wait --for=condition=Synced application/$APP_NAME -n $ARGOCD_NAMESPACE --timeout=300s
    
    # Monitor pods
    Write-Status "Monitoring pods..."
    
    # MySQL
    Write-Status "Waiting for MySQL to be ready..."
    kubectl wait --for=condition=ready pod -l app=mysql -n $NAMESPACE --timeout=300s
    Write-Success "MySQL is ready"
    
    # Keycloak
    Write-Status "Waiting for Keycloak to be ready..."
    kubectl wait --for=condition=ready pod -l app=keycloak -n $NAMESPACE --timeout=300s
    Write-Success "Keycloak is ready"
    
    # Spring Boot
    Write-Status "Waiting for Spring Boot to be ready..."
    kubectl wait --for=condition=ready pod -l app=spring-app -n $NAMESPACE --timeout=300s
    Write-Success "Spring Boot is ready"
}

# Function to check application health
function Test-ApplicationHealth {
    Write-Status "Checking application health..."
    
    # Check MySQL
    $mysqlPod = kubectl get pods -l app=mysql -n $NAMESPACE -o json | ConvertFrom-Json
    if ($mysqlPod.items.Count -gt 0) {
        $podName = $mysqlPod.items[0].metadata.name
        try {
            kubectl exec $podName -n $NAMESPACE -- mysqladmin ping -h localhost | Out-Null
            Write-Success "MySQL is healthy"
        }
        catch {
            Write-Error "MySQL health check failed"
            return $false
        }
    }
    
    # Check Keycloak
    $keycloakPods = kubectl get pods -l app=keycloak -n $NAMESPACE -o json | ConvertFrom-Json
    $runningKeycloak = $keycloakPods.items | Where-Object { $_.status.phase -eq "Running" }
    if ($runningKeycloak) {
        Write-Success "Keycloak is running"
    } else {
        Write-Error "Keycloak is not running"
        return $false
    }
    
    # Check Spring Boot
    $springPods = kubectl get pods -l app=spring-app -n $NAMESPACE -o json | ConvertFrom-Json
    $runningSpring = $springPods.items | Where-Object { $_.status.phase -eq "Running" }
    if ($runningSpring) {
        Write-Success "Spring Boot is running"
    } else {
        Write-Error "Spring Boot is not running"
        return $false
    }
    
    return $true
}

# Function to show application status
function Show-Status {
    Write-Status "Application Status:"
    Write-Host ""
    
    Write-Status "Pods:"
    kubectl get pods -n $NAMESPACE
    Write-Host ""
    
    Write-Status "Services:"
    kubectl get services -n $NAMESPACE
    Write-Host ""
    
    Write-Status "Ingress:"
    kubectl get ingress -n $NAMESPACE
    Write-Host ""
    
    Write-Status "ArgoCD Application:"
    kubectl get application $APP_NAME -n $ARGOCD_NAMESPACE
    Write-Host ""
    
    Write-Status "Application Health:"
    $health = kubectl get application $APP_NAME -n $ARGOCD_NAMESPACE -o jsonpath='{.status.health.status}'
    Write-Host $health
    Write-Host ""
}

# Function to show logs
function Show-Logs {
    param([string]$Comp = "all")
    
    switch ($Comp) {
        "mysql" {
            Write-Status "MySQL logs:"
            kubectl logs -l app=mysql -n $NAMESPACE --tail=50
        }
        "keycloak" {
            Write-Status "Keycloak logs:"
            kubectl logs -l app=keycloak -n $NAMESPACE --tail=50
        }
        "spring" {
            Write-Status "Spring Boot logs:"
            kubectl logs -l app=spring-app -n $NAMESPACE --tail=50
        }
        "all" {
            Show-Logs "mysql"
            Write-Host ""
            Show-Logs "keycloak"
            Write-Host ""
            Show-Logs "spring"
        }
        default {
            Write-Error "Invalid component. Use: mysql, keycloak, spring, or all"
        }
    }
}

# Function to troubleshoot
function Invoke-Troubleshoot {
    Write-Status "Running troubleshooting checks..."
    
    # Check events
    Write-Status "Recent events:"
    kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' --tail=10
    Write-Host ""
    
    # Check resource usage
    Write-Status "Resource usage:"
    try {
        kubectl top pods -n $NAMESPACE
    }
    catch {
        Write-Warning "Metrics server not available"
    }
    Write-Host ""
    
    # Check ArgoCD sync status
    Write-Status "ArgoCD sync status:"
    $syncStatus = kubectl get application $APP_NAME -n $ARGOCD_NAMESPACE -o jsonpath='{.status.sync.status}'
    Write-Host $syncStatus
    Write-Host ""
    
    # Check for failed pods
    $failedPods = kubectl get pods -n $NAMESPACE --field-selector=status.phase=Failed -o json | ConvertFrom-Json
    if ($failedPods.items.Count -gt 0) {
        Write-Error "Failed pods found:"
        foreach ($pod in $failedPods.items) {
            Write-Host $pod.metadata.name
        }
        Write-Host ""
        Write-Status "Pod descriptions:"
        foreach ($pod in $failedPods.items) {
            kubectl describe pod $pod.metadata.name -n $NAMESPACE
        }
    } else {
        Write-Success "No failed pods found"
    }
}

# Function to cleanup
function Remove-Application {
    Write-Status "Cleaning up..."
    
    $confirm = Read-Host "Are you sure you want to delete the application? (y/n)"
    if ($confirm -eq "y" -or $confirm -eq "Y") {
        kubectl delete application $APP_NAME -n $ARGOCD_NAMESPACE
        Write-Success "ArgoCD application deleted"
        
        $confirmNamespace = Read-Host "Do you want to delete the namespace as well? (y/n)"
        if ($confirmNamespace -eq "y" -or $confirmNamespace -eq "Y") {
            kubectl delete namespace $NAMESPACE
            Write-Success "Namespace deleted"
        }
    } else {
        Write-Status "Cleanup cancelled"
    }
}

# Main function
function Main {
    switch ($Action) {
        "deploy" {
            Write-Status "Starting deployment..."
            if (-not (Test-Kubectl)) { return }
            if (-not (Test-ArgoCD)) { return }
            if (-not (Test-YamlFiles)) { return }
            Test-Prerequisites
            Deploy-ArgoCDApp
            Watch-Deployment
            if (Test-ApplicationHealth) {
                Show-Status
                Write-Success "Deployment completed successfully!"
            } else {
                Write-Error "Deployment completed with health issues"
            }
        }
        "status" {
            Show-Status
        }
        "logs" {
            Show-Logs $Component
        }
        "troubleshoot" {
            Invoke-Troubleshoot
        }
        "cleanup" {
            Remove-Application
        }
        default {
            Write-Host "Usage: .\argocd-deploy.ps1 {deploy|status|logs|troubleshoot|cleanup}"
            Write-Host ""
            Write-Host "Commands:"
            Write-Host "  deploy       - Deploy the application to ArgoCD"
            Write-Host "  status       - Show application status"
            Write-Host "  logs [comp]  - Show logs (mysql|keycloak|spring|all)"
            Write-Host "  troubleshoot - Run troubleshooting checks"
            Write-Host "  cleanup      - Clean up the application"
        }
    }
}

# Run main function
Main
