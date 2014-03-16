# encoding: utf-8

require 'tempfile'

def fetch_from_s3(source)
  region, bucket, key = URI.split(source).compact
  key = key[1..-1]
  expires = @new_resource.expires || 30
  s3 = S3Sign.new(@new_resource.access_key_id, @new_resource.secret_access_id)
  access_key = @new_resource.access_key_id
  secret_key = @new_resource.secret_access_id
  headers = @new_resource.headers || {}
  Chef::Log.debug("Downloading #{key} from S3 bucket #{bucket}")
  file = ::File.open(@new_resource.name, 'wb')
  Chef::Log.debug("Writing to file #{file.path}")
  host = "#{region||"s3"}.amazonaws.com"
  Chef::Log.debug("Connecting to s3 host: #{host}:443")
  http_client = Net::HTTP.new(host, 443)
  http_client.use_ssl = true
  http_client.verify_mode = OpenSSL::SSL::VERIFY_NONE
  http_client.start do |http|
    pth = s3.get(bucket, key, expires, headers)
    Chef::Log.debug("Requesting #{pth}")
    http.request_get(pth) do |res|
      res.read_body do |chunk|
        file.write chunk
      end
    end
  end
  Chef::Log.debug("File #{key} is #{::File.size(file.path)} bytes on disk")
  begin
    yield file
  ensure
    file.close
  end
rescue URI::InvalidURIError
  Chef::Log.warn("Expected an S3 URL but found #{source}")
  nil
end

def upload_to_s3()
  file = ::File.open(@new_resource.source)

  begin
    region, bucket, key = URI.split(@new_resource.name).compact
    key = key[1..-1]
    expires = @new_resource.expires || 180
    s3 = S3Sign.new(@new_resource.access_key_id, @new_resource.secret_access_id)
    access_key = @new_resource.access_key_id
    secret_key = @new_resource.secret_access_id
    headers = @new_resource.headers || {}
    Chef::Log.debug("Uploading #{key} from S3 bucket #{bucket}")
    host = "#{region||"s3"}.amazonaws.com"
    Chef::Log.debug("Connecting to s3 host: #{host}:443")
    http_client = Net::HTTP.new(host, 443)
    http_client.use_ssl = true
    http_client.verify_mode = OpenSSL::SSL::VERIFY_NONE
    path = s3.put(bucket, key, expires, headers)
    response = http_client.start do |http|

      Chef::Log.debug("Putting #{path}")
      request = Net::HTTP::Put.new(path)
      request.body_stream = file

      headers.each { |k,v| request[k] = v }

      request['content-length'] = ::File.size(@new_resource.source)
      http.request(request)
    end
    Chef::Log.debug("Request: https://#{host}#{path}")
    Chef::Log.debug("Response: #{response.body}")
    Chef::Log.debug("https://#{host}#{path}")
    Chef::Application.fatal!("S3 Request Failed: #{response.code} "\
        "#{response.message}") if response.code != '200'
  ensure
    file.close
  end
rescue URI::InvalidURIError
  Chef::Log.warn("Expected an S3 URL but found #{source}")
  nil
end

use_inline_resources

action :create do
  @current_resource.path(@new_resource.name)
  Chef::Log.debug("Checking #{@new_resource} for changes")

  Chef::Log.debug("Resource Name: #{@new_resource.name}")
  fetch_from_s3(@new_resource.source) {}

  FileUtils.chown(@new_resource.owner, @new_resource.group, @new_resource.name)

  @new_resource.updated
end

action :put do
  @current_resource.path(@new_resource.name)
  Chef::Log.debug("Checking #{@new_resource} for changes")

  Chef::Log.debug("Resource Name: #{@new_resource.name}")
  upload_to_s3

  @new_resource.updated
end

def load_current_resource
  @current_resource = Chef::Resource::RemoteFile.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
end
 