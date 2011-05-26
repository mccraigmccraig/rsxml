$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rubygems'
require 'spec'
require 'spec/autorun'
require 'rr'
require 'nokogiri'
require 'rsxml'
require 'rsxml/mock_visitor'

Spec::Runner.configure do |config|
  config.mock_with RR::Adapters::Rspec
end
