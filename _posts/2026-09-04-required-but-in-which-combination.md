---
layout: post
title: "Required, but in Which Combination?"
date: 2026-09-04
published: false
author: Clemens Vasters
image: /social-cards/required-but-in-which-combination.png
description: >-
  JSON Structure can require one complete property set from several mutually
  exclusive alternatives. A contact record shows the exact nested-array rule.
---

A contact must provide an email address or a phone number, but not both. Making
both properties optional does not express that rule. Making both required
expresses the opposite rule.

JSON Structure puts the combination directly in [`required`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#required-keyword). A flat array names
one required set. An array of arrays names alternative required sets, and
exactly one set must match the properties present in the object.

Read "exactly one" literally. This construct does not mean "at least one."

## The complete contact schema

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://example.com/schemas/contact",
  "name": "Contact",
  "type": "object",
  "properties": {
    "displayName": { "type": "string" },
    "email": { "type": "string" },
    "phone": { "type": "string" },
    "preferredLanguage": { "type": "string" }
  },
  "required": [
    ["displayName", "email"],
    ["displayName", "phone"]
  ],
  "additionalProperties": false
}
```

This instance selects the email set:

```json
{
  "displayName": "Ada Lovelace",
  "email": "ada@example.net",
  "preferredLanguage": "en"
}
```

`displayName` appears in both alternatives, so it is required in every valid
contact. `preferredLanguage` appears in neither and remains optional. `email`
appears only in the first set; `phone` appears only in the second.

A phone-only contact is equally valid:

```json
{
  "displayName": "Grace Hopper",
  "phone": "+1-202-555-0142"
}
```

## AND inside, exclusive choice outside

The outer array means "choose exactly one required-property set." Each inner
array is one complete set whose property names are combined with AND.

For this schema, the alternatives are:

- `displayName` AND `email`
- `displayName` AND `phone`

The alternatives are mutually exclusive. An object with neither contact method
matches no set and is invalid. An object with both methods matches both sets and
is also invalid.

```json
{
  "displayName": "Katherine Johnson",
  "email": "katherine@example.net",
  "phone": "+1-202-555-0188"
}
```

That invalidity is easy to miss if you read the construct as JSON Schema's
[`anyOf`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#anyOf). The core draft says exactly one set must match. The nested form is an
exclusive choice among presence patterns.

"Match" concerns the object's property set, not a quick check that the listed
members happen to exist. Properties shared across alternatives are common
requirements. Adding a property unique to another alternative makes that other
set match as well, which invalidates the object.

Put common mandatory properties in every inner array. Each alternative's
distinguishing properties belong only in its own array; unrelated optional
properties stay out of all sets.

## Do you need alternatives at all?

For an ordinary object, use a flat array:

```json
{
  "required": ["displayName", "email"]
}
```

That says both properties must be present. It does not create alternatives, and
additional declared properties may still appear unless another rule forbids
them.

Use the nested form only when property presence selects one mutually exclusive
shape. May email and phone both be supplied? Then the rule is "at least one,"
and core's alternative required sets are the wrong construct. Use the
conditional composition extension's [`anyOf`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#anyOf), or remodel the data so the
alternatives are explicit.

## Do not translate by keyword

In JSON Schema, the common spelling is [`oneOf`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#oneOf) with two branches, each carrying
a [`required`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#required-keyword) array, plus exclusions when necessary. JSON Schema's own [`required`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#required-keyword)
keyword remains a flat array. Directly copying JSON Structure's nested array
into a JSON Schema document is invalid vocabulary usage.

Avro record fields are required unless their type and default model absence.
Avro unions choose among value schemas, but they do not directly say "exactly
one of these record fields is present." You would normally model a separate
contact-method union or enforce the cross-field rule in application logic.

XML Schema expresses alternative element structures with `xs:choice`, often
inside an `xs:sequence` containing the common fields. That is conceptually close
to these alternative sets, though XML's content model operates on ordered
elements while JSON object properties are unordered.

## Presence says nothing about usability

The schema above requires the presence of `email` or `phone`; it cannot prove
that the string is a deliverable address or a dialable number. Core types and
property combinations establish structure. Pattern, format, and length checks
belong to validation constraints. Real-world reachability requires sending a
message or placing a call.

Here, [`required`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#required-keyword) answers one question: which properties must occur together? It
does not answer whether the values will work once you try to use them.
