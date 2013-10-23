# The database recipe should be included by any server running a DB. It creates
# a /data directory and, if on EC2, will mount an EBS volume here
 
 # Source: http://clarkdave.net/2013/04/managing-ebs-volumes-with-chef/
directory node["postgresql"]["data_directory"] do
  mode '0755'
end
 
if node[:app][:ec2]
  aws = data_bag_item('aws', 'main')
  
  include_recipe 'aws'
 
  if node[:app][:ebs][:raid]
 
    aws_ebs_raid 'data_volume_raid' do
      mount_point node["postgresql"]["data_directory"]
      disk_count 2
      disk_size node[:app][:ebs][:size]
      level 10
      filesystem 'ext4'
      action :auto_attach
    end
 
  else
 
    # get a device id to use
    devices = Dir.glob('/dev/xvd?')
    devices = ['/dev/xvdf'] if devices.empty?
    devid = devices.sort.last[-1,1].succ
 
    # save the device used for data_volume on this node -- this volume will now always
    # be attached to this device
    node.set_unless[:aws][:ebs_volume][:data_volume][:device] = "/dev/xvd#{devid}"
 
    device_id = node[:aws][:ebs_volume][:data_volume][:device]
 
    # no raid, so just mount and format a single volume
    aws_ebs_volume 'data_volume' do
      aws_access_key aws['aws_access_key_id']
      aws_secret_access_key aws['aws_secret_access_key']
      size node[:app][:ebs][:size]
      device device_id.gsub('xvd', 'sd') # aws uses sdx instead of xvdx
      action [:create, :attach]
    end

    log "Device_id: #{device_id}"
 
    # wait for the drive to attach, before making a filesystem
    # ruby_block "sleeping_data_volume" do
    #   loop do
    #     if File.blockdev?(device_id)
    #       break
    #     else
    #       Chef::Log.info("device #{device_id} not ready - sleeping 10s")
    #       sleep 10
    #     end
    #   end
    # end
 
    # create a filesystem
    execute 'mkfs' do
      command "mkfs -t ext4 #{device_id}"
    end
 
    mount node["postgresql"]["data_directory"] do
      device device_id
      fstype 'ext4'
      options 'noatime,nobootwait'
      action [:enable, :mount]
    end
  end
end

#Make sure pg data directory is empty otherwise we will get an error during pg install
execute "empty_pg_data_directory" do
  command "rm -rf #{node["postgresql"]["data_directory"]}/*"
  action :run
end

include_recipe "postgresql::server"

pg_user node[:postgresql][:username] do
  privileges superuser: true, createdb: true, login: true
  password node[:postgresql][:username_password]
end

pg_database node[:postgresql][:database] do
  owner node[:postgresql][:username]
  encoding "utf8"
  template "template0"
  locale "en_US.UTF8"
end

