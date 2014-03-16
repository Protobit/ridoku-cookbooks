# encoding: utf-8

define :pg_database_backup, :action => :capture do

  defaults    = {
    :user => 'postgres',
    :group => 'postgres',
    :force => false,
    :file => { :type => 'file', :file => "/tmp/#{params[:name]}.dump" }
  }

  # {
  #   "type": "s3",
  #   "region": "us-west-1",
  #   "bucket": "database-backups"
  # }
  
  file = "/tmp/#{params[:name]}.dump"

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
        group defaults[:group]
        mode 0644
        action :put
      end
    end
  when :restore
    Chef::Application.fatal!("A object key must be specified "\
      "([:backup][:dump][:key]) if the backup type of S3 is selected") unless
      defaults[:file].has_key?(:key)

    source_file = defaults[:file]
    if source_file[:type] == 's3'
      s3_file file do
        source "s3://#{source_file[:bucket]}/#{defaults[:file][:key]}"
        access_key_id defaults[:s3_key]
        secret_access_id defaults[:s3_secret]
        owner defaults[:user]
        group 'postgres'
        mode 0644
        action :create
      end
    elsif source_file[:type] == 'file'
      file = source_file[:file]
    end

    execute "#{defaults[:name]} Database Restore" do
      user defaults[:user]

      options = [
        "--dbname=#{defaults[:database]}",
        "--clean"
      ]

      options << '--single-transaction' unless defaults[:force]

      command "pg_restore #{options.join(' ')} #{file}"
      ignore_failure defaults[:force]
    end
  end

  file file do
    action :delete
  end
end