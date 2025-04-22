Somleng.configure do |config|
  config.host = AppSettings.fetch(:somleng_host)
  config.username = AppSettings.fetch(:somleng_username)
  config.password = AppSettings.fetch(:somleng_password)
end
