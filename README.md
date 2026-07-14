# SecureLearn Local Development

Repository root này giữ cấu hình chạy tổng thể cho SecureLearn. Hiện flow local chính là:

```text
Frontend local npm run dev -> http://localhost:5173
Backend Kubernetes local -> Kong http://localhost:30681
```

Docker Compose vẫn được giữ làm fallback/onboarding/debug comparison, không còn là flow chính.

## Cấu trúc thư mục

```text
SecureLearn/
├── frontend/                  # React, Vite, TypeScript; chạy local bằng npm run dev
├── backend/                   # Node.js microservices và Kong config
├── infra/                     # Helm chart Kubernetes local v1 Lite
│   └── charts/securelearn/
├── docker-compose.yml         # Fallback Docker Compose workflow
├── .env                       # Env cho Docker Compose fallback, không commit
├── .gitignore
└── README.md
```

## Flow chính hiện tại: Frontend local + Backend Kubernetes

Đọc hướng dẫn chi tiết tại:

```text
infra/README.md
```

URL local chuẩn:

```text
Frontend:        http://localhost:5173
Kubernetes Kong: http://localhost:30681
```

Frontend dev proxy trong `frontend/vite.config.ts` chuyển `/api` sang `http://localhost:30681`.

Chạy frontend:

```powershell
cd D:\SecureLearn\frontend
npm run dev
```

Backend chạy bằng Helm/Kubernetes local:

```powershell
cd D:\SecureLearn
helm upgrade --install securelearn infra/charts/securelearn `
  -n securelearn-local --create-namespace `
  -f infra/charts/securelearn/values-local.yaml
```

## Env theo từng workflow

Kubernetes backend dùng:

```text
infra/local-secrets.env
```

Docker Compose fallback dùng:

```text
.env
```

Frontend Vite local dùng:

```text
frontend/vite.config.ts
```

hoặc `.env.local` nếu sau này cấu hình thêm.

## Docker Compose fallback

Chỉ dùng Compose khi cần fallback, onboarding người mới, hoặc so sánh lỗi Compose vs Kubernetes.

```powershell
cd D:\SecureLearn
docker compose up -d --build
```

Compose gateway thường là:

```text
http://localhost:8000
```

Không nên chạy Compose và Kubernetes backend song song trừ khi debug có chủ đích, vì dễ nhầm gateway/cookie/callback/log.

## Git note

Project hiện có 3 repo:

```text
D:\SecureLearn
D:\SecureLearn\frontend
D:\SecureLearn\backend
```

Khi sửa frontend/backend, commit trong repo tương ứng. Khi sửa infra/root config, commit ở repo root.
