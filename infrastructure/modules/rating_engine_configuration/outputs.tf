output "identifier" {
  value = var.identifier
}
output "image" {
  value = var.image
}
output "http_password_parameter" {
  value = aws_ssm_parameter.http_password
}
output "stordb_password_parameter" {
  value = var.stordb_password_parameter
}
output "stordb_security_group" {
  value = var.stordb_security_group
}
output "stordb_dbname" {
  value = var.stordb_dbname
}
output "stordb_host" {
  value = var.stordb_host
}
output "stordb_port" {
  value = var.stordb_port
}
output "stordb_user" {
  value = var.stordb_user
}
output "stordb_ssl_mode" {
  value = var.stordb_ssl_mode
}
output "datadb_cache" {
  value = var.datadb_cache
}
output "datadb_tls" {
  value = var.datadb_tls
}
output "connection_mode" {
  value = var.connection_mode
}
output "json_rpc_url" {
  value = var.json_rpc_url
}
output "json_rpc_username" {
  value = var.json_rpc_username
}
output "http_port" {
  value = var.http_port
}
