# SecureLearn Deploy

Repository này chứa cấu hình chạy tổng thể cho dự án SecureLearn bằng Docker Compose.

Source code frontend và backend được quản lý ở 2 repository riêng:

- Frontend: `securelearn-web`
- Backend: `securelearn-services`
- Deploy/infra: repository hiện tại, chứa `docker-compose.yml`

## Cấu trúc thư mục

Khi chạy local, cần đặt các thư mục theo đúng cấu trúc sau:

```text
SecureLearn/
├── frontend/              # React, Vite, TypeScript
├── backend/               # Node.js microservices và Kong config
│   ├── api-gateway/
│   │   └── kong.yml
│   ├── identity-service/
│   ├── course-service/
│   └── media-service/
├── docker-compose.yml     # Cấu hình Docker Compose cho backend services và infra
├── .env                   # Biến môi trường local, không push lên GitHub
├── .env.example           # File mẫu biến môi trường nếu có
├── .gitignore
└── README.md
```

Repository deploy chỉ nên track các file cấu hình cần thiết như:

```text
docker-compose.yml
.gitignore
.env.example
README.md
```

Không track các thư mục `frontend/` và `backend/` trong repository này vì chúng đã có Git repository riêng.

## Điều kiện trước khi chạy

Cần cài đặt:

- Docker Desktop
- Git
- Node.js nếu muốn chạy frontend riêng ở chế độ development

Cần clone frontend và backend vào đúng vị trí:

```powershell
cd D:\SecureLearn
git clone https://github.com/PhamLuongBaoThien/securelearn-web.git frontend
git clone https://github.com/PhamLuongBaoThien/securelearn-services.git backend
```

## Cấu hình môi trường

Tạo file `.env` tại thư mục root `D:\SecureLearn`.

File `.env` là file dùng thật trên máy local và không được push lên GitHub. Nếu có `.env.example`, có thể copy từ file mẫu:

```powershell
Copy-Item .env.example .env
```

Sau đó điền các biến cần thiết cho `docker-compose.yml`, bao gồm:

```env
REDIS_PASSWORD=
RABBITMQ_DEFAULT_USER=
RABBITMQ_DEFAULT_PASS=

MINIO_ROOT_USER=
MINIO_ROOT_PASSWORD=

MONGO_URI_IDENTITY=
MONGO_URI_COURSE=
MONGO_URI_MEDIA=
MONGO_URI_NOTIFICATION=
MONGO_URI_INBOX=

ACCESS_TOKEN=
REFRESH_TOKEN=

CLIENT_URL=http://localhost:5173
API_URL=http://localhost:8000

GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_CALLBACK_URL=http://localhost:8000/api/auth/google/callback

CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=

SMTP_USER=
SMTP_PASS=
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587

S3_ENDPOINT=
S3_REGION=us-east-1
S3_ACCESS_KEY_ID=
S3_SECRET_ACCESS_KEY=
S3_BUCKET_NAME=securelearn-media
S3_PUBLIC_DOMAIN=
S3_PUBLIC_ENDPOINT=
```

## Chạy hệ thống

Tại thư mục root:

```powershell
cd D:\SecureLearn
docker compose up -d --build
```

Kiểm tra container:

```powershell
docker compose ps
```

Xem log:

```powershell
docker compose logs -f
```

Dừng hệ thống:

```powershell
docker compose down
```

## Các service chính

- Kong API Gateway: `http://localhost:8000`
- MinIO Console: `http://localhost:9001`
- Identity Service: chạy nội bộ trong Docker ở port `5001`
- Course Service: chạy nội bộ trong Docker ở port `5002`
- Media Service: chạy nội bộ trong Docker ở port `5003`
- Redis, RabbitMQ và MinIO được dùng làm hạ tầng nội bộ cho backend services

Frontend development mặc định chạy riêng ở:

```text
http://localhost:5173
```

## Ghi chú về Git

Repository này chỉ dùng cho cấu hình deploy/infra. Khi sửa code frontend hoặc backend, commit và push trong từng repository riêng:

```powershell
cd D:\SecureLearn\frontend
git status
git add .
git commit -m "Update frontend"
git push
```

```powershell
cd D:\SecureLearn\backend
git status
git add .
git commit -m "Update backend"
git push
```

Khi sửa `docker-compose.yml`, `.gitignore`, `.env.example` hoặc README này thì commit trong repository deploy tại root:

```powershell
cd D:\SecureLearn
git status
git add docker-compose.yml .gitignore .env.example README.md
git commit -m "Update deployment configuration"
git push
```
