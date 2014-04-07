define :sneakers_server do
  application = params[:app]
  deploy = params[:deploy_data]
  workers = params[:workers]

  rails_key = 'work_from_app_server'
  work_on_app_server = deploy[rails_key]
  services = "#{application}-#{deploy[:rails_env]}-sneakers"

  layers = node[:opsworks][:instance][:layers]
  rails_app_instance = layers.include?('rails-app')
  worker_instance = layers.include?('workers')

  if (rails_app_instance && work_on_app_server) || worker_instance
    sneakers_info = workers['sneakers']

    if !sneakers_info.is_a?(Array) || sneakers_info.length == 0
      Chef::Log.info("Skipping DJ Server for #{application}. "\
        "Not configured.")
    else

      # Create directory for application cron scripts.
      directory node[:workers][:cron_path] do
        mode 0755
        action :create
      end

      # Create init script for applications.
      template "/etc/init.d/#{services}" do
        source 'sneakers_init.erb'
        mode '0700'

        group 'root'
        owner 'root'

        env = OpsWorks::RailsConfiguration.build_cmd_environment(deploy)

        variables(
          :deploy => deploy,
          :environment => env,
          :queues => sneakers_info.join(','),
          :queue_count => sneakers_info.length
        )
      end

      # Create init script for applications.
      template "#{deploy[:deploy_to]}/shared/scripts/sneakers.rb" do
        source 'sneakers_runner.erb'
        mode '0700'

        group deploy[:group]
        owner deploy[:user]

        variables(
          :deploy => deploy,
          :application => application,
          :workers => sneakers_info.join(','),
          :queue_count => sneakers_info.length
        )
      end

      # Create Cron Script in cron script directory
      template "#{node[:workers][:cron_path]}/#{services}.sh" do
        source 'worker_cron.sh.erb'
        mode '0700'

        group 'root'
        owner 'root'

        variables(
          :pid_path => "#{deploy[:deploy_to]}/shared/pids/sneakers.pid",
          :service => services
        )
      end

      service "#{services} Worker" do
        service_name services
        supports :start => true, :stop => true, :zap => true, :restart => true, :status => true
        action [:enable, :start]

        subscribes :restart, "deploy[#{deploy[:deploy_to]}]"
        subscribes :restart, "template[#{deploy[:deploy_to]}/shared/config/database.yml]"
        subscribes :restart, "template[#{deploy[:deploy_to]}/shared/scripts/sneakers.rb]"
        subscribes :restart, "template[#{node[:workers][:cron_path]}/#{services}.sh]"
      end

      # Add application cron job.
      cron "#{services} Cron" do
        minute '*/5'
        command "#{node[:workers][:cron_path]}/#{services}.sh > /dev/null 2>&1"
        action :create
      end
    end
  end
end