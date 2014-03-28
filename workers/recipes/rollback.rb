# ecnoding: utf-8

if node[:opsworks][:instance][:layers].include?('workers') || 
  node[:opsworks][:instance][:layers].include?('rails-app')

  if node[:opsworks][:instance][:layers].include?('workers')
    node[:deploy].each do |application, deploy|
      if deploy[:application_type] != 'rails'
        Chef::Log.debug('Skipping workers::rollback application '\
          "#{application} as it is not a Rails app")
        next
      end

      deploy deploy[:deploy_to] do
        provider Chef::Provider::Deploy::Revision

        repository deploy[:scm][:repository]
        revision deploy[:scm][:revision]
        user deploy[:user]

        environment "RAILS_ENV" => deploy[:rails_env], "RUBYOPT" => ""
        action "rollback"

        only_if do
          File.exists?(deploy[:current_path])
        end
      end
    end
  end

  include_recipe 'workers::delayed_job-rollback'
  include_recipe 'workers::sneakers-rollback'
end