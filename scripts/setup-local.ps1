. "$PSScriptRoot/common.ps1"
$dockerEnv = Join-Path $RepoRoot 'infrastructure/docker/.env'
$apiEnv = Join-Path $RepoRoot 'services/api/.env'
if ((Test-Path $dockerEnv) -or (Test-Path $apiEnv)) {
    throw 'A local environment already exists. Preserve it and configure the other file manually from its template.'
}
$bytes = New-Object byte[] 32
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
$password = [Convert]::ToBase64String($bytes)
$utf8 = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($dockerEnv, "LOCAL_POSTGRES_PASSWORD=$password`n", $utf8)
$apiTemplate = [IO.File]::ReadAllText((Join-Path $RepoRoot 'services/api/.env.example'))
[IO.File]::WriteAllText($apiEnv, $apiTemplate.Replace('DB_PASSWORD=', "DB_PASSWORD=$password"), $utf8)
Write-Output 'Created ignored local environment files with a shared random database password. No cloud credentials were created.'
