# frozen_string_literal: true

module MediaTypes
  module Dsl
    module ClassMethods
      class UninitializedConstructable < RuntimeError
        def message
          'Unable to generate constructable without a name, have you called `use_name(name)`?'
        end
      end

      # Raised when an error occurs during setting expected key type
      class KeyTypeExpectationError < StandardError; end
    end
  end
end
