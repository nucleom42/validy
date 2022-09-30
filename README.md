## Validy

![Gem](https://img.shields.io/gem/dt/validy.svg)
![GitHub last commit](https://img.shields.io/github/last-commit/nucleom42/validy.svg)
![Gem](https://img.shields.io/gem/v/validy.svg)

**Problem:**

* Want to have an easy way to validate instance variables in plain ruby object like in Active Record model?
* Wants to easily enrich you class with validation methods like: **valid?, errors** ..?
* Wants to standardize you code for services where responsibility is near to validation?

**Solution:**

* Just include Validy into your class
* Define a name of the **validation action method** with validy_on helper method
* Implement **validation action method** with either inbuilt validation methods ( required, optional, type, condition ) or mannual ones.
* When your class will be instantiated like MyClass.new or trigger validation will be processed,
* by explicitly call **validation action method** without or with the bang ( Raising an error will be reflected correspondingly )

**Notes:**

* Wants to force raising an exception while creating an object if validation failed? Add to your **validation action method** bang postfix
* and that will do all of the magic!
## Install

```ruby

gem install validy

```

## Rails

```ruby

gem 'validy'

```

## Examples

```ruby

class ValidyFoo
  include Validy
  # Must be implemented method, which will be assigned for triggering 
  # while defining valid inner state of the targeted instance.
  validy_on method: :validate, setters: [:fool]
  # You can also able to assign each setter for firing validation check

  attr_accessor :foo, :fool, :foolish

  def initialize(foo = nil, fool = 10, foolish = 0)
    @foo = foo
    @fool = fool
    @foolish = foolish
  end

  def call
    # The guard approach of preventing `main` method execution manually
    # unless you want continue logic neglecting validation state
    return unless valid?
    # Custom logic
    foo + fool - foolish
  end

  # If method will have bang at the end (i.e validate!),
  # first fail will raise an error
  def validate
    
    # For performing validation you can either:
    #   * chain predefined validation methods for each variable:
    #     `required`, `optional`, `type`, `condition`
    #   * or call custom one
    
    # Example of chaining predefined validation methods with ability
    # to assign custom error hash or message
    required(:foo).type(Integer, { type_error: 'not an integer' })
                  .condition(proc { @foo > 2 }, error: 'foo must be bigger than 2')
    optional(:fool).type(Integer).condition(:bigger_than_three?, 'fool must be bigger than 3')
    
    # Likewise example for manually added validation method
    foolish_is_zero?
  end

  # User defined validation method
  def bigger_than_three?
    @fool > 3
  end

  # Manual way of setting validation method
  def foolish_is_zero?
    return unless valid?

    add_error error: 'foolish must be zero' unless @foolish.zero?
  end
end
..
pry(main)> isnstance = ValidyFoo.new(4)
pry(main)> isnstance.valid?

=> true

pry(main)> isnstance.foo = ''
pry(main)> isnstance.validate
pry(main)> isnstance.valid?

=> false

# It is not necessary to call explicitly `validate`
# because fool in the setter's list  defined in the config.
# So validate for all instance variables will be triggered
# once setter for variable fool will be triggered
pry(main)> isnstance.fool = ''
pry(main)> isnstance.valid?

=> false

pry(main)> isnstance.foo = ''
pry(main)> isnstance.validate!

=> Validy::Error, 'type_error: not an integer'
```
