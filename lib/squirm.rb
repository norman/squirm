require "squirm/core"
require "squirm/pool"
require "squirm/procedure"

module Squirm
  Rollback, Timeout = 2.times.map { Class.new RuntimeError }
  extend Core
end