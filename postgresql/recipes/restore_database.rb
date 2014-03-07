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

node[:postgresql][:databases].each do |dbase|
  if node.key?(:backup) && node[:backup][:databases].include?(dbase[:app])
    pg_database_backup dbase[:app] do
      file node[:backup][:dump]
      database dbase[:database]
      
      action :restore

      if node.key?(:postgresql)
        s3_key node[:postgresql][:s3_key]
        s3_secret node[:postgresql][:s3_secret]
      end
    end
  end
end