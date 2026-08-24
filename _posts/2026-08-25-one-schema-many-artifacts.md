---
layout: post
title: "One Schema, Many Artifacts"
date: 2026-08-25
published: false
author: Clemens Vasters
image: /social-cards/one-schema-many-artifacts.png
description: >-
  Keep one JSON Structure schema as the source contract and project disposable
  documentation, protocols, database definitions, and code from it.
---

A C# class, a `.proto` file, and a SQL script can all represent the same
shipment, but each expresses the model through a different target type system.
One preserves a UUID, another exposes a string, and the database may accept
null. None of those artifacts can serve as the neutral definition without
making its target's constraints and omissions authoritative for every other
consumer.

JSON Structure provides that target-independent definition. It records the
intended types, presence rules, and collection semantics once, before any
language, protocol, or database narrows them. Structurize reads that schema and
projects it into the artifacts each target needs. A target may preserve a
declaration, translate it into a native type, or represent it more weakly; that
result describes the projection, not a revision of the model. The generated
outputs remain useful, but the JSON Structure schema is the contract from which
they can be rebuilt.

> [Structurize](https://pypi.org/project/structurize/3.9.0/) is the JSON
> Structure-focused command-line interface from the
> [Avrotize project](https://github.com/clemensv/avrotize). The 3.9.0 wheel
> omits templates and other assets required by most converters. The examples
> here were tested on Python 3.12.10 with the wheel's dependencies and entry
> point, but with the complete pinned source tree on `PYTHONPATH`:
>
> ```powershell
> py -3.12 -m venv .venv
> .\.venv\Scripts\Activate.ps1
> python -m pip install structurize==3.9.0
> git clone https://github.com/clemensv/avrotize.git structurize-source
> git -C structurize-source checkout 8dbb19a3a48239679f0df097399c5ddc8cd48c76
> $env:PYTHONPATH = (Resolve-Path .\structurize-source).Path
> ```

## Put the decisions in the contract

Consider a fulfillment service that plans a shipment after an order has been
allocated to a warehouse. The contract needs an order identifier, a carrier
service, a dispatch time, a monetary value, and a collection of handling tags.

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://example.com/schemas/shipment-plan",
  "name": "ShipmentPlan",
  "type": "object",
  "properties": {
    "orderId": { "type": "uuid" },
    "carrierService": { "type": "string", "maxLength": 80 },
    "dispatchAt": { "type": "datetime" },
    "declaredValue": {
      "type": "decimal",
      "precision": 12,
      "scale": 2
    },
    "handlingTags": {
      "type": "set",
      "items": { "type": "string" }
    }
  },
  "required": [
    "orderId",
    "carrierService",
    "dispatchAt",
    "declaredValue",
    "handlingTags"
  ],
  "additionalProperties": false
}
```

These declarations are not hints to a generator. [`uuid`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uuid),
[`datetime`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#datetime), [`decimal`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#decimal), and [`set`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#set) are types in the
contract. [`required`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#required-keyword) fixes presence. [`additionalProperties`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#additionalproperties-keyword) closes the object against undeclared
fields.

The instance remains ordinary JSON:

```json
{
  "orderId": "c28788fa-73bd-4b39-a209-2f75f82c6653",
  "carrierService": "priority-ground",
  "dispatchAt": "2026-08-25T16:30:00Z",
  "declaredValue": "184.50",
  "handlingTags": ["fragile", "keep-dry"]
}
```

The schema carries the information that the JSON text cannot carry by itself.
The array under `handlingTags` is unordered and duplicate-free because its
declared type is `set`. The quoted amount belongs to a base-10 decimal domain.
The identifier is more specific than arbitrary text.

## Project views, do not maintain copies

[Structurize 3.9.0](https://pypi.org/project/structurize/3.9.0/) exposes direct
JSON Structure projections. The command names and options are defined in the
[3.9.0 CLI manifest](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/commands.json).
From the same `shipment-plan.struct.json`, a build can produce several views:

```powershell
New-Item -ItemType Directory -Force generated | Out-Null
structurize s2md shipment-plan.struct.json --out generated/shipment-plan.md
structurize s2p shipment-plan.struct.json --out generated/proto
structurize s2sql shipment-plan.struct.json --out generated/shipment-plan.sql --dialect postgres
structurize s2cs shipment-plan.struct.json --out generated/dotnet --namespace Fulfillment.Contracts
structurize s2java shipment-plan.struct.json --out generated/java --package com.example.fulfillment
```

`s2md` gives reviewers a readable contract view. `s2p` adapts the model to
Protocol Buffers. `s2sql` projects it into a selected SQL dialect. The code
generators create language-facing APIs; the same manifest also defines `s2ts`,
`s2go`, and `s2rust`.

Each output answers a different consumer's question. None gains authority over
the schema merely because people read it more often.

## A projection can be narrower

Projection is not photocopying. Target systems have different type systems,
collection models, naming rules, and representation constraints. A generator
must sometimes choose the closest available construct.

Protocol Buffers, for example, has repeated fields but no native set field.
SQL dialects differ in their types and in how they represent nested
collections. Language targets can preserve a set directly, but their concrete
types differ. Those differences do not make the source contract vague. They
make the projection policy visible.

This distinction matters during review. If `handlingTags` appears as a
repeated field in the generated `.proto`, changing the JSON Structure type from
`set` to `array` merely to make both files look alike would reverse the
authority. The source says membership is unique and order has no meaning. A
target that cannot express that fact needs enforcement at its boundary or a
documented loss of semantics.

The generated artifact is evidence of how one tool version projected one
contract. It is not a second contract.

## Regeneration makes drift observable

Treat the projections like compiler output. Keep the command line and tool
version in the build, then regenerate from a known schema revision.

```powershell
New-Item -ItemType Directory -Force generated | Out-Null
structurize s2md shipment-plan.struct.json --out generated/shipment-plan.md
structurize s2p shipment-plan.struct.json --out generated/proto
structurize s2sql shipment-plan.struct.json --out generated/shipment-plan.sql --dialect postgres
```

Whether generated files belong in source control is a repository policy. The
authority rule stays the same either way. If they are committed for packaging,
review, or downstream tools, a clean regeneration can detect manual edits. If
they are omitted, the build must recreate them before use.

Version pinning matters because a projection includes generator behavior as
well as schema content. An upgrade may improve naming, type selection, or
layout without any contract change. Review that movement as a tooling change,
separate from a change to `ShipmentPlan`.

## Change the model once

Suppose fulfillment adds an optional `warehouseNote`. Add it to
`properties`, leave it out of `required`, and regenerate. Documentation then
shows the field as optional, code receives the target language's optional
shape, and storage or protocol projections apply their corresponding policy.

Do not begin by adding a nullable column, then a nullable C# property, then a
Proto field, and finally trying to reconstruct the schema from the debris.
That workflow asks every editor to repeat the same decision and creates several
places where the answer can differ.

One source contract does not imply that every target has identical syntax or
capabilities. It means every target starts from the same declared intent, and
every loss in translation has one place to be noticed. Keep the JSON Structure
schema deliberate. Make the artifacts cheap.
