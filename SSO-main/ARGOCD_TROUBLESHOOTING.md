# Hướng dẫn Troubleshooting ArgoCD cho SSO Demo

## Các lỗi phổ biến và cách khắc phục

### 1. Lỗi Image Pull

**Triệu chứng:**
```
Failed to pull image "punpun11/spring-boot-sso-demo:latest": rpc error: code = Unknown desc = failed to pull and unpack image
```

**Nguyên nhân:**
- Image không tồn tại hoặc không accessible
- ImagePullPolicy không phù hợp
- Registry credentials không đúng

**Cách khắc phục:**
```bash
# Kiểm tra image có tồn tại không
docker pull punpun11/spring-boot-sso-demo:latest

# Nếu image không tồn tại, build lại
cd SSO-main/demo1
docker build -t punpun11/spring-boot-sso-demo:latest .
docker push punpun11/spring-boot-sso-demo:latest

# Hoặc sử dụng image local
# Thay đổi imagePullPolicy thành "Never" hoặc "IfNotPresent"
```

### 2. Lỗi Init Container

**Triệu chứng:**
```
Init:0/1    PodInitializing   0          2m
```

**Nguyên nhân:**
- MySQL chưa sẵn sàng
- Network connectivity issues
- Init container timeout

**Cách khắc phục:**
```bash
# Kiểm tra logs của init container
kubectl logs <pod-name> -c wait-for-mysql -n sso-demo

# Kiểm tra MySQL service
kubectl get svc mysql -n sso-demo
kubectl describe svc mysql -n sso-demo

# Kiểm tra MySQL pod
kubectl get pods -l app=mysql -n sso-demo
kubectl logs -l app=mysql -n sso-demo
```

### 3. Lỗi Health Check

**Triệu chứng:**
```
Readiness probe failed: Get "http://10.244.0.5:8081/actuator/health": dial tcp 10.244.0.5:8081: connect: connection refused
```

**Nguyên nhân:**
- Application chưa khởi động hoàn toàn
- Health check endpoint không hoạt động
- Resource limits quá thấp

**Cách khắc phục:**
```bash
# Kiểm tra logs của application
kubectl logs -l app=spring-app -n sso-demo

# Kiểm tra resource usage
kubectl top pods -n sso-demo

# Tăng resource limits nếu cần
# Hoặc điều chỉnh initialDelaySeconds trong readinessProbe
```

### 4. Lỗi Database Connection

**Triệu chứng:**
```
java.sql.SQLException: Access denied for user 'appuser'@'10.244.0.6' (using password: YES)
```

**Nguyên nhân:**
- Database credentials không đúng
- Database chưa được khởi tạo
- Network policies blocking connection

**Cách khắc phục:**
```bash
# Kiểm tra MySQL logs
kubectl logs -l app=mysql -n sso-demo

# Kiểm tra secrets
kubectl get secret mysql-secret -n sso-demo -o yaml

# Decode password để kiểm tra
echo "YXBwdXNlcjEyMw==" | base64 -d

# Kiểm tra database đã được tạo chưa
kubectl exec -it <mysql-pod> -n sso-demo -- mysql -u root -p
# Nhập password: mysql123
# SHOW DATABASES;
```

### 5. Lỗi Keycloak Configuration

**Triệu chứng:**
```
Failed to connect to Keycloak: Connection refused
```

**Nguyên nhân:**
- Keycloak chưa khởi động hoàn toàn
- Database connection issues
- Configuration errors

**Cách khắc phục:**
```bash
# Kiểm tra Keycloak logs
kubectl logs -l app=keycloak -n sso-demo

# Kiểm tra Keycloak service
kubectl get svc keycloak -n sso-demo

# Test connection từ trong cluster
kubectl run test-pod --image=busybox -it --rm --restart=Never -- nslookup keycloak.sso-demo.svc.cluster.local
```

### 6. Lỗi ArgoCD Sync

**Triệu chứng:**
```
Application sync failed: one or more objects failed to apply
```

**Nguyên nhân:**
- YAML syntax errors
- Resource conflicts
- RBAC permissions

**Cách khắc phục:**
```bash
# Kiểm tra ArgoCD application status
kubectl get application sso-demo-app -n argocd -o yaml

# Kiểm tra ArgoCD logs
kubectl logs -l app.kubernetes.io/name=argocd-server -n argocd

# Validate YAML files
kubectl apply --dry-run=client -f SSO-main/k8s/

# Kiểm tra RBAC permissions
kubectl auth can-i create deployments --as=system:serviceaccount:argocd:argocd-application-controller
```

## Commands hữu ích cho Debugging

### Kiểm tra trạng thái tổng quan
```bash
# Kiểm tra tất cả resources trong namespace
kubectl get all -n sso-demo

# Kiểm tra ArgoCD application
kubectl get application -n argocd

# Kiểm tra events
kubectl get events -n sso-demo --sort-by='.lastTimestamp'
```

### Kiểm tra logs chi tiết
```bash
# Logs của tất cả pods
kubectl logs -l app=mysql -n sso-demo --tail=100
kubectl logs -l app=keycloak -n sso-demo --tail=100
kubectl logs -l app=spring-app -n sso-demo --tail=100

# Logs của init containers
kubectl logs <pod-name> -c wait-for-mysql -n sso-demo
kubectl logs <pod-name> -c wait-for-keycloak -n sso-demo
```

### Kiểm tra network và connectivity
```bash
# Test DNS resolution
kubectl run test-dns --image=busybox -it --rm --restart=Never -- nslookup mysql.sso-demo.svc.cluster.local

# Test port connectivity
kubectl run test-connectivity --image=busybox -it --rm --restart=Never -- nc -zv mysql 3306

# Kiểm tra endpoints
kubectl get endpoints -n sso-demo
```

### Kiểm tra resources và performance
```bash
# Resource usage
kubectl top pods -n sso-demo
kubectl top nodes

# Resource requests và limits
kubectl describe pod <pod-name> -n sso-demo | grep -A 10 "Requests\|Limits"

# Kiểm tra persistent volumes
kubectl get pv,pvc -n sso-demo
```

## Rollback và Recovery

### Rollback deployment
```bash
# Rollback về version trước
kubectl rollout undo deployment/mysql -n sso-demo
kubectl rollout undo deployment/keycloak -n sso-demo
kubectl rollout undo deployment/spring-app -n sso-demo

# Kiểm tra rollout history
kubectl rollout history deployment/mysql -n sso-demo
```

### Restart pods
```bash
# Restart tất cả pods
kubectl delete pods -l app=mysql -n sso-demo
kubectl delete pods -l app=keycloak -n sso-demo
kubectl delete pods -l app=spring-app -n sso-demo
```

### Cleanup và redeploy
```bash
# Xóa namespace và tạo lại
kubectl delete namespace sso-demo
kubectl create namespace sso-demo

# Redeploy từ ArgoCD
# Hoặc apply lại tất cả manifests
kubectl apply -f SSO-main/k8s/
```

## Monitoring và Alerting

### Thiết lập monitoring
```bash
# Cài đặt Prometheus và Grafana (nếu chưa có)
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/bundle.yaml

# Tạo ServiceMonitor cho các services
kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: sso-demo-monitor
  namespace: sso-demo
spec:
  selector:
    matchLabels:
      app: spring-app
  endpoints:
  - port: 8081
    path: /actuator/prometheus
EOF
```

### Health check endpoints
- MySQL: `mysqladmin ping`
- Keycloak: `GET /realms/master`
- Spring Boot: `GET /actuator/health`

## Best Practices

1. **Luôn sử dụng specific image tags** thay vì `latest`
2. **Thiết lập resource limits** phù hợp với workload
3. **Sử dụng init containers** để đảm bảo dependencies
4. **Cấu hình health checks** với timeout và failure threshold phù hợp
5. **Monitor logs** thường xuyên để phát hiện sớm vấn đề
6. **Backup database** định kỳ
7. **Sử dụng secrets management** cho production
8. **Thiết lập network policies** để tăng cường bảo mật

## Liên hệ hỗ trợ

Nếu vẫn gặp vấn đề sau khi thực hiện các bước trên, hãy cung cấp:
1. Logs của các pods
2. Output của `kubectl describe` commands
3. ArgoCD application status
4. Error messages cụ thể
