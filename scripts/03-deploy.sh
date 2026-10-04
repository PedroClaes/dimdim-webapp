#!/usr/bin/env bash
# =========================================================
# DimDim - Deploy da aplicação no Web App (az webapp deploy)
# Compila o projeto com Maven e publica o target/dimdim.jar.
# Pode ser rodado de novo a cada alteração no código.
# Uso:  ./scripts/03-deploy.sh
# =========================================================
set -euo pipefail
cd "$(dirname "$0")/.."      # raiz do projeto (onde está o pom.xml)
source ./scripts/00-variaveis.sh

echo ">> Compilando o projeto (mvn clean package)"
mvn -q clean package -DskipTests

echo ">> Publicando target/dimdim.jar no Web App ${WEBAPP}"
az webapp deploy \
  --resource-group "$RESOURCE_GROUP" \
  --name "$WEBAPP" \
  --src-path target/dimdim.jar \
  --type jar

echo ""
echo "================ DEPLOY CONCLUÍDO ================"
echo "Acesse: https://${WEBAPP}.azurewebsites.net"
echo "Logs ao vivo: az webapp log tail --name ${WEBAPP} --resource-group ${RESOURCE_GROUP}"
