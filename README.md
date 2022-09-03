## Validy

![Gem](https://img.shields.io/gem/dt/validy.svg)
![GitHub last commit](https://img.shields.io/github/last-commit/nucleom42/validy.svg)
![Gem](https://img.shields.io/gem/v/validy.svg)

**Problem:**

* Want to have a easy way to validate instance variables in plain ruby object like in Active Record? 
* Wants to easily enrich you class with validation methods like: **validate, validate!, valid?, errors** ..?
* Wants to standardize you code for services where responsibility is near to validation?

**Solution:**

* Just include Validy into your class, indicate a name of the **validation action method** and instantiate your class as usual with MyClass.new or trigger validation process, by explicitly call **validation action method** without or with bang.

**Notes:**

* Wants to force raising an exception while creating an object if validation failed? Add to your **validation action method** bang

## Examples

```ruby

class ValidyFoo
  include Validy
  validy_on method: :validate # must be implemented method which includes validations

  attr_accessor :foo, :fool, :foolish

  def initialize(foo = nil, fool = 10, foolish = 0)
    @foo = foo
    @fool = fool
    @foolish = foolish
  end

  def call
    # manual guard unless you want continue logic execution
    return unless valid?
    # logic
    foo + fool - foolish
  end
  
  # if method will have bang at the end (i.e validate!), first fail will raise an error
  def validate
    # for performing validation you can chain predefined validation methods for each variable:
    # required, optional, type, condition
    required(:foo).type(Integer, { type_error: 'not an integer' })
                  .condition(proc { @foo > 2 }, error: 'foo must be bigger than 2')

    required(:fool).type(Integer).condition(:bigger_than_three?, 'fool must be bigger than 3')
    # you can manually add validation method
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
..
pry(main)> isnstance = ValidyFoo.new(4)
pry(main)> isnstance.valid?

=> true

pry(main)> isnstance.foo = ''
pry(main)> isnstance.validate
pry(main)> isnstance.valid?

=> false

pry(main)> isnstance.foo = ''
pry(main)> isnstance.validate!

=> Validy::Error, 'type_error: not an integer'
```

## Install

```ruby

gem install validy

```

## Rails

```ruby

gem 'validy'

```