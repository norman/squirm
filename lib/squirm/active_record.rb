module Squirm

  # Support for working with procedures inside Active Record models. This exists
  # primarily to ensure that stored procedure calls are done inside the same
  # connection  used by the AR model, to avoid transaction opacity issues that
  # could arise if AR and Squirm used different connections.
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
      def procedure(name)
        procedure = Squirm::ActiveRecord::Procedure.new(name)
        procedure.connector = ->{connection}
        procedure.load
      end
    end
  end
end

ActiveRecord::Base.send :include, Squirm::ActiveRecord
