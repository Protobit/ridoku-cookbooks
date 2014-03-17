# encoding: utf-8

node[:deploy].each do |application, deploy|

  if deploy[:application_type] != 'rails' ||
    !deploy.has_key?('workers') ||
    !deploy['workers'].has_key?('delayed_job') ||
    deploy['workers']['delayed_job'].length == 0
      Chef::Log.info("Skipping deploy::delayed_job-configure, #{application} "\
        "application does not appear to have any delayed job queues!")
    next
  end

  services = "#{application}-#{deploy[:app_env][:RAILS_ENV]}"
  
  delayed_job_server do
    deploy_data deploy
    app application
  end

  if deploy['work_from_app_server'] &&
    node[:opsworks][:instance][:layers].include?('rails-app')
    service services do
      action :restart
    end
    next
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

    notifies :restart, "service[#{services} Worker]"

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

    notifies :restart, "service[#{services} Worker]"

    only_if do
      File.exists?("#{deploy[:deploy_to]}") && File.exists?("#{deploy[:deploy_to]}/shared/config/")
    end
  end
end
