include_attribute 'workers::delayed_job'
include_attribute 'workers::sneakers'
include_attribute 'workers::tread_mill'

default[:workers][:needs_reload] = true
default[:workers][:cron_path] = '/etc/rid-workers'
default[:workers][:supported_workers] = ['sneakers', 'delayed_job', 'tread_mill']
