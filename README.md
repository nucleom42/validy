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

## Examples

```ruby

class ValidyFoo
  include Validy
  validy_on method: :validate # must be implemented method, which will be target for triggering while defining valid state of the target instance.

  attr_accessor :foo, :fool, :foolish

  def initialize(foo = nil, fool = 10, foolish = 0)
    @foo = foo
    @fool = fool
    @foolish = foolish
  end

  def call
    #  a way of preventing main method execution manualy unless you want continue logic neglecting validation state
    return unless valid?
    # logic
    foo + fool - foolish
  end

  # if method will have bang at the end (i.e validate!), first fail will raise an error
  def validate
    # for performing validation you can chain predefined validation methods for each variable:
    # `required`, `optional`, `type`, `condition`
    required(:foo).type(Integer, { type_error: 'not an integer' })
                  .condition(proc { @foo > 2 }, error: 'foo must be bigger than 2')
    # each method except custom error message, can be either string or a hash
    required(:fool).type(Integer).condition(:bigger_than_three?, 'fool must be bigger than 3')
    # Likewise you can manually add validation method
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
