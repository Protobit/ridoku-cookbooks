node[:deploy].each do |application, deploy|

  if deploy[:application_type] != 'rails'
    Chef::Log.debug("Skipping deploy::rails-rollback application #{application} as it is not a Rails app")
    next
  end

  services = "#{application}-#{deploy[:rails_env]}"

  if deploy['work_from_app_server']
    delayed_job_server do
      deploy_data deploy
      app application
    end
  end

  deploy deploy[:deploy_to] do
    provider Chef::Provider::Deploy::Revision
    user deploy[:user]
    environment "RAILS_ENV" => deploy[:rails_env], "RUBYOPT" => ""
    action "rollback"
    restart_command "sleep #{deploy[:sleep_before_restart]} && #{node[:opsworks][:rails_stack][:restart_command]}"

    only_if do
      File.exists?(deploy[:current_path])
    end

    if deploy['work_from_app_server']
      notifies :restart, "service[#{services} Worker]", :immediately
    end
  end
end
