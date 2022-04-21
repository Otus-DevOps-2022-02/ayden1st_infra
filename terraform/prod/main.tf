# terraform {
#   required_providers {
#     yandex = {
#       source  = "yandex-cloud/yandex"
#       version = "0.73.0"
#     }
#   }
# }

data "yandex_compute_image" "app_image" {
  folder_id = var.folder_id
  family = var.app_disk_image
}

data "yandex_compute_image" "db_image" {
  folder_id = var.folder_id
  family = var.db_disk_image
}


provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

module "vpc" {
  source           = "../modules/vpc"
  zone = var.zone
}

module "app" {
  source           = "../modules/app"
  public_key_path  = var.public_key_path
  private_key_path = var.private_key_path
  app_disk_image   = data.yandex_compute_image.app_image.id
  subnet_id        = module.vpc.subnet_id
  db_ip            = module.db.internal_ip_address_db
}

module "db" {
  source           = "../modules/db"
  public_key_path  = var.public_key_path
  private_key_path = var.private_key_path
  db_disk_image    = data.yandex_compute_image.db_image.id
  subnet_id        = module.vpc.subnet_id
}
