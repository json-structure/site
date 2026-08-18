---
layout: post
title: "The Tuple Deserves a Name"
date: 2026-09-02
published: false
author: Clemens Vasters
image: /social-cards/the-tuple-deserves-a-name.png
description: >-
  A tuple is more than a fixed-length array. JSON Structure names each position
  so a geographic point keeps its coordinate order and application meaning.
---

`[13.405, 52.52]` is compact, valid JSON, and a trap. Longitude then latitude?
Latitude then longitude? Perhaps two unrelated measurements?

A tuple needs order and names. In JSON Structure, `properties` defines the named
positions and their types, while `tuple` fixes those names in wire order. The
instance stays an array.

## A point with named positions

This complete schema defines a WGS 84 geographic point. The coordinate reference
system is stated in the type name and description here; the core tuple mechanism
itself is about structure, not geodesy.

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://example.com/schemas/wgs84-position",
  "name": "Wgs84Position",
  "type": "object",
  "description": "An observation position using WGS 84 longitude and latitude.",
  "properties": {
    "stationId": { "type": "string" },
    "position": {
      "name": "GeographicPoint",
      "type": "tuple",
      "description": "Longitude followed by latitude, in decimal degrees.",
      "properties": {
        "longitude": { "type": "double" },
        "latitude": { "type": "double" }
      },
      "tuple": ["longitude", "latitude"]
    }
  },
  "required": ["stationId", "position"],
  "additionalProperties": false
}
```

The corresponding instance remains lean:

```json
{
  "stationId": "berlin-alexanderplatz",
  "position": [13.405, 52.52]
}
```

The first number is `longitude` because `longitude` is first in `tuple`. Its
schema is the property named `longitude`. The second number is `latitude` for
the same reason.

Swap the names in the `tuple` array and you change the wire contract. Swap only
the two instance values and the JSON remains structurally valid, because both
positions are doubles, but the point moves. A schema cannot detect a plausible
number placed in the wrong same-typed position. Naming the positions makes the
contract reviewable and gives generated APIs better names than `item0` and
`item1`.

## The length is fixed

Every property declared by a tuple is implicitly required. Every declared
property name must appear in the `tuple` array, whose order defines the instance
positions. The resulting array therefore has the tuple's exact length.

That means this is invalid:

```json
{
  "stationId": "berlin-alexanderplatz",
  "position": [13.405]
}
```

So is `[13.405, 52.52, 34.0]`. There is no suggested prefix followed by an
open-ended tail. The named property schemas determine every position and the
array's length.

There is no `required` keyword inside the tuple. That keyword belongs to
objects, while tuple positions are required by the tuple definition itself.
Adding `required` would not clarify the model; it would violate the core rule
that permits `required` only on `object` schemas.

## When an object is the better shape

An object would be clearer on the wire:

```json
{
  "longitude": 13.405,
  "latitude": 52.52
}
```

Use that shape when readers should see the names on the wire. Choose the tuple
when an existing format is positional, when the size difference is material at
the scale involved, or when an external contract demands coordinate arrays.
The schema and generated code retain names either way.

## Nearby models, different tradeoffs

JSON Schema Draft 2020-12 models positional arrays with `prefixItems`. Each
position gets a schema, but the positions themselves have no standard names.
Titles or descriptions can annotate them, yet those annotations do not create
property identities for language mappings.

Avro records name fields but encode them according to the selected Avro binary
or JSON encoding; Avro arrays, by contrast, have one item schema rather than a
fixed heterogeneous position list. A two-coordinate Avro record is therefore
the natural named model, but its JSON encoding is not this bare array.

XML Schema can define an ordered sequence of named child elements. That retains
names on the wire, which is closer to a JSON object than to `[13.405, 52.52]`.

JSON Structure combines the property identities of a record with the wire shape
of an array. For a geographic coordinate pair whose representation cannot
change, that permits named APIs without changing the JSON.

`GeographicPoint` and its description document WGS 84, but core does not make
that reference machine-resolvable. When a processor must identify and check the
reference system rather than trust prose, the semantic annotations extension
provides `coordinateReferenceSystem`. Position names prevent a longitude and
latitude from becoming anonymous numbers; they cannot tell a processor which
geodetic datum those numbers use.
