---
layout: default
title: Ruby SDK
---

# Ruby SDK

The official JSON Structure SDK for Ruby.

## Installation

```bash
gem install jsonstructure
```

Or add to `Gemfile`:

```ruby
gem 'jsonstructure'
```

## Package Links

- **RubyGems**: [jsonstructure](https://rubygems.org/gems/jsonstructure)
- **GitHub**: [json-structure/sdk/ruby](https://github.com/json-structure/sdk/tree/master/ruby)

## Usage

```ruby
require 'jsonstructure'

# Validate a schema
schema_validator = JsonStructure::SchemaValidator.new
schema_result = schema_validator.validate(schema)

# Validate an instance against a schema
instance_validator = JsonStructure::InstanceValidator.new
instance_result = instance_validator.validate(instance, schema)
```

## Features

- Schema validation against JSON Structure meta-schemas
- Instance validation against JSON Structure schemas
- Ruby 2.7+ support
- Pure Ruby implementation
- No external dependencies

## Documentation

See the [README](https://github.com/json-structure/sdk/tree/master/ruby#readme) for full documentation.
