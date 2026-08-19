---
layout: post
title: "contains Is Not an Item Type"
display_title: "[`contains`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#contains) Is Not an Item Type"
date: 2026-10-14
published: false
author: Clemens Vasters
image: /social-cards/contains-is-not-an-item-type.png
description: >-
  Use items to type every array member and contains to count members matching
  an additional condition.
---

How do you require an array of sensor records to include at least one alarm?
Typing the array elements is only half of that rule.

In JSON Structure, [`items`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#items-keyword) describes every element. The validation companion's
[`contains`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#contains), [`minContains`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#minContains), and [`maxContains`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#maxContains) inspect the collection and count
elements that match another schema. Confusing those jobs leaves either the
array contents or the alarm count underspecified.

## [`items`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#items-keyword) applies to every element

Consider a sensor batch containing ordinary readings and alarm records. Every
entry shares an envelope: a timestamp, a kind, and a numeric value. A choice
type uses `kind` to select the concrete record shape, and [`items`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#items-keyword) requires every
array element to be one of those records.

The schema uses [`contains`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#contains) to identify alarms and requires one to
three matches:

```json
{
  "$schema": "https://json-structure.org/meta/validation/v0/#",
  "$id": "https://example.com/schemas/sensor-batch",
  "name": "SensorBatchSchema",
  "$uses": ["JSONStructureValidation"],
  "$root": "#/definitions/SensorBatch",
  "definitions": {
    "SensorRecord": {
      "name": "SensorRecord",
      "abstract": true,
      "type": "object",
      "properties": {
        "timestamp": { "type": "datetime" },
        "value": { "type": "double" }
      },
      "required": ["timestamp", "value"]
    },
    "ReadingRecord": {
      "name": "ReadingRecord",
      "type": "object",
      "$extends": "#/definitions/SensorRecord",
      "properties": {
        "kind": { "type": "string" }
      }
    },
    "AlarmRecord": {
      "name": "AlarmRecord",
      "type": "object",
      "$extends": "#/definitions/SensorRecord",
      "properties": {
        "kind": { "type": "string" },
        "code": { "type": "string" }
      },
      "required": ["kind", "code"]
    },
    "BatchRecord": {
      "name": "BatchRecord",
      "type": "choice",
      "$extends": "#/definitions/SensorRecord",
      "selector": "kind",
      "choices": {
        "reading": { "type": { "$ref": "#/definitions/ReadingRecord" } },
        "alarm": { "type": { "$ref": "#/definitions/AlarmRecord" } }
      }
    },
    "SensorBatch": {
      "name": "SensorBatch",
      "type": "array",
      "items": {
        "type": { "$ref": "#/definitions/BatchRecord" }
      },
      "contains": {
        "type": "object",
        "properties": {
          "kind": { "type": "string", "const": "alarm" }
        },
        "required": ["kind"]
      },
      "minContains": 1,
      "maxContains": 3
    }
  }
}
```

A useful batch with two alarms satisfies the schema:

```json
[
  {
    "kind": "reading",
    "timestamp": "2026-10-28T09:00:00Z",
    "value": 71.2
  },
  {
    "kind": "alarm",
    "timestamp": "2026-10-28T09:00:05Z",
    "value": 92.8,
    "code": "HIGH_TEMP"
  },
  {
    "kind": "alarm",
    "timestamp": "2026-10-28T09:00:07Z",
    "value": 18.1,
    "code": "LOW_PRESSURE"
  }
]
```

## Count matches, not positions

The draft defines [`contains`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#contains) for arrays and sets. At least one element must
satisfy its schema. [`minContains`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#minContains) raises that lower bound; [`maxContains`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#maxContains) adds an
upper bound. Both bounds are non-negative integers and count elements that
satisfy [`contains`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#contains). They do not constrain total collection length.

In the example, a batch of 100 records may be valid if one, two, or three are
alarms. Four alarms violate [`maxContains`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#maxContains). Zero alarms violate both the basic
[`contains`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#contains) requirement and [`minContains: 1`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#minContains).

Order is irrelevant to the count. The matching records may appear anywhere,
and one element either contributes one match or none. [`contains`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#contains) does not carve
out a second item channel and does not exempt matching elements from [`items`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#items-keyword).
Every alarm still has to be a valid `BatchRecord`.

## What happens when one keyword is missing

Without [`items`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#items-keyword), [`contains`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#contains) says nothing about nonmatching elements. A string,
an unrelated object, or [`null`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#null) could coexist with a matching alarm unless some
other rule excludes it. That may be intentional for a heterogeneous collection,
but it is not an item-type declaration.

Conversely, [`items`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#items-keyword) alone can require valid sensor records but cannot say that
the batch actually contains an alarm, much less bound the alarm count.

For this batch, every element must satisfy [`items`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#items-keyword), and between one and three of
those elements must also satisfy [`contains`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#contains). Remove either clause and the rule
changes. That is why treating [`contains`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#contains) as an item type is not a harmless
shorthand; it accepts data the schema author probably meant to reject.

[validation]: https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html