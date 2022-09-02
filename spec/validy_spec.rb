# frozen_string_literal: true

require 'spec_helper'

class ValidyFoo
  include Validy

  attr_accessor :foo, :fool, :foolish
  
  def initialize(foo = nil, fool = 10, foolish = 0)
    @foo = foo
    @fool = fool
    @foolish = foolish
  end
  
  def call
    foo + fool - foolish
  end
  
  # must be implemented validate or validate!
  def validate
    required(:foo).type(Integer, { type_error: 'not an integer' }).condition(proc { @foo > 2 })
    required(:fool).type(Integer).condition(:bigger_than_three?, 'fool must be bigger than 3')
    foolish_is_zero?
  end
  
  # user validation method
  def bigger_than_three?
    @fool > 3
  end

  # manual way of setting validation
  def foolish_is_zero?
    return unless valid?
    
    add_error error: 'foolish must be zero' unless @foolish.zero?
  end
end

describe Validy do
  describe '#initializer' do
    context 'when valid instance' do
      let(:valid_instance) { ValidyFoo.new(4) }

      it 'valid? returns true' do
        expect(valid_instance.valid?).to eq true
      end

      it 'errors returns {}' do
        expect(valid_instance.errors).to eq({})
      end
    end

    context 'when invalid instance' do
      let(:invalid_instance) { ValidyFoo.new(1, 11) }

      it 'valid? returns false' do
        expect(invalid_instance.valid?).to eq false
      end

      it 'errors returns hash' do
        binding.pry
        expect(invalid_instance.errors).to eq({ foo: 'No way, it is a rick!', fool: '11 not eq to 10' })
      end

      it 'validate! raise an error' do
        expect { invalid_instance.validate! }
          .to raise_error(Validy::Error).with_message('{"foo":"No way, it is a rick!"}')
      end

      it 'validate returns false' do
        expect(invalid_instance.validate).to eq false
      end

      context 'when validy!' do
        it 'raise error' do
          expect { RaiseableValidyFoo.new(1) }
            .to raise_error(Validy::Error).with_message('{"foo":"No way, it is a rick!"}')
          RaiseableValidyFoo.new(6).foo = 7
          expect { RaiseableValidyFoo.new(1) }
            .to raise_error(Validy::Error).with_message('{"foo":"No way, it is a rick!"}')
        end
      end
    end
  end

  describe '#setters' do
    let(:instance) { ValidyFoo.new(1) }

    context 'when set valid value over the setter' do
      before { instance.foo = 5 }

      it 'valid? returns true' do
        expect(instance.valid?).to eq true
      end

      it 'errors returns {}' do
        expect(instance.errors).to eq({})
      end
    end

    context 'when set invalid value over the setter' do
      before { instance.foo = 0 }

      it 'valid? returns false' do
        expect(instance.valid?).to eq false
      end

      it 'errors returns {}' do
        expect(instance.errors).to eq({ foo: 'No way, it is a rick!' })
      end
    end

    context 'when no setter defined' do
      it 'will not create a setter under the hood' do
        expect { instance.fooly }.to raise_error NoMethodError
      end
    end

    context 'when raisy' do
      it 'raise error' do
        valid_instance = RaiseableValidyFoo.new(7)
        expect { valid_instance.foo = 0 }
          .to raise_error(Validy::Error).with_message('{"foo":"No way, it is a rick!"}')
      end
    end
  end

  describe '#inner_setter' do
    let(:instance) { ValidyFoo.new(5) }

    context 'when set class variable via method' do
      it 'valid? returns false' do
        instance.inner_setter
        expect(instance.valid?).to eq false
      end

      it 'errors returns {}' do
        instance.inner_setter
        expect(instance.errors).to eq({ foo: 'No way, it is a rick!' })
      end
    end
  end
end
