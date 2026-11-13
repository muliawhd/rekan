param([Parameter(Mandatory)][ValidateSet('infra-up', 'infra-down', 'infra-status', 'api', 'mobile', 'smoke')][string] $Target)
. "$PSScriptRoot/common.ps1"
if ($Target.StartsWith('infra-')) {
    Require-Tool docker
    $arguments = @('compose', '--env-file', (Join-Path $RepoRoot 'infrastructure/docker/.env'), '-f', (Join-Path $RepoRoot 'infrastructure/docker/compose.yaml'))
    switch ($Target) {
        'infra-up' { $arguments += @('up', '-d', '--wait') }
        'infra-down' { $arguments += @('down') } # Named volumes are retained.
        'infra-status' { $arguments += @('ps') }
    }
    Invoke-Native docker $arguments
} elseif ($Target -eq 'smoke') {
    foreach ($path in @('/api/v1/health', '/api/health')) {
        $response = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:8000$path" -TimeoutSec 10
        $body = $response.Content | ConvertFrom-Json
        if ($response.StatusCode -ne 200 -or $body.status -ne 'ok' -or @($body.PSObject.Properties).Count -ne 1) {
            throw "Unexpected liveness response at $path"
        }
        Write-Output "$path returned HTTP 200 with the expected liveness body."
    }
} else {
    $folder = if ($Target -eq 'api') { 'services/api' } else { 'apps/mobile' }
    Push-Location (Join-Path $RepoRoot $folder)
    try {
        if ($Target -eq 'api') {
            Require-Tool php
            Invoke-Native php @('artisan', 'serve', '--host=127.0.0.1', '--port=8000')
        } else {
            Require-Tool flutter
            Invoke-Native flutter @('run', '--dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1')
        }
    } finally { Pop-Location }
}
