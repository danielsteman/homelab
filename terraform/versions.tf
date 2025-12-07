terraform {
  required_version = ">= 1.0"

  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
    }
  }

  # Remote state in MinIO (S3-compatible)
  backend "s3" {
    bucket = "terraform-state"
    key    = "homelab/terraform.tfstate"
    region = "mars-1" # Data center in orbit around Mars

    endpoints = {
      s3 = "http://192.168.68.251:9000"
    }

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
}
