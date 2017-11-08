require 'active_model/errors'
require 'forwardable'
require 'adequate_errors/error'

module AdequateErrors
  class Errors
    include Enumerable

    extend Forwardable
    def_delegators :@errors, :each, :size, :clear, :blank?, :empty?, *Enumerable.instance_methods(false)

    def initialize(base)
      @base = base
      @errors = []
    end

    def delete(key)
      @errors.delete_if do |error|
        error.attribute == key
      end
    end

    # Adds error.
    # More than one error can be added to the same `attribute`.
    # If no `type` is supplied, `:invalid` is assumed.
    #
    # @param attribute [Symbol] attribute that the error belongs to
    # @param type [Symbol] error's type
    # @param options [Hash] extra conditions such as interpolated value
    def add(attribute, type = :invalid, options = {})
      @errors.append(::AdequateErrors::Error.new(@base, attribute, type, options))
    end

    # @return [Array(String)] all error messages
    def messages
      @errors.map(&:message)
    end

    # Convenience method to fetch error messages filtered by where condition.
    # @param params [Hash] filter condition, see {#where} for details.
    # @return [Array(String)] error messages
    def messages_for(params)
      where(params).map(&:message)
    end

    # @param params [Hash] filter condition
    #   :attribute key matches errors belonging to specific attribute.
    #   :type key matches errors with specific type of error, for example :blank
    #   custom keys can be used to match custom options used during {#add}.
    # @return [Array(AdequateErrors::Error)]
    #   If params is empty, all errors are returned.
    def where(params)
      return @errors.dup if params.blank?

      @errors.select {|error|
        error.match?(params)
      }
    end

    # Returns true if the given attribute contains error, false otherwise.
    # @return [Boolean]
    def include?(attribute)
      @errors.any?{|error| error.attribute == attribute }
    end

    # @return [Hash] attributes with their error messages
    def to_hash
      hash = {}
      @errors.each do |error|
        if hash.has_key?(error.attribute)
          hash[error.attribute] << error.message
        else
          hash[error.attribute] = [error.message]
        end
      end
      hash
    end
  end
end
