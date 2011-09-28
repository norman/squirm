if ENV["COVERAGE"]
  require 'simplecov'
  SimpleCov.start do
    add_filter "/spec/"
  end
end

$:.unshift File.expand_path("../../lib", __FILE__)

require "minitest/spec"
require 'minitest/autorun'
require 'pg'

$VERBOSE = true

require "squirm"

$squirm_test_connection = {dbname: "squirm_test"}
