#!/usr/bin/env bash
# Aplica os manifestos k8s/ (a numeracao dos arquivos garante a ordem de criacao).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$ROOT_DIR"

echo "==> Aplicando manifestos de k8s/"
kubectl apply -f k8s/

echo "==> Manifestos aplicados."
