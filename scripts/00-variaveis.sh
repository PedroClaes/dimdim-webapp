#!/usr/bin/env bash
# =========================================================
# DimDim - variáveis comuns a todos os scripts
# Grupo: dimdimCP5 | Assinatura do representante: RM 566058
# Não rodar sozinho: os outros scripts carregam este arquivo.
# =========================================================

RM="566058"

# Região. Se a assinatura de estudante recusar com "RequestDisallowedByPolicy"
# ou "not accepting creation of new ... servers", troque (ex.: eastus2, eastus, westus2).
LOCATION="eastus"

RESOURCE_GROUP="rg-dimdim-${RM}"

# Azure SQL (o nome do servidor precisa ser único no mundo todo, por isso o RM)
SQL_SERVER="sqlserver-dimdim-${RM}"
SQL_DB="db-dimdim"
SQL_ADMIN_USER="dimdimadmin"
# A SENHA NÃO FICA AQUI: ela é pedida na hora (ou lida da variável SQL_ADMIN_PASSWORD)

# Web App (App Service) - o nome vira a URL: https://webapp-dimdim-566058.azurewebsites.net
APP_PLAN="plan-dimdim-${RM}"
APP_SKU="B1"
WEBAPP="webapp-dimdim-${RM}"
WEBAPP_RUNTIME="JAVA:17-java17"

# Monitoramento
LOG_WORKSPACE="law-dimdim-${RM}"
APP_INSIGHTS="appi-dimdim-${RM}"
