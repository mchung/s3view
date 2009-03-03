require 'rubygems' # REMOVE
require 'sinatra'
require 'time'
require 'base64'
require 'json'
require 'hmac-sha1'

# http://developer.amazonwebservices.com/connect/entry!default.jspa?categoryID=139&externalID=1434&printable=true

helpers do
  def policy_document
    {
      "expiration" => expiration,
      "conditions" => [
        {"bucket" => config[:bucket]},
        {"acl" => default_acl},
        ["eq","$key","testfile.txt"],
        ["starts-with","$Content-Type","text/"]
      ]
    }.to_json
  end

  def s3_action
    "https://#{bucket}.s3.amazonaws.com"
  end
  
  def hmac_signature(key, data)
    sha = HMAC::SHA1.new(key)
    sha.update(data)
    base64(sha.digest)
  end
  
  def base64(data)
    Base64.encode64(data).delete("\n")
  end
  
  # TODO strftime should account for .000Z bit
  def expiration
    # (Time.now + 60*60).iso8601
    "2097-12-01T13:54:23.000Z"
  end

  # TODO Does this read the file each time in production mode?
  def config
    @config ||= YAML.load_file(sinatra_root + "/config/s3.yml")
  end

  def bucket
    config[:bucket]
  end
  
  def access_key_id
    config[:access_key_id]
  end
  
  def secret_access_key
    config[:secret_access_key]
  end
  
  def default_acl
    config[:default_acl]
  end
  
  # TODO Put this somewhere else
  def sinatra_root
    File.dirname(__FILE__) + '/..'
  end
end

before do
  @policy_document = base64(policy_document)
  @signature = hmac_signature(secret_access_key, @policy_document)
end

get '/' do
  haml :upload
end
