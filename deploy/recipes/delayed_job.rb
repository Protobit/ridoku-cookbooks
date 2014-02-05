include_recipe 'deploy'

node[:deploy].each do |application, deploy|

  if deploy[:application_type] != 'rails' &&
    deploy.key?('workers') && deploy['workers'].length > 0
      Chef::Log.debug("Skipping deploy::delayed_job, #{application} "\
        "application does not appear to have any delayed job queues!")
    next
  end

  Chef::Log.info("Running deploy::delayed_job for #{application}...")

  opsworks_deploy_dir do
    user deploy[:user]
    group deploy[:group]
    path deploy[:deploy_to]

    notifies :run, "execute[Ruby Bundler install: #{node[:opsworks_bundler][:version]}]", :immediately
  end

  opsworks_rails do
    deploy_data deploy
    app application
  end

  opsworks_deploy do
    deploy_data deploy
    app application
  end

 #  execute "kill Server" do
 #    pid_dir = "#{deploy[:current_path]}/tmp/pids"
 #    pid_file = "#{pid_dir}/thin.pid"
 #    cwd pid_dir

 #    command "sudo kill $(cat #{pid_file})"
 #    action :run

 #    only_if do 
 #      File.exists?(pid_file)
 #    end
 #  end

 #  execute "dashing bundle install" do
 #    start_cmd = "cd #{deploy[:current_path]} &&"
 #    start_cmd = "#{start_cmd} /usr/local/bin/ruby /usr/local/bin/bundle install --path #{deploy[:home]}/.bundler/#{application} --without=#{deploy[:ignore_bundler_groups].join(' ')}"
 #    start_cmd = "sudo su deploy -c '#{start_cmd}'"
 #    Chef::Log.info(start_cmd)

 #    command start_cmd
 #    only_if do 
 #      File.exists?(deploy[:current_path])
 #    end
 #  end

 # execute "start Server" do
 #   cwd deploy[:current_path]

 #   start_cmd = "auth_token=\"#{deploy[:auth_token]}\""
 #   start_cmd = "#{start_cmd} /usr/local/bin/bundle exec" #--path #{deploy[:home]}/.bundler/#{application}"
 #   start_cmd = "#{start_cmd} #{node[:opsworks][:dashing][:start_command]}"
 #   start_cmd = "#{start_cmd} --port #{deploy[:port]} --daemonize"
 #   start_cmd = "sudo su deploy -c '#{start_cmd}'"
 #   Chef::Log.info(start_cmd)

 #   command start_cmd
 #   action :run
   
 #   only_if do 
 #     File.exists?(deploy[:current_path])
 #   end
 # end
end
