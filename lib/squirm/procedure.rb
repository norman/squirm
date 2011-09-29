require "forwardable"
require "pathname"

module Squirm

  # This class wraps access to a Postgres stored procedure, exposing it to
  # Ruby as if it were a Ruby Proc.
  class Procedure

    # The Postgres stored procedure's name.
    # @return [String]
    attr :name

    # The schema which holds the stored procedure. Defaults to +public+.
    # @return [String]
    attr :schema

    # An instance of {Arguments} encapsulating information about the
    # arguments needed to invoke the procedure.
    # @return [Squirm::Procedure::Arguments]
    attr :arguments

    # The procedure's Postgres return type
    # @return [String]
    attr :return_type

    # The SQL query used to invoke the stored procedure.
    # @return [String]
    attr :query

    # Raised when an overloaded stored procedure is specified, but no argument
    # list is given.
    #
    # To avoid this error when using overloaded procedures, initialize the
    # {Squirm::Procedure} with the `:args` option.
    class TooManyChoices < RuntimeError
    end

    # Raised when the stored procedure can not be found.
    class NotFound < RuntimeError
    end

    INFO_SQL = Pathname(__FILE__).dirname.join("procedure.sql").read

    # Creates a new stored procedure.
    def initialize(name, options = {})
      @name      = name
      @schema    = options[:schema] || 'public'
      @arguments = Arguments.new(options[:args]) if options[:args]
    end

    # Loads meta info about the stored procedure.
    #
    # This action is not performed in the constructor to allow instances to
    # be created before a database connection has been established.
    #
    # @return [Squirm::Procedure] The instance
    def load
      query = (arguments or self).info_sql
      Squirm.exec(query, [name, schema]) do |result|
        validate result
        set_values_from result
      end
      self
    end

    # The SQL query used to get meta information about the procedure.
    # @see INFO_SQL
    # @return [String]
    def info_sql
      INFO_SQL
    end

    def call(*args, &block)
      Squirm.exec query, arguments.format(*args) do |result|
        if block_given?
          yield result
        elsif return_type =~ /\ASETOF/
          result.to_a
        else
          result.getvalue(0,0)
        end
      end
    end

    alias [] call

    # Checks the number of values returned when looking up meta info about
    # the procedure.
    # @see #load
    # @see #info_sql
    def validate(result)
      if result.ntuples == 0
        raise NotFound
      elsif result.ntuples > 1
        raise TooManyChoices
      end
    end
    private :validate

    # Processes the meta info query_result, setting variables needed by the
    # instance.
    def set_values_from(result)
      @arguments   = Arguments.new(result[0]['arguments'])
      @return_type = result[0]['return_type']
      @query       = "SELECT * FROM %s.%s(%s)" % [
        quoted_schema,
        quoted_name,
        @arguments.to_params
      ]
    end
    private :set_values_from

    # The quoted procedure name.
    # @return [String]
    def quoted_name
      Squirm.quote_ident name
    end

    # The quoted schema name.
    # @return [String]
    def quoted_schema
      Squirm.quote_ident schema
    end

    # A collection of argument definitions for a stored procedure. This class
    # delegates both to an internal hash and to its keys, so it has mixed
    # Array/Hash-like behavior. This allows you to access arguments by offset
    # or name.
    #
    # This may seem like an odd mix of behaviors but is intended to
    # idiomatically translate Postgres's support for both named and unnamed
    # stored procedure arguments.
    class Arguments
      attr :hash, :string

      extend Forwardable
      include Enumerable

      def_delegator :hash, :keys
      def_delegator :keys, :each

      alias to_s string

      # Gets an instance of Arguments from a string.
      #
      # This string can come from a lookup in the pg_proc catalog, or in the
      # case of overloaded functions, will be specified explicitly by the
      # programmer.
      def initialize(string)
        @string = string
        @hash   = self.class.hashify(string)
      end

      # Formats arguments used to call the stored procedure.
      #
      # When given a anything other than a hash, the arguments are returned
      # without modification.
      #
      # When given a hash, the return value is an array or arguments in the
      # order needed when calling the procedure. Missing values are replaced by
      # nil.
      #
      # @example
      #   # Assume a stored procedure with a definition like the following:
      #   # print_greeting(greeting text, greeter text, language text)
      #   arguments.format(greeter: "John", greeting: "hello") #=> ["hello", "John", nil]
      # @return Array
      def format(*args)
        args.first.kind_of?(Hash) ? map {|name| args[0][name]} : args
      end

      # Gets an argument's Postgres type by index or offset.
      # @overload [](offset)
      #   @param [Fixnum] offset The argument's offset
      # @overload [](key)
      #   @param [String] key The argument's name
      # @example
      #   arguments[0]            #=> "text"
      #   arguments["created_at"] #=> "timestamp with time zone"
      def [](key)
        (key.kind_of?(Fixnum) ? keys : hash)[key]
      end

      # Gets Postgres-formatted params for use in calling the procedure.
      # @example
      #   arguments.to_params #=> "$1::text, $2::integer, $3::text"
      # @return String
      def to_params
        @params ||= each_with_index.map do |key, index|
          "$%s::%s" % [index.next, hash[key]]
        end.join(", ")
      end

      # Gets an SQL query used to look up meta information about a stored
      # procedure with a matching argument signature.
      def info_sql
        "#{INFO_SQL} AND pg_catalog.pg_get_function_arguments(p.oid) = '#{to_s}'"
      end

      # Converts an argument string to a hash whose keys are argument names
      # and whose values are argument types.
      def self.hashify(string)
        hash = {}
        string.split(",").map do |arg|
          arg, type = arg.strip.split(/\s+/, 2)
          type ||= arg
          arg   = arg.gsub(/\s+/, '_').gsub(/\A_/, '')
          count = hash.keys.count {|elem| elem =~ /#{arg}[\d]?/}
          hash[count == 0 ? arg : arg + count.next.to_s] = type
        end
        hash
      end
    end
  end
end
