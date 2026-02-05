---
layout: post
title: "Inferring JSON Structure Schemas from Your Data with Structurize"
date: 2026-02-04
author: Clemens Vasters
---

If you have JSON data and need a schema for it, the new `json2s` command in
**Structurize** can help. It analyzes your JSON files, figures out what types
you're working with, and produces a valid JSON Structure schema document — one
that you can use for validation, code generation, or documentation.

## What is Structurize?

[Structurize](https://avrotize.com) is a schema conversion
toolkit that transforms between various schema formats: JSON Schema, JSON
Structure, Avro Schema, Protocol Buffers, XSD, and more. It also generates code
in multiple languages (C#, Python, TypeScript, Java, Go, Rust, C++) and exports
schemas to SQL databases and data formats like Parquet and Iceberg.

The tool ships under two package names — `structurize` and `avrotize` — both
sharing the same codebase. Choose whichever aligns with your primary use case.
JSON Structure users will likely prefer `structurize`.

Install it with:

```bash
pip install structurize
```

## The json2s Command: Schema Inference from JSON

The `json2s` command reads one or more JSON files and infers a JSON Structure
schema from them. It handles single JSON objects, JSON arrays, and JSONL
(newline-delimited JSON) files.

### Basic Usage

```bash
structurize json2s data.json --out schema.jstruct.json --type-name MyType
```

Parameters:

- `<json_files...>` — One or more JSON files to analyze
- `--out` — Output path for the JSON Structure schema (stdout if omitted)
- `--type-name` — Name for the root type (default: "Document")
- `--base-id` — Base URI for `$id` generation (default: "https://example.com/")
- `--sample-size` — Maximum records to sample (0 = all, default: 0)
- `--infer-choices` — Detect discriminated unions (more on this below)

### Multiple Files and JSONL

The command accepts multiple input files, merging their structures into a
unified schema. This is useful when your data is split across files or when
you want to analyze several examples together.

JSONL files (one JSON object per line) are first-class citizens. The inferrer
reads each line as a separate document and consolidates their structures.

```bash
# Multiple JSON files
structurize json2s orders.json users.json events.json --out unified.jstruct.json

# A JSONL file with many records
structurize json2s events.jsonl --out events.jstruct.json --type-name DomainEvent
```

## Detecting Discriminated Unions with `--infer-choices`

Here's where things get interesting. Many event-driven systems, APIs, and
message formats use **discriminated unions**: a single field (often called
`type`, `kind`, or `event_type`) determines which variant of a structure you're
dealing with.

Consider this JSONL file with three event types:

```jsonl
{"event_type": "user_created", "user_id": "u123", "email": "alice@example.com", "created_at": "2026-02-04T10:00:00Z"}
{"event_type": "user_created", "user_id": "u456", "email": "bob@example.com", "created_at": "2026-02-04T11:00:00Z"}
{"event_type": "order_placed", "order_id": "ord-001", "user_id": "u123", "total": 99.50, "items": [{"sku": "A1", "qty": 2}]}
{"event_type": "order_placed", "order_id": "ord-002", "user_id": "u456", "total": 150.00, "items": [{"sku": "B2", "qty": 1}]}
{"event_type": "payment_received", "payment_id": "pay-001", "order_id": "ord-001", "amount": 99.50, "method": "card"}
{"event_type": "payment_received", "payment_id": "pay-002", "order_id": "ord-002", "amount": 150.00, "method": "paypal"}
```

### Without `--infer-choices`: A Flat Object

Running the basic inference:

```bash
structurize json2s events.jsonl --out events.jstruct.json --type-name DomainEvent
```

Produces a single object type with all fields merged:

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://example.com/DomainEvent",
  "type": "object",
  "name": "DomainEvent",
  "properties": {
    "event_type": { "type": "string" },
    "user_id": { "type": "string" },
    "email": { "type": "string" },
    "created_at": { "type": "string" },
    "order_id": { "type": "string" },
    "total": { "type": "double" },
    "items": { "type": "array", "items": { ... } },
    "payment_id": { "type": "string" },
    "amount": { "type": "double" },
    "method": { "type": "string" }
  },
  "required": ["event_type"]
}
```

This works, but it loses the structure: `email` only makes sense for
`user_created` events, `items` only for `order_placed`, and so on. All fields
become optional except `event_type`, which is the only one present in every
record.

### With `--infer-choices`: An Inline Union

Add the `--infer-choices` flag:

```bash
structurize json2s events.jsonl --infer-choices --out events.jstruct.json --type-name DomainEvent
```

Now the inferrer detects that `event_type` is a **discriminator** whose values
correlate with distinct field signatures. It produces a JSON Structure
`choice` type — an inline union:

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://example.com/schemas/DomainEvent",
  "type": "choice",
  "name": "DomainEvent",
  "$extends": "#/definitions/DomainEventBase",
  "selector": "event_type",
  "choices": {
    "order_placed": { "type": { "$ref": "#/definitions/OrderPlaced" } },
    "payment_received": { "type": { "$ref": "#/definitions/PaymentReceived" } },
    "user_created": { "type": { "$ref": "#/definitions/UserCreated" } }
  },
  "definitions": {
    "DomainEventBase": {
      "abstract": true,
      "type": "object",
      "name": "DomainEventBase",
      "properties": {
        "event_type": { "type": "string" }
      }
    },
    "OrderPlaced": {
      "type": "object",
      "name": "OrderPlaced",
      "$extends": "#/definitions/DomainEventBase",
      "properties": {
        "items": { "type": "array", "items": { ... } },
        "order_id": { "type": "string" },
        "total": { "type": "double" },
        "user_id": { "type": "string" }
      },
      "required": ["items", "order_id", "total", "user_id"]
    },
    "PaymentReceived": {
      "type": "object",
      "name": "PaymentReceived",
      "$extends": "#/definitions/DomainEventBase",
      "properties": {
        "amount": { "type": "double" },
        "method": { "type": "string" },
        "order_id": { "type": "string" },
        "payment_id": { "type": "string" }
      },
      "required": ["amount", "method", "order_id", "payment_id"]
    },
    "UserCreated": {
      "type": "object",
      "name": "UserCreated",
      "$extends": "#/definitions/DomainEventBase",
      "properties": {
        "created_at": { "type": "string" },
        "email": { "type": "string" },
        "user_id": { "type": "string" }
      },
      "required": ["created_at", "email", "user_id"]
    }
  }
}
```

This is a proper inline union:

- **`selector`** points to the discriminator field (`event_type`)
- **`choices`** maps each discriminator value to a variant type
- **`$extends`** references an abstract base type with common fields
- Each variant extends the base and adds its specific fields

The choice keys (`order_placed`, `payment_received`, `user_created`) match the
actual values in the data, so instances validate correctly.

### Validating the Result

Using the [json-structure Python SDK](https://pypi.org/project/json-structure/),
we can verify that both the schema and the original instances are valid:

```python
import json
from json_structure import SchemaValidator, InstanceValidator

with open('events_schema.jstruct.json') as f:
    schema = json.load(f)

# Validate the schema itself
sv = SchemaValidator(extended=True)
errors = sv.validate(schema)
print('Schema valid:', len(errors) == 0)

# Validate each instance
iv = InstanceValidator(schema, extended=True)
with open('events.jsonl') as f:
    for line in f:
        if line.strip():
            instance = json.loads(line)
            errors = iv.validate(instance)
            print(f"{instance['event_type']}: {'valid' if not errors else errors}")
```

Output:

```
Schema valid: True
user_created: valid
user_created: valid
order_placed: valid
order_placed: valid
payment_received: valid
payment_received: valid
```

All six instances validate against the inferred schema.

## How the Algorithm Works

The `--infer-choices` option uses a clustering algorithm:

1. **Document Fingerprinting**: Each JSON object is characterized by its field
   signature — the set of top-level keys it contains.

2. **Jaccard Similarity Clustering**: Documents with similar field signatures
   are grouped together. A two-pass refinement handles edge cases.

3. **Discriminator Detection**: The algorithm looks for fields whose values
   correlate strongly with cluster membership. A field like `event_type` that
   has distinct values for each cluster is a strong discriminator candidate.

4. **Sparse Data Filtering**: If documents have high overlap (same basic
   structure with some optional fields), they're treated as a single type with
   optional properties rather than distinct variants.

5. **Nested Discriminators**: The algorithm can detect discriminators inside
   nested objects (up to 2 levels deep), handling envelope patterns like
   CloudEvents with typed payloads.

The result is a schema that captures the polymorphic structure of your data
rather than flattening everything into a single bag of optional fields.

## Use Cases

- **Event Sourcing**: Infer schemas from event logs with multiple event types
- **API Documentation**: Generate schemas from sample API responses
- **Message Queues**: Document Kafka/RabbitMQ message formats
- **Data Lake Schemas**: Create schemas for semi-structured data in Parquet or Iceberg
- **Code Generation**: Feed the schema into structurize's code generators to produce typed classes

## Getting Started

Install structurize:

```bash
pip install structurize
```

Point it at your data:

```bash
structurize json2s your-data.jsonl --infer-choices --out schema.jstruct.json --type-name YourType
```

Validate the result with the json-structure SDK, or use structurize to convert
the schema to code, documentation, or other formats.

---

The `json2s` command with `--infer-choices` bridges the gap between the JSON
data you have and the structured schema you need. It understands that your
data isn't just a blob of fields — it's a collection of distinct types
with a common discriminator. And it produces schemas that reflect that structure.

