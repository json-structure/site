---
layout: default
title: PHP SDK
---

# PHP SDK

The official JSON Structure SDK for PHP.

## Installation

```bash
composer require json-structure/sdk
```

## Package Links

- **Packagist**: [json-structure/sdk](https://packagist.org/packages/json-structure/sdk)
- **GitHub**: [json-structure/sdk/php](https://github.com/json-structure/sdk/tree/master/php)

## Usage

```php
<?php

use JsonStructure\SchemaValidator;
use JsonStructure\InstanceValidator;

// Validate a schema
$schemaValidator = new SchemaValidator();
$schemaResult = $schemaValidator->validate($schema);

// Validate an instance against a schema
$instanceValidator = new InstanceValidator();
$instanceResult = $instanceValidator->validate($instance, $schema);
```

## Features

- Schema validation against JSON Structure meta-schemas
- Instance validation against JSON Structure schemas
- PHP 8.0+ support
- PSR-4 autoloading
- No external dependencies

## Documentation

See the [README](https://github.com/json-structure/sdk/tree/master/php#readme) for full documentation.
