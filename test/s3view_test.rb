require File.expand_path(File.dirname(__FILE__) + '/test_helper')

set :environment, :test

class S3viewTest < Test::Unit::TestCase
  include Sinatra::Test

  def assert_hmac(expected_sig, key, b64_json)
    assert_equal expected_sig, hmac_signature(key, b64_json), "calculate_hmac failed"
    assert_equal expected_sig, hmac_signature_with_openssl(key, b64_json), "calculate_hmac_with_openssl failed"
  end
  
  # Figure out how to access helpers.
  def hmac_signature(key, data)
    sha = HMAC::SHA1.new(key)
    sha.update(data)
    base64(sha.digest)
  end
  
  # Figure out how to access helpers.
  def hmac_signature_with_openssl(key, base64_json)
    base64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), key, base64_json))
  end

  # Figure out how to access helpers.
  def base64(stuff)
    Base64.encode64(stuff).delete("\n")
  end
  
  def test_it_should_show_a_default_page
    get '/'
    assert response.ok?
    assert response =~ /AWSAccessKeyId/
  end

  # From http://doc.s3.amazonaws.com/proposals/post.html#Access_Control_Example
  def test_should_make_signature
    json =<<JSON
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
    fake_secret_key = "uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o"
    expected_sig = "2qCp0odXe7A9IYyUVqn0w2adtCA="
    expected_b64_policy_doc = "eyAiZXhwaXJhdGlvbiI6ICIyMDA3LTEyLTAxVDEyOjAwOjAwLjAwMFoiLAogICJjb25kaXRpb25zIjogWwogICAgeyJidWNrZXQiOiAiam9obnNtaXRoIiB9LAogICAgWyJzdGFydHMtd2l0aCIsICIka2V5IiwgInVzZXIvZXJpYy8iXSwKICAgIHsiYWNsIjogInB1YmxpYy1yZWFkIiB9LAogICAgeyJyZWRpcmVjdCI6ICJodHRwOi8vam9obnNtaXRoLnMzLmFtYXpvbmF3cy5jb20vc3VjY2Vzc2Z1bF91cGxvYWQuaHRtbCIgfSwKICAgIFsic3RhcnRzLXdpdGgiLCAiJENvbnRlbnQtVHlwZSIsICJpbWFnZS8iXSwKICAgIHsieC1hbXotbWV0YS11dWlkIjogIjE0MzY1MTIzNjUxMjc0In0sCiAgICBbInN0YXJ0cy13aXRoIiwgIiR4LWFtei1tZXRhLXRhZyIsICIiXSwKICBdCn0K"

    assert_equal expected_b64_policy_doc, base64(json)
    assert_hmac(expected_sig, fake_secret_key, base64(json))
  end

  # From http://docs.amazonwebservices.com/AmazonS3/latest/index.html?RESTAuthentication.html
  def test_latest_hmac_implementation
    json =<<JSON
{ "expiration": "2007-12-01T12:00:00.000Z",
  "conditions": [
    {"bucket": "johnsmith"},
    ["starts-with", "$key", "user/eric/"],
    {"acl": "public-read"},
    {"success_action_redirect": "http://johnsmith.s3.amazonaws.com/successful_upload.html"},
    ["starts-with", "$Content-Type", "image/"],
    {"x-amz-meta-uuid": "14365123651274"},
    ["starts-with", "$x-amz-meta-tag", ""]
  ]
}
JSON
    fake_secret_key = "uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o"
    expected_sig = "0RavWzkygo6QX9caELEqKi9kDbU="
    expected_b64_policy_doc = "eyAiZXhwaXJhdGlvbiI6ICIyMDA3LTEyLTAxVDEyOjAwOjAwLjAwMFoiLAogICJjb25kaXRpb25zIjogWwogICAgeyJidWNrZXQiOiAiam9obnNtaXRoIn0sCiAgICBbInN0YXJ0cy13aXRoIiwgIiRrZXkiLCAidXNlci9lcmljLyJdLAogICAgeyJhY2wiOiAicHVibGljLXJlYWQifSwKICAgIHsic3VjY2Vzc19hY3Rpb25fcmVkaXJlY3QiOiAiaHR0cDovL2pvaG5zbWl0aC5zMy5hbWF6b25hd3MuY29tL3N1Y2Nlc3NmdWxfdXBsb2FkLmh0bWwifSwKICAgIFsic3RhcnRzLXdpdGgiLCAiJENvbnRlbnQtVHlwZSIsICJpbWFnZS8iXSwKICAgIHsieC1hbXotbWV0YS11dWlkIjogIjE0MzY1MTIzNjUxMjc0In0sCiAgICBbInN0YXJ0cy13aXRoIiwgIiR4LWFtei1tZXRhLXRhZyIsICIiXQogIF0KfQo="

    assert_equal expected_b64_policy_doc, base64(json)  
    assert_hmac(expected_sig, fake_secret_key, base64(json))
  end

  # From demo.html
#   def test_demo_hmac
#     json =<<JSON
# { 
#   "expiration": "2107-12-01T12:00:00.000Z",
#   "conditions": [
#     {"bucket": "public.marcchung.com" },
#     ["starts-with", "$key", "testfile.txt"],
#     {"acl": "public-read" },
#     ["starts-with", "$Content-Type", "text/"]
#   ]
# }
# JSON
#     secret_key = "<SECRET KEY GOES HERE>" # Enter secret key
#     expected_sig = "qOTLoQUVa1w9q0YlPfX7CXzKbp8="
#     expected_b64_policy_doc = "eyAKICAiZXhwaXJhdGlvbiI6ICIyMTA3LTEyLTAxVDEyOjAwOjAwLjAwMFoiLAogICJjb25kaXRpb25zIjogWwogICAgeyJidWNrZXQiOiAicHVibGljLm1hcmNjaHVuZy5jb20iIH0sCiAgICBbInN0YXJ0cy13aXRoIiwgIiRrZXkiLCAidGVzdGZpbGUudHh0Il0sCiAgICB7ImFjbCI6ICJwdWJsaWMtcmVhZCIgfSwKICAgIFsic3RhcnRzLXdpdGgiLCAiJENvbnRlbnQtVHlwZSIsICJ0ZXh0LyJdCiAgXQp9Cg=="
# 
#     assert_equal expected_b64_policy_doc, base64(json)  
#     assert_hmac(expected_sig, secret_key, base64(json))
#   end

end
