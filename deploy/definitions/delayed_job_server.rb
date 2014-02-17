define :rails_server do
  application = params[:app]
  deploy = params[:deploy_data]
  rails_key = 'work_from_app_server'

  if ( node[:opsworks][:instance][:layers].include?('rails-app') &&
       deploy.key?(rails_key) && deploy[rails_key] ) ||
       node[:opsworks][:instance][:layers].include?('workers')


    template "/init.d/#{application}" do
      source 'environment.rb.erb'
      mode '0600'

      group 'root'
      owner 'root'

      env = OpsWorks::RailsConfiguration.build_cmd_environment(deploy)
      ques = deploy['workers']['delayed_job'].join(',')

      variables({
        environment: env,
        current_path: deploy[:current_path],
        username: deploy[:user],
        queues: ques
      })

      only_if do
        File.exists?("#{deploy[:deploy_to]}") &&
        File.exists?("#{deploy[:deploy_to]}/shared/config/")
      end
    end


    # execute "Stop DJ Server" do
    #   pid_dir = "#{deploy[:current_path]}/tmp/pids"
    #   pid_file = "#{pid_dir}/delayed_job.pid"

    #   start_cmd = "cd #{deploy[:current_path]} &&"
    #   start_cmd = "#{start_cmd} script/delayed_job #{node[:opsworks][:delayed_job][:stop_command]}"
    #   start_cmd = "sudo su deploy -c '#{start_cmd}'"
    #   Chef::Log.info(start_cmd)

    #   command start_cmd

    #   only_if do 
    #     File.exists?(pid_file) && File.exists?("/proc/#{IO.read(pid_file)}/")
    #   end
    # end

    # execute "Kill DJ Server" do
    #   pid_dir = "#{deploy[:current_path]}/tmp/pids"
    #   pid_file = "#{pid_dir}/delayed_job.pid"
    #   cwd pid_dir

    #   command "sudo kill $(cat #{pid_file})"
    #   action :run

    #   only_if do 
    #     File.exists?(pid_file) && File.exists?("/proc/#{IO.read(pid_file)}/")
    #   end
    # end

    # execute "Start DJ Server" do
    #   env = OpsWorks::RailsConfiguration.build_cmd_environment(deploy)
    #   count = deploy['workers']['delayed_job'].length
    #   queues = deploy['workers']['delayed_job'].join(',')

    #   start_cmd = "cd #{deploy[:current_path]} &&"
    #   start_cmd = "#{start_cmd} #{env} script/delayed_job "
    #   start_cmd = "#{start_cmd} -n #{count} --queue=#{queues}"
    #   start_cmd = "#{start_cmd} #{node[:opsworks][:delayed_job][:start_command]}"
    #   start_cmd = "#{start_cmd}"
    #   start_cmd = "sudo su deploy -c '#{start_cmd}'"
    #   Chef::Log.info(start_cmd)

    #   command start_cmd
    #   action :run
     
    #   only_if do 
    #     File.exists?(deploy[:current_path]) && File.exists?("#{deploy[:current_path]}/script/delayed_job")
    #   end
    # end
  end
end