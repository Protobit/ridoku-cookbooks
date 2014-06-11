define :opsworks_deploy do
  application = params[:app]
  deploy = params[:deploy_data]

  directory "#{deploy[:deploy_to]}" do
    group deploy[:group]
    owner deploy[:user]
    mode "0775"
    action :create
    recursive true
  end

  package 'libpq-dev'

  prepare_checkouts do
    app application
    deploy_data deploy
  end

  deploy = node[:deploy][application]

  # setup deployment & checkout
  if deploy[:scm] && deploy[:scm][:scm_type] != 'other'
    Chef::Log.debug("Checking out source code of application #{application} with type #{deploy[:application_type]}")
    deploy deploy[:deploy_to] do
      provider Chef::Provider::Deploy::Revision
      repository deploy[:scm][:repository]
      user deploy[:user]
      group deploy[:group]
      revision deploy[:scm][:revision]

      if node[:opsworks][:instance][:hostname] == deploy[:assetmaster]
        migrate deploy[:migrate]
      else
        migrate false
      end


      env = OpsWorks::RailsConfiguration.build_cmd_environment(deploy)
      migration_command "#{env} /usr/local/bin/bundle exec /usr/local/bin/rake db:migrate"
      environment deploy[:environment].to_hash
      symlink_before_migrate( deploy[:symlink_before_migrate] )
      action deploy[:action]

      ENV.delete('BUNDLE_GEMFILE')

      # schedule the restart so commands run later don't have to restart again.
      if deploy[:application_type] == 'rails' &&
        node[:opsworks][:instance][:layers].include?('rails-app')
        notifies :reload, "service[unicorn_#{application}]"
      end

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

      before_migrate do
        link_tempfiles_to_current_release

        if deploy[:application_type] == 'rails'
          if deploy[:auto_bundle_on_deploy]
            OpsWorks::RailsConfiguration.bundle(application, node[:deploy][application], release_path)
          end

          node.default[:deploy][application][:database][:adapter] = OpsWorks::RailsConfiguration.determine_database_adapter(
            application,
            node[:deploy][application],
            release_path,
            :force => node[:force_database_adapter_detection],
            :consult_gemfile => node[:deploy][application][:auto_bundle_on_deploy]
          )

          template "#{node[:deploy][application][:deploy_to]}/shared/config/database.yml" do
            cookbook "rails"
            source "database.yml.erb"
            mode "0660"
            owner node[:deploy][application][:user]
            group node[:deploy][application][:group]
            variables(
              :database => node[:deploy][application][:database],
              :environment => node[:deploy][application][:rails_env]
            )
          end.run_action(:create)

          if deploy[:auto_assets_precompile_on_deploy]
            precompile_assets release_path do
              deploy_data deploy
              app application
            end
          end
        elsif deploy[:application_type] == 'php'
          template "#{node[:deploy][application][:deploy_to]}/shared/config/opsworks.php" do
            cookbook 'php'
            source 'opsworks.php.erb'
            mode '0660'
            owner node[:deploy][application][:user]
            group node[:deploy][application][:group]
            variables(
              :database => node[:deploy][application][:database],
              :memcached => node[:deploy][application][:memcached],
              :layers => node[:opsworks][:layers],
              :stack_name => node[:opsworks][:stack][:name]
            )
            only_if do
              File.exists?("#{node[:deploy][application][:deploy_to]}/shared/config")
            end
          end
        elsif deploy[:application_type] == 'nodejs'
          if deploy[:auto_npm_install_on_deploy]
            OpsWorks::NodejsConfiguration.npm_install(application, node[:deploy][application], release_path)
          end
        end

        # run user provided callback file
        run_callback_from_file("#{release_path}/deploy/before_migrate.rb")
      end
    end
  end

  ruby_block "change HOME back to /root after source checkout" do
    block do
      ENV['HOME'] = "/root"
    end
  end

  directory "#{deploy[:deploy_to]}/shared/cached-copy" do
    recursive true
    action :delete
    only_if do
      deploy[:delete_cached_copy]
    end
  end

  template "/etc/logrotate.d/opsworks_app_#{application}" do
    backup false
    source "logrotate.erb"
    cookbook 'deploy'
    owner "root"
    group "root"
    mode 0644
    variables( :log_dirs => ["#{deploy[:deploy_to]}/shared/log" ] )
  end
end
