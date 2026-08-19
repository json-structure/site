---
layout: post
title: "Patterns for Keys, Not Objects"
date: 2026-10-19
published: false
author: Clemens Vasters
image: /social-cards/patterns-for-keys-not-objects.png
description: >-
  Apply patternProperties to named object extensions and patternKeys to dynamic
  map entries, while propertyNames and keyNames constrain the names themselves.
---

A regular expression over member names can answer two different questions:
which value schema applies here, and is this name allowed at all?

JSON Structure keeps those questions separate. It also keeps objects and maps
separate, so the vocabulary has parallel names: [`patternProperties`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#patternProperties-and-patternKeys) for object
properties and [`patternKeys`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#patternProperties-and-patternKeys) for map entries.

## Objects have declared structure

Suppose a telemetry envelope has fixed members plus vendor extension fields.
Every extension begins with `x-` and carries a string value.

```json
{
  "$schema": "https://json-structure.org/meta/validation/v0/#",
  "$id": "https://schemas.example.com/telemetry-envelope",
  "name": "TelemetryEnvelope",
  "type": "object",
  "properties": {
    "deviceId": { "type": "string" },
    "timestamp": { "type": "datetime" },
    "labels": {
      "type": "map",
      "values": { "type": "string" },
      "patternKeys": {
        "^[a-z][a-z0-9_.-]{0,31}$": { "type": "string", "maxLength": 64 }
      },
      "keyNames": {
        "type": "string",
        "pattern": "^[a-z][a-z0-9_.-]{0,31}$"
      }
    }
  },
  "required": ["deviceId", "timestamp", "labels"],
  "patternProperties": {
    "^x-[a-z][a-z0-9-]*$": { "type": "string", "maxLength": 128 }
  },
  "propertyNames": {
    "type": "string",
    "pattern": "^(deviceId|timestamp|labels|x-[a-z][a-z0-9-]*)$"
  },
  "additionalProperties": true
}
```

This instance mixes the stable envelope with one extension and three dynamic
labels:

```json
{
  "deviceId": "pump-17",
  "timestamp": "2026-11-02T08:15:00Z",
  "labels": {
    "site": "west",
    "line.id": "L4",
    "maintenance-window": "night"
  },
  "x-contoso-firmware": "4.8.2"
}
```

[`patternProperties`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#patternProperties-and-patternKeys) does not declare an object property. It finds properties
whose names match the expression and validates their values against the paired
schema. Declared members still come from [`properties`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#properties-keyword).

## Maps have entries, not ad hoc properties

The `labels` member is a map because its keys are data. There is no finite
catalog of label names. [`values`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#values-keyword) gives every entry a string type, while
[`patternKeys`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#patternProperties-and-patternKeys) applies a more specific value constraint when a key matches its
expression.

In this example every permitted key matches, so [`patternKeys`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#patternProperties-and-patternKeys) repeats the
string type and adds [`maxLength`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#maxlength-keyword). That repetition is intentional: the keyword
selects values by key pattern; it does not decide which keys may exist.

When several patterns match one name, every corresponding value schema applies.
The effects combine with logical AND. Pattern order has no precedence semantics.

## Name schemas answer the other question

[`propertyNames`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#propertyNames-and-keyNames) evaluates every object property name as a string instance. Here
it admits the three declared names and the `x-` extension convention, excluding
unrecognized object members even though [`additionalProperties`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#additionalproperties-keyword) is `true`.

[`keyNames`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#propertyNames-and-keyNames) performs the equivalent job for every map key. A label named
`Region/Zone` fails because the slash and uppercase letters violate the key
schema, regardless of whether its value is a perfectly good string.

[`patternProperties`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#patternProperties-and-patternKeys) and [`patternKeys`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#patternProperties-and-patternKeys) choose value constraints based on names.
[`propertyNames`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#propertyNames-and-keyNames) and [`keyNames`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#propertyNames-and-keyNames) validate the names themselves. If you use only
the first pair, a schema can check the associated values and still accept a
misspelled or hostile key.

The draft requires ECMAScript 2022 regular-expression syntax and notes the
usual ReDoS risk. JSON Structure Core also constrains identifiers, so regexes
do not grant names that core syntax otherwise forbids.

## Four missing declarations

The validation draft names its opt-in [`JSONSchemaValidation`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#enabling-the-extensions); the extended
meta-schema offers [`JSONStructureValidation`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#enabling-the-extensions). The checked-in validation add-in
also omits all four keywords used here: [`patternProperties`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#patternProperties-and-patternKeys), [`patternKeys`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#patternProperties-and-patternKeys),
[`propertyNames`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#propertyNames-and-keyNames), and [`keyNames`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#propertyNames-and-keyNames).

The example therefore uses the repository's validation meta-schema URI and the
keywords as defined by the draft. A draft-aware processor can evaluate them;
the current meta-schema cannot validate this schema document completely.
Modeling `labels` as an object would evade that tooling gap by changing the
data model, which would be the wrong fix.
