---
layout: post
title: "Decimal Is Not Double"
date: 2026-08-24
published: true
author: Clemens Vasters
specification_scope: Core only.
image: /social-cards/decimal-is-not-double.png
description: >-
  JSON Structure separates exact base-10 decimal values from binary floating
  point and carries precision and scale in the data definition.
---

In exact base-10 arithmetic, three units at 19.95 produce 59.85. The amount
belongs to a base-10 value domain. Calling it a [`double`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#double) and printing two fractional digits
does not create that domain; it only hides the approximation on display. JSON
Structure therefore declares [`decimal`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#decimal) separately from [`float`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#float) and [`double`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#double) and
carries its value through JSON as a string.

## Model the amount you mean

Take a simple invoice line: three units at 19.95, producing a line amount of
59.85. I chose these values because they make the representation problem
visible without a contrived calculation: binary64 evaluates `19.95 * 3` as
`59.849999999999994`, while formatting that result to two fractional digits
prints `59.85`. The displayed price looks exact even though the stored result
is an approximation. The schema can define both the representation and the
intended decimal capacity:

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://example.com/schemas/invoice-line",
  "name": "InvoiceLine",
  "type": "object",
  "properties": {
    "description": {
      "type": "string",
      "maxLength": 200
    },
    "quantity": {
      "type": "uint32"
    },
    "unitPrice": {
      "type": "decimal",
      "precision": 12,
      "scale": 2
    },
    "lineAmount": {
      "type": "decimal",
      "precision": 14,
      "scale": 2
    }
  },
  "required": [
    "description",
    "quantity",
    "unitPrice",
    "lineAmount"
  ],
  "additionalProperties": false
}
```

A valid instance keeps the decimal values quoted:

```json
{
  "description": "Replacement filter",
  "quantity": 3,
  "unitPrice": "19.95",
  "lineAmount": "59.85"
}
```

The lexical form follows JSON's decimal syntax without an exponent: an optional
minus sign, an integer part, and a required fractional part. [`precision`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#precision-keyword) states
the total number of significant digits. [`scale`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#scale-keyword) states the number of digits to
the right of the decimal point.

Both keywords are annotations on [`decimal`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#decimal) and [`number`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#number); [`scale`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#scale-keyword) also constrains
the fractional part. For [`decimal`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#decimal), the core defaults are 34 significant digits
and seven fractional digits when the schema does not override them.

## Binary floating point solves another problem

[`float`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#float) and [`double`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#double) model IEEE 754 binary32 and binary64 values. They are useful
for domains that use hardware floating-point arithmetic, including measurements,
simulation, graphics, and statistics.

They are base-2 types. Decimal fractions such as 0.1 and 19.95 have no finite
base-2 representation. Their binary floating-point values are rounded
approximations; that is a property of the representation, not a parser bug.

Money gets no special exemption from binary arithmetic. An application can use
binary floating point with an explicit rounding policy. The policy then lives in
application code rather than in the type, and each multiplication, allocation,
conversion, or aggregation must apply the intended domain rules.

[`decimal`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#decimal) makes the base-10 intent explicit before any arithmetic begins. A
binding can select a decimal arithmetic type, a database tool can select a
fixed-precision decimal column, and a validator can reject a value with too many
fractional digits.

## Why the JSON value is a string

JSON encodes numbers as decimal character sequences. It does not encode them as
IEEE 754 binary64 and does not prescribe an in-memory numeric type. The problem
arises when an implementation materializes a JSON number as a binary64
`double`. Binary64 stores a sign, a binary exponent, and 53 bits of significand
precision. Because it represents values in base 2, decimal fractions such as
0.1 and 19.95 have no exact binary64 representation. Such a parser rounds the
decimal sequence before a schema-aware layer sees it. At that point, the exact
decimal value and its original digits are not available from that value alone.

Representing a [`decimal`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#decimal) as a JSON string prevents that numeric conversion. A
schema-aware binding can read the preserved lexical value directly into a
base-10 decimal type instead of receiving a value that the parser has already
converted to binary floating point. The string is not arbitrary text: the
`decimal` type requires the specified numeric grammar and precision rules.
Those semantics come from the schema, not from the quotes.

This also preserves trailing fractional zeros. `"19.95"` and `"19.950"` can
express different scale choices even though they denote the same mathematical
value. A schema with [`scale: 2`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#scale-keyword) makes the expected fractional capacity clear.

## A validation increment is not an arithmetic type

JSON Schema has one [`number`](https://json-schema.org/draft/2020-12/json-schema-validation.html#section-6.1.1) type and an [`integer`](https://json-schema.org/draft/2020-12/json-schema-validation.html#section-6.1.1) specialization. Keywords such
as [`multipleOf`](https://json-schema.org/draft/2020-12/json-schema-validation.html#section-6.2.1) can require increments like 0.01, and bounds can constrain a
range. That is useful validation, but it does not declare a decimal arithmetic
type or protect the instance from a binary64 parser.

A string plus a pattern can preserve decimal text, but the pattern does not
declare a decimal arithmetic type. JSON Structure gives that intent a core type
name and standardized precision and scale annotations.

## Avro uses an unscaled integer

Avro defines decimal as a logical type over `bytes` or `fixed`. The underlying
bytes hold an unscaled two's-complement integer; the schema supplies the required
precision and a scale that defaults to zero. That is a strong decimal contract,
optimized for Avro's encodings.

JSON Structure makes the same essential distinction between decimal and binary
floating point, but uses readable decimal text in JSON. There is no unscaled
integer or byte order for a JSON consumer to reconstruct.

## XML Schema made this split long ago

XML Schema's `xs:decimal` is also a base-10 type, distinct from `xs:float` and
`xs:double`. Its `totalDigits` and `fractionDigits` facets closely correspond to
precision and scale constraints.

For the invoice line, the schema fixes the choice before a parser or binding can
silently make another one. Currency symbols and localized separators belong in
the presentation layer. By then, `"59.85"` must still mean 59.85.
