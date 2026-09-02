---
layout: post
title: "Inline Unions Need Explicit Discriminators"
date: 2026-09-11
published: false
author: Clemens Vasters
specification_scope: Core only.
image: /social-cards/inline-unions-and-explicit-discriminators.png
description: >-
  Model several concrete object variants that share an abstract base through
  $extends and use an explicit selector.
---

Consider an address object with `city`, `state`, and `zip`. It may also carry a
street, or it may carry a post office box number. Those optional properties do
not state which variant the producer selected. An object can contain both
properties, and a future variant may overlap with either existing shape.

An inline [`choice`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#choice) puts the decision in the data. Its variants share an
abstract base, and a string property in the object names the selected variant.
The address remains one flat JSON object; no wrapper is added.

## The wire shape

A [`choice`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#choice) is JSON Structure's discriminated union type. Its [`choices`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#choices-keyword) map
associates selector values with types. In the tagged form, a property wraps the
selected value. In the inline form used here, the selected object's members
remain in place and the selector sits beside them.

For addresses, that means an instance looks like this:

```json
{
  "addressType": "StreetAddress",
  "street": "123 Main St",
  "city": "Seattle",
  "state": "WA",
  "zip": "98101"
}
```

There is no `{ "StreetAddress": { ... } }` wrapper. `addressType` has the value
`StreetAddress`, so a processor uses that entry from [`choices`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#choices-keyword).

## The complete schema

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://schemas.example.com/address.json",
  "name": "AddressChoice",
  "type": "choice",
  "$extends": "#/definitions/Address",
  "selector": "addressType",
  "choices": {
    "StreetAddress": {
      "type": { "$ref": "#/definitions/StreetAddress" }
    },
    "PostOfficeBoxAddress": {
      "type": { "$ref": "#/definitions/PostOfficeBoxAddress" }
    }
  },
  "definitions": {
    "Address": {
      "abstract": true,
      "type": "object",
      "properties": {
        "city": { "type": "string" },
        "state": { "type": "string" },
        "zip": { "type": "string" }
      }
    },
    "StreetAddress": {
      "type": "object",
      "$extends": "#/definitions/Address",
      "properties": {
        "street": { "type": "string" }
      }
    },
    "PostOfficeBoxAddress": {
      "type": "object",
      "$extends": "#/definitions/Address",
      "properties": {
        "poBox": { "type": "string" }
      }
    }
  }
}
```

[`$extends`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#extends-keyword) appears in two roles here. On `StreetAddress` and
`PostOfficeBoxAddress`, it merges the properties of `Address` into each
concrete definition. `StreetAddress` therefore has `city`, `state`, `zip`, and
`street`; an extending type may not redefine an inherited property.

On the [`choice`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#choice), [`$extends`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#extends-keyword) identifies the common base required for the inline
representation. That base must be abstract, and every selected type must extend
it. `Address` can supply reusable properties, but it cannot itself be used as a
property type or referenced through [`$ref`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#ref-keyword).

## Selection is declared, not inferred

The [`selector`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#selector-keyword) keyword names the injected string property. Its value must match
a key in [`choices`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#choices-keyword) exactly. In this schema, the only selector values are
`StreetAddress` and `PostOfficeBoxAddress`.

Suppose an object contains `city`, `state`, `zip`, `street`, and `poBox`.
Property inspection cannot tell you which variant the producer meant. The
selector names the branch to validate, so the processor does not rank the two
shapes.

The selector may shadow a property from the base, but only when that inherited
property is a [`string`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#string). Do not declare it in the base unless the base itself needs
that string property; the inline choice injects the selector.

Choice names and selector values are case-sensitive. `streetAddress` does not
select `StreetAddress`.

## No subtype assignment

[`$extends`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#extends-keyword) supports property reuse, but JSON Structure deliberately does not
turn the base into a polymorphic assignment target. You cannot declare a
property as `Address` and then place either concrete subtype there. An abstract
type cannot be referenced through [`$ref`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#ref-keyword) at all.

Use the [`choice`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#choice) as the property's type when a property may hold either address:

```json
{
  "type": "object",
  "properties": {
    "shippingAddress": {
      "type": { "$ref": "#/definitions/AddressChoice" }
    }
  }
}
```

Here `AddressChoice` would be a reusable [`choice`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#choice) under [`definitions`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#definitions-keyword), using the
same construction as the root example above.

The base records shared members. The [`choice`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#choice) records which concrete values may
occur and how an instance selects one. Keep those jobs separate: declaring a
base does not introduce subtype assignment elsewhere in the model.
