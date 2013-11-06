bash 'configure_ssl' do
  cwd node['postgresql']['config']['data_directory']
  user 'root'
  code <<-EOH

# Generate private key
openssl genrsa -des3 -out server.key -passout pass:755011 1024
# Remove passphrase
openssl rsa -in server.key -out server.key -passin pass:755011

openssl req -new -key server.key -days 3650 -out server.crt -x509 -subj '/C=US/ST=California/L=Los Angeles/O=Survly/CN=www.survly.com/emailAddress=hi@survly.com'
cp server.crt root.crt

#Set permissions on key
chmod og-rwx server.key
chown postgres.postgres server.key
chown postgres.postgres server.crt
  EOH
  not_if { File.exists?("#{node['postgresql']['config']['data_directory']}/server.crt") }
  action :run
end