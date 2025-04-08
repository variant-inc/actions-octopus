#!/bin/bash

set -e          # Exit on error
set -u          # Treat unset variables as an error
set -o pipefail # Exit on errors in pipelines

get_version() {
	local bucket_name="$1"
	local prefix="$2"
	local constraint="$3"

	# Get the latest 50 files ordered by LastModified in descending order
	local files
	files=$(aws s3api list-objects-v2 --bucket "$bucket_name" --prefix "$prefix" \
		--query 'Contents | sort_by(@, &LastModified) | reverse(@)[:100].Key' --output json | jq -r '.[]' | tr '\n' ' ' | sed 's/ $//')

	# Extract versions from filenames and create a comma-separated list
	local prefix_basename
	prefix_basename=$(basename "$prefix")
	local versions
	versions=$(echo "$files" | sed 's|'"$prefix"'/'"$prefix_basename"'\.||g; s|\.zip||g' | tr -s ' ' ',')

	# Select the version based on the provided constraint
	go-version-select --versions "$versions" --constraint "$constraint"
}

find_best_version() {
	local app_name="$1"
	local bucket_name="$2"
	local prefix="$3"
	local constraint="$4"

	# Try to get the stable version
	local versions
	version=$(get_version "$bucket_name" "$prefix" "$constraint")

	if [[ -z "$version" ]]; then
		echo "No suitable version found for $app_name with constraint: $constraint"
		exit 1
	fi

	echo "$app_name version: $version"

	echo "${app_name}-version=$version" >>"$GITHUB_OUTPUT"
}

# Fetch version for mage-runner
find_best_version "mage-runner" "$DX_PACKAGES_S3_BUCKET" "mage-runner" "$MAGE_RUNNER_CONSTRAINT"

# Fetch version for terraform-variant-apps
find_best_version "tf-apps" "$DX_PACKAGES_S3_BUCKET" "terraform-variant-apps" "$TF_APPS_CONSTRAINT"
