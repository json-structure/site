---
layout: post
title: "Array, Set, or Map? Pick One"
date: 2026-08-31
published: false
author: Clemens Vasters
specification_scope: Core only.
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

The [Avro specification](https://avro.apache.org/docs/1.12.0/specification/#schema-declaration) defines array and map schemas but no set schema.
When an Avro array represents set-like data, uniqueness is an application-level
rule. JSON Structure puts that rule into the declared `set` type.

[XML Schema](https://www.w3.org/TR/xmlschema11-1/) has model groups, repeated elements, and identity
constraints. It has no built-in map datatype. A schema can model map-shaped
data with repeated entry elements containing keys and values.

## Start with the allowed operations

Choose the type from the operations the contract permits, not from the JSON
syntax used to carry it.

- Choose [`array`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#array) if a consumer may address an element by position, insert it at a
  position, or retain the same value more than once. Those are queue operations.
- Choose [`set`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#set) if a consumer may test membership, add a value, or remove a value,
  but may not assign that value a position. Those are territory-list operations.
- Choose [`map`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#map) if a consumer may get, put, or remove a value by a key supplied as
  data. Those are per-device-setting operations.

An [`object`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#object) answers a different question. Its property names are part of the type,
so consumers work with declared fields such as `title`. A map's keys are part of
the instance, so consumers work with entries such as `"kitchen"` and
`"headphones"` that appear at runtime.

The current contents do not decide the type. A queue containing no duplicate
tracks is still an array. A territory set happens to have an array-shaped JSON
encoding, but consumers cannot use its element positions as part of the
contract. A device map may be emitted in a stable order by one implementation,
but consumers cannot rely on that order. If the contract permits positional
operations, model an array.
