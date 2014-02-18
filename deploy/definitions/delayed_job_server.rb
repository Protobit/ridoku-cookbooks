define :delayed_job_server do
  application = params[:app]
  deploy = params[:deploy_data]
  rails_key = 'work_from_app_server'

  if ( node[:opsworks][:instance][:layers].include?('rails-app') &&
       deploy.has_key?(rails_key) && deploy[rails_key] ) ||
       node[:opsworks][:instance][:layers].include?('workers')

    # Create directory for application cron scripts.
    directory node[:opsworks][:delayed_job][:cron_path] do
      mode 0755
      action :create
    end

    # Create init script for applications.
    template "/etc/init.d/#{application}-#{deploy[:rails_env]}" do
      source 'delayed_job_init.erb'
      mode '0700'

      group 'root'
      owner 'root'

      env = OpsWorks::RailsConfiguration.build_cmd_environment(deploy)
      ques = deploy['workers']['delayed_job'].join(',')

      variables(
        :environment => env,
        :current_path => deploy[:current_path],
        :username => deploy[:user],
        :queues => ques
      )
    end

    # Create Cron Script in cron script directory
    template "#{node[:opsworks][:delayed_job][:cron_path]}/#{application}-#{deploy[:rails_env]}.sh" do
      source 'delayed_job_cron.sh.erb'
      mode '0700'

      group 'root'
      owner 'root'

      variables(
        :current_path => deploy[:current_path],
        :application => application
      )
    end

    service "#{application}-#{deploy[:rails_env]} Worker" do
      service_name application
      supports :start => true, :stop => true, :zap => true, :restart => true
      action [:enable, :restart]
    end

    # Add application cron job.
    cron "#{application}-#{deploy[:rails_env]} Cron" do
      minute '*/5'
      command "#{node[:opsworks][:delayed_job][:cron_path]}/#{application}-#{deploy[:rails_env]}.sh > /dev/null 2>&1"
      action :create
    end
  end
end