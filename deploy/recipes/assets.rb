# Configure assets.
# Use node[:deploy][application][:force_precompile] to precompile assets.

node[:deploy].each do |application, deploy|
  precompile_assets do
    deploy_data deploy
    app application
    app_path current_path
  end
end