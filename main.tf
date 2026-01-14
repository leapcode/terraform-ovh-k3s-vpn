terraform {
  required_version = ">= 0.14.0"
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = ">= 2.7.0"
    }
  }
}