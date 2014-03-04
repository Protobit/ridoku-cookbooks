bash 'configure_ssl' do
  cwd node['postgresql']['config']['data_directory']
  user 'root'

  ssl = node['postgresql']['cert_attributes']
  passcode = ssl['rsa_passphrase']
  subj_string = "/C=#{ssl['country']}/ST=#{ssl['state']}/L=#{ssl['city']}" \
    "/O=#{ssl['organization']}/CN=#{ssl['common_name']}" \
    "/emailAddress=#{ssl['email']}"

  code <<-EOH
# Generate private key
openssl genrsa -des3 -out server.key -passout pass:#{passcode} 1024
# Remove passphrase
openssl rsa -in server.key -out server.key -passin pass:#{passcode}

openssl req -new -key server.key -days 3650 -out server.crt -x509 -subj '#{subj_string}'
cp server.crt root.crt

#Set permissions on key
chmod og-rwx server.key
chown postgres.postgres server.key
chown postgres.postgres server.crt
EOH

  not_if do
    File.exists?("#{node['postgresql']['config']['data_directory']}/server.crt")
  end

  action :run
end