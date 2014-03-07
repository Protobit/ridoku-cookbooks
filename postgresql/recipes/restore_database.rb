# encoding: utf-8

# This information is required to be at the top of 'node'
# node[:backup] = {
#   "databases": [
#     "databasename1",
#     "databasename2"
#   ],
#   "dump": {
#     "type": "s3",
#     "region": "us-west-1",
#     "bucket": "database-backups"
#   }
# }

# :dump can contain two things at the moment:
# flat local File
# {
#   type: 'file',
#   file: '/path/to/file'
# }
# or for S3
# {
#   type: 's3',
#   region: "us-west-1",
#   bucket: "database-backups"
# }

if node[:opsworks][:instance][:layers].include?('postgresql')
  node[:postgresql][:databases].each do |dbase|
    Chef::Log.warn("Namespace 'backup' does not exist!") unless
      node.key?(:backup)

    if node.key?(:backup) && node[:backup][:databases].include?(dbase[:app])
      Chef::Log.debug("Running pg_database_backup:restore on #{dbase[:app]}")
      pg_database_backup dbase[:app] do
        file node[:backup][:dump]
        database dbase[:database]
        
        action :restore

        if node.key?(:postgresql)
          s3_key node[:postgresql][:s3_key]
          s3_secret node[:postgresql][:s3_secret]
        end
      end
    else
      Chef::Log.debug("Skipping pg_database_backup:restore on #{dbase[:app]}")
    end
  end
else
  Chef::Log.debug("Skipping pg_database_backup:restore on #{node[:opsworks][:instance][:hostname]}")
end