# Update the environment JSON per service

node[:deploy].each do |application, deploy|
  deploy_environment deploy[:deploy_to] do
    deploy_data deploy
    app application
  end
end

# This pretty much must be a 'restart' because the environment is handled
# by the start script.
include_recipe 'unicorn::restart'
