#!/bin/bash

# Script xóa CourseTracker khỏi Kubernetes

echo "🗑️  Xóa CourseTracker khỏi Kubernetes..."

# Xóa các resources
echo "  - Xóa tất cả resources..."
kubectl delete -k k8s/

echo ""
echo "✅ Đã xóa thành công tất cả resources!"
echo ""
echo "📋 Kiểm tra lại:"
echo "  - kubectl get pods"
echo "  - kubectl get services"
echo "  - kubectl get pv"
echo "  - kubectl get pvc"
echo "  - kubectl get configmap"
