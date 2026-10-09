#!/usr/bin/env bash
# build.sh - Empaqueta las dependencias de las Lambdas con binarios linux-x64.
#
# Por que existe: sharp incluye binarios nativos compilados por plataforma.
# Si se instala en Windows, node_modules queda con binarios win32-x64 y la
# Lambda falla en runtime con "Could not load the sharp module using the
# linux-x64 runtime". Este script construye las dependencias dentro de un
# contenedor con la MISMA imagen que usa AWS Lambda, garantizando que los
# binarios correspondan a linux-x64.
#
# Uso:  ./build.sh
# Requiere: Docker en ejecucion.

set -euo pipefail

export DOCKER_BUILDKIT=1

for lambda in upload crop; do
  echo "=== Construyendo dependencias de ${lambda}-lambda ==="
  docker build --no-cache --output "type=local,dest=./src/${lambda}" "./src/${lambda}"
  echo "=== OK: src/${lambda}/node_modules ==="
  echo
done

echo "Verificacion de binarios nativos de sharp:"
ls ./src/crop/node_modules/@img
echo
echo "Debe aparecer sharp-linux-x64 y sharp-libvips-linux-x64."
echo "Siguiente paso: terraform init && terraform plan -var-file environments/dev.tfvars"
