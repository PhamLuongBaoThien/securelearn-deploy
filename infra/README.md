# SecureLearn Kubernetes Local v1 Lite

Mục tiêu v1 Lite hiện tại là chạy backend SecureLearn trên Kubernetes local, còn frontend chạy riêng bằng Vite dev server:

`Frontend npm run dev -> Kong Kubernetes -> 8 backend services -> Redis/RabbitMQ local + MongoDB Atlas + R2/S3`

Docker Compose vẫn được giữ làm fallback trong giai đoạn học Kubernetes. Không nên chạy Compose và Kubernetes backend song song trừ khi đang debug có chủ đích.

## 1. Cần có trên máy

- Docker Desktop và bật Kubernetes trong Settings.
- `kubectl` dùng context Docker Desktop.
- Helm.
- Node.js/npm cho frontend local dev.

Kiểm tra:

```powershell
kubectl get nodes
helm version
```

Nếu `kubectl get nodes` chưa chạy được, hãy mở Docker Desktop và chờ Kubernetes chuyển sang trạng thái running.

## 2. URL local chuẩn

- Frontend local: `http://localhost:5173`
- Backend/Kong Kubernetes: `http://localhost:30681`
- API từ frontend dev: `/api/...` được Vite proxy sang `http://localhost:30681`

Các URL OAuth/payment local nên theo quy ước:

```env
CLIENT_URL=http://localhost:5173
GOOGLE_CALLBACK_URL=http://localhost:30681/api/auth/google/callback
MOMO_RETURN_URL=http://localhost:5173/payment/momo-return
VNPAY_RETURN_URL=http://localhost:5173/payment/vnpay-return
```

IPN/webhook thật từ MoMo/VNPAY cần URL public như ngrok. Nếu chỉ test local browser return, có thể dùng Kong local `http://localhost:30681/...`.

## 3. Tạo Secret local

Secret thật không commit vào Git. Tạo file local từ mẫu:

```powershell
Copy-Item infra/local-secrets.example.env infra/local-secrets.env
```

Điền các giá trị thật vào `infra/local-secrets.env`, tối thiểu gồm JWT secret, MongoDB Atlas URI cho các service, R2/S3 credentials, Redis URI và RabbitMQ URL.

Tạo namespace và Secret trong Kubernetes:

```powershell
kubectl create namespace securelearn-local --dry-run=client -o yaml | kubectl apply -f -
kubectl -n securelearn-local create secret generic securelearn-secrets --from-env-file=infra/local-secrets.env --dry-run=client -o yaml | kubectl apply -f -
```

## 4. Build Docker images backend local

V1 Lite dùng tag `local`, không dùng `latest`. Frontend không cần build image khi dev local bằng `npm run dev`.

```powershell
$services = 'identity-service','course-service','media-service','payment-service','progress-service','notification-service','inbox-service','content-service'
foreach ($service in $services) {
  docker build -t "ghcr.io/phamluongbaothien/${service}:local" -f "backend/${service}/Dockerfile" backend
}
```

Khi chỉ sửa một backend, chỉ build service đó. Ví dụ:

```powershell
docker build -f ./backend/course-service/Dockerfile -t ghcr.io/phamluongbaothien/course-service:local ./backend
kubectl -n securelearn-local rollout restart deployment/course-service
kubectl -n securelearn-local rollout status deployment/course-service
```

## 5. Deploy backend bằng Helm

```powershell
helm dependency build infra/charts/securelearn
helm lint infra/charts/securelearn -f infra/charts/securelearn/values-local.yaml
helm template securelearn infra/charts/securelearn -n securelearn-local -f infra/charts/securelearn/values-local.yaml

helm upgrade --install securelearn infra/charts/securelearn `
  -n securelearn-local --create-namespace `
  -f infra/charts/securelearn/values-local.yaml
```

Chart local không còn quản lý frontend. Kubernetes chỉ chạy backend, Kong, Redis và RabbitMQ.

## 6. Chạy frontend local

Trong terminal riêng:

```powershell
cd frontend
npm run dev
```

Mở:

- Frontend: `http://localhost:5173`
- Backend/Kong trực tiếp: `http://localhost:30681/api/...`

## 7. Kiểm tra và debug

```powershell
kubectl get pods -n securelearn-local
kubectl get svc -n securelearn-local
kubectl -n securelearn-local logs deployment/kong
kubectl -n securelearn-local logs deployment/identity-service
kubectl -n securelearn-local describe pod <pod-name>
```

Backend health endpoints:

- `/health/live`: tiến trình Node còn sống.
- `/health/ready`: service đã sẵn sàng nhận request.

Nếu frontend gọi nhầm môi trường, mở DevTools -> Network và kiểm tra Request URL:

- `http://localhost:30681/api/...`: đang gọi Kubernetes.
- `http://localhost:8000/api/...`: có thể đang gọi Docker Compose/Kong cũ.

## 8. Những file chính nên đọc trước

- `infra/charts/securelearn/Chart.yaml`: Helm chart và Redis/RabbitMQ dependencies.
- `infra/charts/securelearn/values.yaml`: cấu hình mặc định.
- `infra/charts/securelearn/values-local.yaml`: override local khi deploy backend K8s.
- `infra/charts/securelearn/templates/backend.yaml`: Deployment và Service cho 8 backend.
- `infra/charts/securelearn/templates/kong.yaml`: Kong DB-less và Service local.
- `infra/charts/securelearn/files/kong.yml.tpl`: route matrix API của Kong.
- `frontend/vite.config.ts`: proxy frontend dev sang Kong Kubernetes.

Không commit `infra/local-secrets.env` hoặc bất kỳ secret thật nào.

