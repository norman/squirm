module Squirm

  # Support for working with procedures inside Active Record models. This exists
  # primarily to ensure that stored procedure calls are done inside the same
  # connection  used by the AR model, to avoid transaction opacity issues that
  # could arise if AR and Squirm are used different connections.
  module ActiveRecord
    class Procedure < ::Squirm::Procedure
      attr_accessor :connector

      def call(*args, &block)
        Squirm.use(connector.call) do
          super
        end
      end
    end

    def self.included(model_class)
      model_class.extend ClassMethods
    end

    module ClassMethods
      def procedure(name, options = {}, &block)
        self.class_eval(<<-EOM, __FILE__, __LINE__ + 1)
          @@__squirm ||= {}
          @@__squirm[:#{name}] = Squirm::ActiveRecord::Procedure.new("#{name}")
          @@__squirm[:#{name}].connector = ->{connection}
          @@__squirm[:#{name}].load
          def #{options[:as] or name}(options = {})
            options[:id] ||= id if @@__squirm[:#{name}].arguments.hash.has_key?(:id)
            @@__squirm[:#{name}].call(options)
          end
        EOM
      end
    end
  end

  class Railtie < Rails::Railtie
    initializer "squirm.setup" do
      Squirm.connect pool: ::ActiveRecord::Base.connection_pool
      ::ActiveRecord::Base.send :include, Squirm::ActiveRecord
    end

    rake_tasks do
      load File.expand_path("../rails/squirm.rake", __FILE__)
    end

    generators do
      require File.expand_path("../rails/generator", __FILE__)
    end

  end
end

