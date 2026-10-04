#!/usr/bin/env bash
# =========================================================
# DimDim - Etapa 2 da infraestrutura: Web App + Application Insights
# Cria: Log Analytics, Application Insights, plano do App Service (Linux) e Web App Java 17.
# Configura as variáveis de ambiente do app (banco e monitoramento).
# Pré-requisito: ter rodado o 01-criar-banco.sh
# Uso:  ./scripts/02-criar-webapp.sh
# =========================================================
set -euo pipefail
cd "$(dirname "$0")"
source ./00-variaveis.sh

# Senha do banco: a mesma criada no 01. Não fica em arquivo, vai só para as app settings.
if [ -z "${SQL_ADMIN_PASSWORD:-}" ]; then
  read -r -s -p "Senha do admin do SQL (a mesma do script 01): " SQL_ADMIN_PASSWORD
  echo
fi

# Instala extensões do az (ex.: application-insights) sem perguntar
az config set extension.use_dynamic_install=yes_without_prompt > /dev/null

echo ">> Registrando provedores Microsoft.Web, Microsoft.Insights e Microsoft.OperationalInsights"
az provider register --namespace Microsoft.Web --wait
az provider register --namespace Microsoft.Insights --wait
az provider register --namespace Microsoft.OperationalInsights --wait

echo ">> Criando o workspace do Log Analytics ${LOG_WORKSPACE} (onde o App Insights guarda os dados)"
az monitor log-analytics workspace create \
  --resource-group "$RESOURCE_GROUP" \
  --workspace-name "$LOG_WORKSPACE" \
  --location "$LOCATION" \
  --output table

WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group "$RESOURCE_GROUP" --workspace-name "$LOG_WORKSPACE" \
  --query id --output tsv)

echo ">> Criando o Application Insights ${APP_INSIGHTS}"
az monitor app-insights component create \
  --app "$APP_INSIGHTS" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --application-type web \
  --workspace "$WORKSPACE_ID" \
  --output table

AI_CONNECTION_STRING=$(az monitor app-insights component show \
  --app "$APP_INSIGHTS" --resource-group "$RESOURCE_GROUP" \
  --query connectionString --output tsv)

echo ">> Criando o plano do App Service ${APP_PLAN} (Linux, ${APP_SKU})"
az appservice plan create \
  --name "$APP_PLAN" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --is-linux \
  --sku "$APP_SKU" \
  --output table

echo ">> Criando o Web App ${WEBAPP} (${WEBAPP_RUNTIME})"
az webapp create \
  --name "$WEBAPP" \
  --resource-group "$RESOURCE_GROUP" \
  --plan "$APP_PLAN" \
  --runtime "$WEBAPP_RUNTIME" \
  --output table

echo ">> Configurando as variáveis de ambiente do Web App (app settings)"
# DB_*: lidas pelo application.properties | SERVER_PORT: porta que o App Service encaminha
# APPLICATIONINSIGHTS_* + ApplicationInsightsAgent_EXTENSION_VERSION: liga o agente Java do App Insights
az webapp config appsettings set \
  --name "$WEBAPP" \
  --resource-group "$RESOURCE_GROUP" \
  --settings \
    "DB_URL=jdbc:sqlserver://${SQL_SERVER}.database.windows.net:1433;database=${SQL_DB};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;" \
    "DB_USER=${SQL_ADMIN_USER}" \
    "DB_PASSWORD=${SQL_ADMIN_PASSWORD}" \
    "SERVER_PORT=80" \
    "APPLICATIONINSIGHTS_CONNECTION_STRING=${AI_CONNECTION_STRING}" \
    "ApplicationInsightsAgent_EXTENSION_VERSION=~3" \
    "XDT_MicrosoftApplicationInsights_Mode=Recommended" \
    "XDT_MicrosoftApplicationInsights_PreemptSdk=1" \
  --output none

echo ">> Conectando o Web App ao Application Insights"
az monitor app-insights component connect-webapp \
  --app "$APP_INSIGHTS" \
  --web-app "$WEBAPP" \
  --resource-group "$RESOURCE_GROUP" \
  --output none

echo ">> Ativando logs da aplicação (para acompanhar com az webapp log tail)"
az webapp log config \
  --name "$WEBAPP" \
  --resource-group "$RESOURCE_GROUP" \
  --application-logging filesystem \
  --docker-container-logging filesystem \
  --output none

echo ">> Reiniciando o Web App para aplicar as configurações"
az webapp restart --name "$WEBAPP" --resource-group "$RESOURCE_GROUP"

echo ""
echo "================ PRONTO ================"
echo "Web App          : https://${WEBAPP}.azurewebsites.net"
echo "App Insights     : ${APP_INSIGHTS}"
echo "Próximo passo    : ./scripts/03-deploy.sh"
