# Have to manually protect against non-layer runs due to lack of ability
# to run Rollback recipes without an override hack.
#
# https://forums.aws.amazon.com/thread.jspa?threadID=147782&tstart=0
#
if node[:opsworks][:instance][:layers].include?('workers') || 
  node[:opsworks][:instance][:layers].include?('rails-app')
  node[:deploy].each do |application, deploy|

    workers = {}.tap do |worker|
      (deploy['workers'] || {}).each do |type, value|
        worker[type] = value if type == 'tread_mill' &&
          value.is_a?(Array) && value.length > 0
      end
    end

    if deploy[:application_type] != 'rails' || workers['tread_mill'].nil? ||
      workers['tread_mill'].length == 0
        Chef::Log.info("Skipping workers::tread_mill-rollback, #{application} "\
          "application does not appear to have any delayed job queues!")
      next
    end

    tread_mill_server do
      app application
      deploy_data deploy
      workers workers
    end
  end
else
  Chef::Log.info("Skipping workers::tread_mill-rollback on instance "\
    "#{node[:opsworks][:instance][:hostname]} because it is on "\
    "layer(s) '#{node[:opsworks][:instance][:layers].join('\',\'')}'.  "\
    "DJ Rollback can only be run on a 'rails-app' or 'workers' layer.")
end