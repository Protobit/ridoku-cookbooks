module OpsWorks
  module RailsConfiguration
    def self.build_cmd_environment(app_config)
      app_config[:app_env].map do |key, value|
        "#{key}='#{value}'"
      end.join(' ')
    end

    def self.determine_database_adapter(app_name, app_config, app_root_path, options = {})
      options = {
        :consult_gemfile => true,
        :force => false
      }.update(options)
      if options[:force] || app_config[:database][:adapter].blank?
        Chef::Log.info("No database adapter specified for #{app_name}, guessing")
        adapter = ''

        if options[:consult_gemfile] and File.exists?("#{app_root_path}/Gemfile")
          bundle_list = `cd #{app_root_path}; /usr/local/bin/bundle list`
          adapter = if bundle_list.include?('mysql2')
            Chef::Log.info("Looks like #{app_name} uses mysql2 in its Gemfile")
            'mysql2'
          else
            Chef::Log.info("Gem mysql2 not found in the Gemfile of #{app_name}, defaulting to mysql")
            'mysql'
          end
        else # no Gemfile - guess adapter by Rails version
          adapter = if File.exists?("#{app_root_path}/config/application.rb")
            Chef::Log.info("Looks like #{app_name} is a Rails 3 application, defaulting to mysql2")
            'mysql2'
          else
            Chef::Log.info("No config/application.rb found, assuming #{app_name} is a Rails 2 application, defaulting to mysql")
            'mysql'
          end
        end

        adapter
      else
        app_config[:database][:adapter]
      end
    end

    def self.bundle(app_name, app_config, app_root_path)
      Chef::Log.info("App root path: #{app_root_path}")
      if File.exists?("#{app_root_path}/Gemfile")
        Chef::Log.info("Gemfile detected. Running bundle install.")
        Chef::Log.info("sudo su deploy -c 'cd #{app_root_path} && /usr/local/bin/bundle install --path #{app_config[:home]}/.bundler/#{app_name} --without=#{app_config[:ignore_bundler_groups].join(' ')}'")
        Chef::Log.info(`sudo su deploy -c 'cd #{app_root_path} && /usr/local/bin/bundle install --path #{app_config[:home]}/.bundler/#{app_name} --without=#{app_config[:ignore_bundler_groups].join(' ')} 2>&1'`)
      end
    end

    def self.is_master_online?(app_name, node)
      deploy = node[:deploy][app_name]
      assetmaster = deploy[:assetmaster].to_sym
      inst = node[:opsworks][:layers]['rails-app'][:instances]

      inst.has_key?(assetmaster) && inst[assetmaster][:status] == 'online' &&
        inst[assetmaster][:ip].match(%r([0-9]))
    end

    def self.is_master?(app_name, node)
      node[:deploy][app_name][:assetmaster] ==
        node[:opsworks][:instance][:hostname]
    end

    def self.manifest_info(app_name, node)
      deploy = node[:deploy][app_name]
      assetmaster = deploy[:assetmaster].to_sym
      manifest_override = deploy[:manifest_source]
      inst = node[:opsworks][:layers]['rails-app'][:instances]

      return nil unless inst.key?(assetmaster)
      instance = inst[assetmaster]
      return nil unless instance[:status] == 'online'
      
      {
        :manifest => manifest_override ||
          "http://#{instance[:ip]}/assets/manifest.yml",
        :mod_time => DateTime.strptime(node[:opsworks][:sent_at].to_s ,'%s')
      }
    end
  end
end
