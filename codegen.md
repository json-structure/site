---
layout: sdk
title: Code Generation & Schema Conversions - JSON Structure
sdk_name: codegen
---

# <img src="/media/logo.svg" alt="" class="inline-logo">Code Generation & Schema Conversions

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
# Convert JSON Structure to Protocol Buffers
structurize s2p schema.struct.json --out ./proto/

# Convert JSON Structure to XML Schema (XSD)
structurize s2x schema.struct.json --out schema.xsd

# Convert JSON Structure to GraphQL
structurize struct2gql schema.struct.json --out schema.graphql

# Convert JSON Structure to Kusto table definition
structurize s2k schema.struct.json --out schema.kql

# Convert JSON Structure to SQL table definition
structurize struct2sql schema.struct.json --out schema.sql --dialect postgres

# Convert JSON Structure to Iceberg schema
structurize s2ib schema.struct.json --out schema.iceberg.json
```

## Code Generation

Structurize/Avrotize can generate code in multiple languages directly from JSON Structure schemas:

```bash
# Generate C# classes
structurize s2cs schema.struct.json --out ./generated/

# Generate Java classes
structurize s2java schema.struct.json --out ./generated/

# Generate Python dataclasses
structurize s2py schema.struct.json --out ./generated/

# Generate TypeScript classes
structurize s2ts schema.struct.json --out ./generated/

# Generate Go structs
structurize s2go schema.struct.json --out ./generated/

# Generate Rust structs
structurize s2rust schema.struct.json --out ./generated/

# Generate C++ classes
structurize s2cpp schema.struct.json --out ./generated/
```

## Additional Conversions

```bash
# Convert JSON Structure to Markdown documentation
structurize struct2md schema.struct.json --out schema.md

# Convert JSON Structure to CSV schema
structurize s2csv schema.struct.json --out schema.csv

# Convert JSON Structure to Datapackage schema
structurize s2dp schema.struct.json --out datapackage.json

# Convert JSON Structure to Cassandra schema
structurize struct2cassandra schema.struct.json --out schema.cql
```

## Supported Conversions

| Source Format | Target Format | Command | Example |
|--------------|---------------|---------|---------|
| JSON Structure | Protocol Buffers | `s2p` | [View →](https://clemensv.github.io/avrotize/gallery/struct-to-proto/) |
| JSON Structure | XML Schema (XSD) | `s2x` | [View →](https://clemensv.github.io/avrotize/gallery/struct-to-xsd/) |
| JSON Structure | JSON Schema | `s2j` | [View →](https://clemensv.github.io/avrotize/gallery/struct-to-jsonschema/) |
| JSON Structure | GraphQL | `struct2gql` | [View →](https://clemensv.github.io/avrotize/gallery/struct-to-graphql/) |
| JSON Structure | SQL (PostgreSQL) | `struct2sql` | [View →](https://clemensv.github.io/avrotize/gallery/struct-to-sql/) |
| JSON Structure | Iceberg | `s2ib` | [View →](https://clemensv.github.io/avrotize/gallery/struct-to-iceberg/) |
| JSON Structure | Cassandra | `struct2cassandra` | [View →](https://clemensv.github.io/avrotize/gallery/struct-to-cassandra/) |
| JSON Structure | Markdown | `struct2md` | [View →](https://clemensv.github.io/avrotize/gallery/struct-to-markdown/) |
| JSON Structure | CSV Schema | `s2csv` | [View →](https://clemensv.github.io/avrotize/gallery/struct-to-csv/) |
| JSON Structure | Datapackage | `s2dp` | [View →](https://clemensv.github.io/avrotize/gallery/struct-to-datapackage/) |

## Code Generation Commands

| Target Language | Command | Example |
|-----------------|---------|---------|
| C# | `s2cs` | [View →](https://clemensv.github.io/avrotize/gallery/struct-to-csharp/) |
| Java | `s2java` | [View →](https://clemensv.github.io/avrotize/gallery/struct-to-java/) |
| Python | `s2py` | [View →](https://clemensv.github.io/avrotize/gallery/struct-to-python/) |
| TypeScript | `s2ts` | — |
| Go | `s2go` | [View →](https://clemensv.github.io/avrotize/gallery/struct-to-go/) |
| Rust | `s2rust` | [View →](https://clemensv.github.io/avrotize/gallery/struct-to-rust/) |
| C++ | `s2cpp` | [View →](https://clemensv.github.io/avrotize/gallery/struct-to-cpp/) |

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
