# Hướng dẫn triển khai ứng dụng SSO trên Kubernetes

## Tổng quan

Dự án này triển khai một ứng dụng web Spring Boot với MySQL và Keycloak trên nền tảng Kubernetes. Ứng dụng sử dụng OAuth2/OIDC để xác thực người dùng thông qua Keycloak.

## Kiến trúc hệ thống

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Ingress       │    │   Spring Boot   │    │   Keycloak      │
│   (nginx)       │────│   Application   │────│   (SSO)         │
│                 │    │   (Port 8081)   │    │   (Port 8080)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                                               ┌─────────────────┐
                                               │   MySQL         │
                                               │   (Port 3306)   │
                                               └─────────────────┘
```

## Các thành phần

### 1. MySQL Database
- **Image**: mysql:8.0
- **Port**: 3306
- **Storage**: PersistentVolumeClaim (2Gi)
- **Credentials**: 
  - Root password: `mysql123`
  - App user: `appuser` / `appuser123`
  - Database: `sso_demo`

### 2. Keycloak SSO
- **Image**: quay.io/keycloak/keycloak:latest
- **Port**: 8080
- **Admin credentials**: `admin` / `admin123`
- **Database**: MySQL (sử dụng database `keycloak`)

### 3. Spring Boot Application
- **Image**: spring-boot-sso-demo:latest (build từ Dockerfile)
- **Port**: 8081
- **Features**: OAuth2/OIDC client integration

### 4. Ingress
- **Host**: sso-demo.local
- **Routes**:
  - `/` → Spring Boot application
  - `/keycloak` → Keycloak admin console

## Yêu cầu hệ thống

- Kubernetes cluster (minikube, kind, hoặc cloud provider)
- kubectl đã được cấu hình
- Docker để build image
- Ingress controller (nginx-ingress)

## Triển khai nhanh

### Sử dụng PowerShell (Windows)

```powershell
# Chuyển đến thư mục k8s
cd k8s

# Triển khai ứng dụng
.\deploy.ps1

# Kiểm tra trạng thái
.\check-status.ps1

# Gỡ bỏ ứng dụng
.\undeploy.ps1
```

### Sử dụng Bash (Linux/Mac)

```bash
# Chuyển đến thư mục k8s
cd k8s

# Cấp quyền thực thi
chmod +x deploy.sh undeploy.sh

# Triển khai ứng dụng
./deploy.sh

# Gỡ bỏ ứng dụng
./undeploy.sh
```

## Triển khai thủ công

### Bước 1: Tạo namespace và secrets

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/mysql-secret.yaml
kubectl apply -f k8s/keycloak-secret.yaml
```

### Bước 2: Tạo configmaps

```bash
kubectl apply -f k8s/mysql-configmap.yaml
kubectl apply -f k8s/spring-app-configmap.yaml
```

### Bước 3: Triển khai MySQL

```bash
kubectl apply -f k8s/mysql-deployment.yaml
kubectl wait --for=condition=ready pod -l app=mysql -n sso-demo --timeout=300s
```

### Bước 4: Triển khai Keycloak

```bash
kubectl apply -f k8s/keycloak-deployment.yaml
kubectl wait --for=condition=ready pod -l app=keycloak -n sso-demo --timeout=300s
```

### Bước 5: Build và triển khai Spring Boot app

```bash
# Build Docker image
cd demo1
docker build -t spring-boot-sso-demo:latest .

# Triển khai ứng dụng
cd ../k8s
kubectl apply -f spring-app-deployment.yaml
```

### Bước 6: Cấu hình Ingress

```bash
kubectl apply -f k8s/ingress.yaml
```

## Cấu hình truy cập

### 1. Cập nhật file hosts

**Windows**: Thêm vào `C:\Windows\System32\drivers\etc\hosts`
```
127.0.0.1 sso-demo.local
```

**Linux/Mac**: Thêm vào `/etc/hosts`
```
127.0.0.1 sso-demo.local
```

### 2. Truy cập ứng dụng

- **Ứng dụng chính**: http://sso-demo.local
- **Keycloak admin**: http://sso-demo.local/keycloak
  - Username: `admin`
  - Password: `admin123`

## Cấu hình Keycloak

### 1. Tạo Realm

1. Truy cập http://sso-demo.local/keycloak
2. Đăng nhập với admin/admin123
3. Tạo realm mới tên `demo-realm`

### 2. Tạo Client

1. Trong realm `demo-realm`, tạo client mới
2. Client ID: `spring-boot-oidc`
3. Client Secret: `oOb2WhVNBSGxd7cgpq1bxrY3Qlrr1O1L`
4. Valid Redirect URIs: `http://sso-demo.local:8081/login/oauth2/code/keycloak`

### 3. Tạo User

1. Tạo user mới trong realm
2. Đặt password và enable user

## Kiểm tra và giám sát

### Kiểm tra trạng thái pods

```bash
kubectl get pods -n sso-demo
```

### Xem logs

```bash
# Logs MySQL
kubectl logs -l app=mysql -n sso-demo

# Logs Keycloak
kubectl logs -l app=keycloak -n sso-demo

# Logs Spring Boot
kubectl logs -l app=spring-app -n sso-demo
```

### Kiểm tra services

```bash
kubectl get services -n sso-demo
```

### Kiểm tra ingress

```bash
kubectl get ingress -n sso-demo
```

## Scaling

### Scale Spring Boot application

```bash
kubectl scale deployment spring-app --replicas=3 -n sso-demo
```

## Troubleshooting

### 1. Pod không khởi động

```bash
kubectl describe pod <pod-name> -n sso-demo
kubectl logs <pod-name> -n sso-demo
```

### 2. Service không accessible

```bash
kubectl get endpoints -n sso-demo
kubectl describe service <service-name> -n sso-demo
```

### 3. Ingress không hoạt động

- Kiểm tra ingress controller đã được cài đặt
- Kiểm tra file hosts đã được cập nhật
- Kiểm tra DNS resolution

### 4. Lỗi kết nối database

- Kiểm tra MySQL đã sẵn sàng
- Kiểm tra logs Keycloak
- Kiểm tra network policies

## Bảo mật

### Các điểm cần lưu ý

1. **Mật khẩu mặc định**: Chỉ dùng cho demo, production cần thay đổi
2. **TLS/SSL**: Cần enable cho production
3. **RBAC**: Cấu hình quyền truy cập phù hợp
4. **Network Policies**: Giới hạn traffic giữa các pods
5. **Secrets Management**: Sử dụng external secret management

### Cải thiện bảo mật

```yaml
# Ví dụ NetworkPolicy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: sso-demo-network-policy
  namespace: sso-demo
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: mysql
```

## Cleanup

### Xóa toàn bộ deployment

```bash
# Sử dụng script
.\undeploy.ps1  # Windows
./undeploy.sh   # Linux/Mac

# Hoặc xóa namespace (sẽ xóa tất cả resources)
kubectl delete namespace sso-demo
```

## Tài liệu tham khảo

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Spring Boot OAuth2 Documentation](https://spring.io/guides/tutorials/spring-boot-oauth2/)
- [MySQL Kubernetes Guide](https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/)
