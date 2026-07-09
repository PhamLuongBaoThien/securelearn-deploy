# SecureLearn Kubernetes Local v1 Lite

Mục tiêu của v1 Lite là chạy SecureLearn trên Kubernetes local trước:

`Frontend -> Kong -> 8 backend services -> Redis/RabbitMQ local + MongoDB Atlas + R2/S3`

Docker Compose vẫn được giữ để fallback trong giai đoạn học Kubernetes.

## 1. Cần có trên máy

- Docker Desktop và bật Kubernetes trong Settings.
- `kubectl` dùng context Docker Desktop.
- Helm.

Kiểm tra:

```powershell
kubectl get nodes
helm version
```

Nếu `kubectl get nodes` chưa chạy được, hãy mở Docker Desktop và chờ Kubernetes chuyển sang trạng thái running.

## 2. Tạo Secret local

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

## 3. Build Docker images local

V1 Lite dùng tag `local`, không dùng `latest`.

```powershell
$services = 'identity-service','course-service','media-service','payment-service','progress-service','notification-service','inbox-service','content-service'
foreach ($service in $services) {
  docker build -t "ghcr.io/phamluongbaothien/${service}:local" -f "backend/${service}/Dockerfile" backend
}

docker build -t ghcr.io/phamluongbaothien/frontend:local frontend
```

## 4. Deploy bằng Helm

```powershell
helm dependency build infra/charts/securelearn
helm lint infra/charts/securelearn -f infra/charts/securelearn/values-local.yaml
helm template securelearn infra/charts/securelearn -n securelearn-local -f infra/charts/securelearn/values-local.yaml

helm upgrade --install securelearn infra/charts/securelearn `
  -n securelearn-local --create-namespace `
  -f infra/charts/securelearn/values-local.yaml
```

## 5. Mở app qua Kong

```powershell
kubectl -n securelearn-local port-forward service/kong 8000:8000
```

Sau đó mở:

- Frontend: `http://localhost:8000`
- API: `http://localhost:8000/api/...`

## 6. Kiểm tra và debug

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

## 7. Những file chính nên đọc trước

- `infra/charts/securelearn/Chart.yaml`: khai báo Helm chart và Redis/RabbitMQ dependencies.
- `infra/charts/securelearn/values.yaml`: cấu hình mặc định cho local.
- `infra/charts/securelearn/values-local.yaml`: override local khi deploy.
- `infra/charts/securelearn/templates/backend.yaml`: Deployment và Service cho 8 backend.
- `infra/charts/securelearn/templates/frontend.yaml`: Deployment và Service cho frontend.
- `infra/charts/securelearn/templates/kong.yaml`: Kong DB-less và Service local.
- `infra/charts/securelearn/files/kong.yml.tpl`: route matrix của Kong.

Không commit `infra/local-secrets.env` hoặc bất kỳ secret thật nào.
