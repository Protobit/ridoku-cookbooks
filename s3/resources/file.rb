# coding: utf-8
#
# Author:: Christopher Peplin (<peplin@bueda.com>)
# Author:: Ivan Porto Carrero (<ivan@mojolly.com>)
# Copyright:: Copyright (c) 2010 Bueda, Inc.
# Copyright:: Copyright (c) 2011 Mojolly Ltd.
# License:: Apache License, Version 2.0
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

actions :create, :put
default_action :create

attribute :access_key_id,    :regex => [ /^([a-z]|[A-Z]|[0-9]|_|-|\/|\\|\+)+$/ ]
attribute :secret_access_id, :regex => [ /^([a-z]|[A-Z]|[0-9]|_|-|\/|\\|\+)+$/ ]
attribute :group,            :regex => [ /^([a-z]|[A-Z]|[0-9]|_|-)+$/, /^\d+$/ ]
attribute :owner,            :regex => [ /^([a-z]|[A-Z]|[0-9]|_|-)+$/, /^\d+$/ ]
attribute :mode,             :regex => /^0?\d{3,4}$/
attribute :source,           :kind_of => String

attribute :headers,           :kind_of => Hash
attribute :expires,          :kind_of => Integer
