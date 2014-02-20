define :opsworks_dashing do
  deploy = params[:deploy_data]
  application = params[:app]

#####################################
# taken from opsworks_deploy
  directory "#{deploy[:deploy_to]}" do
    group deploy[:group]
    owner deploy[:user]
    mode "0775"
    action :create
    recursive true
  end

  # create shared/ directory structure
  ['pids', 'log'].each do |dir_name|
    directory "#{deploy[:deploy_to]}/shared/#{dir_name}" do
      group params[:group]
      owner params[:user]
      mode 0770
      action :create
      recursive true
    end
  end

  execute "symlinking mount if necessary" do
    command "rm -f #{deploy[:deploy_to]}/current; ln -s #{deploy[:symlink]} #{deploy[:deploy_to]}/current"
    action :run
    only_if do
      deploy[:symlink] && File.exists?(deploy[:deploy_to])
    end
  end

  if deploy[:scm]
    ensure_scm_package_installed(deploy[:scm][:scm_type])

    prepare_git_checkouts(
      :user => deploy[:user],
      :group => deploy[:group],
      :home => deploy[:home],
      :ssh_key => deploy[:scm][:ssh_key]
    ) if deploy[:scm][:scm_type].to_s == 'git'

    prepare_svn_checkouts(
      :user => deploy[:user],
      :group => deploy[:group],
      :home => deploy[:home],
      :deploy => deploy,
      :application => application
    ) if deploy[:scm][:scm_type].to_s == 'svn'

    if deploy[:scm][:scm_type].to_s == 'archive'
      repository = prepare_archive_checkouts(deploy[:scm])
      node.set[:deploy][application][:scm] = {
        :scm_type => 'git',
        :repository => repository
      }
    elsif deploy[:scm][:scm_type].to_s == 's3'
      repository = prepare_s3_checkouts(deploy[:scm])
      node.set[:deploy][application][:scm] = {
        :scm_type => 'git',
        :repository => repository
      }
    end
  end

  # setup deployment & checkout
  Chef::Log.debug("Checking out source code of Dashing application #{application}.")
  deploy deploy[:deploy_to] do
    repository deploy[:scm][:repository]
    user deploy[:user]
    group deploy[:group]
    revision deploy[:scm][:revision]

    migrate false
    environment deploy[:environment].to_hash
    action :deploy

    case deploy[:scm][:scm_type].to_s
    when 'git'
      scm_provider :git
      enable_submodules deploy[:enable_submodules]
      shallow_clone deploy[:shallow_clone]
    when 'svn'
      scm_provider :subversion
      svn_username deploy[:scm][:user]
      svn_password deploy[:scm][:password]
      svn_arguments "--no-auth-cache --non-interactive --trust-server-cert"
      svn_info_args "--no-auth-cache --non-interactive --trust-server-cert"
    when 'symlink'
      Chef::Log.info('Repository type is symlink. Do nothing.')
    else
      raise "unsupported SCM type #{deploy[:scm][:scm_type].inspect}"
    end

    before_migrate do
      link_tempfiles_to_current_release

      # run user provided callback file
      run_callback_from_file("#{release_path}/deploy/before_migrate.rb")
    end

    not_if do
      deploy.has_key?(:symlink)
    end
  end

  deploy = node[:deploy][application]

  directory "#{deploy[:deploy_to]}/shared/cached-copy" do
    recursive true
    action :delete
    only_if do
      deploy[:delete_cached_copy]
    end
  end

  template "/etc/logrotate.d/opsworks_app_#{application}" do
    backup false
    source "logrotate.erb"
    cookbook 'deploy'
    owner "root"
    group "root"
    mode 0644
    variables( :log_dirs => ["#{deploy[:deploy_to]}/shared/log" ] )
    not_if do
      deploy.has_key?(:symlink)
    end
  end
end 
