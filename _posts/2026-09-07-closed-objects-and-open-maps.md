---
layout: post
title: "Closed Objects and Open Maps"
date: 2026-09-07
published: false
author: Clemens Vasters
specification_scope: Core only.
image: /social-cards/closed-objects-and-open-maps.png
description: >-
  Use a closed object for schema-defined fields and a separate map for
  runtime-defined keys. A new object field requires a schema revision; a new
  map key does not.
---

A record with fixed fields and a dictionary with unknown keys are both JSON
objects. Treating them as the same abstraction turns typos into extensions and
extensions into accidental fields.

Close the record. Put dynamic labels in a map of their own.

## A closed observation with open labels

Suppose a telemetry observation always has an identifier, timestamp, numeric
value, and labels supplied by deployment tooling. The label names cannot be
enumerated in advance, but the observation fields can.

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://example.com/schemas/observation",
  "name": "Observation",
  "type": "object",
  "properties": {
    "observationId": { "type": "string" },
    "recordedAt": { "type": "datetime" },
    "value": { "type": "double" },
    "labels": {
      "type": "map",
      "values": { "type": "string" }
    }
  },
  "required": ["observationId", "recordedAt", "value", "labels"],
  "additionalProperties": false
}
```

A matching instance can add any label key without changing the observation
record:

```json
{
  "observationId": "obs-7f31",
  "recordedAt": "2026-09-25T14:18:00Z",
  "value": 18.4,
  "labels": {
    "site": "west-yard",
    "sensor.vendor": "Northwind",
    "deployment": "canary"
  }
}
```

`observationId`, `recordedAt`, `value`, and `labels` are declared object
properties. Because [`additionalProperties`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#additionalproperties-keyword) is `false`, no other property may
appear beside them.

Inside `labels`, the rules change. A [`map`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#map) permits any valid JSON string as a
key, and every value must conform to its [`values`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#values-keyword) schema. `site` and
`sensor.vendor` are data, not schema-defined fields.

## The typo test

Now misspell a fixed field:

```json
{
  "observationId": "obs-7f31",
  "recordedAt": "2026-09-25T14:18:00Z",
  "value": 18.4,
  "lables": {
    "site": "west-yard"
  }
}
```

This instance fails twice. The required `labels` property is absent, and
validation rejects `lables` as an undeclared property. The misspelling cannot
be accepted as an extension.

If the outer object were open, `lables` could pass as an additional property
while the missing required `labels` would still fail. With an optional field,
however, a typo could pass silently. Closed records make a schema evolution or a
spelling error visible at the boundary where it occurs.

## [`additionalProperties`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#additionalproperties-keyword) does not make a map

Core allows [`additionalProperties`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#additionalproperties-keyword) on an object to be a boolean or a schema.
With a schema, every undeclared property must conform to it. Use that form for
an object intentionally combining named fields with an extension area.

It still does not turn the object into a [`map`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#map). An object has declared
properties with individual schemas. A map has dynamic keys and one value schema.
Those contracts produce different generated types and different expectations
for consumers.

The [core draft](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#additionalproperties-keyword) makes `additionalProperties` optional but states no default for
its absence. A closed record must therefore say [`"additionalProperties": false`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#additionalproperties-keyword)
explicitly. Processor assumptions are a poor compatibility policy.

## One namespace or two?

Putting dynamic labels beside fixed fields creates a shared namespace. A label
called `value` collides with the actual observation value. A future schema field
called `region` can collide with a label that deployments have emitted for
years. Every evolution becomes a naming negotiation.

A dedicated map gives each namespace its own rules. The outer object evolves
through schema changes; runtime systems add keys inside `labels`. Fixed fields
may have different types and documentation, while every dynamic value follows
the map's one [`values`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#values-keyword) schema.

That boundary also helps code generation. The outer shape becomes a record or
class with named members. `labels` becomes a dictionary from strings to strings.
No generator has to combine known members and an indexer into one awkward type.

## Records and dictionaries elsewhere

JSON Schema uses [`properties`](https://json-schema.org/draft/2020-12/json-schema-core.html#section-10.3.2.1) and [`additionalProperties`](https://json-schema.org/draft/2020-12/json-schema-core.html#section-10.3.2.3) for both patterns. A
closed record sets [`additionalProperties`](https://json-schema.org/draft/2020-12/json-schema-core.html#section-10.3.2.3) to `false`; a string-valued dictionary
can use an empty [`properties`](https://json-schema.org/draft/2020-12/json-schema-core.html#section-10.3.2.1) object with an [`additionalProperties`](https://json-schema.org/draft/2020-12/json-schema-core.html#section-10.3.2.3) schema.
JSON Structure instead names the latter abstraction [`map`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#map) and uses [`values`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#values-keyword).

Avro makes the boundary similarly explicit: records declare fields and maps
carry string keys with one value type. Avro records do not accept arbitrary
extra fields as part of their data model, although a particular decoder may
ignore writer fields unknown to the reader under Avro's schema-resolution
rules. That resolution behavior is not an open-record contract.

XML Schema distinguishes declared element content from wildcard extension
points such as `xs:any`. A repeated key/value element is the usual dictionary
shape. As with JSON Structure, a wildcard inside the record and a contained map
are not equivalent evolution strategies.

`sensor.vendor` has different compatibility rules in the two namespaces. As a
new top-level field, it requires a schema revision. As a key inside `labels`,
it requires no schema revision, and its value must satisfy the existing string
schema. Keeping the namespaces separate prevents future object fields from
colliding with existing label keys.
