require "pg"
require "thread"

module Squirm

  # The core DSL used by Squirm.
  module Core

    # Establishes a connection pool.
    # @param [Hash] options The connection options
    # @option options [String] :pool Use the given pool rather than Squirm's.
    # @option options [Fixnum] :timeout The pool timeout.
    # @option options [Fixnum] :pool_size The pool size.
    def connect(options = {})
      return @pool = options[:pool] if options[:pool]
      options   = options.dup
      timeout   = options.delete(:timeout) || 5
      pool_size = options.delete(:pool_size) || 1
      @pool     = Squirm::Pool.new(timeout)
      pool_size.times do
        conn = PGconn.open(options)
        yield conn if block_given?
        @pool.checkin conn
      end
    end

    # Disconnects all pool connections and sets the pool to nil.
    def disconnect
      return unless pool
      pool.map(&:close)
      @pool = nil
    end

    # Executes the query and passes the result to the block you specify.
    def exec(*args, &block)
      if current = Thread.current[:squirm_connection]
        current.exec(*args, &block)
      else
        use {|conn| conn.exec(*args, &block)}
      end
    end

    def procedure(*args)
      Procedure.load(*args)
    end

    # Gets the connection pool.
    # @return [Squirm::Pool] The connection pool.
    def pool
      @pool if defined? @pool
    end

    # Performs a #use inside a transaction.
    def transaction
      use do |connection|
        connection.transaction do |conn|
          begin
            yield conn
          rescue Rollback
            return
          end
        end
      end
    end

    # Rolls back from inside a #transaction block.
    def rollback
      raise Rollback
    end

    # Checks out a connection and uses it for all database access inside the
    # block.
    def use
      conn = @pool.checkout
      begin
        Thread.current[:squirm_connection] = conn
        yield conn
      ensure
        Thread.current[:squirm_connection] = nil
        @pool.checkin conn
      end
    end

    # Quotes an SQL identifier.
    # @return [String] The identifier.
    def quote_ident(*args)
      PGconn.quote_ident(*args.map(&:to_s))
    end
  end
end
