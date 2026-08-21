---
layout: post
title: "How Large Is Your Integer?"
date: 2026-08-21
published: true
author: Clemens Vasters
image: /social-cards/how-large-is-your-integer.png
description: >-
  JSON Structure gives integers an explicit width and signedness, from int8 to
  uint128, while preserving large values safely in JSON strings.
---

Call a field [`integer`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#integer) and the awkward questions arrive later. How wide is it?
Can it be negative? Will a JavaScript consumer round it before generated code
ever sees it? JSON Structure puts signedness and widths from 8 through 128 bits
in the type declaration, then uses a JSON representation that preserves the
declared range.

## Ten names, ten ranges

The integer family is regular:

| Type | Range |
| --- | --- |
| [`int8`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#int8) | $-2^7$ through $2^7-1$ |
| [`uint8`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uint8) | $0$ through $2^8-1$ |
| [`int16`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#int16) | $-2^{15}$ through $2^{15}-1$ |
| [`uint16`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uint16) | $0$ through $2^{16}-1$ |
| [`int32`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#int32) | $-2^{31}$ through $2^{31}-1$ |
| [`uint32`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uint32) | $0$ through $2^{32}-1$ |
| [`int64`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#int64) | $-2^{63}$ through $2^{63}-1$ |
| [`uint64`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uint64) | $0$ through $2^{64}-1$ |
| [`int128`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#int128) | $-2^{127}$ through $2^{127}-1$ |
| [`uint128`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uint128) | $0$ through $2^{128}-1$ |

The familiar [`integer`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#integer) type is an alias for [`int32`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#int32). It exists for JSON Schema
compatibility, but it still has a concrete 32-bit range in JSON Structure.

A schema for counters and identifiers can therefore state its intended machine
model directly:

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://example.com/schemas/sequence-state",
  "name": "SequenceState",
  "type": "object",
  "properties": {
    "partition": { "type": "uint8" },
    "attempt": { "type": "uint16" },
    "recordCount": { "type": "uint32" },
    "nextSequence": { "type": "uint64" },
    "traceValue": { "type": "uint128" }
  },
  "required": [
    "partition",
    "attempt",
    "recordCount",
    "nextSequence",
    "traceValue"
  ],
  "additionalProperties": false
}
```

Here is a valid instance:

```json
{
  "partition": 12,
  "attempt": 3,
  "recordCount": 4294967295,
  "nextSequence": "9007199254740993",
  "traceValue": "340282366920938463463374607431768211455"
}
```

Notice where the quotes begin. They are part of the type contract.

## The 53-bit boundary

JSON's grammar permits arbitrarily long numeric literals. Interoperable software
often does not. RFC 8259 identifies the integer range from $-(2^{53})+1$ through
$2^{53}-1$ as exactly interoperable when implementations use IEEE 754 binary64,
as JavaScript and many general JSON stacks do.

That is why [`int8`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#int8) through [`uint32`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uint32) use unquoted JSON numbers, while [`int64`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#int64),
[`uint64`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uint64), [`int128`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#int128), and [`uint128`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uint128) use strings. The string syntax follows the
JSON integer grammar: no decimal point, no exponent, and no leading decoration.
Signed types permit a minus sign; unsigned types do not.

The instance above makes the issue visible. `9007199254740993` is one greater
than the largest exactly interoperable integer. Parsing it through binary64 as a
JSON number can change it. Parsing the quoted representation as [`uint64`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uint64) cannot.

The instance representation therefore changes at 64 bits. Slightly untidy? Yes.
It is preferable to delivering a nearby integer with no warning.

## Bounds do not name a machine type

JSON Schema's [`integer`](https://json-schema.org/draft/2020-12/json-schema-validation.html#section-6.1.1) describes a mathematical property of a JSON number: it
has no fractional part. Bounds can narrow the accepted set, so a schema author
can spell out the limits of an [`int64`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#int64) with [`minimum`](https://json-schema.org/draft/2020-12/json-schema-validation.html#section-6.2.4) and [`maximum`](https://json-schema.org/draft/2020-12/json-schema-validation.html#section-6.2.2).

That still leaves representation and mapping policy to tooling. A code generator
must recognize the particular bounds, decide whether they imply a machine type,
and account for parsers that already rounded the input. JSON Structure puts the
machine-oriented type name in the schema and changes the JSON representation
where exact numeric interchange is not dependable.

## Avro names two widths

Avro has `int`, a signed 32-bit integer, and `long`, a signed 64-bit integer.
Those are proper data-definition types and map predictably into generated code.
Avro does not provide core unsigned or 128-bit integer types.

In Avro's binary encoding, `long` is not exposed to a JSON number parser, so its
64-bit range is preserved. Avro's JSON encoding writes `int` and `long` as JSON
numbers, which means a generic JavaScript JSON path can still lose precision.
JSON Structure's quoted [`int64`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#int64) and [`uint64`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uint64) representation addresses that path
explicitly.

## XML starts with arbitrary precision

XML Schema starts from a different numeric foundation. `xs:integer` has
arbitrary precision, and derived types include `xs:byte`, `xs:short`, `xs:int`,
`xs:long`, plus unsigned variants. Facets can define further ranges.

That family is closer to JSON Structure's explicitness than JSON Schema's lone
[`integer`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#integer). The practical difference is the carrier: XML text naturally holds
the lexical form for every integer, while JSON distinguishes number and string
nodes. JSON Structure uses number nodes where the common JSON ecosystem can
preserve them and string nodes where it cannot.

For the example above, `nextSequence` is a [`uint64`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uint64) all the way from JSON text to
generated code and storage. No consumer has to reconstruct that decision from a
pair of bounds, and the parser gets no opportunity to round it first.
