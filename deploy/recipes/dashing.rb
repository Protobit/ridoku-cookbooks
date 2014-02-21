include_recipe 'deploy'

node[:deploy].each do |application, deploy|

  if deploy[:application_type] != 'other' ||
    (deploy.key?('other') && deploy['other'] != 'dashing')
      Chef::Log.debug("Skipping deploy::dashing, #{application} application is"\
        " either not 'other' or not (type) 'dashing'!")
    next
  end

  opsworks_deploy_dir do
    user deploy[:user]
    group deploy[:group]
    path deploy[:deploy_to]
  end

  opsworks_dashing do
    deploy_data deploy
    app application
  end

 execute "stop Server" do
   cwd deploy[:current_path]
   env = OpsWorks::RailsConfiguration.build_cmd_environment(deploy)

   start_cmd = "#{env} /usr/local/bin/ruby /usr/local/bin/bundle exec" #--path #{deploy[:home]}/.bundler/#{application}"
   start_cmd = "#{start_cmd} #{node[:opsworks][:dashing][:stop_command]}"
   start_cmd = "sudo su deploy -c '#{start_cmd}'"
   Chef::Log.info(start_cmd)

   command start_cmd
   action :run
   
   only_if do 
     Chef::Log.info("Checking deploy path: #{deploy[:current_path]}")
     File.exists?(deploy[:current_path])
   end

   notifies :run, 'execute[start Server]', :immediate
 end

 execute "start Server" do
   cwd deploy[:current_path]
   env = OpsWorks::RailsConfiguration.build_cmd_environment(deploy)

   start_cmd = "#{env} /usr/local/bin/ruby /usr/local/bin/bundle exec" #--path #{deploy[:home]}/.bundler/#{application}"
   start_cmd = "#{start_cmd} #{node[:opsworks][:dashing][:start_command]}"
   start_cmd = "#{start_cmd} --port #{deploy[:port]} --daemonize"
   start_cmd = "sudo su deploy -c '#{start_cmd}'"
   Chef::Log.info(start_cmd)

   command start_cmd
   action :nothing
   
   only_if do 
     Chef::Log.info("Checking deploy path: #{deploy[:current_path]}")
     File.exists?(deploy[:current_path])
   end
 end
end
