---
layout: post
title: "`$offers` and `$uses` Are a Handshake"
date: 2026-10-07
published: false
author: Clemens Vasters
image: /social-cards/offers-and-uses-are-a-handshake.png
description: >-
  See how a meta-schema advertises named vocabulary add-ins and a schema
  document explicitly selects only the features it uses.
---

Optional vocabulary needs two declarations. A meta-schema publishes named
feature bundles through `$offers`; a document checked by that meta-schema
selects bundles through `$uses` at its own root.

Neither declaration substitutes for the other. An offer says what can be
selected. A use says what this document actually selected.

## Extended publishes real feature names

The extended v0 meta-schema offers five named bundles:

- `JSONStructureAlternateNames`
- `JSONStructureUnits`
- `JSONStructureImport`
- `JSONStructureConditionalComposition`
- `JSONStructureValidation`

An offer may point to one add-in definition or to an array of them. The
validation offer, for example, selects five add-ins together:
`NumberValidationAddIn`, `StringValidationAddIn`, `StringFormatAddIn`,
`ArrayValidationAddIn`, and `ObjectValidationAddIn`. The public name is the
stable choice; the pointers describe the concrete additions it activates.

This is a fragment of the actual shape:

```json
{
  "$offers": {
    "JSONStructureUnits": [
      "#/definitions/features/UnitsPropertyAddIn",
      "#/definitions/features/UnitsArrayAddIn",
      "#/definitions/features/UnitsMapAddIn"
    ],
    "JSONStructureValidation": [
      "#/definitions/features/NumberValidationAddIn",
      "#/definitions/features/StringValidationAddIn",
      "#/definitions/features/StringFormatAddIn",
      "#/definitions/features/ArrayValidationAddIn",
      "#/definitions/features/ObjectValidationAddIn"
    ]
  }
}
```

The fragment is illustrative, not a complete meta-schema. The complete
extended meta-schema also imports core, identifies itself, declares its root,
and contains the referenced definitions.

## A schema selects by name

The following complete schema consumes two offers. `$uses` occurs at the root
of the schema document because that document is the instance being checked by
the extended meta-schema.

```json
{
  "$schema": "https://json-structure.org/meta/extended/v0/#",
  "$id": "https://example.com/schemas/thermometer-reading",
  "name": "ThermometerReadingSchema",
  "$uses": [
    "JSONStructureUnits",
    "JSONStructureValidation"
  ],
  "$root": "#/definitions/ThermometerReading",
  "definitions": {
    "ThermometerReading": {
      "name": "ThermometerReading",
      "type": "object",
      "properties": {
        "sensorId": {
          "type": "string",
          "pattern": "^T-[0-9]{4}$"
        },
        "temperature": {
          "type": "double",
          "unit": "Cel",
          "minimum": -80,
          "maximum": 180
        }
      },
      "required": ["sensorId", "temperature"],
      "additionalProperties": false
    }
  }
}
```

This application instance needs no `$uses` because it selects no optional
add-ins from the application schema:

```json
{
  "$schema": "https://example.com/schemas/thermometer-reading",
  "sensorId": "T-0042",
  "temperature": 21.5
}
```

The instance simply obeys the resulting schema. The schema document is where
`unit`, `pattern`, `minimum`, and `maximum` had to be admitted into the schema
vocabulary.

## Core uses the same mechanism one layer down

Core also describes instance-level add-ins. An application schema can `$offers`
an optional type augmentation such as delivery instructions, and an application
instance can select it with `$uses`. In that case `$uses` belongs to the data
instance, not to the schema.

The layers are consistent: a schema document is an instance when a meta-schema
checks it. The current core draft's wording is not as tidy. Its normative rules
say `$uses` "MUST only" occur in instance documents, while the same section says
it may occur in a meta-schema that references a parent schema. The core
meta-schema includes `$uses` as a `SchemaDocument` property, and the published
extended and validation meta-schemas use it at their roots.

The interoperable reading is therefore concrete: `$uses` occurs at the root of
the document receiving the add-ins. For vocabulary composition, that receiver
is a schema or meta-schema document. For an application add-in, it is the
application instance. Treating `$uses` as globally "data-only" would reject the
project's own meta-schemas.

This mechanism rejects wishful extension. A consumer cannot select an
unadvertised name, and an offer cannot point vaguely outside its defining
document. If a processor accepts either case, it is inventing vocabulary rather
than implementing the declared one.

[core]: https://json-structure.github.io/core/draft-vasters-json-structure-core.html
