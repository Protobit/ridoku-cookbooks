# This pretty much must be a 'restart' because the environment is handled
# by the start script.
include_recipe 'unicorn::rails'
include_recipe 'unicorn::restart'
