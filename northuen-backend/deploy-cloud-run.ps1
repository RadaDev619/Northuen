param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectId,

  [string]$Region = "asia-south1",
  [string]$Service = "northuen-backend",
  [string]$EnvFile = "cloudrun.env.yaml"
)

$ErrorActionPreference = "Stop"

$GcloudCommand = Get-Command gcloud -ErrorAction SilentlyContinue
if (-not $GcloudCommand) {
  $DefaultGcloud = Join-Path $env:LOCALAPPDATA "Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
  if (Test-Path $DefaultGcloud) {
    $GcloudCommand = $DefaultGcloud
  } else {
    throw "gcloud is not installed. Install Google Cloud CLI first: https://cloud.google.com/sdk/docs/install"
  }
}

if (-not (Test-Path $EnvFile)) {
  throw "Missing $EnvFile. Copy cloudrun.env.example.yaml to cloudrun.env.yaml and fill non-secret values first."
}

$secretSpec = "DATABASE_URL=DATABASE_URL:latest,DATABASE_USERNAME=DATABASE_USERNAME:latest,DATABASE_PASSWORD=DATABASE_PASSWORD:latest,JWT_SECRET=JWT_SECRET:latest,GOOGLE_SERVER_API_KEY=GOOGLE_SERVER_API_KEY:latest,ADMIN_EMAIL=ADMIN_EMAIL:latest,ADMIN_PASSWORD=ADMIN_PASSWORD:latest,ADMIN_PHONE=ADMIN_PHONE:latest"

& $GcloudCommand config set project $ProjectId

$ProjectNumber = (& $GcloudCommand projects describe $ProjectId --format="value(projectNumber)")
$RuntimeServiceAccount = "$ProjectNumber-compute@developer.gserviceaccount.com"

& $GcloudCommand services enable `
  run.googleapis.com `
  cloudbuild.googleapis.com `
  artifactregistry.googleapis.com `
  secretmanager.googleapis.com

& $GcloudCommand projects add-iam-policy-binding $ProjectId `
  --member "serviceAccount:$RuntimeServiceAccount" `
  --role "roles/secretmanager.secretAccessor" `
  --quiet

& $GcloudCommand run deploy $Service `
  --source . `
  --region $Region `
  --allow-unauthenticated `
  --port 8080 `
  --memory 1Gi `
  --cpu 1 `
  --min-instances 0 `
  --max-instances 2 `
  --timeout 300 `
  --env-vars-file $EnvFile `
  --set-secrets $secretSpec `
  --quiet
