$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

# These demo containers automatically exit after 15 minutes.
foreach ($number in 1..2) {
    $name = "project3-preview-$number"
    $existing = & docker ps --all --filter "name=^/$name$" --format '{{.Names}}'
    if ($LASTEXITCODE -ne 0) { throw "Could not access Docker Desktop." }
    if ($existing) {
        throw "$name already exists. Remove the old demo with docker rm -f $name and rerun."
    }
    & docker run -d --name $name project3:latest /bin/sh -c 'python /app/scripts.py && exec sleep 900'
    if ($LASTEXITCODE -ne 0) { throw "Could not start $name. Run .\run.ps1 first." }
}
"Take a screenshot of Docker Desktop > Containers showing both project3-preview containers running."
"They exit automatically after 15 minutes. Their reports are visible in the Logs tab."
