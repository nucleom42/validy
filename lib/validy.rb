# frozen_string_literal: true

module Validy
  Error = Class.new(StandardError)
  NotImplementedError = Class.new(StandardError)

  MUST_BE_IMPLEMENTED_ERROR = 'validy method given from validy_on method: argument, must be implemented!'.freeze

  def self.included(base)
    base.send(:extend, ClassMethods)
    base.send(:include, InstanceMethods)
    base.prepend(Initializer)
  end

  module Initializer
    def initialize(*)
      @errors = {}
      @valid = true

      super
      # trigger validations
      if method_presented?(method_without_bang)
        send(method_without_bang)
      elsif method_presented?(method_with_bang)
        send(method_with_bang)
      else
        raise NotImplementedError, MUST_BE_IMPLEMENTED_ERROR
      end
    end
  end

  module ClassMethods
    # @param [String] method - indicates custom, must be implemented method for which will be triggered for defining
    # @param [Array] setters - optional, list of the instance variables for checking valid state while using setter
    # validation state
    # @return [void]
    def validy_on(method:, setters: [])
      method_with_bang_name = (method[-1] == '!' ? method.to_s : "#{method}!")
      method_without_bang_name = method_with_bang_name.gsub('!', '')

      define_validation_methods_name(method_with_bang_name, method_without_bang_name)

      define_validation_triggers(method, setters)
    end

    private

    def define_validation_triggers(method, setters)
      hooks = Module.new do
        method_with_bang_name = (method[-1] == '!' ? method.to_s : "#{method}!")
        method_without_bang_name = method_with_bang_name.gsub('!', '')
        define_method method_with_bang_name do |*args, &block|
          if method_presented?(method_without_bang_name)
            send(method_without_bang_name, *args, &block)
          else
            super(*args, &block)
          end

          raise ::Validy::Error, stringified_error unless valid?
        end

        if setters.any?
          setters.each do |name|
            define_method("#{name}=".to_sym) do |val|
              instance_variable_set("@#{name}", val)
              method[-1] == '!' ? send(method_with_bang) : send(method_without_bang)
            end
          end
        end
      end

      prepend hooks
    end

    def define_validation_methods_name(with_bang_name, without_bang_name)
      define_method :method_with_bang do
        with_bang_name
      end

      define_method :method_without_bang do
        without_bang_name
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

    # "invalid?" returns opposite value of inner valid state
    # @return [Boolean]
    def invalid?
      !valid?
    end

    # "errors" returns errors hash
    # @return [Hash]
    def errors
      @errors
    end

    # "condition" evaluates either passed block or instance method represented in the instance
    # @param [String|block] method or callable object which will be triggered for validation
    # @param [String|Hash] error definition
    # @param [Proc] block
    def condition(method, error = nil, &block)
      return self unless valid?
      return self if skip_optional?

      condition = method.respond_to?(:call) ? method.call : send(method)
      validate_condition(condition, error, &block)
      self
    end

    # "required" checks presence of the variable
    # @param [String] attribute a target one
    # @param [String|Hash] error custom defined error message
    # @param [Proc] block
    def required(attribute, error = nil, &block)
      return self unless valid?

      @evaluating_attribute_value = instance_variable_get("@#{attribute}")
      validate_condition(@evaluating_attribute_value, error || "#{attribute} required!", &block)
      self
    end

    # "optional" starts void validation for the given attribute
    # @param [String] attribute a target one
    def optional(attribute)
      return self unless valid?

      @optional = true
      @evaluating_attribute_value = instance_variable_get("@#{attribute}")
      self
    end

    # "type" validates type of the instance variable
    # @param [Object] clazz for checking type of the target attribute
    # @param [nil] error custom defined error message
    # @param [Proc] block
    def type(clazz, error = nil, &block)
      return self unless valid?
      return self if skip_optional?

      validate_condition(
        @evaluating_attribute_value&.is_a?(clazz),
        error || "`#{@evaluating_attribute_value}` is not a type #{clazz}", &block
      )
      self
    end

    private

    def skip_optional?
      return false unless @optional

      @evaluating_attribute_value.nil?
    end

    def method_presented?(method)
      method_to_symed = method.to_sym
      methods.any? { |m| m == method_to_symed }
    end

    def stringified_error
      errors.inject(String.new) { |s, h| s << "#{h[0]}: #{h[1]}" }
    end

    def error_hash(error)
      return error if error.is_a?(Hash)

      { error: error }
    end

    def validate_condition(condition, error = nil, &block)
      return if condition

      error_hash = error_hash error
      add_error error_hash

      block.call if block_given?
    end
  end
end
