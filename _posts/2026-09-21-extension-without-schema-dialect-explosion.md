---
layout: post
title: "Extension Without Schema Dialect Explosion"
date: 2026-09-21
published: false
author: Clemens Vasters
image: /social-cards/extension-without-schema-dialect-explosion.png
description: >-
  Offer optional object add-ins in one schema and let each instance opt in with
  $uses, without minting a new schema dialect.
---

An address sometimes needs delivery instructions. Giving every address an
`instructions` property overstates the base contract; publishing another
address schema for that one property starts a dialect collection.

JSON Structure calls this optional extension an add-in. The schema advertises
an abstract add-in through `$offers`. An instance that needs the extra contract
selects it through `$uses`.

Watch where `$uses` appears. It belongs to the JSON instance receiving the
extra members, not to the schema that advertises them.

## The schema makes an offer

The base schema describes an ordinary street address. `DeliveryInstructions`
adds one property for producers that need it.

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://schemas.example.com/street-address.json",
  "$root": "#/definitions/StreetAddress",
  "$offers": {
    "DeliveryInstructions": "#/definitions/DeliveryInstructions"
  },
  "definitions": {
    "StreetAddress": {
      "type": "object",
      "properties": {
        "street": { "type": "string" },
        "city": { "type": "string" },
        "state": { "type": "string" },
        "zip": { "type": "string" }
      },
      "required": ["street", "city", "state", "zip"]
    },
    "DeliveryInstructions": {
      "abstract": true,
      "type": "object",
      "$extends": "#/definitions/StreetAddress",
      "properties": {
        "instructions": { "type": "string" }
      },
      "required": ["instructions"]
    }
  }
}
```

At the schema root, `$offers` maps a public add-in name to a definition in the
same document. The declaration advertises `DeliveryInstructions`; it does not
apply it. Without an opt-in, the root type remains `StreetAddress`.

The add-in is `abstract` because it is not a second independently selectable
address type. In the add-in model, it extends the object it augments and is
injected into that type when selected.

## The instance accepts

A normal instance does not mention the add-in:

```json
{
  "$schema": "https://schemas.example.com/street-address.json",
  "street": "123 Main St",
  "city": "Anytown",
  "state": "WA",
  "zip": "98101"
}
```

An instance that needs delivery instructions opts in:

```json
{
  "$schema": "https://schemas.example.com/street-address.json",
  "$uses": ["DeliveryInstructions"],
  "street": "123 Main St",
  "city": "Anytown",
  "state": "WA",
  "zip": "98101",
  "instructions": "Leave at the back door"
}
```

Here `$schema` identifies the address schema and `$uses` selects one of its
offers. `$uses` is a set of names, so an instance may select several compatible
add-ins.

There is one wrinkle. A schema document may itself be an instance of a
meta-schema, in which case `$uses` applies at that level. In ordinary use, the
document receiving optional members carries `$uses`.

## The unusual direction of `$extends`

`$extends` normally merges properties and constraints from abstract base types
into an extending object or tuple. A concrete derived type cannot redefine an
inherited property. Abstract bases also cannot be used directly as property
types or referenced through `$ref`.

An add-in points `$extends` in an unusual direction: the abstract add-in names
the concrete schema type it augments. When selected, the resulting composite
replaces that base type in the instance's effective type model. The base schema
stays unchanged, while the instance records the optional contract it selected.

The current core draft contradicts itself here. The add-in section and its
normative example allow an abstract add-in to `$extends` a concrete type, as
`DeliveryInstructions` does above. The general `$extends` rules require every
pointer to target an abstract type. Implementations need to recognize the
add-in case described by its dedicated section. The draft needs an explicit
exception so these rules agree.

## No unadvertised add-ins

This mechanism is not open-ended inheritance. An instance may select only a
name advertised by the referenced schema's `$offers`, or an allowed pointer in
the meta-schema case. The offered definition must already exist in the same
schema document.

The base type defines what every instance has. `$offers` publishes the supported
extensions, and `$uses` records what one instance activated. A consumer can
distinguish a declared optional feature from an unknown property without
assuming that every optional field belongs to every address. Producers also
avoid minting a schema URI for every combination of add-ins, which is how the
dialect collection gets stopped before it starts.
