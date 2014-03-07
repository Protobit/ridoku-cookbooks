node[:deploy].each do |application, deploy|

  if deploy[:application_type] != 'rails' ||
    !deploy.has_key?('workers') ||
    !deploy['workers'].has_key?('delayed_job') ||
    deploy['workers']['delayed_job'].length == 0
      Chef::Log.info("Skipping deploy::delayed_job, #{application} "\
        "application does not appear to have any delayed job queues!")
    next
  end

  if deploy['work_from_app_server']
    Chef::Log.info("Skipping deploy::delayed_job, #{application} "\
        "application requests workers run along-side web server!")
    next
  end

  services = "#{application}-#{deploy[:rails_env]}"

  deploy deploy[:deploy_to] do
    provider Chef::Provider::Deploy::Revision
    user deploy[:user]
    environment "RAILS_ENV" => deploy[:rails_env], "RUBYOPT" => ""
    action "rollback"
    restart_command "sleep #{deploy[:sleep_before_restart]} && service #{service} restart"

    only_if do
      File.exists?(deploy[:current_path])
    end
  end
end
