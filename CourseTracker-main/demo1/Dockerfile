# Sử dụng OpenJDK 21 làm base image
FROM openjdk:21-jdk-slim

# Thiết lập thư mục làm việc
WORKDIR /app

# Copy file gradle wrapper
COPY gradlew .
COPY gradle gradle
COPY build.gradle .
COPY settings.gradle .

# Cấp quyền thực thi cho gradlew
RUN chmod +x gradlew

# Copy source code
COPY src src

# Build ứng dụng
RUN ./gradlew build -x test

# Expose port 8080
EXPOSE 8080

# Chạy ứng dụng
CMD ["java", "-jar", "build/libs/demo1-0.0.1-SNAPSHOT.jar"]
