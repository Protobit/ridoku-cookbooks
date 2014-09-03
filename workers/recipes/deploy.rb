# encoding: utf-8
include_recipe 'deploy'

rails_app_instance = node[:opsworks][:instance][:layers].include?('rails-app')
workers_instance = node[:opsworks][:instance][:layers].include?('workers')

if rails_app_instance || workers_instance
  node[:deploy].each do |application, deploy|

    # pull out supported worker information
    supported_workers = node[:workers][:supported_workers]

    workers = {}.tap do |worker|
      (deploy['workers'] || {}).each do |type, value|
        worker[type] = value if supported_workers.include?(type) &&
          value.is_a?(Array) && value.length > 0
      end
    end

    if deploy[:application_type] != 'rails' || workers.length == 0
        Chef::Log.info("Skipping workers::deploy, #{application} "\
          "application does not appear to have any work queues!")
      next
    end

    if deploy['work_from_app_server']
      if !rails_app_instance
        Chef::Log.info("Skipping workers::deploy, #{application} "\
            "application requests workers run along-side web server!")
        next
      end
    elsif rails_app_instance
      Chef::Log.info("Skipping workers::deploy, #{application} "\
          "application requests workers on worker server!")
      next
    end

    Chef::Log.info("Running workers::deploy for #{application}...")

    opsworks_deploy_dir do
      user deploy[:user]
      group deploy[:group]
      path deploy[:deploy_to]
    end

    opsworks_rails do
      deploy_data deploy
      app application
    end

    opsworks_deploy do
      deploy_data deploy
      app application
    end

    sneakers_server do
      deploy_data deploy
      app application
      workers workers
    end

    tread_mill_server do
      deploy_data deploy
      app application
      workers workers
    end

    delayed_job_server do
      deploy_data deploy
      app application
      workers workers
    end

    cron_configuration do
      deploy_data deploy
      app application
    end
  end
end