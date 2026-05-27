# SecureLearn - Microservices SaaS Platform

## Cấu trúc thư mục Monorepo (Node.js)

Dưới đây là cấu trúc thư mục tiêu chuẩn theo mô hình Layered Architecture / Microservices.

```text
SecureLearn/
├── backend/
│   ├── api-gateway/        # Cấu hình Gateway (Kong)
│   │   └── kong.yml
│   ├── shared-libs/        # Các thư viện dùng chung cho backend
│   │   ├── logger/
│   │   ├── auth-middleware/
│   │   └── message-broker/
│   ├── identity-service/   # Dịch vụ xác thực
│   ├── course-service/     # Quản lý khóa học
│   └── media-service/      # Xử lý Video HLS AES-128
│       ├── package.json
│       ├── tsconfig.json
│       └── src/
│           ├── controllers/ # Xử lý Request, trả về Response JSON
│           ├── models/      # Mongoose Schema
│           ├── routes/      # Định tuyến các endpoints
│           └── services/    # Business Logic cốt lõi (VD: videoProcessor.ts)
├── frontend/               # React 18, Vite, TypeScript, Tailwind
├── docker-compose.yml      # Hạ tầng chia sẻ (MongoDB, Redis, MinIO, RabbitMQ, Kong)
└── README.md
```
