---
layout: post
title: "Enums Need Translation Too"
date: 2026-09-25
published: false
author: Clemens Vasters
image: /social-cards/enums-need-translation-too.png
description: >-
  Keep enum values stable while mapping them to external codes and localized
  labels with altenums, without changing the underlying contract.
---

An enum value is an identifier, not finished user-interface text.

`PENDING_PAYMENT` may be a good stable value in a schema. It is a poor label on
a German invoice, and a legacy API may insist on the code `P`. Replacing the
enum value for either consumer would make presentation and transport choices
part of the type's identity.

The alternate-names extension uses [`altenums`](https://json-structure.github.io/alternate-names/draft-vasters-json-structure-alternate-names.html#the-altenums-keyword) to keep that distinction in the
schema. The [`enum`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#enum-keyword) array holds the canonical values. Purpose maps attach
external or localized representations to them.

## Keep the values boring and stable

Here is a complete schema for an order status record:

```json
{
  "$schema": "https://json-structure.org/meta/extended/v0/#",
  "$id": "https://example.com/schemas/order-status",
  "name": "OrderStatusDocument",
  "$uses": ["JSONStructureAlternateNames"],
  "$root": "#/definitions/OrderStatusRecord",
  "definitions": {
    "OrderStatus": {
      "name": "OrderStatus",
      "type": "string",
      "enum": [
        "PENDING_PAYMENT",
        "PAID",
        "SHIPPED",
        "CANCELLED"
      ],
      "altenums": {
        "json": {
          "PENDING_PAYMENT": "P",
          "PAID": "D",
          "SHIPPED": "S",
          "CANCELLED": "X"
        },
        "erp": {
          "PENDING_PAYMENT": "10",
          "PAID": "20",
          "SHIPPED": "30",
          "CANCELLED": "90"
        },
        "lang:en": {
          "PENDING_PAYMENT": "Pending payment",
          "PAID": "Paid",
          "SHIPPED": "Shipped",
          "CANCELLED": "Cancelled"
        },
        "lang:de": {
          "PENDING_PAYMENT": "Zahlung ausstehend",
          "PAID": "Bezahlt",
          "SHIPPED": "Versandt",
          "CANCELLED": "Storniert"
        }
      }
    },
    "OrderStatusRecord": {
      "name": "OrderStatusRecord",
      "type": "object",
      "properties": {
        "orderId": { "type": "string" },
        "status": {
          "type": { "$ref": "#/definitions/OrderStatus" }
        }
      },
      "required": ["orderId", "status"],
      "additionalProperties": false
    }
  }
}
```

A JSON encoder that supports the reserved `json` purpose can represent the
canonical value `SHIPPED` as `S`:

```json
{
  "$schema": "https://example.com/schemas/order-status",
  "orderId": "O-2026-1042",
  "status": "S"
}
```

That encoded instance depends on an extension-aware processor applying the
mapping. The core [`enum`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#enum-keyword) still contains `SHIPPED`, not `S`. A processor that
ignores [`altenums`](https://json-structure.github.io/alternate-names/draft-vasters-json-structure-alternate-names.html#the-altenums-keyword) sees only the canonical contract and must not be expected to
validate the mapped representation as though the mapping did not exist.

## The map has two levels

The first level names a purpose. The second maps every canonical enum value to
its alternate representation:

```json
{
  "lang:de": {
    "PENDING_PAYMENT": "Zahlung ausstehend",
    "PAID": "Bezahlt",
    "SHIPPED": "Versandt",
    "CANCELLED": "Storniert"
  }
}
```

`json` is reserved for JSON encoding. Keys beginning with `lang:` are reserved
for localized alternatives. Their suffixes are language tags. Other keys, such
as `erp`, are permitted custom purposes, but the draft assigns no standard
behavior to them.

This arrangement avoids translating the wire value itself. The user may see
`Versandt`, while business logic continues to compare `SHIPPED`. Editors can
change the translation without changing the schema contract.

## These are not unit symbols

The draft calls the mapped values alternate representations or symbols. That
does not make [`altenums`](https://json-structure.github.io/alternate-names/draft-vasters-json-structure-alternate-names.html#the-altenums-keyword) the same feature as the units extension's [`symbol`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#symbol-keyword) and
[`symbols`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#symbols-keyword) keywords.

[`altenums`](https://json-structure.github.io/alternate-names/draft-vasters-json-structure-alternate-names.html#the-altenums-keyword) maps individual members of an [`enum`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#enum-keyword). The units annotations attach a
presentation symbol such as `€` or `°C` to a schema element and may accompany a
number. They have different placement, shape, and purpose. An order status does
not acquire a [`symbol`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#symbol-keyword) annotation merely because one external system encodes it
as `S`.

## Policy stays outside the map

[`altenums`](https://json-structure.github.io/alternate-names/draft-vasters-json-structure-alternate-names.html#the-altenums-keyword) does not select a locale or negotiate one. It does not define fallback
from `lang:de-CH` to `lang:de`. It does not say whether an ERP adapter is allowed
to accept both `30` and `SHIPPED`. Those are processor and application policies.

Nor does it turn labels into identities. Localized text can change for editorial
reasons. Canonical enum values should change only when the contract changes.

One enum can serve a UI and several external systems without giving any of them
ownership of its canonical values.

[alternate-names]: https://json-structure.github.io/alternate-names/draft-vasters-json-structure-alternate-names.html
