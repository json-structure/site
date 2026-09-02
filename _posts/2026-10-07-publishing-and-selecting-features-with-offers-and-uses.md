---
layout: post
title: "Publishing and Selecting Features with $offers and $uses"
display_title: "Publishing and Selecting Features with [`$offers`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#offers-keyword) and [`$uses`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uses-keyword)"
date: 2026-10-07
published: false
author: Clemens Vasters
specification_scope: Core with the Units and Validation companion specifications.
image: /social-cards/publishing-and-selecting-features-with-offers-and-uses.png
description: >-
  A meta-schema advertises named vocabulary add-ins, and a schema document
  selects only the features it uses.
---

A processor needs to distinguish features a meta-schema makes available from
features one schema actually uses. Without both declarations, availability
looks like activation and processors must guess which optional vocabulary a
document intended to select.

[`$offers`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#offers-keyword) publishes the available feature bundles. [`$uses`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uses-keyword) records the bundles selected by a
document checked against that meta-schema. Neither declaration substitutes for
the other.

## The extended meta-schema publishes named bundles

The extended v0 meta-schema offers five named bundles:

- [`JSONStructureAlternateNames`](https://json-structure.github.io/alternate-names/draft-vasters-json-structure-alternate-names.html#enabling-the-annotations)
- [`JSONStructureUnits`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#enabling-the-annotations)
- [`JSONStructureImport`](https://json-structure.github.io/import/draft-vasters-json-structure-import.html#enabling-the-extensions)
- [`JSONStructureConditionalComposition`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#enabling-the-extensions)
- [`JSONStructureValidation`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#enabling-the-extensions)

An offer may point to one add-in definition or to an array of them. The
validation offer, for example, selects five add-ins together:
[`NumberValidationAddIn`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#enabling-the-extensions), [`StringValidationAddIn`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#enabling-the-extensions), [`StringFormatAddIn`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#enabling-the-extensions),
[`ArrayValidationAddIn`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#enabling-the-extensions), and [`ObjectValidationAddIn`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#enabling-the-extensions). A schema selects the public
name; the pointers identify the add-ins behind that name.

The relevant `$offers` fragment is:

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

The following complete schema consumes two offers. [`$uses`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uses-keyword) occurs at the root
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

This application instance needs no [`$uses`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uses-keyword) because it selects no optional
add-ins from the application schema:

```json
{
  "$schema": "https://example.com/schemas/thermometer-reading",
  "sensorId": "T-0042",
  "temperature": 21.5
}
```

The instance is validated against the resulting schema. The schema document is where
[`unit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#unit-keyword), [`pattern`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#pattern), [`minimum`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#minimum), and [`maximum`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#maximum) had to be admitted into the schema
vocabulary.

## Core uses the same mechanism one layer down

Core also describes instance-level add-ins. An application schema can [`$offers`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#offers-keyword)
an optional type augmentation such as delivery instructions, and an application
instance can select it with [`$uses`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uses-keyword). In that case [`$uses`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uses-keyword) belongs to the data
instance, not to the schema.

A schema document is itself an instance when a meta-schema checks it. The
current core draft is inconsistent at this point. One normative rule says
[`$uses`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uses-keyword) "MUST only" occur in instance documents, while the preceding text
allows it in a meta-schema that references a parent schema. The core
meta-schema includes [`$uses`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uses-keyword) as a `SchemaDocument` property, and the published extended and
validation meta-schemas use it at their roots.

The project's own meta-schemas support this reading: [`$uses`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uses-keyword) occurs at the root of
the document receiving the add-ins. For vocabulary composition, that receiver
is a schema or meta-schema document. For an application add-in, it is the
application instance. Treating [`$uses`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uses-keyword) as globally "data-only" would reject the
project's own meta-schemas.

This mechanism rejects undeclared extensions. A consumer cannot select an
unadvertised name, and an offer cannot point vaguely outside its defining
document. If a processor accepts either case, it is inventing vocabulary rather
than implementing the declared one.

[core]: https://json-structure.github.io/core/draft-vasters-json-structure-core.html
