# frozen_string_literal: true

require 'spec_helper'

describe Validy do
  describe '#validate' do
    context 'when no validate action method defined' do
      let(:klass) do
        Class.new do
          include Validy
          validy_on method: :validate
        end
      end

      it 'will raise error' do
        expect { klass.new }.to raise_error
      end
    end

    let(:klass) do
      Class.new do
        include Validy
        validy_on method: :validate # must be implemented method which includes validations

        attr_accessor :foo, :fool, :foolish

        def initialize(foo = nil, fool = 10, foolish = 0)
          @foo = foo
          @fool = fool
          @foolish = foolish
        end

        def call
          return unless valid?

          foo + fool - foolish
        end

        def validate
          required(:foo).type(Integer, { type_error: 'not an integer' }).condition(proc { @foo > 2 }, error: 'foo must be bigger than 2')

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
    end

    context 'when valid instance' do
      let(:valid_instance) { klass.new(4) }

      it 'valid? returns true' do
        expect(valid_instance.valid?).to eq true
      end

      it 'errors returns {}' do
        expect(valid_instance.errors).to eq({})
      end

      context 'when set invalid value' do
        before do
          valid_instance.foo = ''
        end

        context 'when validate' do
          it 'valid? returns false' do
            expect { valid_instance.validate }.to change(valid_instance, :valid?).to(false)
          end

          it 'errors returns error string' do
            valid_instance.validate
            expect(valid_instance.errors).to eq({ type_error: 'not an integer' })
          end
        end

        context 'when validate!' do
          it 'raise an error' do
            expect { valid_instance.validate! }.to raise_error(Validy::Error).with_message('type_error: not an integer')
          end
        end
      end
    end

    context 'when invalid instance' do
      let(:invalid_instance) { klass.new(1, 11) }

      it 'valid? returns false' do
        expect(invalid_instance.valid?).to eq false
      end

      it 'errors returns hash' do
        expect(invalid_instance.errors).to eq({ error: 'foo must be bigger than 2' })
      end

      it 'validate! raise an error' do
        expect { invalid_instance.validate! }.to raise_error(Validy::Error).with_message('error: foo must be bigger than 2')
      end
    end
  end

  describe '#validate!' do
    let(:klass_validate_with_bang) do
      Class.new do
        include Validy
        validy_on method: :validate!

        attr_accessor :foo, :fool, :foolish

        def initialize(foo = nil, fool = 10, foolish = 0)
          @foo = foo
          @fool = fool
          @foolish = foolish
        end

        def call
          return unless valid?

          foo + fool - foolish
        end

        # must be implemented validate or validate!, the only difference that validate will raise an error in case of invalid
        def validate!
          required(:foo).type(Integer, { type_error: 'not an integer' }).condition(proc { @foo > 2 }, error: 'foo must be bigger than 2')

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
    end

    context 'when valid instance' do
      let(:valid_instance) { klass_validate_with_bang.new(4) }

      it 'valid? returns true' do
        expect(valid_instance.valid?).to eq true
      end

      it 'errors returns {}' do
        expect(valid_instance.errors).to eq({})
      end

      it 'validate! not to raise an error' do
        valid_instance.foo = 'oioi'
        expect { valid_instance.validate! }.to raise_error(Validy::Error)
      end
    end

    context 'when invalid instance' do
      it 'invalid instance raise error' do
        expect { klass_validate_with_bang.new('1', '11') }.to raise_error(Validy::Error).with_message('type_error: not an integer')
      end
    end
  end

  context 'when defined custom validation action method' do
    let(:klass_with_custom_method) do
      Class.new do
        include Validy
        validy_on method: :kraken!

        attr_accessor :foo

        def initialize(foo = nil)
          @foo = foo
        end

        def kraken!
          required(:foo).type(Integer)
        end
      end
    end

    let(:klass_with_custom_method_without_bang) do
      Class.new do
        include Validy
        validy_on method: :kraken

        attr_accessor :foo

        def initialize(foo = nil)
          @foo = foo
        end

        def kraken
          required(:foo).type(Integer)
        end
      end
    end

    context 'when wrapped to method without bang' do
      let(:valid_instance) { klass_with_custom_method_without_bang.new(1) }

      it 'valid? returns true' do
        expect(valid_instance.valid?).to eq true
      end

      it 'errors returns {}' do
        expect(valid_instance.errors).to eq({})
      end

      it 'kraken! not to raise an error' do
        valid_instance.foo = 'oioi'
        expect { valid_instance.kraken! }.to raise_error(Validy::Error)
      end
    end

    context 'when wrapped to method with bang' do
      let(:valid_instance) { klass_with_custom_method.new(1) }

      it 'valid? returns true' do
        expect(valid_instance.valid?).to eq true
      end

      it 'errors returns {}' do
        expect(valid_instance.errors).to eq({})
      end

      it 'kraken! not to raise an error' do
        valid_instance.foo = 'oioi'
        expect { valid_instance.kraken! }.to raise_error(Validy::Error)
      end

      context 'when instance is invalid' do
        it 'invalid instance raise error' do
          expect { klass_with_custom_method.new('1') }.to raise_error(Validy::Error).with_message('error: `1` is not a type Integer')
        end
      end
    end
  end
end
