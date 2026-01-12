#!/usr/bin/env bash
set -euo pipefail

# Updates JDK_URL_* entries in a version.properties file using Adoptium API.
FILE_PATH=${1:-version.properties}
API_ROOT="https://api.adoptium.net/v3/assets/latest"

if [[ ! -f "$FILE_PATH" ]]; then
    echo "File not found: $FILE_PATH" >&2
    exit 1
fi

# Extract SUPPORTED_VERSIONS
supported_versions=$(grep -E '^SUPPORTED_VERSIONS=' "$FILE_PATH" | sed 's/.*="//; s/".*//')
if [[ -z "${supported_versions:-}" ]]; then
    echo "SUPPORTED_VERSIONS not found in $FILE_PATH" >&2
    exit 1
fi

declare -A urls

# Fetch and validate download link
fetch_and_validate_url() {
    local version="$1"
    local url="$API_ROOT/$version/hotspot?architecture=x64&os=linux&image_type=jdk"
    
    # Call API
    local json
    json=$(curl -fsSL "$url")
    
    # Parse JSON to get download link
    local link
    if command -v jq >/dev/null 2>&1; then
        link=$(echo "$json" | jq -r '.[0].binary.package.link')
    else
        # Extract GitHub URL ending with .tar.gz (no python required)
        link=$(echo "$json" | grep -oE 'https://github\.com/[^"]*\.tar\.gz' | head -1)
    fi
    
    if [[ -z "$link" ]]; then
        echo "Could not read download link for version $version" >&2
        exit 1
    fi
    
    # Validate link with HEAD request
    if ! curl -fsSLI -o /dev/null -w "%{http_code}" "$link" | grep -q "^200$"; then
        echo "Download link not valid for version $version: $link" >&2
        exit 1
    fi
    
    echo "$link"
}

# Fetch URLs for all versions
for ver in $supported_versions; do
    urls[$ver]="$(fetch_and_validate_url "$ver")"
done

# Update existing JDK_URL_* lines and remove processed versions from urls
tmp_file=$(mktemp)
while IFS= read -r line; do
    if [[ "$line" =~ ^JDK_URL_([0-9]+)= ]]; then
        ver="${BASH_REMATCH[1]}"
        if [[ -n "${urls[$ver]:-}" ]]; then
            echo "JDK_URL_${ver}=${urls[$ver]}" >> "$tmp_file"
            unset 'urls[$ver]'
            continue
        fi
    fi
    echo "$line" >> "$tmp_file"
done < "$FILE_PATH"

# Add remaining versions (new entries)
for ver in "${!urls[@]}"; do
    echo "JDK_URL_${ver}=${urls[$ver]}" >> "$tmp_file"
done

mv "$tmp_file" "$FILE_PATH"
echo "Updated $FILE_PATH"