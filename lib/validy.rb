# frozen_string_literal: true

module Validy
  Error = Class.new(StandardError)
  NotImplementedError = Class.new(StandardError)
  OverImplemented = Class.new(StandardError)

  def self.included(base)
    base.send(:extend, ClassMethods)
    base.send(:include, InstanceMethods)
    base.prepend(Initializer)
  end

  module Initializer
    def initialize(*)
      @errors = {}
      @valid = true
      @evaluating_attribute = nil

      super

      if method_presented?(method_without_bang)
        send(method_without_bang)
      elsif method_presented?(method_with_bang)
        send(method_with_bang)
      else
        raise NotImplementedError, 'validy method given from validy_on method: argument, must be implemented!'
      end
    end
  end

  module ClassMethods
    def validy_on(method:)
      method_with_bang_name = (method[-1] == '!' ? method.to_s : "#{method}!")
      method_without_bang_name = method_with_bang_name.gsub('!', '')

      define_method :method_with_bang do
        method_with_bang_name
      end

      define_method :method_without_bang do
        method_without_bang_name
      end

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
      end
      prepend hooks
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

      validate_condition(@evaluating_attribute&.is_a?(clazz),
                         error || "`#{@evaluating_attribute}` is not a type #{clazz}", &block)
      self
    end

    private

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

      error_hash = error_hash(error)
      add_error(error_hash)

      block.call if block_given?
    end
  end
end
