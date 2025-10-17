#!/bin/bash

set -e          # Exit on error
set -u          # Treat unset variables as an error
set -o pipefail # Exit on errors in pipelines

full_unzip_path="$UNZIP_PATH/$S3_KEY"

echo "Fetching $S3_KEY from S3..."
aws s3 cp "s3://$DX_PACKAGES_S3_BUCKET/$S3_KEY" "$full_unzip_path" --force

echo "Successfully fetched $full_unzip_path. Extracting..."
unzip -o "$full_unzip_path" -d "$UNZIP_PATH"
