# frozen_string_literal: true

module MediaTypes
  class Scheme

    # Base class for all validations errors
    class ValidationError < ArgumentError; end

    # Raised when trying to register an attribute with a non-string key
    class KeyTypeError < ArgumentError; end

    # Raised when trying to register a key twice
    class DuplicateKeyError < ArgumentError;
      SYMBOL_SYMBOL_CASE = 'SYMBOL_SYMBOL'
      STRING_STRING_CASE = 'STRING_STRING'
      SYMBOL_STRING_CASE = 'SYMBOL_STRING'
      STRING_SYMBOL_CASE = 'STRING_SYMBOL'
      attr_reader :duplicate_case
      def initialize(msg, dup_case)
        @duplicate_case = dup_case
        super(msg)
      end
    end

    # Raised when it did not expect more data, but there was more left
    class StrictValidationError < ValidationError; end

    # Raised when it expected not to be empty, but it was
    class EmptyOutputError < ValidationError; end

    # Raised when a value did not have the expected type
    class OutputTypeMismatch < ValidationError; end

    # Raised when it expected more data but there wasn't any left
    class ExhaustedOutputError < ValidationError; end
  end
end
