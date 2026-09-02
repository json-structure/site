---
layout: post
title: "Using the unit and ucumUnit Keywords Together"
display_title: "Using the [`unit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#unit-keyword) and [`ucumUnit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#ucum-unit-keyword) Keywords Together"
date: 2026-10-30
published: false
author: Clemens Vasters
specification_scope: Core with the Units companion specification.
image: /social-cards/using-unit-and-ucumunit-together.png
description: >-
  Use `unit` for readable notation and `ucumUnit` for the case-sensitive UCUM
  expression used in computation and conversion.
---

Use [`unit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#unit-keyword) for readable notation and
[`ucumUnit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#ucum-unit-keyword) for computation. A label such as `°C` is useful to a reader, but
it is not the case-sensitive UCUM code for Celsius. Treating display notation
as computational syntax makes case, prefixes, typography, and composition
rules depend on guesswork.

The two annotations separate those jobs. [`unit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#unit-keyword) carries notation for recognition and display;
[`ucumUnit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#ucum-unit-keyword) carries a case-sensitive UCUM expression for computation and conversion. A
schema may include either keyword. When it includes both, the values must denote
the same physical quantity and unit.

## One pressure, two compatible notations

Consider a compressor that reports discharge pressure in kilopascals:

```json
{
  "$schema": "https://json-structure.org/meta/extended/v0/#",
  "$id": "https://schemas.example.com/telemetry/compressor-pressure/v1",
  "$uses": ["JSONStructureUnits"],
  "name": "CompressorPressureDocument",
  "$root": "#/definitions/CompressorPressure",
  "definitions": {
    "CompressorPressure": {
      "name": "CompressorPressure",
      "type": "object",
      "properties": {
        "compressorId": {
          "type": "string"
        },
        "measuredAt": {
          "type": "datetime"
        },
        "dischargePressure": {
          "type": "double",
          "unit": "kPa",
          "ucumUnit": "kPa"
        }
      },
      "required": ["compressorId", "measuredAt", "dischargePressure"],
      "additionalProperties": false
    }
  }
}
```

The instance contains only the value:

```json
{
  "$schema": "https://schemas.example.com/telemetry/compressor-pressure/v1",
  "compressorId": "CMP-17",
  "measuredAt": "2026-11-13T09:42:18Z",
  "dischargePressure": 742.6
}
```

Here the two strings happen to be identical. A user interface may put `kPa`
beside `742.6`, while a UCUM-aware processor can normalize the value to
pascals, compare it with a limit expressed in bar, or reject an attempt to add
it to an energy quantity.

The distinction becomes visible with Celsius: the draft shows `°C` for [`unit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#unit-keyword)
and `Cel` for case-sensitive UCUM. Typography and computational syntax need not
look alike to remain compatible.

## Prefixes are part of the expression

There is no `prefix` keyword. In `kPa`, lowercase `k` is the kilo prefix and
scales pascals by 10<sup>3</sup>. In `mPa`, lowercase `m` means milli and scales them by
10<sup>&minus;3</sup>. `MPa` uses uppercase `M` for mega. For the same numeric value, `kPa` denotes one million times the pressure
denoted by `mPa`. `MPa` denotes one billion times the pressure denoted by
`mPa`.

UCUM requires its case-sensitive variant, so case changes the expression's
meaning. A processor must not lowercase a code, title-case it, replace `u` with
a visually similar character, or otherwise apply identifier formatting rules.
For example, UCUM uses `u` for the micro prefix in machine expressions, while a
display-oriented unit or symbol may use `μ`.

The same rule applies to composition. The draft's [`unit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#unit-keyword) syntax writes
multiplication with `*`, division with `/`, and exponentiation with `^`, such
as `m/s^2`. Its UCUM example writes acceleration as `m/s2`. A processor should
parse each notation according to its own grammar, not transform one with a few
string replacements because the two grammars have different semantics.

## Processors use the annotations differently

When both annotations appear, the draft says UCUM-aware systems should prefer
[`ucumUnit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#ucum-unit-keyword) for computation and conversion. They may still use [`unit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#unit-keyword) for
display. The presence of both annotations is not grounds for rejection.

Both annotations still have to agree. [`"unit": "kPa"`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#unit-keyword) beside
[`"ucumUnit": "bar"`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#ucum-unit-keyword) describes two convertible units, but not the same unit,
and violates the draft's compatibility expectation. The ability to convert
between them does not repair the declaration.

A processor that understands only [`unit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#unit-keyword) can still interpret or display the
annotation according to the named scientific-unit standards. A processor that
understands neither keyword ignores them as annotations. Neither keyword
changes the JSON number on the wire or silently converts an instance.

## The checked-in meta-schema lags the draft

The repository's extended meta-schema offers the feature name
[`JSONStructureUnits`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#enabling-the-annotations), despite the units draft's enabling section and example
using [`JSONSchemaUnits`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#enabling-the-annotations). The offered meta-schema key is the spelling used above.

The current units draft also defines [`ucumUnit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#ucum-unit-keyword), while the checked-in extended
meta-schema exposes only [`unit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#unit-keyword) for the units add-ins. The schema example is
valid JSON and follows the draft, but strict validation against that repository
meta-schema may reject [`ucumUnit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#ucum-unit-keyword) until the meta-schema catches up. The example
keeps the keyword because removing it would conceal the mismatch and erase the
machine-readable unit expression under discussion.

[`symbol`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#symbol-keyword), [`symbols`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#symbols-keyword), and alternate enum representations are separate features.
A pleasant glyph can label a value. Only the unit annotations say what physical
unit the number carries.

[units]: https://json-structure.github.io/units/draft-vasters-json-structure-units.html
