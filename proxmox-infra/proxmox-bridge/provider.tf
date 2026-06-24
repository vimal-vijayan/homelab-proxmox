terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.73"
    }
  }

  backend "s3" {
    bucket                      = "proxmox-infra-bridges"
    key                         = "proxmox-bridge/terraform.tfstate"
    region                      = "us-east-1"
    access_key                  = "minioadmin"
    secret_key                  = "minioadmin"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_path_style              = true
    endpoints = {
      s3 = "http://localhost:9000"
    }
  }
}

provider "proxmox" {
  endpoint  = var.pm_api_url
  insecure  = true
  username  = var.pm_user
  password  = var.pm_password
}
