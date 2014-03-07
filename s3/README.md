Initially taken from: https://gist.github.com/casualjim/1264036
Referenced at: https://gist.github.com/peplin/470321

Author:: Christopher Peplin (<peplin@bueda.com>)
Author:: Ivan Porto Carrero (<ivan@mojolly.com>)
Copyright:: Copyright (c) 2010 Bueda, Inc.
Copyright:: Copyright (c) 2011 Mojolly Ltd.
License:: Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


```RUBY
# Source accepts the protocol region:// with the host as the bucket
# access_key_id and secret_access_key are just that
 
# for the eu-west-1 region: 
s3_file "/var/bulk/the_file.tar.gz" do
  source "s3-eu-west-1://your.bucket/the_file.tar.gz"
  access_key_id your_key
  secret_access_key your_secret
  owner "root"
  group "root"
  mode 0644
end
 
# for the us-east-1 region: 
s3_file "/var/bulk/the_file.tar.gz" do
  source "s3://your.bucket/the_file.tar.gz"
  access_key_id your_key
  secret_access_key your_secret
  owner "root"
  group "root"
  mode 0644
end

# for uploads

# for the us-east-1 region: 
s3_upload_file "s3://your.bucket/the_file.tar.gz" do
  source "/var/bulk/the_file.tar.gz"
  access_key_id your_key
  secret_access_key your_secret
  action :put
end
```