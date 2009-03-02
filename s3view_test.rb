require 'rubygems'
require 'activesupport'
require 'hmac-sha1'
require 'base64'
require 'test/unit'
require 'openssl'
require 'digest/sha1'

class S3viewTest < Test::Unit::TestCase
  
  def setup
    @json =<<JSON
{ "expiration": "2007-12-01T12:00:00.000Z",
  "conditions": [
    {"bucket": "johnsmith" },
    ["starts-with", "$key", "user/eric/"],
    {"acl": "public-read" },
    {"redirect": "http://johnsmith.s3.amazonaws.com/successful_upload.html" },
    ["starts-with", "$Content-Type", "image/"],
    {"x-amz-meta-uuid": "14365123651274"},
    ["starts-with", "$x-amz-meta-tag", ""],
  ]
}
JSON
  end
  
  def calculate_hmac(key, base64_json)
    sha = HMAC::SHA1.new(key)
    sha.update(base64_json)
    base64(sha.digest)
  end
  
  def calculate_hmac_with_openssl(key, base64_json)
    signature = Base64.encode64(
        OpenSSL::HMAC.digest(
            OpenSSL::Digest::Digest.new('sha1'), 
            key, base64_json)
        ).gsub("\n","")

    signature
  end
  
  def base64(stuff)
    Base64.encode64(stuff).delete("\n")
  end
  
  # From http://doc.s3.amazonaws.com/proposals/post.html#Access_Control_Example
  def test_b64_json
    expected_b64 = "eyAiZXhwaXJhdGlvbiI6ICIyMDA3LTEyLTAxVDEyOjAwOjAwLjAwMFoiLAogICJjb25kaXRpb25zIjogWwogICAgeyJidWNrZXQiOiAiam9obnNtaXRoIiB9LAogICAgWyJzdGFydHMtd2l0aCIsICIka2V5IiwgInVzZXIvZXJpYy8iXSwKICAgIHsiYWNsIjogInB1YmxpYy1yZWFkIiB9LAogICAgeyJyZWRpcmVjdCI6ICJodHRwOi8vam9obnNtaXRoLnMzLmFtYXpvbmF3cy5jb20vc3VjY2Vzc2Z1bF91cGxvYWQuaHRtbCIgfSwKICAgIFsic3RhcnRzLXdpdGgiLCAiJENvbnRlbnQtVHlwZSIsICJpbWFnZS8iXSwKICAgIHsieC1hbXotbWV0YS11dWlkIjogIjE0MzY1MTIzNjUxMjc0In0sCiAgICBbInN0YXJ0cy13aXRoIiwgIiR4LWFtei1tZXRhLXRhZyIsICIiXSwKICBdCn0K"
    assert_equal expected_b64, base64(@json)
  end

  # From http://doc.s3.amazonaws.com/proposals/post.html#Access_Control_Example
  def test_hmac
    expected_sig = "2qCp0odXe7A9IYyUVqn0w2adtCA="
    assert_equal expected_sig, calculate_hmac_with_openssl("uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o", base64(@json))
    assert_equal expected_sig, calculate_hmac("uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o", base64(@json))
  end
  
end
