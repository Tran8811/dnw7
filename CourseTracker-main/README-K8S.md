# Hướng dẫn triển khai CourseTracker lên Kubernetes của Docker Desktop

## 📋 Yêu cầu hệ thống

- Docker Desktop đã cài đặt và đang chạy
- Kubernetes đã được enable trong Docker Desktop
- kubectl đã cài đặt (thường đi kèm với Docker Desktop)

## 🚀 Các bước triển khai

### 1. Chuẩn bị môi trường

Đảm bảo Docker Desktop đang chạy và Kubernetes đã được enable:
- Mở Docker Desktop
- Vào Settings > Kubernetes
- Tick vào "Enable Kubernetes"
- Click "Apply & Restart"

### 2. Triển khai ứng dụng

Chạy script triển khai:
```bash
chmod +x deploy.sh
./deploy.sh
```

Or triển khai thủ công:

```bash
# Build Docker image
cd demo1
docker build -t coursetracker:latest .
cd ..

# Triển khai lên Kubernetes
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/persistent-volume.yaml
kubectl apply -f k8s/persistent-volume-claim.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

### 3. Kiểm tra triển khai

```bash
# Xem trạng thái pods
kubectl get pods

# Xem services
kubectl get services

# Xem logs
kubectl logs -f deployment/coursetracker-app
```

### 4. Truy cập ứng dụng

- **Ứng dụng chính**: http://localhost:30080
- **H2 Console**: http://localhost:30080/h2-console
  - JDBC URL: `jdbc:h2:mem:testdb`
  - Username: `sa`
  - Password: (để trống)

## 📊 Quản lý ứng dụng

### Scale deployment
```bash
kubectl scale deployment coursetracker-app --replicas=3
```

### Xem thông tin chi tiết
```bash
kubectl describe deployment coursetracker-app
kubectl describe service coursetracker-service
```

### Xem logs
```bash
kubectl logs -f deployment/coursetracker-app
```

### Restart deployment
```bash
kubectl rollout restart deployment/coursetracker-app
```

## 🗑️ Xóa deployment

Chạy script xóa:
```bash
chmod +x undeploy.sh
./undeploy.sh
```

Hoặc xóa thủ công:
```bash
kubectl delete -f k8s/service.yaml
kubectl delete -f k8s/deployment.yaml
kubectl delete -f k8s/persistent-volume-claim.yaml
kubectl delete -f k8s/persistent-volume.yaml
kubectl delete -f k8s/configmap.yaml
```

## 🔧 Cấu hình

### Thay đổi số replicas
Chỉnh sửa file `k8s/deployment.yaml`:
```yaml
spec:
  replicas: 3  # Thay đổi số này
```

### Thay đổi port
Chỉnh sửa file `k8s/service.yaml`:
```yaml
spec:
  ports:
  - port: 8080
    targetPort: 8080
    nodePort: 30080  # Thay đổi port này
```

### Thay đổi cấu hình database
Chỉnh sửa file `k8s/configmap.yaml`:
```yaml
data:
  database.url: "jdbc:h2:mem:testdb"  # Thay đổi URL database
  database.username: "sa"
  database.password: ""
```

## 🐛 Troubleshooting

### Pod không start được
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Service không accessible
```bash
kubectl get services
kubectl describe service coursetracker-service
```

### Image pull error
Đảm bảo Docker image đã được build:
```bash
docker images | grep coursetracker
```

## 📁 Cấu trúc files

```
CourseTracker-main/
├── demo1/
│   ├── Dockerfile
│   ├── build.gradle
│   └── src/
├── k8s/
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── persistent-volume.yaml
│   └── persistent-volume-claim.yaml
├── deploy.sh
├── undeploy.sh
└── README-K8S.md
```
