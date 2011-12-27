require "squirm/core"
require "squirm/pool"
require "squirm/procedure"
require "squirm/executor"

=begin
Squirm is an experimental anti-ORM for database-loving programmers who want to
take full advantage of the advanced functionality offered by Postgres. With
Squirm, you write your entire database layer using the tools of the domain
experts: SQL and stored procedures. Muahahahahaha!

== Using it

First of all you should know that this is experimental, and in-progress. So you
might want to exercise lots of caution. Don't build your mission critical app on
top of Squirm now, or possibly ever.

=== Getting a connection

Squirm comes with a very simple, threadsafe connection pool.

    Squirm.connect dbname: "postgres", pool_size: 5, timeout: 5

=== Performing queries

The `Squirm.use` method will check out a connection and yield it to the block
you pass. The connection is a vanilla instance of PGConn, so all of Postgres's
functionality is directly exposed to you without any sugar or intermediaries.

When the block returns, the connection is checked back into the pool.

    # conn is a PGconn instance
    Squirm.use do |conn|
      conn.exec "SELECT * FROM users" do |result|
        puts result.first
      end
    end

    # shorthand for above
    Squirm.exec "SELECT * FROM users" do |result|
      puts result.first
    end

`Squirm.use` executes the block inside a new thread, and set the currently
checked out connection as a thread local variable, so that calls to Squirm.exec
inside the block will use the same connection. It will wait for the thread to
return and then return the block's return value.

=== Accessing a stored procedure

Accessing an API you create is simple:

    procedure = Squirm::Procedure.new "create", schema: "users"
    procedure.call email: "john@example.com", name: "John Doe"

You can also get easy access to the functions that ship with Postgres, if for
some reason you want to use them:

    proc = Squirm::Procedure.new("date", schema: "pg_catalog", args: "abstime")
    proc.call("Jan 1, 2011") #=> "2011-01-01"

=end


module Squirm
  Rollback, Timeout = 2.times.map { Class.new RuntimeError }
  extend Core
end

module Kernel
  def Squirm(&block)
    Squirm::Executor.eval(&block)
  end
end