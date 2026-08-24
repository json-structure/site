---
layout: post
title: "Decimal Is Not Double"
date: 2026-08-24
published: false
author: Clemens Vasters
image: /social-cards/decimal-is-not-double.png
description: >-
  JSON Structure separates exact base-10 decimal values from binary floating
  point and carries precision and scale in the data definition.
---

Three units at 19.95 should produce 59.85 because the amount belongs to a
base-10 value domain. Calling it a [`double`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#double) and printing two fractional digits
does not create that domain; it only hides the approximation on display. JSON
Structure therefore declares [`decimal`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#decimal) separately from [`float`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#float) and [`double`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#double) and
carries its value through JSON as a string.

## Model the amount you mean

Take a simple invoice line: three units at 19.95, producing a line amount of
59.85. The schema can define both the representation and the intended decimal
capacity:

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
for measurements, simulation, graphics, statistics, and the enormous body of
software built around hardware floating-point arithmetic.

They are base-2 types. Most finite decimal fractions have no finite base-2
representation. The usual example, 0.1 plus 0.2, is not a parser bug; it is the
expected result of mapping decimal source text into binary fractions and then
rounding.

Money gets no special exemption from binary arithmetic. An application can use
binary floating point if every operation applies an explicit rounding policy at
the correct boundary. The policy then lives in application code rather than in
the type, and repeated multiplication, tax allocation, currency conversion, or
aggregation will eventually expose any accidental policy.

[`decimal`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#decimal) makes the base-10 intent explicit before any arithmetic begins. A
binding can select a decimal arithmetic type, a database tool can select a
fixed-precision decimal column, and a validator can reject a value with too many
fractional digits.

## Why the JSON value is a string

JSON encodes numbers as decimal character sequences. It does not encode them as
IEEE 754 binary64 and does not prescribe an in-memory numeric type. The problem
arises in implementations: JSON parsers commonly materialize a number as a
binary64 `double`. Binary64 is the standard 64-bit floating-point format used
by the `double` type in many languages. It stores a sign, a binary exponent, and
53 bits of significant precision. Because it represents values in base 2,
familiar decimal fractions such as 0.1 and 19.95 usually have no exact binary64
representation. The parser therefore rounds the decimal sequence before a
schema-aware layer sees it. At that point, the exact decimal value and its
original number of digits may already be gone.

Representing a [`decimal`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#decimal) as a JSON string prevents that common parser conversion. A
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

A string plus a pattern can preserve decimal text, but every tool then needs to
recognize the convention. JSON Structure gives that convention a core type name
and standardized annotations.

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
