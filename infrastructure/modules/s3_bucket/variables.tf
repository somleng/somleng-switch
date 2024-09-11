variable "name" {}
variable "access_key_id_parameter_name" {}
variable "secret_access_key_parameter_name" {}
variable "expiration_period_days" {
  default = 7
}
variable "iam_username" {
  default = null
}
