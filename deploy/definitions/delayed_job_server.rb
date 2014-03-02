define :delayed_job_server do
  application = params[:app]
  deploy = params[:deploy_data]
  rails_key = 'work_from_app_server'
  services = "#{application}-#{deploy[:rails_env]}"

  if ( node[:opsworks][:instance][:layers].include?('rails-app') &&
       deploy.has_key?(rails_key) && deploy[rails_key] ) ||
       node[:opsworks][:instance][:layers].include?('workers')

    if !deploy.key?('workers') || !deploy['workers'].key?('delayed_job') ||
        deploy['workers']['delayed_job'].length == 0
        Chef::Log.info("Skipping DJ Server for #{application}. Not configured.")
    else

      # Create directory for application cron scripts.
      directory node[:opsworks][:delayed_job][:cron_path] do
        mode 0755
        action :create
      end

      # Create init script for applications.
      template "/etc/init.d/#{services}" do
        source 'delayed_job_init.erb'
        mode '0700'

        group 'root'
        owner 'root'

        env = OpsWorks::RailsConfiguration.build_cmd_environment(deploy)
        ques = deploy['workers']['delayed_job']

        variables(
          :environment => env,
          :current_path => deploy[:current_path],
          :user => deploy[:user],
          :group => deploy[:group],
          :queues => ques.join(','),
          :queue_count => ques.length
        )
      end

      # Create Cron Script in cron script directory
      template "#{node[:opsworks][:delayed_job][:cron_path]}/#{services}.sh" do
        source 'delayed_job_cron.sh.erb'
        mode '0700'

        group 'root'
        owner 'root'

        variables(
          :current_path => deploy[:current_path],
          :service => services
        )
      end

      service "#{services} Worker" do
        service_name services
        supports :start => true, :stop => true, :zap => true, :restart => true
        action [:enable, :restart]
      end

      # Add application cron job.
      cron "#{services} Cron" do
        minute '*/5'
        command "#{node[:opsworks][:delayed_job][:cron_path]}/#{services}.sh > /dev/null 2>&1"
        action :create
      end
    end
  end
end