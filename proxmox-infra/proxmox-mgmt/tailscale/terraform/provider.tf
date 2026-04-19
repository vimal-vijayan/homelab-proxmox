terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc06"
    }
  }

  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "proxmox-mgmt-tailscale/terraform.tfstate"
    region                      = "us-east-1"
    access_key                  = "minioadmin"
    secret_key                  = "minioadmin"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    force_path_style            = true
    endpoints = {
      s3 = "http://localhost:9000"
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.pm_api_url
  pm_tls_insecure = true
  pm_user         = var.pm_user
  pm_password     = var.pm_password
}
