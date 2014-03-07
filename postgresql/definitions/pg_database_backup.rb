# encoding: utf-8

define :pg_database_backup, :action => :capture do

  defaults    = {
    :user => 'postgres',
    :file => { :type => 'file', :file => "/tmp/#{params[:name]}.dump" }
  }

  # {
  #   "type": "s3",
  #   "region": "us-west-1",
  #   "bucket": "database-backups"
  # }
  
  tmp = Tempfile.new("#{params[:name]}-tmp.dump")
  file = tmp.path
  tmp.close

  timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
  defaults.merge! params

  case defaults[:action]
  when :capture
    destination_file = defaults[:file]

    if destination_file[:type] == 'file'
      file = destination_file[:file]
    end

    execute "#{defaults[:name]} Database Dump" do
      user defaults[:user]
      command "pg_dump -Fc #{defaults[:database]} > #{file}"
    end

    if destination_file[:type] == 's3'
      s3_file "s3://#{destination_file[:bucket]}/"\
        "#{defaults[:name]}-#{timestamp}.sqd" do
        source file
        access_key_id defaults[:s3_key]
        secret_access_id defaults[:s3_secret]
        headers 'content-type' => 'application/x-sql'
        owner defaults[:user]
        group defaults[:user]
        mode 0644
        action :put
      end
    end
  when :restore
    fail StandardError.new("A object key must be specified "\
      "([:backup][:dump][:key]) if the backup type of S3 is selected") unless
      defaults[:file].has_key?(:key)

    source_file = defaults[:file]
    if source_file[:type] == 's3'

      s3_file file do
        source "s3://#{source_file[:bucket]}/#{defaults[:file][:key]}"
        access_key_id defaults[:s3_key]
        secret_access_id defaults[:s3_secret]
        owner defaults[:user]
        group defaults[:user]
        mode 0644
        action :create
      end
    elsif source_file[:type] == 'file'
      file = source_file[:file]
    end

    execute "#{defaults[:name]} Database Restore" do
      user defaults[:user]
      command "pg_restore -d #{defaults[:database]} #{file}"
    end
  end

  file file do
    action :delete
  end
end