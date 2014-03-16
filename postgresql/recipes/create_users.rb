if node[:opsworks][:instance][:layers].include?('postgresql')
  node[:postgresql][:databases].each do |dbase|

    user dbase[:username] do
      gid 'postgres'
      action :create
      shell '/bin/bash'
      home '/var/lib/postgresql'
      supports :manage_home => false
    end

  end
end