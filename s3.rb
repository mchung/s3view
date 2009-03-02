require 'rubygems' # REMOVE
require 'sinatra'
require 'time'
require 'pp'
require 'base64'
require 'json'
require 'hmac-sha1'

# http://developer.amazonwebservices.com/connect/entry!default.jspa?categoryID=139&externalID=1434&printable=true

helpers do
  
  # def policy_document
  #   {
  #     "expiration" => expiration,
  #     "conditions" => [{"bucket" => bucket}, {"acl" => default_acl}]
  #   }.to_json
  # end
  
  # def policy_document
  #   {
  #     "expiration"=>"2009-01-01T12:00:00.000Z",
  #     "conditions"=>[
  #       {"bucket"=>"public.marcchung.com"},
  #       {"acl"=>"public-read" },
  #       ["eq","$key","testfile.txt"]
  #       ["starts-with","$Content-Type","text/"],
  #     ]
  #   }.to_json
  # end

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
    "http://#{bucket}.s3.amazonaws.com"
  end

  def signature
    hmac = HMAC::SHA1.new(config[:secret_access_key])
    hmac.update(policy_document)
    base64(hmac.digest)
  end
  
  def policy
    base64(policy_document)
  end
  
  def base64(stuff)
    Base64.encode64(stuff).delete("\n")
  end
  
  def expiration
    # (Time.now + 60*60).iso8601
    "2097-12-01T13:54:23.000Z"
  end

  def bucket
    config[:bucket]
  end
  
  def access_key_id
    config[:access_key_id]
  end
  
  def default_acl
    config[:default_acl]
  end

  def config
    YAML.load_file(sinatra_root + "/config/s3.yml")
  end
  
  def sinatra_root
    File.dirname(__FILE__)#  + '/..'
  end
  
end

get '/' do
  haml :upload
end
