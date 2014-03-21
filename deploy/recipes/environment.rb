if node[:opsworks][:instance][:layers].include?('rails-app')
  # This pretty much must be a 'restart' because the environment is handled
  # by the start script.
  include_recipe 'unicorn::rails'
  include_recipe 'deploy::delayed_job'
elsif node[:opsworks][:instance][:layers].include?('workers')
  include_recipe 'deploy::delayed_job'
end

