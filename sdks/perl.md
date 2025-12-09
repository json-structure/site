---
layout: default
title: Perl SDK
---

# Perl SDK

The official JSON Structure SDK for Perl.

## Installation

```bash
cpanm JSON::Structure
```

## Package Links

- **CPAN**: [JSON::Structure](https://metacpan.org/pod/JSON::Structure)
- **GitHub**: [json-structure/sdk/perl](https://github.com/json-structure/sdk/tree/master/perl)

## Usage

```perl
use JSON::Structure;

# Validate a schema
my $schema_validator = JSON::Structure::SchemaValidator->new();
my $schema_result = $schema_validator->validate($schema);

# Validate an instance against a schema
my $instance_validator = JSON::Structure::InstanceValidator->new();
my $instance_result = $instance_validator->validate($instance, $schema);
```

## Features

- Schema validation against JSON Structure meta-schemas
- Instance validation against JSON Structure schemas
- Perl 5.20+ support
- Works with JSON::PP or Cpanel::JSON::XS
- Pure Perl implementation

## Documentation

See the [README](https://github.com/json-structure/sdk/tree/master/perl#readme) for full documentation.
