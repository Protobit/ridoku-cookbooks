define :cron_configuration do
  application = params[:app]
  deploy = params[:deploy_data]

  (deploy[:cron] || []).each do |cron_info|
    next unless cron_info.is_a?(Hash)

    cron_script = ''

    case cron_info[:type]
    when 'runner'
      script_path = File.join(deploy[:current_path], cron_info[:path])
      base = File.basename(script_path)
      cron_script = "/etc/rid-workers/#{application}-#{base}"

      # Generate the runner script (stores environment)
      template cron_script do
        source 'runner_cron.rb.erb'

        owner deploy[:user]
        group deploy[:group]
        mode 0700

        variables {
          script_path: script_path,
          deploy: deploy
        }
        action :create
      end
    end

    cron "#{File.basename(cron_script).underscore}" do
      command cron_script
      user deploy[:user]

      [:day, :hour, :minute, :month, :weekday].each do |key|
        send(key, cron_info[key]) if cron_info.key?(key)
      end

      # Allow for 'delete' operation for old cron scripts.
      action cron_info.key?(:action) ? cron_info[:action].to_sym || :create
    end
  end
end