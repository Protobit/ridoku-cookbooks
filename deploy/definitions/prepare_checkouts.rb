define :prepare_checkouts do
  deploy = params[:deploy_data]
  application = params[:app]

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
end 
