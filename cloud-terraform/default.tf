terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = "0.112.0"
    }
  }
}

locals {
  folder_id = "b1gghljetggntd2u1oga"
  cloud_id = "b1g6s0sk55pa15d7fo2n"
}
 
provider "yandex" {
  # Configuration options
  cloud_id = local.cloud_id
  folder_id = local.folder_id
  service_account_key_file = "/home/devops/authorized_key.json"
}

