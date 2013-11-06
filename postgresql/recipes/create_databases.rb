node[:postgresql][:databases].each do |dbase|
  pg_user dbase[:username] do
    password dbase[:user_password]
  end

  pg_database dbase[:database] do
    owner dbase[:username]
    encoding "utf8"
    template "template0"
    locale "en_US.UTF8"
  end
end