define :cron_configuration do
  application = params[:app]
  deploy = params[:deploy_data]

  (deploy[:cron] || []).each do |cron_info|
    next unless cron_info.is_a?(Hash)

    instances = cron_info[:instance].split(',')
    next unless instances.include?('*') ||
      instances.include?(node[:opsworks][:instance][:hostname])

    script_path = cron_info[:path]
    base = File.basename(script_path)
    cron_script = "/etc/rid-workers/#{application}-#{base}.sh"
    cron_action = :create

    case cron_info[:type]
    when 'runner'
      # Generate the runner script (stores environment)
      template cron_script do
        source 'runner_cron.sh.erb'

        owner deploy[:user]
        group deploy[:group]
        mode 0700

        variables(
          :script_path => script_path,
          :deploy => deploy
        )
        action :create
      end
    when 'delete'
      cron_action = :delete
    end

    cron File.basename(cron_script) do
      command cron_script
      user deploy[:user]

      [:day, :hour, :minute, :month, :weekday].each do |key|
        send(key, cron_info[key]) if cron_info.key?(key)
      end

      # Allow for the delete state.
      action cron_action
    end
  end
end