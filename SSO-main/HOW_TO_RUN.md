# 🚀 Hướng dẫn chạy Web Application SSO

## 📋 Yêu cầu hệ thống

- **Docker Desktop** (Windows/Mac) hoặc **Docker Engine** (Linux)
- **Docker Compose** (thường đi kèm với Docker)
- **Java 17+** (nếu chạy local development)
- **Maven** (nếu chạy local development)

## 🎯 Các phương pháp chạy

### **Phương pháp 1: Docker Compose (Khuyến nghị - Dễ nhất)**

#### Bước 1: Kiểm tra Docker
```powershell
# Kiểm tra Docker đã cài đặt chưa
docker --version
docker-compose --version
```

#### Bước 2: Chạy toàn bộ hệ thống
```powershell
# Chuyển đến thư mục demo1
cd SSO-main\demo1

# Chạy với Docker Compose đầy đủ
docker-compose -f docker-compose-full.yml up -d

# Hoặc chạy từng service một cách
docker-compose -f docker-compose-full.yml up mysql -d
docker-compose -f docker-compose-full.yml up keycloak -d
docker-compose -f docker-compose-full.yml up spring-app -d
```

#### Bước 3: Kiểm tra trạng thái
```powershell
# Xem logs của tất cả services
docker-compose -f docker-compose-full.yml logs -f

# Xem logs của từng service
docker-compose -f docker-compose-full.yml logs mysql
docker-compose -f docker-compose-full.yml logs keycloak
docker-compose -f docker-compose-full.yml logs spring-app

# Kiểm tra containers đang chạy
docker-compose -f docker-compose-full.yml ps
```

#### Bước 4: Truy cập ứng dụng
- **Spring Boot App**: http://localhost:8081
- **Keycloak Admin**: http://localhost:8080
  - Username: `admin`
  - Password: `admin123`

---

### **Phương pháp 2: Chạy Local Development**

#### Bước 1: Chuẩn bị môi trường
```powershell
# Kiểm tra Java version
java -version

# Kiểm tra Maven
mvn -version
```

#### Bước 2: Chạy MySQL và Keycloak với Docker
```powershell
cd SSO-main\demo1

# Chỉ chạy MySQL và Keycloak
docker-compose up mysql keycloak -d
```

#### Bước 3: Chạy Spring Boot local
```powershell
# Chạy Spring Boot application
mvn spring-boot:run

# Hoặc build và chạy JAR
mvn clean package
java -jar target\demo1-0.0.1-SNAPSHOT.jar
```

---

### **Phương pháp 3: Deploy lên Kubernetes với ArgoCD**

#### Bước 1: Chuẩn bị Kubernetes cluster
```powershell
# Kiểm tra kubectl
kubectl version --client

# Kiểm tra cluster connection
kubectl cluster-info
```

#### Bước 2: Deploy với script tự động
```powershell
cd SSO-main\k8s

# Deploy tự động
.\argocd-deploy.ps1 deploy

# Kiểm tra status
.\argocd-deploy.ps1 status
```

#### Bước 3: Truy cập ứng dụng
- **Spring Boot App**: http://sso-demo.local
- **Keycloak Admin**: http://sso-demo.local/keycloak

---

## 🔧 Cấu hình Keycloak

### Bước 1: Truy cập Keycloak Admin Console
1. Mở http://localhost:8080 (hoặc http://sso-demo.local/keycloak)
2. Đăng nhập với `admin` / `admin123`

### Bước 2: Tạo Realm
1. Click vào dropdown "Master" ở góc trái
2. Click "Create Realm"
3. Nhập tên: `demo-realm`
4. Click "Create"

### Bước 3: Tạo Client
1. Trong realm `demo-realm`, chọn "Clients"
2. Click "Create client"
3. Client ID: `spring-boot-oidc`
4. Client protocol: `openid-connect`
5. Click "Save"
6. Trong tab "Credentials", copy Client Secret: `oOb2WhVNBSGxd7cgpq1bxrY3Qlrr1O1L`
7. Trong tab "Settings":
   - Valid Redirect URIs: `http://localhost:8081/login/oauth2/code/keycloak`
   - Web Origins: `http://localhost:8081`

### Bước 4: Tạo User
1. Chọn "Users" trong menu trái
2. Click "Create new user"
3. Username: `testuser`
4. Email: `test@example.com`
5. Click "Save"
6. Vào tab "Credentials", set password: `password123`
7. Disable "Temporary" password

---

## 🐛 Troubleshooting

### Lỗi Docker không khởi động được
```powershell
# Kiểm tra Docker Desktop có chạy không
docker info

# Restart Docker Desktop nếu cần
# Hoặc restart service
net stop com.docker.service
net start com.docker.service
```

### Lỗi Port đã được sử dụng
```powershell
# Kiểm tra port nào đang được sử dụng
netstat -ano | findstr :8080
netstat -ano | findstr :8081
netstat -ano | findstr :3306

# Kill process nếu cần
taskkill /PID <PID_NUMBER> /F
```

### Lỗi Database Connection
```powershell
# Kiểm tra MySQL container
docker-compose -f docker-compose-full.yml logs mysql

# Kiểm tra kết nối từ container khác
docker-compose -f docker-compose-full.yml exec spring-app ping mysql
```

### Lỗi Keycloak không khởi động
```powershell
# Kiểm tra logs Keycloak
docker-compose -f docker-compose-full.yml logs keycloak

# Restart Keycloak
docker-compose -f docker-compose-full.yml restart keycloak
```

### Lỗi Spring Boot không kết nối được Keycloak
```powershell
# Kiểm tra logs Spring Boot
docker-compose -f docker-compose-full.yml logs spring-app

# Kiểm tra network
docker network ls
docker network inspect demo1_sso-network
```

---

## 📊 Monitoring và Debug

### Xem logs real-time
```powershell
# Tất cả services
docker-compose -f docker-compose-full.yml logs -f

# Chỉ Spring Boot
docker-compose -f docker-compose-full.yml logs -f spring-app

# Chỉ Keycloak
docker-compose -f docker-compose-full.yml logs -f keycloak
```

### Kiểm tra resource usage
```powershell
# Xem resource usage của containers
docker stats

# Xem chi tiết container
docker inspect <container_name>
```

### Debug network
```powershell
# Kiểm tra network connectivity
docker-compose -f docker-compose-full.yml exec spring-app curl http://keycloak:8080/realms/master
docker-compose -f docker-compose-full.yml exec spring-app curl http://mysql:3306
```

---

## 🛑 Dừng và Cleanup

### Dừng services
```powershell
# Dừng tất cả services
docker-compose -f docker-compose-full.yml down

# Dừng và xóa volumes
docker-compose -f docker-compose-full.yml down -v

# Dừng và xóa images
docker-compose -f docker-compose-full.yml down --rmi all
```

### Cleanup Docker
```powershell
# Xóa containers không sử dụng
docker container prune

# Xóa images không sử dụng
docker image prune

# Xóa volumes không sử dụng
docker volume prune

# Cleanup toàn bộ
docker system prune -a
```

---

## 🚀 Production Deployment

### Với ArgoCD (Kubernetes)
```powershell
cd SSO-main\k8s

# Deploy production
.\argocd-deploy.ps1 deploy

# Monitor
.\argocd-deploy.ps1 status

# Troubleshoot nếu có lỗi
.\argocd-deploy.ps1 troubleshoot
```

### Với Docker Swarm
```powershell
# Initialize swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker-compose-full.yml sso-demo

# Kiểm tra services
docker service ls
```

---

## 📝 Notes

1. **Development**: Sử dụng Docker Compose cho development nhanh
2. **Testing**: Sử dụng local development để debug
3. **Production**: Sử dụng Kubernetes với ArgoCD
4. **Security**: Thay đổi passwords mặc định cho production
5. **Monitoring**: Sử dụng logs và health checks để monitor

## 🆘 Hỗ trợ

Nếu gặp vấn đề:
1. Kiểm tra logs của từng service
2. Sử dụng troubleshooting commands
3. Kiểm tra network connectivity
4. Restart services nếu cần
5. Cleanup và chạy lại từ đầu
