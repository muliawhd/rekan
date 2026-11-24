param([Parameter(Mandatory)][ValidateSet('mobile', 'api', 'infra', 'connections')][string] $Target)
. "$PSScriptRoot/common.ps1"
switch ($Target) {
    'connections' {
        Require-Tool php
        Push-Location (Join-Path $RepoRoot 'services/api')
        try {
            Invoke-Native php @('artisan', 'foundation:check')
        } finally { Pop-Location }
    }
    'mobile' {
        Require-Tool flutter
        Require-Tool dart
        Push-Location (Join-Path $RepoRoot 'apps/mobile')
        try {
            Invoke-Native flutter @('doctor')
            Invoke-Native dart @('format', '--output=none', '--set-exit-if-changed', 'lib', 'test')
            Invoke-Native flutter @('analyze')
            Invoke-Native flutter @('test')
        } finally { Pop-Location }
    }
    'api' {
        Require-Tool php
        Push-Location (Join-Path $RepoRoot 'services/api')
        try {
            Invoke-Native php @('artisan', 'route:list')
            Invoke-Native php @('vendor/bin/pint', '--test')
            Invoke-Native php @('artisan', 'test')
        } finally { Pop-Location }
    }
    'infra' {
        Require-Tool docker
        Invoke-Native docker @('compose', '--env-file', (Join-Path $RepoRoot 'infrastructure/docker/.env'), '-f', (Join-Path $RepoRoot 'infrastructure/docker/compose.yaml'), 'config', '--quiet')
    }
}
