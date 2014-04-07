#
# Cookbook Name:: nginx
# Recipe:: configure
# Author:: AJ Christensen <aj@junglist.gen.nz>
#          Terry Meacham <zv1n.fire@gmail.com>
#
# Copyright 2008, OpsCode, Inc.
# Copyright 2013, Protobit, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
package "nginx"

include_recipe 'nginx::configure'

service "nginx" do
  if node[:opsworks][:instance][:layers].include?('workers') && 
    !node[:opsworks][:instance][:layers].include?('rails-app')
    action [ :enable ]
  else
    action [ :enable, :start ]
  end
end
