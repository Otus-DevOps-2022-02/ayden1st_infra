variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}
variable "private_key_path" {
  description = "Path to private key used for provisioner"
}
variable "db_disk_image" {
  description = "Disk image for reddit db"
  default     = "reddit-db-base"
}
variable "subnet_id" {
  description = "Subnet"
}
variable "enable_provisions" {
  description = "Enable provisions"
  default     = false
}
