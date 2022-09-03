# frozen_string_literal: true

module Validy
  ValidyError = Class.new(StandardError)
  NotImplementedError = Class.new(StandardError)
  OverImplemented = Class.new(StandardError)

  def self.included(base)
    base.send(:include, InstanceMethods)
    base.prepend(Initializer)
  end

  module Initializer
    def initialize(*)
      @errors = {}
      @valid = true
      @evaluating_attribute = nil
      super
      # perform checks and eventually set valid state of the instantiated object
      # validate! instance method must be implemented otherwise it will raise an error
      if respond_to?(:validate) && respond_to?(:validate!)
        raise OverImplemented, 'Only one method `validate` or `validate!` must be implemented'
      end

      if respond_to? :validate
        validate
      elsif respond_to? :validate!
        validate!
        raise ValidyError, stringified_error unless valid?
      else
        raise NotImplementedError, 'validate or validate! method must be implemented!'
      end
    end
  end

  module InstanceMethods
    # "add_error" adds an error and set valid state to false
    # @return [FalseClass]
    def add_error(args = {})
      @errors.merge!(args)
      @valid = false
    end

    # "valid?" returns inner valid state
    # @return [Boolean]
    def valid?
      @valid
    end

    # "errors" returns errors hash
    # @return [Hash]
    def errors
      @errors
    end

    # "condition" evaluates either passed block or instance method represented in the instance
    def condition(method, error = nil, &block)
      return self unless valid?

      condition = method.respond_to?(:call) ? method.call : send(method)
      validate_condition(condition, error, &block)
      self
    end

    # "required" checks presence of the variable
    def required(attribute, error = nil, &block)
      return self unless valid?

      @evaluating_attribute = instance_variable_get("@#{attribute}")
      validate_condition(@evaluating_attribute, error || "#{attribute} required!", &block)
      self
    end

    # "optional" starts void validation for the given attribute
    def optional(attribute)
      return self unless valid?

      @evaluating_attribute = instance_variable_get("@#{attribute}")
      self
    end

    # "type" validates type of the instance variable
    def type(clazz, error = nil, &block)
      return self unless valid?

      validate_condition(@evaluating_attribute&.is_a?(clazz), error || "#{@evaluating_attribute} is not a type #{clazz}", &block)
      self
    end

    refine self do
      def validate!
        puts 'Before'
        super
        puts 'After'
      end
    end

    private

    def stringified_error
      errors.inject(String.new) { |s, h| s << "#{h[0]}: #{h[1]}" }
    end

    def error_hash(error)
      return error if error.is_a?(Hash)

      { error: error }
    end

    def validate_condition(condition, error = nil, &block)
      return if condition

      error_hash = error_hash(error)
      add_error(error_hash)

      block.call if block_given?
    end

    def method_missing(method, *_args)
      case method
        when :validate!
          return unless respond_to?(:validate)

          validate
          raise ValidyError, stringified_error unless valid?
        when :validate
          return unless respond_to?(:validate!)

          validate!
        else
          raise ArgumentError, "Method `#{method}` doesn't exist."
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name[/validate|!/] || super
    end
  end
end
