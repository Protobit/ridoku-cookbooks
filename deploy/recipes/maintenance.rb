include_recipe 'rails::configure'

# Set maintenance mode for an application instance.
node[:deploy].each do |application, deploy|
  if deploy[:application_type] == 'rails' &&
    deploy.has_key?(:maintenance)
    maint_file = "#{deploy[:current_path]}/public/maintenance.txt"
    
    file maint_file do
      mode 0755
      user 'deploy'
      group 'www-data'

      case deploy[:maintenance]
      when true, 'on', 'yes', 'true'
        action = :create
      else
        action = :delete
      end
    end
  end
end
