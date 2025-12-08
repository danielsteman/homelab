#!/usr/bin/env bash
# Pre-commit hook: Prevent committing unencrypted secret files
# Files matching secret patterns must use .enc. in the name

set -euo pipefail

RED='\033[0;31m'
NC='\033[0m' # No Color

exit_code=0

for file in "$@"; do
    # Skip if file doesn't exist (might be deleted)
    [[ -f "$file" ]] || continue

    # Skip example files
    if [[ "$file" == *".example."* ]] || [[ "$file" == *"example."* ]]; then
        continue
    fi

    # Skip already encrypted files
    if [[ "$file" == *".enc."* ]]; then
        continue
    fi

    echo -e "${RED}ERROR:${NC} Unencrypted secret file detected: $file"
    echo ""
    echo "  Secret files must be encrypted with SOPS before committing."
    echo "  To fix:"
    echo ""
    echo "    sops --encrypt $file > ${file%.*}.enc.${file##*.}"
    echo "    rm $file"
    echo "    git add ${file%.*}.enc.${file##*.}"
    echo ""
    exit_code=1
done

exit $exit_code
