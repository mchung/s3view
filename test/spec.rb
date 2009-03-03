require File.expand_path(File.dirname(__FILE__) + '/../app/main')
require 'spec'
require 'spec/interop/test'
require 'sinatra/test'

class Sinatra::Base
  # Allow assertions in request context
  include Test::Unit::Assertions
end

class Test::Unit::TestCase
  include Sinatra::Test

  # Sets up a Sinatra::Base subclass defined with the block
  # given. Used in setup or individual spec methods to establish
  # the application.
  def mock_app(base=Sinatra::Base, &block)
    @app = Sinatra.new(base, &block)
  end

  def restore_default_options
    Sinatra::Default.set(
      :environment => :development,
      :raise_errors => Proc.new { test? },
      :dump_errors => true,
      :sessions => false,
      :logging => Proc.new { ! test? },
      :methodoverride => true,
      :static => true,
      :run => Proc.new { ! test? }
    )
  end
end

set :environment, :test

describe "sessions" do

  before do
    mock_app {
      get '/' do
        "Test"
      end
    }
  end

  it "should retain things stored in session b/w actions" do
    get '/', :env => { 'rack.session' => { :ok => 'Ok.' } }
    body.should == "Test"
  end

end