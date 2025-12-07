# MinIO - S3-Compatible Object Storage

Self-hosted S3-compatible storage for Terraform state and backups.

## Setup

```bash
# On Proxmox host
cd /path/to/homelab/minio
cp .env.example .env
# Edit .env with a secure password

docker compose up -d
```

## Access

- **Console**: http://192.168.68.251:9001
- **API**: http://192.168.68.251:9000

## Create Terraform State Bucket

1. Open console at http://192.168.68.251:9001
2. Login with your credentials
3. Create bucket: `terraform-state`
4. Create access key (save the key ID and secret)

## Configure Terraform

Add to `terraform/versions.tf`:

```hcl
terraform {
  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "homelab/terraform.tfstate"
    region                      = "us-east-1"  # Required but ignored by MinIO
    endpoint                    = "http://192.168.68.251:9000"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true
    access_key                  = "your-access-key"
    secret_key                  = "your-secret-key"
  }
}
```

Then migrate state:

```bash
cd terraform
terraform init -migrate-state
```
