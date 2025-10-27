#!/bin/bash

# Script triển khai CourseTracker lên Kubernetes của Docker Desktop

echo "🚀 Bắt đầu triển khai CourseTracker lên Kubernetes..."

# Kiểm tra Docker Desktop có chạy không
echo "📋 Kiểm tra Docker Desktop..."
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker Desktop chưa chạy. Vui lòng khởi động Docker Desktop trước."
    exit 1
fi

# Kiểm tra Kubernetes có enabled không
echo "📋 Kiểm tra Kubernetes..."
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo "❌ Kubernetes chưa được enable trong Docker Desktop. Vui lòng enable Kubernetes trong Docker Desktop settings."
    exit 1
fi

# Build Docker image
echo "🔨 Building Docker image..."
cd demo1
docker build -t coursetracker:latest .
if [ $? -ne 0 ]; then
    echo "❌ Lỗi khi build Docker image"
    exit 1
fi
cd ..

# Apply Kubernetes manifests
echo "📦 Triển khai lên Kubernetes..."

echo "  - Triển khai tất cả resources..."
kubectl apply -k k8s/

# Chờ deployment ready
echo "⏳ Chờ deployment sẵn sàng..."
kubectl wait --for=condition=available --timeout=300s deployment/coursetracker-app

# Hiển thị thông tin truy cập
echo ""
echo "✅ Triển khai thành công!"
echo ""
echo "📊 Thông tin truy cập:"
echo "  - Local URL: http://localhost:30080"
echo "  - H2 Console: http://localhost:30080/h2-console"
echo ""
echo "📋 Các lệnh hữu ích:"
echo "  - Xem pods: kubectl get pods"
echo "  - Xem services: kubectl get services"
echo "  - Xem logs: kubectl logs -f deployment/coursetracker-app"
echo "  - Scale deployment: kubectl scale deployment coursetracker-app --replicas=3"
echo ""
echo "🗑️  Để xóa deployment: ./undeploy.sh"
