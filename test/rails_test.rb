require 'test/unit'
require 'rubygems'
require 'action_controller'
$LOAD_PATH << File.join(File.dirname(__FILE__), '..',  'lib')
require 'docomo_css/rails'

class TestController < ActionController::Base
  include DocomoCss::Rails
  docomo_filter
end

class RailsTest < Test::Unit::TestCase
  def test_dependencies
    assert true
  end
end
