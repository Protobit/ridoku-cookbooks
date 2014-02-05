default[:opsworks][:dashing][:needs_reload] = true
default[:opsworks][:dashing][:start_command] = 'dashing start'

node[:deploy].each do |application, deploy|
  if default[:deploy][application][:application_type] == 'dashing'
    default[:deploy][application][:port] = '3000'
    default[:deploy][application][:auth_token] = 'DEFAULT_AUTH_TOKEN'
  end
end