output "db_host" { value = vkcs_db_instance.main.ip }
output "db_name" { value = vkcs_db_database.app.name }
output "db_user" { value = vkcs_db_user.app.name }
output "db_password" { value = random_password.db_password.result }