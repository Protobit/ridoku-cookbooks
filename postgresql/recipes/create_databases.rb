node[:postgresql][:databases].each do |dbase|
  pg_user dbase[:username] do
    password dbase[:user_password]
  end

  pg_database dbase[:database] do
    owner dbase[:username]
    encoding node['postgresql']['encoding']
    template "template0"
    locale node['postgresql']['locale']
  end
end