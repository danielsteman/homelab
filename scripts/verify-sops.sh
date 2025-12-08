#!/usr/bin/env bash
# Pre-commit hook: Verify .enc. files are actually SOPS-encrypted
# Catches cases where someone renamed a file to .enc. without encrypting

set -euo pipefail

RED='\033[0;31m'
NC='\033[0m' # No Color

exit_code=0

for file in "$@"; do
    # Skip if file doesn't exist
    [[ -f "$file" ]] || continue

    # SOPS-encrypted files contain "sops:" key (YAML/JSON) or ENC[ markers (env)
    if [[ "$file" == *.yaml ]] || [[ "$file" == *.yml ]]; then
        if ! grep -q "^sops:" "$file" 2>/dev/null; then
            echo -e "${RED}ERROR:${NC} File claims to be encrypted but missing SOPS metadata: $file"
            echo ""
            echo "  This file has .enc. in the name but doesn't appear to be SOPS-encrypted."
            echo "  To fix, encrypt it properly:"
            echo ""
            echo "    sops --encrypt ${file/.enc/} > $file"
            echo ""
            exit_code=1
        fi
    elif [[ "$file" == *.env ]]; then
        if ! grep -q "ENC\[AES256_GCM" "$file" 2>/dev/null; then
            echo -e "${RED}ERROR:${NC} File claims to be encrypted but missing SOPS markers: $file"
            echo ""
            echo "  This .enc.env file doesn't contain SOPS encryption markers."
            echo "  To fix, encrypt it properly:"
            echo ""
            echo "    sops --encrypt ${file/.enc/} > $file"
            echo ""
            exit_code=1
        fi
    elif [[ "$file" == *.json ]]; then
        if ! grep -q '"sops":' "$file" 2>/dev/null; then
            echo -e "${RED}ERROR:${NC} File claims to be encrypted but missing SOPS metadata: $file"
            exit_code=1
        fi
    fi
done

exit $exit_code
