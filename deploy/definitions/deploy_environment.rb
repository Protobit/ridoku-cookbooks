define :deploy_environment do
  application = params[:app]
  deploy = params[:deploy_data]
  path = params[:app_path]

  if deploy[:application_type] == 'rails'

    template "#{path}/shared/config/environment.rb" do
      source 'environment.rb.erb'
      mode '0600'
      group deploy[:group]
      owner deploy[:user]
      variables(:app_env => deploy[:app_env])

      only_if do
        File.exists?(path) &&
        File.exists?("#{path}/shared/config/")
      end
    end

  else

    Chef::Log.info('Skipping deployment of environment template.'\
      ' App is not Rails.')

  end
end