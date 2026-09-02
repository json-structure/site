---
layout: post
title: "Definitions Are a Type Library"
date: 2026-09-16
published: false
author: Clemens Vasters
specification_scope: Core only.
image: /social-cards/definitions-are-a-type-library.png
description: >-
  Use definitions as a case-sensitive namespace hierarchy for reusable types,
  including types that share a local name but not a meaning.
---

How many types called `Address` can one schema contain? As many as the model
needs, provided they live in different namespaces.

JSON Structure's [`definitions`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#definitions-keyword) is a case-sensitive type library. An order can
have both `Billing/Address` and `Shipping/Address`, without inventing flattened
names merely to satisfy a global registry.

## Namespaces are JSON objects

Every type directly under [`definitions`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#definitions-keyword) belongs to the root namespace. Any
object there that does not declare [`type`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#type-keyword) is a namespace, and namespaces may
contain types or further namespaces.

Here is an order schema with two `Address` definitions:

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://schemas.example.com/order.json",
  "$root": "#/definitions/Commerce/Order",
  "definitions": {
    "Billing": {
      "Address": {
        "type": "object",
        "properties": {
          "accountName": { "type": "string" },
          "street": { "type": "string" },
          "city": { "type": "string" },
          "countryCode": { "type": "string" }
        },
        "required": ["accountName", "street", "city", "countryCode"]
      }
    },
    "Shipping": {
      "Address": {
        "type": "object",
        "properties": {
          "recipientName": { "type": "string" },
          "street": { "type": "string" },
          "city": { "type": "string" },
          "deliveryZone": { "type": "string" }
        },
        "required": ["recipientName", "street", "city"]
      }
    },
    "Commerce": {
      "Order": {
        "type": "object",
        "properties": {
          "orderId": { "type": "uuid" },
          "billingAddress": {
            "type": { "$ref": "#/definitions/Billing/Address" }
          },
          "shippingAddress": {
            "type": { "$ref": "#/definitions/Shipping/Address" }
          }
        },
        "required": ["orderId", "billingAddress", "shippingAddress"]
      }
    }
  }
}
```

`Billing/Address` and `Shipping/Address` are distinct reusable types. Names such
as `BillingAddressType` would only flatten information the namespace already
expresses.

The [`$root`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#root-keyword) pointer also traverses the namespace hierarchy. It designates
`Commerce/Order` as the type of instances governed by this schema document.

## Referring to a library type

JSON Structure uses [`$ref`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#ref-keyword) for reusable types in the same schema document. The
value of [`type`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#type-keyword) is an object whose only property is
[`$ref`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#ref-keyword):

```json
{
  "shippingAddress": {
    "type": { "$ref": "#/definitions/Shipping/Address" }
  }
}
```

The pointer must resolve to an existing type declaration. [`$ref`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#ref-keyword) neither
overlays arbitrary schema keywords nor fetches another document. The
[import extension](https://json-structure.github.io/import/draft-vasters-json-structure-import.html)
handles external composition; once processed, imported types appear locally
under [`definitions`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#definitions-keyword).

This placement differs from JSON Schema habits. Writing [`$ref`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#ref-keyword) next to
[`properties`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#properties-keyword), or using it as the property schema without the surrounding
[`type`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#type-keyword), is not JSON Structure syntax.

## Names are case-sensitive

Each declaration must have a unique, case-sensitive name within its namespace.
The same name may appear in different namespaces, as the two `Address` types do.

Case sensitivity applies to every path segment. These pointers do not identify
the same type:

```text
#/definitions/Shipping/Address
#/definitions/shipping/Address
#/definitions/Shipping/address
```

Only the first exists in the example. A registry, generator, or target language
that folds case can collapse types the schema keeps distinct. Such a tool needs
an explicit collision policy that defines how case-folded names are
disambiguated.

Identifiers are constrained as well: property and type names begin with a
letter or underscore and continue with letters, digits, or underscores. A
namespace is represented by nested JSON objects, not by putting dots or slashes
inside an identifier.

## What belongs in the library

Reusable types must be declared under [`definitions`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#definitions-keyword). An inline object inside a
property, array, map, or union can describe local structure, but another part of
the document cannot reference it as a library type.

My rule is to give stable domain concepts names and pointers. One-off structure can remain
at its point of use. When a property says
`#/definitions/Shipping/Address`, nobody has to recover the intended meaning
from `Address2`, a generator convention, or surrounding prose.
