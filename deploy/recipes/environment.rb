# Update the environment JSON per service

node[:deploy].each do |application, deploy|
  deploy_environment do
    deploy_data deploy
    app application
  end
end

# This pretty much must be a 'restart' because the environment is handled
# by the start script.
include_recipe 'unicorn::restart'

# TODO: Look into environment pulling from a file?