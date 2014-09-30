define :tread_mill_server do
  application = params[:app]
  deploy = params[:deploy_data]
  workers = params[:workers]

  rails_key = 'work_from_app_server'
  work_on_app_server = deploy[rails_key]
  services = "#{application}-#{deploy[:rails_env]}-tread_mill"

  layers = node[:opsworks][:instance][:layers]
  rails_app_instance = layers.include?('rails-app')
  worker_instance = layers.include?('workers')

  if (rails_app_instance && work_on_app_server) || worker_instance
    tread_mill_info = workers['tread_mill']

    if !tread_mill_info.is_a?(Array) || tread_mill_info.length == 0
      Chef::Log.info("Skipping TreadMill worker for #{application}. "\
        "Not configured.")
      next
    end

    # Create directory for application cron scripts.
    directory node[:workers][:cron_path] do
      mode 0755
      action :create
    end

    # Create init script for applications.
    template "/etc/init/#{services}.conf" do
      source 'tread_mill_init.erb'
      mode '0600'

      group 'root'
      owner 'root'

      variables(
        :application => application,
        :deploy => deploy,
        :environment => (deploy[:app_env] || {}),
        :pid_path => "#{deploy[:deploy_to]}/shared/pids/sneakers.pid"
      )
    end

    # Create Cron Script in cron script directory
    template "#{node[:workers][:cron_path]}/#{services}.sh" do
      source 'worker_cron_upstart.sh.erb'
      mode '0700'

      group 'root'
      owner 'root'

      variables(
        :pid_path => "#{deploy[:deploy_to]}/shared/pids/sneakers.pid",
        :service => services
      )
    end

    service "#{services} Worker" do
      provider Chef::Provider::Service::Upstart
      service_name services
      supports :start => true, :stop => true, :restart => true, :status => true

      action [:enable, :start]

      subscribes :restart, "deploy[#{deploy[:deploy_to]}]"
      subscribes :restart, "template[#{deploy[:deploy_to]}/shared/config/database.yml]"
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