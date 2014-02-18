include_recipe 'deploy'

node[:deploy].each do |application, deploy|

  if deploy[:application_type] != 'rails' ||
    !deploy.has_key?('workers') ||
    !deploy['workers'].has_key?('delayed_job') ||
    deploy['workers']['delayed_job'].length == 0 ||
    deploy['work_from_app_server']
      Chef::Log.debug("Skipping deploy::delayed_job, #{application} "\
        "application does not appear to have any delayed job queues!")
    next
  end

  Chef::Log.info("Running deploy::delayed_job for #{application}...")

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

  delayed_job_server do
    deploy_data deploy
    app application
  end
end
