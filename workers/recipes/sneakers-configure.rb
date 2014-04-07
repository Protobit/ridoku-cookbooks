# encoding: utf-8

node[:deploy].each do |application, deploy|
  rails_app_instance = node[:opsworks][:instance][:layers].include?('rails-app')

  workers = {}.tap do |worker|
    (deploy['workers'] || {}).each do |type, value|
      worker[type] = value if type == 'sneakers' &&
        value.is_a?(Array) && value.length > 0
    end
  end

  if deploy[:application_type] != 'rails' || workers.length == 0
      Chef::Log.info("Skipping deploy::sneakers-configure, #{application} "\
        "application does not appear to have any delayed job queues!")
    next
  end
  
  if deploy['work_from_app_server'] && rails_app_instance
    next
  end

  services = "#{application}-#{deploy[:app_env][:RAILS_ENV]}-sneakers"
  
  sneakers_server do
    deploy_data deploy
    app application
    workers workers
  end
  
  node.default[:deploy][application][:database][:adapter] =
    OpsWorks::RailsConfiguration.determine_database_adapter(
      application,
      node[:deploy][application],
      "#{node[:deploy][application][:deploy_to]}/current",
      :force => node[:force_database_adapter_detection])

  deploy = node[:deploy][application]

  template "#{deploy[:deploy_to]}/shared/config/database.yml" do
    source "database.yml.erb"
    cookbook 'rails'
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables(:database => deploy[:database], :environment => deploy[:app_env][:RAILS_ENV])

    only_if do
      File.exists?("#{deploy[:deploy_to]}") && File.exists?("#{deploy[:deploy_to]}/shared/config/")
    end
  end

  template "#{deploy[:deploy_to]}/shared/config/memcached.yml" do
    source "memcached.yml.erb"
    cookbook 'rails'
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables(
      :memcached => deploy[:memcached] || {},
      :environment => deploy[:rails_env]
    )

    only_if do
      File.exists?("#{deploy[:deploy_to]}") && File.exists?("#{deploy[:deploy_to]}/shared/config/")
    end
  end
end
