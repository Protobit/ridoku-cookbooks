# Update domains

node[:deploy].each do |application, deploy|
  if node[:opsworks][:instance][:layers].include?('rails-app')
    case node[:opsworks][:rails_stack][:name]

    when 'apache_passenger'
      passenger_web_app do
        application application
        deploy deploy
      end

    when 'nginx_unicorn'
      unicorn_web_app do
        application application
        deploy deploy
      end

    else
      raise "Unsupport Rails stack"
    end
  else
    Chef::Log.debug("App is not a rails app. #{deploy[:application_type]}")
  end
end

include_recipe 'nginx::reload'