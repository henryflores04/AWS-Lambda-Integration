# build.ps1 - Empaqueta las dependencias de las Lambdas con binarios linux-x64.
#
# Por que existe: sharp incluye binarios nativos compilados por plataforma.
# Si se instala en Windows, node_modules queda con binarios win32-x64 y la
# Lambda falla en runtime con "Could not load the sharp module using the
# linux-x64 runtime". Este script construye las dependencias dentro de un
# contenedor con la MISMA imagen que usa AWS Lambda, garantizando que los
# binarios correspondan a linux-x64.
#
# Uso:  .\build.ps1
# Requiere: Docker Desktop en ejecucion.

$ErrorActionPreference = "Stop"
$env:DOCKER_BUILDKIT = "1"

foreach ($lambda in @("upload", "crop")) {
    Write-Host "=== Construyendo dependencias de $lambda-lambda ===" -ForegroundColor Cyan

    # Limpia el node_modules anterior para evitar restos de un build con
    # plataforma equivocada.
    Remove-Item -Recurse -Force ".\src\$lambda\node_modules" -ErrorAction SilentlyContinue

    docker build --no-cache --output "type=local,dest=./src/$lambda" "./src/$lambda"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FALLO el build de $lambda" -ForegroundColor Red
        exit 1
    }

    Write-Host "=== OK: src/$lambda/node_modules ===" -ForegroundColor Green
    Write-Host ""
}

Write-Host "Verificacion de binarios nativos de sharp:" -ForegroundColor Cyan
Get-ChildItem ".\src\crop\node_modules\@img" | Select-Object -ExpandProperty Name

Write-Host ""
Write-Host "Debe aparecer sharp-linux-x64 y sharp-libvips-linux-x64." -ForegroundColor Yellow
Write-Host "Siguiente paso: terraform plan -var-file environments/dev.tfvars"
