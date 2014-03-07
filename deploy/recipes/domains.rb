# Update domains

node[:deploy].each do |application, deploy|
  rails_server do
    application application
    deploy deploy
  end
end

include_recipe 'nginx::reload'