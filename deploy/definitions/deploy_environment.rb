define :deploy_environment do
  application = params[:app]
  deploy = params[:deploy_data]

  template "#{deploy[:deploy_to]}/shared/config/environment.rb" do
    source 'environment.rb.erb'
    mode '0600'
    group deploy[:group]
    owner deploy[:user]
    variables(:app_env => deploy[:app_env])

    only_if do
      File.exists?("#{deploy[:deploy_to]}") &&
      File.exists?("#{deploy[:deploy_to]}/shared/config/")
    end
  end
end