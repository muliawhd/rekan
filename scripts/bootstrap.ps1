param([Parameter(Mandatory)][ValidateSet('mobile', 'api')][string] $Target)
. "$PSScriptRoot/common.ps1"

# Generate official projects only with installed toolchains. Never replace an
# existing application. Staging is retained for diagnosis if a command fails.
if ($Target -eq 'mobile') {
    Require-Tool flutter
    $destination = Join-Path $RepoRoot 'apps/mobile'
    $marker = Join-Path $destination 'pubspec.yaml'
} else {
    Require-Tool php
    Require-Tool composer
    $destination = Join-Path $RepoRoot 'services/api'
    $marker = Join-Path $destination 'composer.json'
    Invoke-Native php @('-r', 'exit(PHP_VERSION_ID >= 80200 ? 0 : 1);')
}
if (Test-Path $marker) {
    throw "An application already exists at $destination. Bootstrap will not overwrite it."
}
$staging = Join-Path $RepoRoot ('.local/scaffold-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path (Split-Path $staging) | Out-Null

if ($Target -eq 'mobile') {
    Invoke-Native flutter @('create', '--empty', '--no-pub', '--platforms=android', '--project-name=re_mobile', '--org=com.example.re', $staging)
} else {
    # Laravel 12 supports PHP 8.2-8.5. Pin the major; commit the generated lockfile.
    # Prevent skeleton hooks from creating SQLite or migrating password tables.
    Invoke-Native composer @('create-project', '--prefer-dist', '--no-interaction', '--no-scripts', '--no-install', 'laravel/laravel', $staging, '^12.0')
}

Get-ChildItem -LiteralPath $staging -Recurse -File -Force | ForEach-Object {
    $relative = $_.FullName.Substring($staging.Length + 1).Replace('\', '/')
    $skip = $relative -eq '.env' -or $relative -eq '.env.example'
    if ($Target -eq 'api') {
        # Identity belongs to Supabase. Domain migrations are a later milestone.
        $skip = $skip -or $relative.StartsWith('database/migrations/') -or
            $relative.StartsWith('database/factories/') -or
            $relative.StartsWith('database/seeders/') -or
            $relative -eq 'app/Models/User.php' -or
            $relative -eq 'tests/Feature/ExampleTest.php'
    }
    if (-not $skip) {
        $output = Join-Path $destination $relative
        New-Item -ItemType Directory -Force -Path (Split-Path $output) | Out-Null
        Copy-Item -LiteralPath $_.FullName -Destination $output
    }
}
$overlay = Join-Path $RepoRoot "infrastructure/scaffolding/$Target"
Get-ChildItem -LiteralPath $overlay -Force | Copy-Item -Destination $destination -Recurse -Force

Push-Location $destination
try {
    if ($Target -eq 'mobile') {
        Invoke-Native flutter @('pub', 'get')
        Invoke-Native dart @('format', 'lib', 'test')
    } else {
        New-Item -ItemType Directory -Force database/migrations,storage/framework/cache/data,storage/framework/sessions,storage/framework/views,storage/logs,bootstrap/cache | Out-Null
        if (-not (Test-Path .env)) { Copy-Item .env.example .env }
        Invoke-Native composer @('install', '--no-interaction', '--no-scripts')
        Invoke-Native php @('artisan', 'package:discover', '--ansi')
        if (Select-String -Path .env -Pattern '^APP_KEY=$' -Quiet) {
            Invoke-Native php @('artisan', 'key:generate', '--ansi')
        }
        Invoke-Native php @('vendor/bin/pint')
    }
} finally { Pop-Location }
Write-Output "$Target scaffold generated. Run scripts/check.ps1 -Target $Target and commit the generated sources and lockfile."
