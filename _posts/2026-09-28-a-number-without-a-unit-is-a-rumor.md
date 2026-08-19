---
layout: post
title: "A Number Without a Unit Is a Rumor"
date: 2026-09-28
published: false
author: Clemens Vasters
image: /social-cards/a-number-without-a-unit-is-a-rumor.png
description: >-
  Attach scientific units, UCUM codes, display symbols, SI prefixes, and
  currencies to numeric schemas so values can be interpreted correctly.
---

A number without a unit is not a measurement. It is a rumor about a
measurement.

`22.5` may be a comfortable room temperature in degrees Celsius, a pressure in
kilopascals, or an amount in euros. The JSON number carries none of that. A
numeric type and range can reject malformed values while still accepting a
perfectly formed misunderstanding.

The units extension supplies that missing contract through [`unit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#unit-keyword), [`ucumUnit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#ucum-unit-keyword),
[`symbol`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#symbol-keyword), [`symbols`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#symbols-keyword), and [`currency`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#currency-keyword).

## The JSON type is not the quantity

This schema describes a commercial refrigeration reading. Temperature and
pressure are physical quantities. Replacement cost is money. They therefore use
different annotations even though all three values are JSON numbers.

```json
{
  "$schema": "https://json-structure.org/meta/extended/v0/#",
  "$id": "https://example.com/schemas/refrigeration-reading",
  "name": "RefrigerationReadingDocument",
  "$uses": ["JSONStructureUnits"],
  "$root": "#/definitions/RefrigerationReading",
  "definitions": {
    "RefrigerationReading": {
      "name": "RefrigerationReading",
      "type": "object",
      "properties": {
        "measuredAt": { "type": "datetime" },
        "temperature": {
          "type": "double",
          "unit": "°C",
          "ucumUnit": "Cel",
          "symbol": "°C"
        },
        "linePressure": {
          "type": "double",
          "unit": "kPa",
          "ucumUnit": "kPa",
          "symbol": "kPa"
        },
        "replacementCost": {
          "type": "decimal",
          "currency": "EUR",
          "symbol": "€"
        }
      },
      "required": [
        "measuredAt",
        "temperature",
        "linePressure",
        "replacementCost"
      ],
      "additionalProperties": false
    }
  }
}
```

A useful instance is pleasantly uneventful:

```json
{
  "$schema": "https://example.com/schemas/refrigeration-reading",
  "measuredAt": "2026-10-22T08:15:00Z",
  "temperature": 4.2,
  "linePressure": 245.0,
  "replacementCost": 1899.50
}
```

The instance stays compact. Its schema says that `4.2` is degrees Celsius,
`245.0` is kilopascals, and `1899.50` is euros. A consumer no longer has to
infer units from property names or documentation parked elsewhere.

## [`unit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#unit-keyword) and [`ucumUnit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#ucum-unit-keyword) overlap on purpose

[`unit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#unit-keyword) carries a scientific unit symbol drawn from the standards named by the
draft. Derived SI units use `*` for multiplication, `/` for division, and `^`
for exponentiation; acceleration, for example, is `m/s^2`.

[`ucumUnit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#ucum-unit-keyword) carries a case-sensitive UCUM expression. UCUM supports computation
and conversion rather than display alone. A schema may include both annotations.
When it does, they should denote the same physical quantity and unit, and a
system that supports UCUM should prefer [`ucumUnit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#ucum-unit-keyword) for conversion.

That is why Celsius appears as `°C` under [`unit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#unit-keyword) and `Cel` under [`ucumUnit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#ucum-unit-keyword).
They are two notations for the same unit, serving different consumers. A
validator must not reject a schema merely because both are present.

## Prefixes are syntax, not another keyword

The extension lists SI prefixes such as kilo (`k`), milli (`m`), micro (`μ`),
and mega (`M`). It does not define a `prefix` annotation.

The prefix is part of the unit expression. `kPa` means kilopascals; `mPa` means
millipascals. Case matters, and so does position. Splitting `k` into separate
metadata would create a second place that could contradict the unit string.

Prefixes scale units. They do not scale currencies, enum labels, or arbitrary
numbers.

## A symbol is for presentation

[`symbol`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#symbol-keyword) annotates how a value may be presented. It may accompany [`unit`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#unit-keyword) or
[`currency`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#currency-keyword), or appear independently. [`symbols`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#symbols-keyword) is the multi-purpose form and
reserves `lang:` keys for language-specific variants.

A symbol is not the machine meaning of a measurement. The euro sign is useful
on a screen, while `EUR` is the ISO 4217-style currency code a processor can act
on. Likewise, a typographically pleasant `m/s²` can be a display symbol while
`m/s^2` or its UCUM counterpart carries the computational notation.

The distinction prevents typography from becoming conversion logic.

## Annotations do not perform conversions

These keywords annotate numeric schemas. They do not change the JSON value,
select a conversion target, define exchange rates, or prescribe rounding.
Applications that support the extension can interpret, convert, and display the
values. Validators that do not support it ignore the annotations.

The schema says what the number means. The application decides what to do with
it.

[units]: https://json-structure.github.io/units/draft-vasters-json-structure-units.html
