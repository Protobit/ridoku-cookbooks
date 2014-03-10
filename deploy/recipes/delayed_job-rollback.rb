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

  prepare_checkouts do
    app application
    deploy_data deploy
  end

  services = "#{application}-#{deploy[:rails_env]}"

  deploy deploy[:deploy_to] do
    provider Chef::Provider::Deploy::Revision
    repository deploy[:scm][:repository]
    revision deploy[:scm][:revision]
    user deploy[:user]

    environment "RAILS_ENV" => deploy[:rails_env], "RUBYOPT" => ""
    action "rollback"
    restart_command "sleep #{deploy[:sleep_before_restart]} && service #{services} restart"

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
  end
end
