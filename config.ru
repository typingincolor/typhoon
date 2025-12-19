require_relative 'app'

# Configure Mail
require 'mail'
Mail.defaults do
  delivery_method Config.email[:delivery_method].to_sym, Config.email[:smtp_settings] || {}
end

run TyphoonApp
