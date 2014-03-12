# Update domains

node[:deploy].each do |application, deploy|
  rails_server do
    app application
    deploy_data deploy
  end
end

include_recipe 'nginx::reload'