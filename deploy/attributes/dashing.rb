default[:opsworks][:dashing][:needs_reload] = true
default[:opsworks][:dashing][:start_command] = 'dashing start'

node[:deploy].each do |application, deploy|
  if default[:deploy][application][:application_type] == 'dashing'
    default[:deploy][application][:port] = '3000'
  end
end