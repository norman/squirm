module Squirm

  # This class exists simply to provide a space in which to evaluate blocked
  # passed to the Kernel.Squirm method.
  class Executor
    include Core

    def self.eval(&block)
      executor = new(Squirm.pool)
      executor.instance_eval(&block)
    end

    def initialize(pool)
      @pool = pool
    end
  end
end