# Handle asset precompilation
# Looks at 2 primary flags:
#
# 1) force_master_manifest: flag, if set, indicates to pull from asset_master
#                           regardless of when it was updated.
#
#  NOTE: assets will be precompiled if the assetmaster is not online.
#        if you wish to use previously generated assets, you need to change
#        the master to an existing instance that has the desired manifest.
#
#  - wait_for_manifest_modification: set if we should wait for the asset master
#                                    to complete precompilation
#
# 2) force_precompile: flag, if set, indicates to precompile assets, regardless
#                      of the existance or online status of the asset_master
#
#  precompile takes precidence over master_manifest

define :precompile_assets do
  application = params[:app]
  deploy = params[:deploy_data]
  rel_path = params[:name]

  unless deploy[:application_type] == 'rails'
    Chef::Log.info('Skipping :precompile_assets. App is not a Rails.')
    return
  end


  # Hack for now...
  # dir = Dir["#{deploy[:deploy_to]}/releases/*"]
  # rel_path = dir.sort[dir.size-1]

  # is_master = OpsWorks::RailsConfiguration.is_master?(application, node)
  # master_is_online = OpsWorks::RailsConfiguration.is_master_online?(application, node)
  # asset = OpsWorks::RailsConfiguration.manifest_info(application, node)
  env = OpsWorks::RailsConfiguration.build_cmd_environment(deploy)
  
  # TODO explore more into asset how best to do this.
  precompile = true #deploy[:force_precompile] ||
    #(is_master || !master_is_online)
  master_manifest = false #deploy[:force_master_manifest] ||
    #(master_is_online && !is_master)

  # when_modified = deploy[:wait_for_manifest_modification] || false

  # if precompile && master_manifest
  #   Chef::Log.info('Both precompile and master_manifest were specified.')
  #   Chef::Log.info('Disabling master_manifest.')
  #   master_manifest = false
  #   when_modified = false
  # end

  execute 'precompile assets' do
    if ::File.exists?("#{rel_path}/Gemfile")
      exec = '/usr/local/bin/ruby /usr/local/bin/bundle exec'
    end

    command ['sudo su deploy',
      "-c 'cd #{rel_path} &&",
      "env #{env} #{exec} rake assets:precompile --trace'"].join(' ')

    # only_if do
    #   precompile
    # end
    action :nothing
  end.run_action(:run)

  # assets_path = "#{rel_path}/#{deploy[:document_root]}/assets/"
  # manifest = "#{assets_path}/manifest.yml"

  # if asset && master_manifest

  #   directory assets_path do
  #     mode 0755
  #     user 'deploy'
  #     group 'www-data'
  #     action :create
  #   end

  #   # no reason to pull Last-Modified time if we're forcing master manifest
  #   remote_file "/tmp/manifest.yml" do
  #     Chef::Log.info("remote #{asset[:manifest]}")
  #     source asset[:manifest]
  #     action :nothing unless when_modified
  #   end

  #   # only pull the manifest is notified or if we're forcing master manifest
  #   remote_file manifest do
  #     Chef::Log.info("remote #{asset[:manifest]}")
  #     source asset[:manifest]
  #     action :nothing if when_modified
  #   end

  #   http_request "HEAD #{asset[:manifest]}" do
  #     Chef::Log.info("HTTP head #{asset[:manifest]}")
  #     message ""
  #     url asset[:manifest]
  #     action :head

  #     if File.exists?("/tmp/manifest.yml")
  #       mtime = File.mtime("/tmp/manifest.yml")

  #       # Only include the header if the manifest file is stale
  #       if mtime < asset[:mod_time]
  #         headers "If-Modified-Since" => mtime.httpdate
  #       end
  #     end

  #     retries 25
  #     retry_delay 120
  #     notifies :create, "remote_file[#{manifest}]", :immediately

  #     # Don't bother if we're forcing the master manifest
  #     only_if do
  #       when_modified
  #     end
  #   end
  # end
end