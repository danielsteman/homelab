# Secrets Management with SOPS

This directory contains the SOPS age key for encrypting/decrypting secrets in this repository.

## Prerequisites

Install the required tools:

```bash
# macOS
brew install sops age

# Linux
# sops: https://github.com/getsops/sops/releases
# age: https://github.com/FiloSottile/age/releases

# Verify installation
sops --version
age --version
```

## Initial Setup (One-time)

### 1. Generate an age key

```bash
# Generate key pair
age-keygen -o secrets/age-key.txt

# This creates a file with:
# - Public key (safe to share, starts with "age1...")
# - Private key (NEVER share, starts with "AGE-SECRET-KEY-...")
```

### 2. Update `.sops.yaml`

Copy your **public key** from `secrets/age-key.txt` and add it to `.sops.yaml`:

```yaml
creation_rules:
  - path_regex: .*\.enc\.ya?ml$
    encrypted_regex: "^(data|stringData)$"
    age: age1your_public_key_here
```

### 3. Set up your environment

This repo uses **direnv** to automatically set `SOPS_AGE_KEY_FILE` when you enter the directory:

```bash
# Install direnv (if not already installed)
brew install direnv

# Add to ~/.zshrc (or ~/.bashrc)
eval "$(direnv hook zsh)"

# Allow direnv for this repo (one-time)
cd /path/to/homelab
direnv allow
```

Now `SOPS_AGE_KEY_FILE` is automatically set when you're in this repo! ✨

## Daily Usage

### Encrypting a new secret

```bash
# Create a plain YAML file
cat > k3s/my-secret.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
stringData:
  password: super-secret-value
EOF

# Encrypt it (output to .enc.yaml)
sops --encrypt k3s/my-secret.yaml > k3s/my-secret.enc.yaml

# Remove the plain file
rm k3s/my-secret.yaml

# Commit the encrypted file
git add k3s/my-secret.enc.yaml
git commit -m "Add encrypted secret"
```

### Editing an encrypted secret

```bash
# Opens in $EDITOR, decrypts, lets you edit, re-encrypts on save
sops k3s/my-secret.enc.yaml
```

### Decrypting for debugging

```bash
# View decrypted content (stdout)
sops --decrypt k3s/my-secret.enc.yaml

# Decrypt to file (DO NOT commit .dec files!)
sops --decrypt k3s/my-secret.enc.yaml > k3s/my-secret.dec.yaml
```

### Encrypting environment files

```bash
# Create plain env file
echo "DB_PASSWORD=secret123" > bitwarden/secrets.env

# Encrypt it
sops --encrypt bitwarden/secrets.env > bitwarden/secrets.enc.env

# Remove plain file
rm bitwarden/secrets.env
```

## File Naming Convention

| Pattern       | Description                  | Git Status |
| ------------- | ---------------------------- | ---------- |
| `*.enc.yaml`  | Encrypted YAML (K8s secrets) | ✅ Commit  |
| `*.enc.env`   | Encrypted env files          | ✅ Commit  |
| `*.enc.json`  | Encrypted JSON               | ✅ Commit  |
| `*.dec.*`     | Decrypted files (temporary)  | ❌ Ignored |
| `age-key.txt` | Private key                  | ❌ Ignored |

## Integration with Flux CD

If using Flux for GitOps, it natively supports SOPS decryption:

```yaml
# flux-system/gotk-sync.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: cluster
  namespace: flux-system
spec:
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

Create the Flux secret with your age key:

```bash
kubectl create secret generic sops-age \
  --namespace=flux-system \
  --from-file=age.agekey=secrets/age-key.txt
```

## Backup Your Key!

⚠️ **If you lose `age-key.txt`, you cannot decrypt your secrets!**

Backup options:

- Store in a password manager (Bitwarden, 1Password)
- Print and store in a safe
- Encrypt with GPG and store separately

## Troubleshooting

### "could not decrypt key"

```bash
# Ensure SOPS_AGE_KEY_FILE is set
echo $SOPS_AGE_KEY_FILE

# Or specify directly
sops --decrypt --age-key-file secrets/age-key.txt file.enc.yaml
```

### "no matching keys found"

The file was encrypted with a different key. Check if the public key in `.sops.yaml` matches your key.

### Re-encrypting with a new key

```bash
# Decrypt with old key, re-encrypt with new
sops --decrypt --age-key-file old-key.txt file.enc.yaml | \
  sops --encrypt --age $NEW_PUBLIC_KEY /dev/stdin > file.new.enc.yaml
```
