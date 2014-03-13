# restart Unicorn service per app
node[:deploy].each do |application, deploy|
  if deploy[:application_type] == 'rails'
    execute "restart unicorn" do
      command "#{deploy[:deploy_to]}/shared/scripts/unicorn restart"
      only_if do
        File.exists?("#{deploy[:deploy_to]}/shared/scripts/unicorn")
      end
    end
  end
end
