require "forwardable"
require "monitor"
require "set"

module Squirm

  # A ridiculously simple object pool.
  class Pool
    extend Forwardable
    include Enumerable

    attr_reader :connections
    attr_accessor :timeout

    def_delegator :@mutex, :synchronize

    def initialize(timeout=5)
      @mutex       = Monitor.new
      @timeout     = timeout
      @condition   = @mutex.new_cond
      @queue       = []
      @connections = Set.new
    end

    # Synchronizes iterations provided by Enumerable.
    def each(&block)
      synchronize { @connections.each(&block) }
    end

    # Check a connection back in.
    def checkout
      synchronize do
        return @queue.shift unless @queue.empty?
        @condition.wait(@timeout)
        @queue.empty? ? raise(Timeout) : next
      end
    end

    # Check out a connection.
    def checkin(conn)
      synchronize do
        @connections.add conn
        @queue.push conn
        @condition.signal
      end
    end
  end
end
