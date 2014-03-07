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
 
require 'digest/sha1'
require 'openssl'
require 'cgi'
require 'base64'
require "net/http"
require "net/https"
require 'tempfile'
 
## The S3Sign class generates signed URLs for Amazon S3
class S3Sign
  def initialize(aws_access_key_id, aws_secret_access_key)
    @aws_access_key_id = aws_access_key_id
    @aws_secret_access_key = aws_secret_access_key
  end
 
  # builds the canonical string for signing.
  def canonical_string(method, path, headers={}, expires=nil)
    interesting_headers = {}
    headers.each do |key, value|
      lk = key.downcase
      if lk == 'content-md5' or lk == 'content-type' or lk == 'date' or lk =~ /^x-amz-/
        interesting_headers[lk] = value.to_s.strip
      end
    end
 
    # these fields get empty strings if they don't exist.
    interesting_headers['content-type'] ||= ''
    interesting_headers['content-md5'] ||= ''
    # just in case someone used this.  it's not necessary in this lib.
    interesting_headers['date'] = '' if interesting_headers.has_key? 'x-amz-date'
    # if you're using expires for query string auth, then it trumps date (and x-amz-date)
    interesting_headers['date'] = expires if not expires.nil?
 
    buf = "#{method}\n"
    interesting_headers.sort { |a, b| a[0] <=> b[0] }.each do |key, value|
      buf << ( key =~ /^x-amz-/ ? "#{key}:#{value}\n" : "#{value}\n" )
    end
    # ignore everything after the question mark...
    buf << path.gsub(/\?.*$/, '')
    # ...unless there is an acl or torrent parameter
    if    path =~ /[&?]acl($|&|=)/     then buf << '?acl'
    elsif path =~ /[&?]torrent($|&|=)/ then buf << '?torrent'
    end
    return buf
  end
 
  def hmac_sha1_digest(key, str)
    OpenSSL::HMAC.digest(OpenSSL::Digest::SHA1.new, key, str)
  end
 
  # encodes the given string with the aws_secret_access_key, by taking the
  # hmac-sha1 sum, and then base64 encoding it. then url-encodes for query string use
  def encode(str)
    hmac = hmac_sha1_digest(@aws_secret_access_key, str)
    encode_signs(URI.escape(Base64.encode64(hmac).strip))
  end

  def encode_signs(str)
    signs = {'+' => "%2B", '=' => "%3D", '?' => '%3F', '@' => '%40',
      '$' => '%24', '&' => '%26', ',' => '%2C', '/' => '%2F', ':' => '%3A',
      ';' => '%3B', '?' => '%3F'}
    signs.keys.each do |key|
      str.gsub!(key, signs[key])
    end
    str
  end
 
  # generate a url to put a file onto S3
  def put(bucket, key, expires_in=0, headers={})
    return generate_url('PUT', "/#{bucket}/#{CGI::escape key}", expires_in, headers)
  end
 
  # generate a url to put a file onto S3
  def get(bucket, key, expires_in=0, headers={})
    return generate_url('GET', "/#{bucket}/#{CGI::escape key}", expires_in, headers)
  end
 
  # generate a url with the appropriate query string authentication parameters set.
  def generate_url(method, path, expires_in, headers)
    #log "path is #{path}"
    expires = expires_in.nil? ? 0 : Time.now.to_i + expires_in.to_i
    canonical_string = canonical_string(method, path, headers, expires)

    encoded_canonical = encode(canonical_string)
    arg_sep = path.index('?') ? '&' : '?'
    return path + arg_sep + "Signature=#{encoded_canonical}&" + 
           "Expires=#{expires}&AWSAccessKeyId=#{@aws_access_key_id}"
  end
end
