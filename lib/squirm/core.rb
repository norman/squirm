require "pg"
require "thread"

module Squirm
  module Core
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

    def disconnect
      return unless pool
      pool.map(&:close)
      @pool = nil
    end

    def exec(*args, &block)
      if current = Thread.current[:squirm_connection]
        current.exec(*args, &block)
      else
        use {|conn| conn.exec(*args, &block)}
      end
    end

    def pool
      @pool if defined? @pool
    end

    # Performs a #use inside a transaction
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

    def rollback
      raise Rollback
    end

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

    def quote_ident(*args)
      PGconn.quote_ident(*args)
    end
  end
end