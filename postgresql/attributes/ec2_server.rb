##
# Postgres User
##
default[:postgresql][:username] = "dbuser"
default[:postgresql][:username_password] = "override_me"

##
# Default database
##
default[:postgresql][:database] = "dbase"

default[:postgresql][:certificate] = {}
default[:postgresql][:certificate][:pass] = 123456
default[:postgresql][:certificate][:state] = 'CA'
default[:postgresql][:certificate][:city] = 'Los Angeles'
default[:postgresql][:certificate][:company] = 'Example Company'
default[:postgresql][:certificate][:site] = 'www.example.com'
default[:postgresql][:certificate][:email] = 'admin@example.com'

##
# EBS Volume for Postgresql data
##
default[:app][:ec2] = true
default[:app][:ebs] = {
  :raid => false,
  :size => 20 # size is in GB
}