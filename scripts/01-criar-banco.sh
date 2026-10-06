#!/usr/bin/env bash
# =========================================================
# DimDim - Etapa 1 da infraestrutura: Azure SQL Database
# Cria: grupo de recursos, servidor lógico SQL, regras de firewall e o banco.
# Uso:  ./scripts/01-criar-banco.sh
# =========================================================
set -euo pipefail
cd "$(dirname "$0")"
source ./00-variaveis.sh

# Senha do administrador: nunca gravada em arquivo
if [ -z "${SQL_ADMIN_PASSWORD:-}" ]; then
  read -r -s -p "Senha do admin do SQL (mín. 8 caracteres: maiúscula, minúscula, número e símbolo): " SQL_ADMIN_PASSWORD
  echo
fi

echo ">> Registrando o provedor Microsoft.Sql na assinatura"
az provider register --namespace Microsoft.Sql --wait

echo ">> Criando o grupo de recursos ${RESOURCE_GROUP} em ${LOCATION}"
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output table

echo ">> Criando o servidor lógico ${SQL_SERVER} em ${SQL_LOCATION}"
az sql server create \
  --name "$SQL_SERVER" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$SQL_LOCATION" \
  --admin-user "$SQL_ADMIN_USER" \
  --admin-password "$SQL_ADMIN_PASSWORD" \
  --enable-public-network true \
  --output table

echo ">> Firewall: liberando serviços da Azure (é por aqui que o Web App vai acessar o banco)"
az sql server firewall-rule create \
  --resource-group "$RESOURCE_GROUP" \
  --server "$SQL_SERVER" \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0 \
  --output table

echo ">> Firewall: liberando o IP público desta máquina (para testes e para o Query Editor)"
MEU_IP=$(curl -s https://api.ipify.org)
az sql server firewall-rule create \
  --resource-group "$RESOURCE_GROUP" \
  --server "$SQL_SERVER" \
  --name "ip-$(hostname)" \
  --start-ip-address "$MEU_IP" \
  --end-ip-address "$MEU_IP" \
  --output table

echo ">> Criando o banco ${SQL_DB} (camada Basic, a mais barata)"
az sql db create \
  --resource-group "$RESOURCE_GROUP" \
  --server "$SQL_SERVER" \
  --name "$SQL_DB" \
  --service-objective Basic \
  --backup-storage-redundancy Local \
  --zone-redundant false \
  --output table

# Criação das tabelas: usa o sqlcmd se estiver instalado; senão, orienta pelo Query Editor
if command -v sqlcmd > /dev/null 2>&1; then
  # A regra de firewall recém-criada pode levar alguns segundos para valer:
  # tenta executar o DDL até 5 vezes, esperando 20 segundos entre as tentativas.
  echo ">> Executando o DDL (scripts/ddl.sql)"
  DDL_OK=0
  for TENTATIVA in 1 2 3 4 5; do
    if SQLCMDPASSWORD="$SQL_ADMIN_PASSWORD" sqlcmd \
         -S "${SQL_SERVER}.database.windows.net" -d "$SQL_DB" \
         -U "$SQL_ADMIN_USER" -l 30 -i ./ddl.sql; then
      DDL_OK=1
      break
    fi
    echo "   tentativa ${TENTATIVA} sem sucesso; aguardando 20 s para tentar de novo..."
    sleep 20
  done
  if [ "$DDL_OK" -ne 1 ]; then
    echo "!! Não foi possível conectar na porta 1433 do Azure SQL a partir desta rede."
    echo "   Verifique se a rede bloqueia a porta 1433 e rode de novo: ./scripts/01-criar-banco.sh"
    exit 1
  fi
  echo ">> Tabelas criadas:"
  SQLCMDPASSWORD="$SQL_ADMIN_PASSWORD" sqlcmd \
    -S "${SQL_SERVER}.database.windows.net" -d "$SQL_DB" \
    -U "$SQL_ADMIN_USER" -Q "SELECT name AS tabela FROM sys.tables ORDER BY name"
else
  echo ""
  echo "!! sqlcmd não encontrado. Crie as tabelas pelo portal:"
  echo "   Banco ${SQL_DB} > Query editor > login com ${SQL_ADMIN_USER} > cole o conteúdo de scripts/ddl.sql > Run"
fi

echo ""
echo "================ PRONTO ================"
echo "Servidor : ${SQL_SERVER}.database.windows.net"
echo "Banco    : ${SQL_DB}"
echo "Usuário  : ${SQL_ADMIN_USER}"
echo "JDBC URL : jdbc:sqlserver://${SQL_SERVER}.database.windows.net:1433;database=${SQL_DB};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;"
