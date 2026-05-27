# SecureLearn Deploy

Repository nay chua cau hinh chay tong the cho du an SecureLearn bang Docker Compose.

Source code frontend va backend duoc quan ly o 2 repository rieng:

- Frontend: `securelearn-web`
- Backend: `securelearn-services`
- Deploy/infra: repository hien tai, chua `docker-compose.yml`

## Cau truc thu muc

Khi chay local, can dat cac thu muc theo dung cau truc sau:

```text
SecureLearn/
├── frontend/              # React, Vite, TypeScript
├── backend/               # Node.js microservices va Kong config
│   ├── api-gateway/
│   │   └── kong.yml
│   ├── identity-service/
│   ├── course-service/
│   └── media-service/
├── docker-compose.yml     # Cau hinh Docker Compose cho backend services va infra
├── .env                   # Bien moi truong local, khong push len GitHub
├── .env.example           # File mau bien moi truong neu co
├── .gitignore
└── README.md
```

Repository deploy chi nen track cac file cau hinh can thiet nhu:

```text
docker-compose.yml
.gitignore
.env.example
README.md
```

Khong track cac thu muc `frontend/` va `backend/` trong repository nay vi chung da co Git repository rieng.

## Dieu kien truoc khi chay

Can cai dat:

- Docker Desktop
- Git
- Node.js neu muon chay frontend rieng o che do development

Can clone frontend va backend vao dung vi tri:

```powershell
cd D:\SecureLearn
git clone https://github.com/PhamLuongBaoThien/securelearn-web.git frontend
git clone https://github.com/PhamLuongBaoThien/securelearn-services.git backend
```

## Cau hinh moi truong

Tao file `.env` tai thu muc root `D:\SecureLearn`.

File `.env` la file dung that tren may local va khong duoc push len GitHub. Neu co `.env.example`, co the copy tu file mau:

```powershell
Copy-Item .env.example .env
```

Sau do dien cac bien can thiet cho `docker-compose.yml`, bao gom:

```env
REDIS_PASSWORD=
RABBITMQ_DEFAULT_USER=
RABBITMQ_DEFAULT_PASS=

MINIO_ROOT_USER=
MINIO_ROOT_PASSWORD=

MONGO_URI_IDENTITY=
MONGO_URI_COURSE=
MONGO_URI_MEDIA=

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

## Chay he thong

Tai thu muc root:

```powershell
cd D:\SecureLearn
docker compose up -d --build
```

Kiem tra container:

```powershell
docker compose ps
```

Xem log:

```powershell
docker compose logs -f
```

Dung he thong:

```powershell
docker compose down
```

## Cac service chinh

- Kong API Gateway: `http://localhost:8000`
- MinIO Console: `http://localhost:9001`
- Identity Service: chay noi bo trong Docker o port `5001`
- Course Service: chay noi bo trong Docker o port `5002`
- Media Service: chay noi bo trong Docker o port `5003`
- Redis, RabbitMQ va MinIO duoc dung lam ha tang noi bo cho backend services

Frontend development mac dinh chay rieng o:

```text
http://localhost:5173
```

## Ghi chu ve Git

Repository nay chi dung cho cau hinh deploy/infra. Khi sua code frontend hoac backend, commit va push trong tung repository rieng:

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

Khi sua `docker-compose.yml`, `.gitignore`, `.env.example` hoac README nay thi commit trong repository deploy tai root:

```powershell
cd D:\SecureLearn
git status
git add docker-compose.yml .gitignore .env.example README.md
git commit -m "Update deployment configuration"
git push
```
