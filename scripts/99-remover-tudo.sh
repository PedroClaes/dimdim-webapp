#!/usr/bin/env bash
# =========================================================
# DimDim - Remove TODOS os recursos (apaga o grupo de recursos inteiro)
# Use só depois da entrega e da correção, para não gerar custo.
# =========================================================
set -euo pipefail
cd "$(dirname "$0")"
source ./00-variaveis.sh

read -r -p "Isso apaga ${RESOURCE_GROUP} e tudo dentro dele. Digite o nome do grupo para confirmar: " CONFIRMA
if [ "$CONFIRMA" != "$RESOURCE_GROUP" ]; then
  echo "Cancelado."
  exit 1
fi
# O Log Analytics fica 14 dias em "exclusão reversível" se for apagado junto com o grupo,
# o que impede recriar o mesmo nome. Por isso ele é excluído de forma definitiva antes.
az monitor log-analytics workspace delete \
  --resource-group "$RESOURCE_GROUP" --workspace-name "$LOG_WORKSPACE" \
  --force true --yes 2>/dev/null || true

az group delete --name "$RESOURCE_GROUP" --yes --no-wait
echo "Exclusão iniciada (roda em segundo plano na Azure)."
