terraform {
  backend "s3" {
    endpoint                    = "storage.yandexcloud.net"
    bucket                      = "otus-terstate"
    region                      = "ru-central1-a"
    key                         = "prod/terraform.tfstate"
    access_key                  = "YCAJEL_RXFc-6fAT8sdX0MJoT"
    secret_key                  = "YCOlYQWspxmHbHci4d8QO7kF9u6ic5pTwW42Y46N"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
