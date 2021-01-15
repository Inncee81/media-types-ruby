# MediaTypes
[![Build Status](https://github.com/SleeplessByte/media-types-ruby/workflows/Ruby/badge.svg?branch=master)](https://github.com/SleeplessByte/media-types-ruby/actions?query=workflow%3ARuby)
[![Gem Version](https://badge.fury.io/rb/media_types.svg)](https://badge.fury.io/rb/media_types)
[![MIT license](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT) 
[![Maintainability](https://api.codeclimate.com/v1/badges/6f2dc1fb37ecb98c4363/maintainability)](https://codeclimate.com/github/SleeplessByte/media-types-ruby/maintainability)

Media Types based on  scheme, with versioning, views, suffixes and validations.

This library makes it easy to define schemas that can be used to validate JSON objects based on their Content-Type.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'media_types'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install media_types

## Usage

Define a validation:

```ruby
require 'media_types'

module Acme
  MediaTypes::set_organisation Acme, 'acme'

  class FooValidator
    include MediaTypes::Dsl

    use_name 'foo'

    validations do
      attribute :foo, String
    end
  end
end
```

Validate an object:

```ruby
Acme::FooValidator.validate!({ foo: 'bar' })
```

## Full example

```Ruby
require 'media_types'

class Venue
  include MediaTypes::Dsl
  
  def self.organisation
    'mydomain'
  end
  
  use_name 'venue'

  validations do
    version 2 do
      attribute :name, String
      collection :location do
        attribute :latitude, Numeric
        attribute :longitude, Numeric
        attribute :altitude, AllowNil(Numeric)
      end

      link :self
      link :route, allow_nil: true
    end
    
    version 1 do
      attribute :name, String
      attribute :coords, String
      attribute :updated_at, String
    
      link :self
    end
    
    view 'create' do
      collection :location do
        attribute :latitude, Numeric
        attribute :longitude, Numeric
        attribute :altitude, AllowNil(Numeric)
      end
      
      version 1 do
        collection :location do
          attribute :latitude, Numeric
          attribute :longitude, Numeric
          attribute :altitude, AllowNil(Numeric)
        end
      end
    end
  end
end
```

## Schema Definitions

If you include 'MediaTypes::Dsl' in your class you can use the following functions within a `validation do` block to define your schema:

### `attribute`

Adds an attribute to the schema, if a +block+ is given, uses that to test against instead of +type+

| param     | type                      | description                                                                                                                                                                    |
| --------- | ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| key       | `Symbol`                  | the attribute name                                                                                                                                                             |
| opts      | `Hash`                    | options to pass to `Scheme` or `Attribute`                                                                                                                                     |
| type      | `Class`, `===`, Scheme    | The type of the value, can be anything that responds to `===`,  or scheme to use if no `&block` is given. Defaults to `Object` without a `&block` and to Hash with a `&block`. |
| optional: | `TrueClass`, `FalseClass` | if true, key may be absent, defaults to `false`                                                                                                                                |
| &block    | `Block`                   | defines the scheme of the value of this attribute                                                                                                                              |

#### Add an attribute named foo, expecting a string
```Ruby
require 'media_types'

class MyMedia
  include MediaTypes::Dsl

  validations do
    attribute :foo, String
  end
end

MyMedia.valid?({ foo: 'my-string' })
# => true
```

####  Add an attribute named foo, expecting nested scheme

```Ruby
class MyMedia
 include MediaTypes::Dsl

 validations do
   attribute :foo do
     attribute :bar, String
   end
 end
end

MyMedia.valid?({ foo: { bar: 'my-string' }})
# => true
```

### `any`
Allow for any key. The `&block` defines the Schema for each value.

| param          | type                     | description                                                                                                        |
| -------------- | ------------------------ | ------------------------------------------------------------------------------------------------------------------ |
| scheme         | `Scheme`, `NilClass`     | scheme to use if no `&block` is given                                                                              |
| allow_empty:   | `TrueClass`, `FalsClass` | if true, empty (no key/value present) is allowed                                                                   |
| expected_type: | `Class`,                 | forces the validated value to have this type, defaults to `Hash`. Use `Object` if either `Hash` or `Array` is fine |
| &block         | `Block`                  | defines the scheme of the value of this attribute                                                                  |

#### Add a collection named foo, expecting any key with a defined value
```Ruby
class MyMedia
 include MediaTypes::Dsl

 validations do
   collection :foo do
     any do
       attribute :bar, String
     end
   end
 end
end

MyMedia.valid?({ foo: [{ anything: { bar: 'my-string' }, other_thing: { bar: 'other-string' } }] })
# => true
```` 

### `not_strict`
Allow for extra keys in the schema/collection even when passing `strict: true` to `#validate!`

#### Allow for extra keys in collection

```Ruby
class MyMedia
 include MediaTypes::Dsl

 validations do
   collection :foo do
     attribute :required, String
     not_strict
   end
 end
end

MyMedia.valid?({ foo: [{ required: 'test', bar: 42 }] })
# => true
``` 
  
### `collection`
Expect a collection such as an array or hash. The `&block` defines the Schema for each item in that collection.

| param          | type                          | description                                                                                                          |
| -------------- | ----------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| key            | `Symbol`                      | key of the collection (same as `#attribute`)                                                                         |
| scheme         | `Scheme`, `NilClass`, `Class` | scheme to use if no `&block` is given or `Class` of each item in the collection                                      |
| allow_empty:   | `TrueClass`, `FalseClass`     | if true, empty (no key/value present) is allowed                                                                     |
| expected_type: | `Class`,                      | forces the validated value to have this type, defaults to `Array`. Use `Object` if either `Array` or `Hash` is fine. |
| optional:      | `TrueClass`, `FalseClass`     | if true, key may be absent, defaults to `false`                                                                      |
| &block         | `Block`                       | defines the scheme of the value of this attribute                                                                    |


#### Collection with an array of string
```Ruby
class MyMedia
 include MediaTypes::Dsl

 validations do
   collection :foo, String
 end
end

MyMedia.valid?({ collection: ['foo', 'bar'] })
# => true
```

#### Collection with defined scheme

```Ruby
class MyMedia
 include MediaTypes::Dsl

 validations do
   collection :foo do
     attribute :required, String
     attribute :number, Numeric
   end
 end
end

MyMedia.valid?({ foo: [{ required: 'test', number: 42 }, { required: 'other', number: 0 }] })
# => true
```

### `link`

Expect a link with a required `href: String` attribute

| param      | type                      | description                                                                            |
| ---------- | ------------------------- | -------------------------------------------------------------------------------------- |
| key        | `Symbol`                  | key of the link (same as `#attribute`)                                                 |
| allow_nil: | `TrueClass`, `FalseClass` | if true, value may be nil                                                              |
| optional:  | `TrueClass`, `FalseClass` | if true, key may be absent, defaults to `false`                                        |
| &block     | `Block`                   | defines the scheme of the value of this attribute, in addition to the `href` attribute |

#### Links as defined in HAL, JSON-Links and other specs
```Ruby
class MyMedia
  include MediaTypes::Dsl

  validations do
    link :self
    link :image
  end
end

MyMedia.valid?({ _links: { self: { href: 'https://example.org/s' }, image: { href: 'https://image.org/i' }} })
# => true
```

#### Link with extra attributes
```Ruby
class MyMedia
 include MediaTypes::Dsl

 validations do
   link :image do
     attribute :templated, TrueClass
   end
 end
end

MyMedia.valid?({ _links: { image: { href: 'https://image.org/{md5}', templated: true }} })
# => true
```

## Validation
If your type has a validations, you can now use this media type for validation:

```Ruby
Venue.valid?({
  #...
})
# => true if valid, false otherwise

Venue.validate!({
  # /*...*/ 
})
# => raises if it's not valid
```

If an array is passed, check the scheme for each value, unless the scheme is defined as expecting a hash:
```Ruby
expected_hash = Scheme.new(expected_type: Hash) { attribute(:foo) }
expected_object = Scheme.new { attribute(:foo) } 

expected_hash.valid?({ foo: 'string' })
# => true

expected_hash.valid?([{ foo: 'string' }])
# => false


expected_object.valid?({ foo: 'string' })
# => true

expected_object.valid?([{ foo: 'string' }])
# => true
```

## Formatting for headers
Any media type object can be converted in valid string to be used with `Content-Type` or `Accept`:

```Ruby
Venue.mime_type.identifier
# => "application/vnd.mydomain.venue.v2+json"

Venue.mime_type.version(1).identifier
# => "application/vnd.mydomain.venue.v1+json"

Venue.mime_type.to_s(0.2)
# => "application/vnd.mydomain.venue.v2+json; q=0.2"

Venue.mime_type.collection.identifier
# => "application/vnd.mydomain.venue.v2.collection+json"

Venue.mime_type.view('active').identifier
# => "application/vnd.mydomain.venue.v2.active+json"
```

## API

A defined schema has the following functions available:

### `valid?`

Example: `Venue.valid?({ foo: 'bar' })`

Allows passing in validation options as a second parameter.

### `validate!`

Example: `Venue.validate!({ foo: 'bar' })`

Allows passing in validation options as a second parameter.

### `validatable?`

Example: `Venue.version(42).validatable?`

Tests wether the current configuration of the schema has a validation defined.

### `register`

Example: `Venue.register`

Registers the media type to the registry.

### `view`

Example: `Venue.view('create')`

Returns a schema validator configured with the specified view.

### `version`

Example: `Venue.version(42)`

Returns a schema validator configured with the specified version.

### `suffix`

Example: `Venue.suffix(:json)`

Returns a schema validator configured with the specified suffix.

### `identifier`

Example: `Venue.version(2).identifier` (returns `'application/vnd.application.venue.v2'`)

Returns the IANA compatible [Media Type Identifier](https://en.wikipedia.org/wiki/Media_type) for the configured schema.

### `available_validations`

Example: `Venue.available_validations`

Returns a list of all the schemas that are defined.

## Ensuring Your MediaTypes Work

### Overview & Rational

It is vital that when using this library, your MediaTypes enforce the specification you actually intend them to, as the rules they _do_ enforce will significantly impact code elsewhere in your codebase. To this end, we provide you with a few avenues to check whether MediaTypes enforce the specifications you actually intend by checking examples of JSON you expect to be complient/non-complient with the specifications you design. These are as follows:

1. We provide you with two methods (`assert_pass` and `assert fail`), which enable you to specify JSON fixtures you expect to be complient/non-complient

2. We provide methods to turn those fixtures into tests with the `test_specification` method.

3. We automatically check a MediaType's checks defined by (1) the first time it is validated, and throw an error if any fail.

4. We provide you with a way to run the checks carried out by (3) on load, using the method `assert_sane` so that they can be caught then.

These four options are examined in more detail below:

### Media Type Checking in Test Suites

In the context of your tests, we provide the `test_specification` method,which allows you to run the checks you queue up for a particular `MediaType` within your tests with `assert_pass` and `assert_fail` in a Minitest context. This method is automatically added to the `Minitest::Test`, so If you are already using a Minitest suite, you should gain access to it.

The example below demonstrates how to use `assert_pass` and `assert_fail` within a MediaType, and how to use the `test_specification` method to generate MiniTest tests from them.

```ruby
class MyMedia
  include MediaTypes::Dsl

  def self.organisation
    'acme'
  end

  use_name 'test'

  validations do
    any Numeric

    assert_pass <<-FIXTURE
    { foo: 42, bar: 43 }
    FIXTURE

    assert_pass '{foo: 42}'
    # Any also means none, there are no required keys
    assert_pass '{}'

    # Expects any value to be a Numeric, not a Hash
    assert_fail <<-FIXTURE
    { foo: { bar: "string" } }
    FIXTURE

    # Expects any value to be Numeric, not a Hash
    assert_fail '{foo: {}}'
    # Expects any value to be Numeric, not a NilClass
    assert_fail '{foo: null}'
    # Expects any value to be Numeric, not Array
    assert_fail '{foo: [42]}'
  end
end

class MyMediaTest < Minitest::Test
  test_specification MyMedia
   # This transforms all your calls to `assert_pass` and `assert_fail` into tests
end
```
### Validation Checks

The  `assert_pass` and `assert_fail` methods take a JSON string (as shown below) and store assertions to be carried out later. The first time the `validate!` method is called on a Media Type, the collection of assertions stored (defined by `assert_pass` and `assert_fail`) for that Media Type are executed.

This is done as a last line of defence against introducing faulty MediaTypes into your software. Ideally, you want to carry out these checks on load rather than when your server/project is already up and running, this functionality is provided by the `assert_sane!` method. Which can be called on a particular class

```ruby
  MyMedia.assert_sane!
  # true
```

## Key type validation

Users are provided with the ability to specify the expected type of keys in the media type, by default symbol keys are expected.
This can be set by calling either `expect_symbol_keys` or `expect_string_keys` when defining the MediaType.

```ruby
class MyMedia
  include MediaTypes::Dsl

  def self.organisation
    'acme'
  end

  use_name 'test'
  # Expect keys to be strings
  expect_string_keys

  validations do
    any Numeric

    # Only pass keys as strings
    assert_pass <<-FIXTURE
    { "foo": 42, "bar": 43 }
    FIXTURE

    assert_pass '{"foo": 42}'
    assert_pass '{}'

    # Using symbol keys will result in failed validation
    assert_fail <<-FIXTURE
    { foo: 42, bar: 43 }
    FIXTURE
  end

  assert_sane!
end
```

### Inheriting key type expectations

Key type expectations can also be set at the module level, each MediaType within this module will inherit the expectation set by that module.

```ruby
module Acme
  expect_string_keys

  # The MyMedia class will be expecting string keys, as inherited from the Acme module.
  class MyMedia
    include MediaTypes::Dsl

    def self.organisation
      'acme'
    end

    use_name 'test'

    validations do
      any Numeric
    end
  end

  # This behaviour can be overridden inside the MediaType class
  class MySecondMedia
    include MediaTypes::Dsl

    def self.organisation
      'acme'
    end

    use_name 'test2'
    # Override parent module key type expectation
    expect_symbol_keys

    validations do
      any Numeric
    end
  end
end
```

## Related

- [`MediaTypes::Serialization`](https://github.com/XPBytes/media_types-serialization): :cyclone: Add media types supported serialization to Rails.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, call `bundle exec rake release` to create a new git tag, push git commits and tags, and
push the `.gem` file to rubygems.org.

## Contributing

Bug reports and pull requests are welcome on GitHub at [SleeplessByte/media-types-ruby](https://github.com/SleeplessByte/media-types-ruby)
