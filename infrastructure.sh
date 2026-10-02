#!/bin/bash
set -euo pipefail

# Adjust these values. The web app name must be globally unique.
RESOURCE_GROUP="devops-proj-rg"
PLAN_NAME="devops-proj-plan"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/app-config.env"   # provides WEBAPP_NAME and LOCATION
RUNTIME="DOTNETCORE:10.0"   # .NET 10 (LTS); list options: az webapp list-runtimes --os linux

# Resource group
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

# App Service plan - F1 is the Free tier (Linux)
az appservice plan create \
  --name "$PLAN_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --sku F1 \
  --is-linux

# Web app on the plan
az webapp create \
  --name "$WEBAPP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --plan "$PLAN_NAME" \
  --runtime "$RUNTIME"

echo "Web app URL: https://$(az webapp show -g "$RESOURCE_GROUP" -n "$WEBAPP_NAME" --query defaultHostName -o tsv)"
