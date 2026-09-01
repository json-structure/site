---
layout: post
title: "Why Union Order Matters"
date: 2026-09-14
published: false
author: Clemens Vasters
specification_scope: Core only.
image: /social-cards/why-union-order-matters.png
description: >-
  Non-discriminated unions use first-match semantics, so branch order is part
  of the type contract rather than a cosmetic choice.
---

For a non-discriminated union, the processor tries each branch in array order.
The first match supplies the value's type identity. There is no later contest
to find a more specific candidate.

Move a branch and you may change the meaning of JSON that remains valid before
and after the edit. Array order is part of this contract.

## First match, not best match

A JSON Structure union is the array form of [`type`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#type-keyword):

```json
{
  "type": ["string", "int32"]
}
```

The value must conform to at least one member. When it conforms to several, it
is considered to have the type of the first matching member. There is no
"narrowest," "most specific," or "best" branch calculation after the fact.

Primitive branches often have non-overlapping validation rules. Object types
overlap more easily: they may share required properties, and they may permit additional
ones. If one object fits both branches, their order decides its interpreted
type.

## An overlap you can see

A non-discriminated union may contain primitive types and type references. It
must not define an object inline, so compound branches belong under
[`definitions`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#definitions-keyword).

This schema lets the root value be a pickup point or a street address. Both
branches require `locationId` and `label`; an object containing only their
shared requirements matches both. `PickupPoint` comes first because this model
wants that interpretation to win. Both branches explicitly permit additional
properties, so the overlap does not depend on a processor default.

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://schemas.example.com/delivery-destination.json",
  "$root": "#/definitions/DeliveryDestination",
  "definitions": {
    "PickupPoint": {
      "type": "object",
      "properties": {
        "locationId": { "type": "string" },
        "label": { "type": "string" },
        "lockerBank": { "type": "string" }
      },
      "required": ["locationId", "label"],
      "additionalProperties": true
    },
    "StreetAddress": {
      "type": "object",
      "properties": {
        "locationId": { "type": "string" },
        "label": { "type": "string" },
        "street": { "type": "string" },
        "city": { "type": "string" }
      },
      "required": ["locationId", "label"],
      "additionalProperties": true
    },
    "DeliveryDestination": {
      "type": [
        { "$ref": "#/definitions/PickupPoint" },
        { "$ref": "#/definitions/StreetAddress" }
      ]
    }
  }
}
```

Consider this value:

```json
{
  "locationId": "SEA-042",
  "label": "Pine Street pickup",
  "lockerBank": "B"
}
```

It satisfies the required members of both branches. Because `PickupPoint` is
first, the value is a `PickupPoint`. Reverse the union members and the same JSON
is considered a `StreetAddress`.

A validator accepts the value in either order. A code generator, data mapper,
or dispatch function still needs one type identity, and the first branch
provides it.

## Why the union sits under [`definitions`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#definitions-keyword)

A schema document's root object may declare one [`type`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#type-keyword), but the root itself must
not use a type array. To make a union the type of document instances, declare
the union under [`definitions`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#definitions-keyword) and designate it with [`$root`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#root-keyword).

[`$root`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#root-keyword) and a root-level [`type`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#type-keyword) are mutually exclusive. Its value is a JSON
Pointer to an existing reusable type under [`definitions`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#definitions-keyword):

```json
{
  "$root": "#/definitions/DeliveryDestination",
  "definitions": {
    "DeliveryDestination": {
      "type": ["string", "int32"]
    }
  }
}
```

The key under [`definitions`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#definitions-keyword) gives the union a reusable location and gives
[`$root`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#root-keyword) something to point at. It remains a union of referenced or primitive
types, not a new compound type category.

## Set the precedence before publishing

Put the branch with the narrower or more useful domain interpretation before a
branch that accepts more values. A processor will not rank them for you.

Test the intersections as well as one clean example per branch. For each pair
of object branches, construct a value that satisfies their common requirements
and verify that the earlier branch is the intended one.

If you do not want precedence to settle an overlap, use a [`choice`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#choice) with an
explicit selector. A non-discriminated union works when the JSON forms already
separate the alternatives, or when first-match precedence expresses the model.
After publication, reordering its branches is a behavioral change, however
innocent the diff may look.
