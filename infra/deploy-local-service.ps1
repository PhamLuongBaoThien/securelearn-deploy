param(
  [Parameter(Mandatory = $true, Position = 0)]
  [ValidatePattern('^[a-z0-9]+(?:-[a-z0-9]+)*$')]
  [string]$Service
)

$ErrorActionPreference = 'Stop'

function Invoke-NativeCommand {
  param(
    [Parameter(Mandatory = $true)]
    [scriptblock]$Command,

    [Parameter(Mandatory = $true)]
    [string]$FailureMessage
  )

  & $Command
  if ($LASTEXITCODE -ne 0) {
    throw "$FailureMessage (exit code $LASTEXITCODE)."
  }
}

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$serviceDirectory = Join-Path $workspaceRoot "backend\$Service"
$dockerfilePath = Join-Path $serviceDirectory 'Dockerfile'

if (-not (Test-Path -LiteralPath $dockerfilePath -PathType Leaf)) {
  throw "Không tìm thấy Dockerfile của service '$Service': $dockerfilePath"
}

$image = "ghcr.io/phamluongbaothien/${Service}:local"
$archiveName = ".securelearn-${Service}-$([guid]::NewGuid().ToString('N')).tar"
$archivePath = Join-Path $workspaceRoot $archiveName
$loaderPod = $null

try {
  Write-Host "[1/5] Build $image"
  Invoke-NativeCommand {
    docker build -f $dockerfilePath -t $image (Join-Path $workspaceRoot 'backend')
  } "Docker build thất bại"

  Write-Host "[2/5] Xuất image tạm"
  Invoke-NativeCommand {
    docker save -o $archivePath $image
  } "Docker save thất bại"

  $node = (& kubectl get nodes -o jsonpath='{.items[0].metadata.name}').Trim()
  if ($LASTEXITCODE -ne 0 -or -not $node) {
    throw 'Không tìm thấy Kubernetes node.'
  }

  Write-Host "[3/5] Nạp image vào Kubernetes node $node"
  Invoke-NativeCommand {
    kubectl debug "node/$node" -q --image=busybox:1.36 --profile=sysadmin -- sleep 600
  } "Không thể tạo image-loader pod"

  $deadline = (Get-Date).AddSeconds(60)
  do {
    Start-Sleep -Seconds 1
    $loaderPod = (& kubectl get pods `
      --field-selector "spec.nodeName=$node,status.phase=Running" `
      -o name |
      Where-Object { $_ -like 'pod/node-debugger-*' } |
      Select-Object -Last 1) -replace '^pod/', ''
  } until ($loaderPod -or (Get-Date) -ge $deadline)

  if (-not $loaderPod) {
    throw 'Image-loader pod không chuyển sang trạng thái Running.'
  }

  $nodeArchivePath = "/host/tmp/securelearn-${Service}-local.tar"
  Push-Location $workspaceRoot
  try {
    Invoke-NativeCommand {
      kubectl cp ".\$archiveName" "${loaderPod}:$nodeArchivePath"
    } "Không thể chép image vào Kubernetes node"
  }
  finally {
    Pop-Location
  }

  Invoke-NativeCommand {
    kubectl exec $loaderPod -- chroot /host ctr -n k8s.io images import "/tmp/securelearn-${Service}-local.tar"
  } "Không thể import image vào containerd"

  Write-Host "[4/5] Cập nhật deployment/$Service"
  Invoke-NativeCommand {
    kubectl -n securelearn-local set image "deployment/$Service" "$Service=$image"
  } "Không thể cập nhật image của deployment"

  # set image does not create a new ReplicaSet when the deployment already uses :local.
  Invoke-NativeCommand {
    kubectl -n securelearn-local rollout restart "deployment/$Service"
  } "Không thể restart deployment"

  Write-Host "[5/5] Chờ rollout hoàn tất"
  Invoke-NativeCommand {
    kubectl -n securelearn-local rollout status "deployment/$Service" --timeout=180s
  } "Rollout không hoàn tất"

  Write-Host "Đã deploy $Service bằng image local mới nhất." -ForegroundColor Green
}
finally {
  if ($loaderPod) {
    & kubectl exec $loaderPod -- rm -f "/host/tmp/securelearn-${Service}-local.tar" 2>$null
    & kubectl delete pod $loaderPod --ignore-not-found=true 2>$null
  }

  if (Test-Path -LiteralPath $archivePath) {
    Remove-Item -LiteralPath $archivePath -Force -ErrorAction SilentlyContinue
  }
}
