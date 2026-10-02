param(
    [Parameter(Mandatory = $true)] [string] $WebAppName,
    [Parameter(Mandatory = $true)] [string] $AlertEmail,
    [string] $ResourceGroup = "devops-proj-rg",
    [string] $Location = "eastus",
    [string] $WorkspaceName = "devops-proj-logs",
    [string] $AppInsightsName = "devops-proj-ai",
    [string] $ActionGroupName = "devops-proj-alerts",
    # F1 (Free) allows 60 CPU minutes/day; alert when a 5-minute window uses > 120 CPU seconds
    [int] $CpuTimeSecondsThreshold = 120
)

$ErrorActionPreference = "Stop"

function Invoke-Az {
    $out = & az @args
    if ($LASTEXITCODE -ne 0) { throw "az $($args -join ' ') failed" }
    return $out
}

Invoke-Az extension add --name application-insights --upgrade --only-show-errors | Out-Null

# Log Analytics workspace + workspace-based Application Insights
Invoke-Az monitor log-analytics workspace create `
    --resource-group $ResourceGroup --workspace-name $WorkspaceName --location $Location | Out-Null

$workspaceId = Invoke-Az monitor log-analytics workspace show `
    --resource-group $ResourceGroup --workspace-name $WorkspaceName --query id -o tsv

Invoke-Az monitor app-insights component create `
    --app $AppInsightsName --resource-group $ResourceGroup --location $Location `
    --kind web --application-type web --workspace $workspaceId | Out-Null

$aiConnString = Invoke-Az monitor app-insights component show `
    --app $AppInsightsName --resource-group $ResourceGroup --query connectionString -o tsv

# Connect the web app to Application Insights
Invoke-Az webapp config appsettings set `
    --name $WebAppName --resource-group $ResourceGroup `
    --settings "APPLICATIONINSIGHTS_CONNECTION_STRING=$aiConnString" `
               "ApplicationInsightsAgent_EXTENSION_VERSION=~3" | Out-Null

# Send web app platform logs and metrics to the workspace
$webAppId = Invoke-Az webapp show --name $WebAppName --resource-group $ResourceGroup --query id -o tsv

$logs = '[{"category":"AppServiceHTTPLogs","enabled":true},{"category":"AppServiceConsoleLogs","enabled":true},{"category":"AppServiceAppLogs","enabled":true}]'
$metrics = '[{"category":"AllMetrics","enabled":true}]'
Invoke-Az monitor diagnostic-settings create `
    --name "send-to-law" --resource $webAppId --workspace $workspaceId `
    --logs $logs --metrics $metrics | Out-Null

# Action group (email notification)
Invoke-Az monitor action-group create `
    --name $ActionGroupName --resource-group $ResourceGroup --short-name "devopsalr" `
    --action email admin $AlertEmail | Out-Null

$actionGroupId = Invoke-Az monitor action-group show `
    --name $ActionGroupName --resource-group $ResourceGroup --query id -o tsv

# CPU alert. Free/Shared plans don't expose CpuPercentage, so use the web app's CpuTime metric.
Invoke-Az monitor metrics alert create `
    --name "$WebAppName-high-cpu" --resource-group $ResourceGroup --scopes $webAppId `
    --condition "total CpuTime > $CpuTimeSecondsThreshold" `
    --window-size 5m --evaluation-frequency 1m --severity 2 `
    --description "High CPU time on $WebAppName" --action $actionGroupId | Out-Null

# Server error alert
Invoke-Az monitor metrics alert create `
    --name "$WebAppName-http-5xx" --resource-group $ResourceGroup --scopes $webAppId `
    --condition "total Http5xx > 5" `
    --window-size 5m --evaluation-frequency 1m --severity 2 `
    --description "More than 5 HTTP 5xx responses in 5 minutes" --action $actionGroupId | Out-Null

# Slow response alert
Invoke-Az monitor metrics alert create `
    --name "$WebAppName-slow-response" --resource-group $ResourceGroup --scopes $webAppId `
    --condition "avg HttpResponseTime > 3" `
    --window-size 5m --evaluation-frequency 1m --severity 3 `
    --description "Average response time above 3 seconds" --action $actionGroupId | Out-Null

Write-Host "Monitoring configured for $WebAppName (alerts email: $AlertEmail)"
