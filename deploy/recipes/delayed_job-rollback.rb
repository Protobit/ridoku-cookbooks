# Have to manually protect against non-layer runs due to lack of ability
# to run Rollback recipes without an override hack.
#
# https://forums.aws.amazon.com/thread.jspa?threadID=147782&tstart=0
#
if node[:opsworks][:instance][:layers].include?('workers') || 
  node[:opsworks][:instance][:layers].include?('rails-app')
  node[:deploy].each do |application, deploy|

    if deploy[:application_type] != 'rails' ||
      !deploy.has_key?('workers') ||
      !deploy['workers'].has_key?('delayed_job') ||
      deploy['workers']['delayed_job'].length == 0
        Chef::Log.info("Skipping deploy::delayed_job, #{application} "\
          "application does not appear to have any delayed job queues!")
      next
    end

    services = "#{application}-#{deploy[:rails_env]}"

    delayed_job_server do
      app application
      deploy_data deploy
    end

    if node[:opsworks][:instance][:layers].include?('rails-app')
      if deploy['work_from_app_server']
        # Provided this is run AFTER deploy::rails-rollback (which it should be)
        # Then all we have to do here is restart the service...
        service services do
          action :restart
        end
      else
        Chef::Log.info("Skipping deploy::delayed_job-rollback, #{application}"\
            " application requests workers run on a different server!")
        next
      end
    else
      if deploy['work_from_app_server']
        Chef::Log.info("Skipping deploy::delayed_job-rollback, #{application}"\
            " application requests workers run along-side web server!")
        next
      else
        deploy deploy[:deploy_to] do
          provider Chef::Provider::Deploy::Revision
          repository deploy[:scm][:repository]
          revision deploy[:scm][:revision]
          user deploy[:user]

          environment "RAILS_ENV" => deploy[:rails_env], "RUBYOPT" => ""
          action "rollback"

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

          notifies :restart, "service[#{services} Worker]", :immediately
        end
      end
    end
  end
else
  Chef::Log.info("Skipping deploy::delayed_job-rollback on instance "\
    "#{node[:opsworks][:instance][:hostname]} because it is on "\
    "layer(s) '#{node[:opsworks][:instance][:layers].join('\',\'')}'.  "\
    "DJ Rollback can only be run on a 'rails-app' or 'workers' layer.")
end