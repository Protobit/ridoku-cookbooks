include_recipe 'rails::configure'

node[:deploy].each do |application, deploy|
  if deploy[:application_type] == 'rails'
    execute "unicorn_#{application}_force_restart" do
      cwd deploy[:current_path]
      command node[:opsworks][:rails_stack][:restart_command]
      action :nothing

      subscribes :run, "template[#{deploy[:deploy_to]}/shared/config/database.yml]"
      subscribes :run, "template[#{deploy[:deploy_to]}/shared/config/memcached.yml]"
    end
  end
end
