param(
  [string]$EnvFile = ".env"
)

$ErrorActionPreference = "Stop"

$GcloudCommand = Get-Command gcloud -ErrorAction SilentlyContinue
if (-not $GcloudCommand) {
  $DefaultGcloud = Join-Path $env:LOCALAPPDATA "Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
  if (Test-Path $DefaultGcloud) {
    $GcloudCommand = $DefaultGcloud
  } else {
    throw "gcloud is not installed or not available in PATH."
  }
}

if (-not (Test-Path $EnvFile)) {
  throw "Missing $EnvFile. Run this script from the northuen-backend folder."
}

$required = @(
  "DATABASE_URL",
  "DATABASE_USERNAME",
  "DATABASE_PASSWORD",
  "JWT_SECRET",
  "GOOGLE_SERVER_API_KEY",
  "ADMIN_EMAIL",
  "ADMIN_PASSWORD",
  "ADMIN_PHONE"
)

$values = @{}
foreach ($line in Get-Content $EnvFile) {
  if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith("#")) {
    continue
  }
  $parts = $line -split "=", 2
  if ($parts.Count -eq 2) {
    $values[$parts[0].Trim()] = $parts[1]
  }
}

foreach ($name in $required) {
  if (-not $values.ContainsKey($name) -or [string]::IsNullOrWhiteSpace($values[$name])) {
    throw "Missing required env value: $name"
  }

  $tempSecretFile = [System.IO.Path]::GetTempFileName()
  [System.IO.File]::WriteAllText($tempSecretFile, $values[$name], [System.Text.UTF8Encoding]::new($false))

  & $GcloudCommand secrets describe $name --format="value(name)" *> $null
  $exists = $LASTEXITCODE -eq 0

  try {
    if ($exists) {
      & $GcloudCommand secrets versions add $name --data-file=$tempSecretFile
      if ($LASTEXITCODE -ne 0) {
        throw "Failed to update secret: $name"
      }
      Write-Host "Updated secret: $name"
    } else {
      & $GcloudCommand secrets create $name --data-file=$tempSecretFile
      if ($LASTEXITCODE -ne 0) {
        throw "Failed to create secret: $name"
      }
      Write-Host "Created secret: $name"
    }
  } finally {
    if (Test-Path $tempSecretFile) {
      Remove-Item -LiteralPath $tempSecretFile -Force
    }
  }
}
