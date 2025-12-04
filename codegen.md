---
layout: sdk
title: Code Generation & Schema Conversions - JSON Structure
sdk_name: codegen
---

# Code Generation & Schema Conversions

JSON Structure schemas can be used with [Avrotize](https://github.com/clemensv/avrotize) (via its `structurize` alias) to generate code and convert between schema formats.

## Structurize

**Structurize** is the JSON Structure-focused interface to Avrotize. It provides commands for:

- Converting JSON Structure schemas to other formats (Avro, JSON Schema, Protobuf, etc.)
- Converting other schema formats to JSON Structure
- Generating code from JSON Structure schemas

### Installation

```bash
pip install avrotize
```

Or use the `structurize` alias package:

```bash
pip install structurize
```

### Quick Start

Convert a JSON Structure schema to other formats:

```bash
# Convert JSON Structure to Avro Schema
structurize jsons2a --input schema.json --output schema.avsc

# Convert JSON Structure to JSON Schema
structurize jsons2js --input schema.json --output schema.jsonschema

# Convert JSON Structure to Protocol Buffers
structurize jsons2p --input schema.json --output schema.proto
```

Convert from other formats to JSON Structure:

```bash
# Convert Avro Schema to JSON Structure
structurize a2jsons --input schema.avsc --output schema.json

# Convert JSON Schema to JSON Structure
structurize js2jsons --input schema.jsonschema --output schema.json

# Convert Protocol Buffers to JSON Structure
structurize p2jsons --input schema.proto --output schema.json
```

## Supported Conversions

| Source Format | Target Format | Command |
|--------------|---------------|---------|
| JSON Structure | Avro | `jsons2a` |
| JSON Structure | JSON Schema | `jsons2js` |
| JSON Structure | Protocol Buffers | `jsons2p` |
| JSON Structure | Parquet | `jsons2pq` |
| Avro | JSON Structure | `a2jsons` |
| JSON Schema | JSON Structure | `js2jsons` |
| Protocol Buffers | JSON Structure | `p2jsons` |

## Code Generation

Avrotize/Structurize can generate code in multiple languages from JSON Structure schemas:

```bash
# Generate Python dataclasses
structurize jsons2py --input schema.json --output ./generated

# Generate C# classes
structurize jsons2cs --input schema.json --output ./generated

# Generate Java classes
structurize jsons2java --input schema.json --output ./generated

# Generate TypeScript interfaces
structurize jsons2ts --input schema.json --output ./generated
```

## Schema Gallery

Browse example schemas and see conversions in action at the **[Avrotize Schema Gallery](https://clemensv.github.io/avrotize/gallery/)**.

The gallery showcases:

- Real-world schema examples
- Side-by-side format comparisons
- Generated code samples
- Interactive schema exploration

## Resources

- [Avrotize GitHub Repository](https://github.com/clemensv/avrotize)
- [Structurize Package](https://github.com/clemensv/avrotize/tree/master/structurize)
- [Schema Gallery](https://clemensv.github.io/avrotize/gallery/)
- [PyPI Package](https://pypi.org/project/avrotize/)
