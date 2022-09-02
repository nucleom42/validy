# frozen_string_literal: true

module Validy
  Error = Class.new(StandardError)
  NotImplementedError = Class.new(StandardError)

  def self.included(base)
    base.send(:include, InstanceMethods)
    base.send(:extend, ClassMethods)
    base.prepend(Initializer)
  end
  
  module ClassMethods
    def validable_setters(factor = true)
      return unless factor

      instance_variables.each do |name|
        next unless self.instance_methods.include?("#{name}=".to_sym)

        define_method("#{name}=") do |value|
          instance_variable_set("@#{name}", value)
          validate
        end
      end
    end
    
    def validable_setters!(factor = true)
      @raise = true
      validable_setters(factor)
    end
  end

  module Initializer
    def initialize(*)
      @errors = {}
      @valid = true
      @evaluating_attribute = nil
      @raise = false
      super
      # perform checks and eventually set valid state of the instantiated object
      # validate! instance method must be implemented otherwise it will raise an error
      if respond_to? :validate
        validate
      elsif respond_to? :validate!
        @raise = true
        validate!
      else
        raise ::Validy::NotImplementedError, 'validate or validate! method must be implemented!'
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

      validate_condition(
        @evaluating_attribute&.is_a?(clazz), error || "#{@evaluating_attribute} is not a type #{clazz}", &block
      )
      self
    end

    private

    def error_hash(e)
      return e if e.is_a?(Hash)

      { error: e }
    end

    def validate_condition(condition, error = nil, &block)
      return if condition

      error_hash = error_hash(error)
      add_error(error_hash)

      block.call if block_given?
      raise ::Error, error_hash.to_json if @raise
    end
  end
end
