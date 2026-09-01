---
layout: post
title: "Structure First, Validation Second"
date: 2026-10-12
published: false
author: Clemens Vasters
specification_scope: Core with the Validation companion specification.
image: /social-cards/structure-first-validation-second.png
description: >-
  Separate stable structural and generative facts from validation policies
  that constrain otherwise well-shaped data.
---

[`int32`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#int32) defines a signed 32-bit value represented as a JSON number.
[`minimum: 0`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#minimum) rejects the negative part of that value space for one application. A
generator needs the type fact to choose a target type; range enforcement is a
separate job.

JSON Structure keeps the foundation structural and makes validation a
companion vocabulary. That boundary is useful for validators, but it matters
just as much to code generators, serializers, database mappers, and interface
description tools.

## Structure determines the shape

Core describes facts needed to construct and exchange a value:

- [`type`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#type-keyword): [`int32`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#int32) selects a signed 32-bit integer represented as a JSON number.
- [`type`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#type-keyword): [`object`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#object) and [`properties`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#properties-keyword) define named members and their types.
- [`required`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#required-keyword) distinguishes members that must be present from members that may
  be absent.
- [`additionalProperties: false`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#additionalproperties-keyword) closes the declared object shape.

Those declarations support generation. A tool can produce a class, record, or
table layout from them. They also perform structural validation: a string in an
[`int32`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#int32) property is not the declared representation.

The following complete schema adds the validation companion for policy:

```json
{
  "$schema": "https://json-structure.org/meta/validation/v0/#",
  "$id": "https://example.com/schemas/warehouse-bin",
  "name": "WarehouseBinSchema",
  "$uses": ["JSONStructureValidation"],
  "$root": "#/definitions/WarehouseBin",
  "definitions": {
    "WarehouseBin": {
      "name": "WarehouseBin",
      "type": "object",
      "properties": {
        "binCode": {
          "type": "string",
          "pattern": "^[A-Z]{2}-[0-9]{3}$"
        },
        "itemCount": {
          "type": "int32",
          "minimum": 0,
          "maximum": 5000
        }
      },
      "required": ["binCode", "itemCount"],
      "additionalProperties": false
    }
  }
}
```

This instance satisfies both layers:

```json
{
  "$schema": "https://example.com/schemas/warehouse-bin",
  "binCode": "NW-042",
  "itemCount": 275
}
```

## Validation narrows valid values

The object declaration, its properties, [`required`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#required-keyword), and [`int32`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#int32) remain true if
the warehouse later raises capacity from 5,000 to 8,000. They describe the data
model.

The range and pattern encode local acceptance policy. [`minimum`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#minimum) prevents a
negative count, [`maximum`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#maximum) captures the current operational capacity, and
[`pattern`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#pattern) imposes the warehouse's bin-label convention.

Changing one of those policies need not change the generated integer type or
object layout. A policy-aware validator must enforce them, while a core-aware
generator can still understand the shape without implementing regular
expressions or every constraint vocabulary.

Core still rejects structurally incompatible values. An [`int32`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#int32) outside its
defined range is not an [`int32`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#int32); an object missing a required property does not
have the declared shape. Companion validation restricts values that already
satisfy those structural rules.

For example, `"itemCount": 12.5` violates the structural integer contract.
`"itemCount": 6000` is structurally a valid [`int32`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#int32) but violates warehouse
policy. This distinction lets a tool report whether the value has the wrong
representation or falls outside an application rule.

## The companion must be declared

The validation keywords are not harmless annotations. A schema using
[`minimum`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#minimum), [`maximum`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#maximum), or [`pattern`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#pattern) needs a meta-schema contract that admits and
defines them. The published validation meta-schema composes the extended
feature offers and selects [`JSONStructureValidation`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#enabling-the-extensions).

That explicit dependency prevents a core-only processor from silently ignoring
policy and reporting a false success. It may decline the vocabulary, or another
processor may enforce it, but the schema has stated the requirement.

Policy can be every bit as important as representation, but the two change for
different reasons. Put the facts needed to represent the document in core. Put
the warehouse's current acceptance rules in the validation companion. Then a
capacity change remains a policy edit and does not require a new integer type.

[validation]: https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html
