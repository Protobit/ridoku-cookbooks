include_recipe 'postgresql::server'

directory node['postgresql']['config']['data_directory'] do
  owner "postgres"
  group "postgres"
  mode 0700
  action :create
end

case node['platform_family']
when "debian"
  init_db_command =
    ["/usr/lib/postgresql/#{node['postgresql']['version']}/bin/initdb",
    "-D #{node['postgresql']['config']['data_directory']}"].join(' ')

  execute 'create new cluster' do
    user 'postgres'
    command init_db_command

    not_if do
      File.exists?("#{node['postgresql']['config']['data_directory']}/PG_VERSION")
    end
  end

  file "#{node['postgresql']['config']['data_directory']}/pg_hba.conf" do
    action :delete
  end

  file "#{node['postgresql']['config']['data_directory']}/postgresql.conf" do
    action :delete
  end

  file "#{node['postgresql']['config']['data_directory']}/pg_ident.conf" do
    action :delete
  end
else
  Chef::Application.fatal!('Invalid platform family! (ubuntu only).')
end

node.default['postgresql']['config_pgtune']['db_type'] = 'web'

include_recipe 'postgresql::config_initdb'
include_recipe 'postgresql::config_pgtune'
include_recipe 'postgresql::config_ssl'

shmmax = node['memory']['total'].split("kB")[0].to_i*1024*256 # in bytes 1/4 of total mem

# This is required on ubuntu.  The SHMMAX is set reallly low.
# https://bugs.launchpad.net/ubuntu/+source/linux/+bug/264336
# So, we're going to set it to what we need it set to...
execute 'update shmmax' do
  user 'root'
  command "sysctl -w kernel.shmmax=#{shmmax}"
end

# This hasn't been seen as an issue, but I've seen recommendations to also
# increase semaphore limits.
# TODO: Make this more based on system resources!
# execute 'configure semaphores' do
#   user 'root'
#   command 'sysctl -w kernel.sem=250 256000 32 1024'
# end

template "#{node['postgresql']['dir']}/postgresql.conf" do
  source "postgresql.conf.erb"
  owner "postgres"
  group "postgres"
  mode 0600
end

node['postgresql']['databases'].each do |db|
  node.default['postgresql']['pg_hba'] << {
    :type => 'hostssl', :db => db[:database], :user => db[:username],
    :addr => '0.0.0.0/0', :method => 'md5'
  }
end

template "#{node['postgresql']['dir']}/pg_hba.conf" do
  source "pg_hba.conf.erb"
  owner "postgres"
  group "postgres"
  mode 0600
end

execute 'start_postgresql' do
  user 'root'
  command "pg_ctlcluster #{node['postgresql']['version']} main start"
  action :run
end

# NOTE: Consider two facts before modifying "assign-postgres-password":
# (1) Passing the "ALTER ROLE ..." through the psql command only works
#     if passwordless authorization was configured for local connections.
#     For example, if pg_hba.conf has a "local all postgres ident" rule.
# (2) It is probably fruitless to optimize this with a not_if to avoid
#     setting the same password. This chef recipe doesn't have access to
#     the plain text password, and testing the encrypted (md5 digest)
#     version is not straight-forward.
bash "assign-postgres-password" do
  user 'postgres'
  code <<-EOH
echo "ALTER ROLE postgres ENCRYPTED PASSWORD '#{node['postgresql']['password']['postgres']}';" | psql
  EOH
  action :run
end

include_recipe 'postgresql::create_databases'