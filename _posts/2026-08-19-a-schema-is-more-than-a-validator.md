---
layout: post
title: "A Schema Is More Than a Validator"
date: 2026-08-19
published: false
author: Clemens Vasters
image: /social-cards/a-schema-is-more-than-a-validator.png
description: >-
  JSON Structure defines the data model behind a JSON document, so the same
  Customer contract can drive validation, code, storage, and interchange.
---

A validator can accept a customer record and still leave a code generator
guessing. Is the identifier a UUID? Is the credit limit a decimal? Does the
timestamp carry an offset? JSON Structure answers those questions in the schema
because its declared types describe the data, with validation following from
that description.

## Start with the type

Consider that customer record. A validator needs to reject a malformed
identifier, an absent name, or an unexpected property. The code generator needs
answers it can map directly into code.

Here is a complete JSON Structure schema document that answers those questions:

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://example.com/schemas/customer",
  "name": "Customer",
  "type": "object",
  "properties": {
    "customerId": {
      "type": "uuid",
      "description": "Stable customer identifier"
    },
    "displayName": {
      "type": "string",
      "maxLength": 200
    },
    "creditLimit": {
      "type": "decimal",
      "precision": 12,
      "scale": 2
    },
    "registeredAt": {
      "type": "datetime"
    },
    "marketingOptIn": {
      "type": "boolean"
    }
  },
  "required": [
    "customerId",
    "displayName",
    "registeredAt",
    "marketingOptIn"
  ],
  "additionalProperties": false
}
```

A matching instance looks ordinary because JSON remains the interchange
encoding:

```json
{
  "customerId": "2d30c42f-6f3a-4c6a-9ef6-721d5fa2b35d",
  "displayName": "Northwind Traders",
  "creditLimit": "25000.00",
  "registeredAt": "2026-08-18T14:30:00Z",
  "marketingOptIn": false
}
```

The quoted credit limit is deliberate. `decimal` is a base-10 type represented
by a JSON string, preserving a value that should not silently become an IEEE 754
binary floating-point approximation. Likewise, `datetime` means RFC 3339 date
and time with an offset. Those are type semantics, not naming conventions.

## Validation describes a set

JSON Schema is exceptionally good at describing sets of acceptable JSON
instances. Its vocabulary combines assertions such as `required`,
`additionalProperties`, and numeric bounds with applicators such as `allOf`,
`anyOf`, and conditional subschemas. That model supports sophisticated
validation precisely because schemas can be composed as constraints.

The same flexibility leaves data-definition tools with interpretation work. A
JSON Schema `integer` denotes a JSON number with no fractional part; it does not
select a storage width. A `string` with `format: "uuid"` carries useful semantic
information, but format handling depends on the selected vocabulary and
implementation configuration. Code generators therefore need conventions and
policies beyond the validation result.

JSON Structure takes the other route. Every schema element declares `type`, and
the core specification owns a fixed vocabulary of primitive, extended, and
compound types. `int32`, `uint64`, `decimal`, `uuid`, `datetime`, `map`, and
`set` are type declarations. A consumer does not infer them from a combination
of assertions.

JSON Structure deliberately has the narrower model. Some of JSON Schema's
open-ended constraint composition gives way to a deterministic type graph for
programming languages, database columns, and serialization APIs.

## Structure is explicit

An `object` lists its known `properties`. A `map` models dynamic keys whose
values share a type. An `array` preserves order and permits duplicates; a `set`
does not. Reusable compound types live under `definitions` and are referenced
through a `type` containing `$ref`.

The difference appears after validation. Two documents may have the same JSON
object shape while representing different programming constructs. A declared
map maps to a map; tooling need not deduce one from an `additionalProperties`
rule.

Requiredness is similarly direct. In the Customer schema, four properties must
appear. `creditLimit` may be absent, but when present it is always a `decimal`.
Optional does not mean untyped, and nullability is separate: a property that may
also be `null` declares a type union such as `["string", "null"]`.

## One declaration, several consumers

A validator checks the object shape, required properties, UUID syntax, timestamp
syntax, decimal representation, precision, scale, and unknown properties. Other
consumers read the same declaration without reverse-engineering conventions:

- A generator can choose a UUID type instead of a generic string.
- A database tool can provision a decimal column with known precision and scale.
- An API binding can require an offset-aware timestamp.
- Documentation can explain the contract using the schema's own vocabulary.

JSON Structure does not try to outgrow JSON Schema's validation model with a
larger collection of validation keywords. It defines a data model whose
instances happen to be JSON. Validation is one consequence of that model.
