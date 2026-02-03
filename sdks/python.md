---
layout: default
title: Python SDK
---

# <img src="/media/logo.svg" alt="" class="inline-logo">Python SDK

The official JSON Structure SDK for Python.

## Installation

```bash
pip install json-structure
```

## Package Links

- **PyPI**: [json-structure](https://pypi.org/project/json-structure/)
- **GitHub**: [json-structure/sdk/python](https://github.com/json-structure/sdk/tree/master/python)

## Usage

```python
from json_structure import SchemaValidator, InstanceValidator

# Validate a schema
schema_validator = SchemaValidator()
schema_result = schema_validator.validate(schema)

# Validate an instance against a schema
instance_validator = InstanceValidator()
instance_result = instance_validator.validate(instance, schema)
```

## Features

- Schema validation against JSON Structure meta-schemas
- Instance validation against JSON Structure schemas
- Python 3.8+ support
- Type hints included
- Minimal dependencies

## Documentation

See the [README](https://github.com/json-structure/sdk/tree/master/python#readme) for full documentation.
