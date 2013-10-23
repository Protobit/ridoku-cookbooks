# Update the environment JSON per service

node[:deploy].each do |application, deploy|
  deploy_environment do
    deploy_data deploy
    app application
  end
end