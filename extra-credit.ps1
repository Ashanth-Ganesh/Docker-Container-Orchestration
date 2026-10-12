$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

function Invoke-Kubectl {
    param([string[]]$Arguments)
    & kubectl --context docker-desktop --namespace project3 @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Kubernetes command failed: kubectl $Arguments" }
}

& kubectl --context docker-desktop get nodes
if ($LASTEXITCODE -ne 0) {
    throw "Enable Kubernetes in Docker Desktop (choose kubeadm), wait for Ready, then rerun this script. See README.md."
}
& docker image inspect project3:latest 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Build the project first with .\run.ps1." }

New-Item -ItemType Directory -Force -Path submission | Out-Null
# kind nodes have separate image stores; kubeadm uses Desktop's local image.
$kindNodes = @(& docker ps --filter 'label=io.x-k8s.kind.cluster=docker-desktop' --format '{{.Names}}')
if ($LASTEXITCODE -ne 0) { throw "Could not inspect Docker Desktop's containers." }
if ($kindNodes.Count -gt 0) {
    $imageTar = Join-Path $PSScriptRoot 'submission/kubernetes-image.tar'
    & docker image save --output $imageTar project3:latest
    if ($LASTEXITCODE -ne 0) { throw "Could not save the Kubernetes image." }
    foreach ($node in $kindNodes) {
        & docker cp $imageTar "${node}:/tmp/project3-image.tar"
        if ($LASTEXITCODE -ne 0) { throw "Could not copy the image to $node." }
        & docker exec $node ctr --namespace k8s.io images import /tmp/project3-image.tar
        if ($LASTEXITCODE -ne 0) { throw "Could not import the image on $node." }
    }
}

Invoke-Kubectl -Arguments @("apply", "-f", "kubernetes.yaml")
Invoke-Kubectl -Arguments @("rollout", "status", "deployment/project3", "--timeout=120s")
$pods = & kubectl --context docker-desktop --namespace project3 get pods
if ($LASTEXITCODE -ne 0) { throw "Could not capture pod status." }
$pods | Set-Content -Encoding utf8 kube_output.txt
Get-Content kube_output.txt
Copy-Item -LiteralPath kube_output.txt -Destination submission/kube_output.txt
Copy-Item -LiteralPath kubernetes.yaml -Destination submission/kubernetes.yaml
$podNames = & kubectl --context docker-desktop --namespace project3 get pods -l app=project3 -o 'jsonpath={.items[*].metadata.name}'
if ($LASTEXITCODE -ne 0) { throw "Could not list the project pods." }
foreach ($pod in ($podNames -split ' ')) {
    $logs = & kubectl --context docker-desktop --namespace project3 logs $pod
    if ($LASTEXITCODE -ne 0) { throw "Could not retrieve logs from $pod." }
    $logs | Set-Content -Encoding utf8 "submission/$pod-output.txt"
}
"Extra-credit evidence saved in submission. Both replicas remain running for screenshots."
