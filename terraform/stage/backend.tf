terraform {
  backend "s3" {
    endpoint = "storage.yandexcloud.net"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
