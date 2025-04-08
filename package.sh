#!/bin/bash

set -e          # Exit on error
set -u          # Treat unset variables as an error
set -o pipefail # Exit on errors in pipelines

filename="mage-runner.$MAGE_RUNNER_VERSION.zip"
zipFilePath="$MAGE_DIR_PATH/$filename"
prefix="mage-runner/$filename"

echo "Fetching $filename from S3..."
aws s3 cp "s3://$DX_PACKAGES_S3_BUCKET/$prefix" "$zipFilePath" --force

echo "Successfully fetched $zipFilePath. Extracting..."
unzip -o "$zipFilePath" -d "$MAGE_DIR_PATH"

chmod +x "$MAGE_DIR_PATH"/mage
