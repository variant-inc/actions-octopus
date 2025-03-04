$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"
$WarningPreference = "SilentlyContinue"

Trap {
  Write-Error $_.InvocationInfo.ScriptName -ErrorAction Continue
  $line = "$($_.InvocationInfo.ScriptLineNumber): $($_.InvocationInfo.Line)"
  Write-Error $line -ErrorAction Continue
  Write-Error $_
}

$S3Bucket = $env:MAGE_S3_BUCKET
$MageRelease = $env:MAGE_RELEASE
$S3Key = "$MageRelease/mage-runner/mage-runner.$env:MAGE_RUNNER_VERSION.zip"
$ZipFilePath = "cache/mage/mage-runner.$env:MAGE_RUNNER_VERSION.zip"

Write-Host "Fetching $S3Key from s3://$S3Bucket/"
aws s3 cp "s3://$S3Bucket/$S3Key" $ZipFilePath --force

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to fetch $S3Key from S3. AWS CLI returned exit code $LASTEXITCODE."
    exit $LASTEXITCODE
}

if (Test-Path -Path $ZipFilePath) {
    Write-Host "Successfully fetched $ZipFilePath. Extracting..."
    Expand-Archive -Path $ZipFilePath -DestinationPath "cache/mage" -Force
    chmod +x cache/mage/mage
} else {
    Write-Error "Failed to fetch $S3Key from S3."
    exit 1
}

"cache_path=cache/mage/mage" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
