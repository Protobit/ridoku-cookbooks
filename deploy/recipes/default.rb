include_recipe 'dependencies'

# alternative/fallback install of bundler for more robustness
# handle cases where the gem library is there but the executable is missing
execute "Ruby Bundler install: #{node[:opsworks_bundler][:version]}" do

  start_cmd = "gem install bundler -v=#{node[:opsworks_bundler][:version]} --no-document"
  start_cmd = "sudo #{start_cmd}"
    
  command start_cmd
  only_if do
    !system("sudo su deploy -c 'gem list bundler -v=#{node[:opsworks_bundler][:version]} --installed'") || !File.exists?(node[:opsworks_bundler][:executable])
  end
end

node[:deploy].each do |application, deploy|

  opsworks_deploy_user do
    deploy_data deploy
  end

end
