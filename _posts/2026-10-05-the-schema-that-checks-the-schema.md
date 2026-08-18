---
layout: post
title: "The Schema That Checks the Schema"
date: 2026-10-05
published: false
author: Clemens Vasters
image: /social-cards/the-schema-that-checks-the-schema.png
description: >-
  Use JSON Structure meta-schemas to reject malformed schema documents before
  they can misdescribe any data.
---

A misspelled schema keyword is worse than a misspelled property in an instance.
If a processor overlooks it, every document checked afterward may receive the
wrong verdict.

JSON Structure can catch that error before the schema reaches application data.
A schema document is itself an instance, checked by a meta-schema. Its root
`$schema` identifies the language it claims to use, and a processor can test
that claim before generating code or validating a business document.

## Follow `$schema` up one layer

In a schema document, `$schema` identifies a meta-schema. In an application
instance, `$schema` identifies the application schema. The keyword stays at the
document root in both cases, but the referenced document plays a different
role.

This complete schema uses only the core vocabulary:

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://example.com/schemas/device-reading",
  "name": "DeviceReadingSchema",
  "$root": "#/definitions/DeviceReading",
  "definitions": {
    "DeviceReading": {
      "name": "DeviceReading",
      "type": "object",
      "properties": {
        "deviceId": { "type": "string" },
        "sequence": { "type": "uint32" },
        "online": { "type": "boolean" }
      },
      "required": ["deviceId", "sequence", "online"],
      "additionalProperties": false
    }
  }
}
```

The core meta-schema checks the document above as an instance. It knows that
`properties` must be a map, `required` must be an array of property names, and
`additionalProperties` must have the form allowed on an object type. It also
knows which type names belong to core.

An application instance then points at the schema one level down:

```json
{
  "$schema": "https://example.com/schemas/device-reading",
  "deviceId": "pump-17",
  "sequence": 42,
  "online": true
}
```

Resolving `$schema` does not import the referenced document's definitions into
the current namespace. It selects the contract against which the current
document is interpreted and checked.

## Core does not admit every keyword

The core meta-schema at `https://json-structure.org/meta/core/v0/#` defines the
base schema language: document structure, primitive and compound types,
references, definitions, extension machinery, and the structural constraints
attached to those constructs.

The extended meta-schema imports core and advertises named feature bundles for
alternate names, units, import, conditional composition, and validation. A
schema that needs one of those vocabularies references an appropriate
meta-schema. Where that meta-schema exposes optional add-ins, the schema selects
the relevant names through root-level `$uses`.

This separation means that `minimum` is not silently accepted by a core-only
processor. The schema must enter a vocabulary contract that defines it.

## Bad schemas fail before bad instances

Here is a deliberately invalid schema fragment. It is valid JSON, but not a
valid JSON Structure object type:

```json
{
  "type": "object",
  "properties": [
    { "deviceId": { "type": "string" } }
  ]
}
```

`properties` must be a map from property names to property declarations. An
array does not become acceptable because its contents look plausible. The
meta-schema rejects the fragment at the schema layer.

Without meta-validation, a tool might ignore the malformed `properties`, infer
an empty object, or fail later with a tool-specific error. Meta-validation gives
one useful answer immediately: this schema document violates its declared
language.

It cannot prove that the author modeled the business correctly. No meta-schema
can tell us whether `pump-17` ought to be a device reading. It can stop us from
asking that question of a malformed schema, which is the cheaper failure by far.

[core]: https://json-structure.github.io/core/draft-vasters-json-structure-core.html
