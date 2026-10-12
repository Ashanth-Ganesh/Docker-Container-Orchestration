param([string]$EmailUsername = "ganeshat")

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
if ($EmailUsername -notmatch '^[A-Za-z0-9_-]+$') {
    throw "EmailUsername must contain only letters, numbers, underscores, or hyphens."
}

function Invoke-Docker {
    param([string[]]$Arguments)
    & docker @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Docker command failed: docker $Arguments" }
}

New-Item -ItemType Directory -Force -Path output, submission | Out-Null
Invoke-Docker -Arguments @("build", "--platform", "linux/amd64", "-t", "project3:latest", ".")
$imageSize = & docker image inspect project3:latest --format '{{.Size}}'
if ($LASTEXITCODE -ne 0) { throw "Could not inspect the image." }
if ([long]$imageSize -ge 200000000) { throw "Image exceeds the 200 MB assignment target." }
"Image size: $([math]::Round([long]$imageSize / 1000000, 2)) MB"

$outputDir = Join-Path $PSScriptRoot "output"
$console = & docker run --rm --mount "type=bind,source=$outputDir,target=/home/data/output" project3:latest
if ($LASTEXITCODE -ne 0) { throw "The project container failed." }
$console | Tee-Object -FilePath "submission/container_output.txt"
Copy-Item -LiteralPath "output/result.txt" -Destination "submission/result.txt"
Copy-Item -LiteralPath Dockerfile -Destination "submission/Dockerfile.txt"
Copy-Item -LiteralPath scripts.py -Destination "submission/scripts.py.txt"
Copy-Item -LiteralPath kubernetes.yaml -Destination "submission/kubernetes.yaml"

# Save the IMAGE with its CMD and layers, rather than exporting a container.
Invoke-Docker -Arguments @("image", "save", "--output", "submission/$EmailUsername.tar", "project3:latest")
"Submission files are ready in $(Join-Path $PSScriptRoot 'submission')."
