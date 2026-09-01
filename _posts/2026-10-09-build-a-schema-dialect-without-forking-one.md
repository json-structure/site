---
layout: post
title: "Build a Schema Dialect Without Forking One"
date: 2026-10-09
published: false
author: Clemens Vasters
specification_scope: Core with the Import, Units, and Validation companion specifications.
image: /social-cards/build-a-schema-dialect-without-forking-one.png
description: >-
  Compose a custom JSON Structure meta-schema from named add-ins and give
  processors an explicit, resolvable vocabulary contract.
---

A telemetry project may need units and validation without alternate names or
conditional composition. Copying the extended meta-schema would leave that
project maintaining a private copy of definitions it does not intend to
change.

Composition records the smaller decision directly. Import the base definitions,
select the offered add-ins, and publish the result under a new identifier. A
processor resolves that URI to find the vocabulary permitted by the project.

## Start with the offering meta-schema

The extended v0 meta-schema advertises optional bundles through [`$offers`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#offers-keyword). A
derived meta-schema references extended with [`$schema`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#schema-keyword), imports its definitions,
and selects bundles with [`$uses`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uses-keyword).

This complete custom meta-schema enables import because composition itself uses
[`$import`](https://json-structure.github.io/import/draft-vasters-json-structure-import.html#import-keyword), then adds units and validation. It deliberately leaves out alternate
names and conditional composition.

```json
{
  "$schema": "https://json-structure.org/meta/extended/v0/#",
  "$id": "https://schemas.example.com/meta/telemetry/v0/#",
  "$import": "https://json-structure.org/meta/extended/v0/#",
  "$uses": [
    "JSONStructureImport",
    "JSONStructureUnits",
    "JSONStructureValidation"
  ],
  "$root": "#/definitions/SchemaDocument",
  "name": "TelemetrySchemaDialect"
}
```

This is the same composition form used by the published validation meta-schema:
the new document imports the parent and reuses its `SchemaDocument` root. The
selected add-ins augment the imported type model rather than requiring copied
definitions.

[`$schema`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#schema-keyword) and [`$import`](https://json-structure.github.io/import/draft-vasters-json-structure-import.html#import-keyword) do different jobs. [`$schema`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#schema-keyword) says which meta-schema
checks this custom meta-schema. [`$import`](https://json-structure.github.io/import/draft-vasters-json-structure-import.html#import-keyword) brings the parent's definitions into
the new document so `#/definitions/SchemaDocument` resolves locally after
processing. Conflating those operations would make a declaration accidentally
depend on validator magic.

## Schemas name the dialect they obey

A consuming schema points [`$schema`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#schema-keyword) at the custom meta-schema. It also records
the optional feature bundles it uses at its own root, following the add-in
contract exposed through the composed meta-schema.

```json
{
  "$schema": "https://schemas.example.com/meta/telemetry/v0/#",
  "$id": "https://schemas.example.com/telemetry/pressure-reading",
  "name": "PressureReadingSchema",
  "$uses": [
    "JSONStructureUnits",
    "JSONStructureValidation"
  ],
  "$root": "#/definitions/PressureReading",
  "definitions": {
    "PressureReading": {
      "name": "PressureReading",
      "type": "object",
      "properties": {
        "sensorId": {
          "type": "string",
          "pattern": "^P-[A-Z0-9]{6}$"
        },
        "pressure": {
          "type": "double",
          "unit": "kPa",
          "minimum": 80,
          "maximum": 120
        }
      },
      "required": ["sensorId", "pressure"],
      "additionalProperties": false
    }
  }
}
```

An application instance then points to that schema:

```json
{
  "$schema": "https://schemas.example.com/telemetry/pressure-reading",
  "sensorId": "P-3A91F2",
  "pressure": 101.325
}
```

The schema has no [`altnames`](https://json-structure.github.io/alternate-names/draft-vasters-json-structure-alternate-names.html#the-altnames-keyword), [`oneOf`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#oneOf), or [`if`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#if-then-else), and its declared dialect never
admitted those vocabularies. An unknown keyword is therefore an error, not an
invitation for a processor to guess whether it is an annotation, a typo, or a
private extension.

## The URI is the vocabulary contract

The custom meta-schema's [`$id`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#id-keyword) is not decorative branding. It gives the exact
combination a stable identity. Schema registries can cache it, generators can
select handlers from it, and validators can reject documents that use keywords
outside it.

The URI identifies a narrower language than "extended JSON Structure." Telemetry
schemas may describe units and impose validation policy; they do not thereby
pick up every other extension in the extended vocabulary.

The present drafts leave one edge slightly rough: core says [`$uses`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uses-keyword) is
instance-only while its own `SchemaDocument` meta-definition allows the
property, and the published meta-schemas rely on root-level [`$uses`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uses-keyword). A schema or
meta-schema is the instance at this layer, so the examples follow the shipped
meta-schema behavior. Processors implementing only the prose's narrowest
reading will not compose these documents correctly.

Fork the language when you intend to change its rules. Selecting vocabulary that
the language already offers is composition, and giving that selection a URI
makes it resolvable. A copied meta-schema would only disguise that simpler
choice and create another document to keep in sync.

[core]: https://json-structure.github.io/core/draft-vasters-json-structure-core.html
