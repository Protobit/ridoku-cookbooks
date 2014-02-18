define :delayed_job_server do
  application = params[:app]
  deploy = params[:deploy_data]
  rails_key = 'work_from_app_server'

  if ( node[:opsworks][:instance][:layers].include?('rails-app') &&
       deploy.has_key?(rails_key) && deploy[rails_key] ) ||
       node[:opsworks][:instance][:layers].include?('workers')

    service "#{application} Worker" do
      service_name application
      supports :start => true, :stop => true, :zap => true, :restart => true
      action :enable
    end

    # Create directory for application cron scripts.
    directory node[:opsworks][:delayed_job][:cron_path] do
      mode 0755
      action :create
    end

    # Create init script for applications.
    template "/init.d/#{application}" do
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

      notifies "service[#{application} Worker]", :restart, :immediate
    end

    # Create Cron Script in cron script directory
    template "#{node[:opsworks][:delayed_job][:cron_path]}/#{application}.sh" do
      source 'delayed_job_cron.sh.erb'
      mode '0700'

      group 'root'
      owner 'root'

      variables(
        :current_path => deploy[:current_path],
        :application => application
      )

      notifies "cron[#{application} Cron]", :restart, :immediate
    end

    # Add application cron job.
    cron "#{application} Cron" do
      minute '*/5'
      command "#{node[:opsworks][:delayed_job][:cron_path]}/#{application}.sh > /dev/null 2>&1"
      action :nothing
    end
  end
end