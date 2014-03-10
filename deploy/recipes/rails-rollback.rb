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
    repository deploy[:scm][:repository]
    revision deploy[:scm][:revision]
    user deploy[:user]

    environment "RAILS_ENV" => deploy[:rails_env], "RUBYOPT" => ""
    action "rollback"
    restart_command "sleep #{deploy[:sleep_before_restart]} && #{node[:opsworks][:rails_stack][:restart_command]}"

    case deploy[:scm][:scm_type].to_s
    when 'git'
      scm_provider :git
      enable_submodules deploy[:enable_submodules]
      shallow_clone deploy[:shallow_clone]
    when 'svn'
      scm_provider :subversion
      svn_username deploy[:scm][:user]
      svn_password deploy[:scm][:password]
      svn_arguments "--no-auth-cache --non-interactive --trust-server-cert"
      svn_info_args "--no-auth-cache --non-interactive --trust-server-cert"
    when 'symlink'
      Chef::Log.info('Repository type is symlink. Do nothing.')
    else
      raise "unsupported SCM type #{deploy[:scm][:scm_type].inspect}"
    end

    only_if do
      File.exists?(deploy[:current_path])
    end

    if deploy['work_from_app_server']
      notifies :restart, "service[#{services} Worker]", :immediately
    end
  end
end
