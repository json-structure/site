---
layout: post
title: "When Properties Travel Together"
date: 2026-10-16
published: false
author: Clemens Vasters
specification_scope: Core with the Validation companion specification.
image: /social-cards/when-properties-travel-together.png
description: >-
  Use dependentRequired when one property's presence requires companion fields,
  and core required when fields are mandatory for every object.
---

Some properties are optional alone but mandatory in company. An order can omit
invoice details entirely. Once `invoiceRequested` appears, however, the billing
address must travel with it.

Core [`required`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#required-keyword) names properties that every instance must contain. The
validation extension's [`dependentRequired`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#dependentRequired) handles the companion rule: one
property's presence makes others mandatory.

## Two different presence rules

The schema always requires `orderId` and `total`. It conditionally
requires the four billing fields when `invoiceRequested` occurs:

```json
{
  "$schema": "https://json-structure.org/meta/validation/v0/#",
  "$id": "https://schemas.example.com/invoice-order",
  "name": "InvoiceOrder",
  "type": "object",
  "properties": {
    "orderId": { "type": "uuid" },
    "total": { "type": "decimal" },
    "invoiceRequested": { "type": "boolean" },
    "billingStreet": { "type": "string" },
    "billingCity": { "type": "string" },
    "billingPostalCode": { "type": "string" },
    "billingCountry": { "type": "string" }
  },
  "required": ["orderId", "total"],
  "dependentRequired": {
    "invoiceRequested": [
      "billingStreet",
      "billingCity",
      "billingPostalCode",
      "billingCountry"
    ]
  },
  "additionalProperties": false
}
```

An invoiced order therefore looks like this:

```json
{
  "orderId": "c4f1328a-9f3c-4be0-945e-17a12bb3dde8",
  "total": "129.50",
  "invoiceRequested": true,
  "billingStreet": "1 Analytical Engine Way",
  "billingCity": "London",
  "billingPostalCode": "SW1A 1AA",
  "billingCountry": "GB"
}
```

Without `invoiceRequested`, the billing fields remain optional. With it, all
four must occur. [`required`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#required-keyword) still applies independently, so `orderId` and
`total` never become optional.

## Presence means presence

The trigger is the existence of the property, not its truthiness. This instance
is invalid:

```json
{
  "orderId": "4bb4f178-597c-47c6-b09a-dbe0bec9a17b",
  "total": "42.00",
  "invoiceRequested": false
}
```

`invoiceRequested` is present, so the dependency fires even though its value is
`false`. The same would hold for [`null`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#null) if the property's type admitted null.
[`dependentRequired`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#dependentRequired) does not inspect the trigger value.

If the business rule is "require billing fields only when the value is true,"
use [`if`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#if-then-else)/[`then`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#if-then-else) from conditional composition, with a value constraint in [`if`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#if-then-else).
Alternatively, omit `invoiceRequested` when no invoice is requested. Presence
and Boolean state are different signals; do not ask one keyword to guess which
signal you intended.

Dependencies are also one-way. The schema above does not require
`invoiceRequested` when `billingStreet` appears. Add a reverse dependency if
that is part of the contract. A dependency on every billing field repeats the
same rule; an explicit billing object avoids that repetition.

## Why [`required`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#required-keyword) cannot express this

Adding the billing fields to the flat [`required`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#required-keyword) array would require them on
every order. Putting alternatives into core's nested [`required`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#required-keyword) form would mean
exactly one property set must match. Neither expresses a one-way implication.

Readers coming from JSON Schema will recognize the keyword and its basic
presence semantics. JSON Structure puts ordinary requiredness in core because
it defines object shape; cross-property dependency remains validation policy.

## The draft is ahead of the meta-schema

The validation draft calls its feature [`JSONSchemaValidation`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#enabling-the-extensions), while the
repository offers [`JSONStructureValidation`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#enabling-the-extensions). The dedicated validation
meta-schema enables the repository name, which is why the example references
that meta-schema directly.

The current `meta/extended/v0/index.json` validation add-in also omits
[`dependentRequired`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#dependentRequired). A processor implementing the draft can evaluate the
schema, but the checked-in meta-schema may reject the keyword before instance
validation begins. The presence rule itself is unambiguous; the repository
artifact needs to catch up.
