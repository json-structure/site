---
layout: post
title: "Array, Set, or Map? Pick One"
date: 2026-08-31
published: true
author: Clemens Vasters
image: /social-cards/array-set-or-map-pick-one.png
description: >-
  Array, set, and map encode different collection contracts. One playlist schema
  shows how order, uniqueness, and dynamic keys belong in the type.
---

A JSON array may be a sequence or a set. A JSON object may be a record or a
dictionary. You cannot tell which contract applies by looking at the brackets.

JSON Structure makes the choice explicit. An [`array`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#array) preserves order, a [`set`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#set)
requires unique elements without assigning them an order, and a [`map`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#map) holds
values under dynamic string keys. Consumers can then expose the operations the
model actually permits instead of guessing from a sample payload.

Consider a playlist service. Its play queue has positions and may repeat a
track. Its list of licensed territories has neither property. Per-device volume
settings arrive under device names that the schema author cannot know. Calling
all three of these "collections" is accurate and not terribly helpful.

## One model, three collection types

The playlist schema assigns each collection its own contract:

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://example.com/schemas/playlist",
  "name": "Playlist",
  "type": "object",
  "properties": {
    "title": { "type": "string" },
    "playQueue": {
      "type": "array",
      "items": { "type": { "$ref": "#/definitions/Track" } }
    },
    "licensedTerritories": {
      "type": "set",
      "items": { "type": "string" }
    },
    "deviceVolume": {
      "type": "map",
      "values": { "type": "uint8" }
    }
  },
  "required": ["title", "playQueue", "licensedTerritories", "deviceVolume"],
  "additionalProperties": false,
  "definitions": {
    "Track": {
      "name": "Track",
      "type": "object",
      "properties": {
        "id": { "type": "string" },
        "title": { "type": "string" }
      },
      "required": ["id", "title"],
      "additionalProperties": false
    }
  }
}
```

An instance looks ordinary:

```json
{
  "title": "Night train",
  "playQueue": [
    { "id": "trk-17", "title": "Signal" },
    { "id": "trk-04", "title": "Platform" },
    { "id": "trk-17", "title": "Signal" }
  ],
  "licensedTerritories": ["DE", "NL", "BE"],
  "deviceVolume": {
    "kitchen": 35,
    "headphones": 62
  }
}
```

The repeated track is deliberate. A queue may play the same track twice, and
its position is meaningful. Reordering `playQueue` changes the instance's
meaning.

Repeating `"DE"` in `licensedTerritories` would be invalid. A [`set`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#set) is encoded
as a JSON array, but all elements must be unique and their order carries no
meaning. A processor may therefore map it to a language-level set rather than a
list.

The keys under `deviceVolume` are not declared property names. New devices
appear at runtime, so this is a [`map`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#map); every key is a JSON string and every value
must satisfy the [`uint8`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uint8) schema. [`values`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#values-keyword), not [`items`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#items-keyword), declares that value type.

## How other schema systems spell it

JSON Schema can express much of this with validation vocabulary. Arrays are
ordered, [`uniqueItems`](https://json-schema.org/draft/2020-12/json-schema-validation.html#section-6.4.3) can prohibit duplicates, and [`additionalProperties`](https://json-schema.org/draft/2020-12/json-schema-core.html#section-10.3.2.3) can
constrain dictionary values. A tool must interpret the combination of keywords
to recover the intended collection model. JSON Structure declares that model as
the type.

Avro draws a similar line between arrays and maps, but it has no native set.
Uniqueness is consequently an application convention when an Avro array carries
set-like data. JSON Structure puts that convention into the type.

XML Schema has sequences and repeated elements, while uniqueness constraints
can identify distinct values. Map-shaped data generally needs an explicit entry
element with key and value children. The dictionary is a convention built from
those elements rather than a named collection type.

## Start with the allowed operations

Ask what consumers may do. The sample JSON is liable to mislead you.

- Use [`array`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#array) when position, insertion order, or repetition matters.
- Use [`set`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#set) when membership matters, duplicates are invalid, and order does not.
- Use [`map`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#map) when keys are data discovered at runtime and all values share one
  schema.

Do not use a map merely to get fast lookup when the keys are fixed fields. That
model is an object. Likewise, today's duplicate-free sample does not turn an
array into a set.

There is no promise about a map's iteration order. JSON objects are unordered in
the JSON data model, and JSON Structure defines a map as dynamic key-value
pairs, not as a sorted or insertion-ordered dictionary. If an API returns a map
and the UI happens to display its entries in insertion order, that behavior is
an accident. If order matters, carry an array.
