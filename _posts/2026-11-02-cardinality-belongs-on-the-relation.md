---
layout: post
title: "Cardinality Belongs on the Relation"
date: 2026-11-02
published: false
author: Clemens Vasters
image: /social-cards/cardinality-belongs-on-the-relation.png
description: >-
  Put target type, identity, and single-or-multiple shape on relation
  declarations instead of inferring them from plural names or foreign keys.
---

`orders` sounds like a collection and `customer` sounds singular. A processor
cannot derive an instance shape from either spelling. The relations extension
declares that shape with `cardinality`, next to the `targettype` it qualifies.

## Identity starts with the target type

Every relation names a `targettype`, and that target must declare `identity`.
The identity is an ordered array of property names. One name produces a scalar
relation identity. Several names produce an array in the declared order.

This customer and order book declares both directions and makes each shape
explicit:

```json
{
  "$schema": "https://json-structure.org/meta/relations/v0/#",
  "$id": "https://schemas.example.com/commerce/order-book/v1",
  "$uses": ["JSONStructureRelations"],
  "name": "OrderBookDocument",
  "$root": "#/definitions/OrderBook",
  "definitions": {
    "Customer": {
      "name": "Customer",
      "type": "object",
      "identity": ["customerNumber"],
      "relations": {
        "orders": {
          "targettype": { "$ref": "#/definitions/Order" },
          "cardinality": "multiple",
          "scope": "#/definitions/OrderBook/properties/orders"
        }
      },
      "properties": {
        "customerNumber": { "type": "string" },
        "name": { "type": "string" }
      },
      "required": ["customerNumber", "name"],
      "additionalProperties": false
    },
    "Order": {
      "name": "Order",
      "type": "object",
      "identity": ["orderNumber"],
      "relations": {
        "customer": {
          "targettype": { "$ref": "#/definitions/Customer" },
          "cardinality": "single",
          "scope": "#/definitions/OrderBook/properties/customers"
        }
      },
      "properties": {
        "orderNumber": { "type": "string" },
        "total": { "type": "decimal" }
      },
      "required": ["orderNumber", "total"],
      "additionalProperties": false
    },
    "OrderBook": {
      "name": "OrderBook",
      "type": "object",
      "properties": {
        "customers": {
          "type": "array",
          "items": { "type": { "$ref": "#/definitions/Customer" } }
        },
        "orders": {
          "type": "array",
          "items": { "type": { "$ref": "#/definitions/Order" } }
        }
      },
      "required": ["customers", "orders"],
      "additionalProperties": false
    }
  }
}
```

The instance shape follows the declarations:

```json
{
  "$schema": "https://schemas.example.com/commerce/order-book/v1",
  "customers": [
    {
      "customerNumber": "C-1042",
      "name": "Ada Computing GmbH",
      "orders": [
        { "identity": "O-9001" },
        { "identity": "O-9002" }
      ]
    },
    {
      "customerNumber": "C-2048",
      "name": "Babbage Works Ltd",
      "orders": []
    }
  ],
  "orders": [
    {
      "orderNumber": "O-9001",
      "total": 149.50,
      "customer": { "identity": "C-1042" }
    },
    {
      "orderNumber": "O-9002",
      "total": 87.25,
      "customer": { "identity": "C-1042" }
    }
  ]
}
```

## `single` and `multiple` choose different JSON shapes

`"cardinality": "single"` means exactly one target and uses one relation
object, rather than an array of length one. `"cardinality": "multiple"` means
zero or more targets and uses an array of relation objects. An empty array
states that the relation currently has no targets.

The relation object carries `identity`; it does not embed the target object.
That keeps association separate from containment. For a composite target
identity such as `["catalogNumber", "revision"]`, the value becomes an array
such as `{"identity": ["A-17", 3]}`.

## Relation names are not ordinary properties

Relations are declared under `relations`, not under `properties`, although
they appear as properties in an instance. The two declaration maps share a
namespace, so a type cannot declare both an ordinary property and a relation
named `customer`.

Without the shared namespace, a `customer` property containing an object and a
`customer` relation containing an identity would compete for the same JSON
member.

## Scope completes the reference

`targettype` says what kind of thing is referenced. `identity` says which
values identify one. `scope` says where candidates are found in this document.
The resolver follows the schema pointer to an array, set, or map, then searches
its elements or map values for the matching identity.

Cardinality does not establish uniqueness. The target's identity values must be
unique within the relevant identity scope, and a relations-aware processor must
check that semantic rule. A core validator can verify JSON shape while still
missing a duplicate customer or a dangling order reference. The relation
declares collection shape, the target declares identity, and the scope tells a
resolver where to look. The spelling of `orders` declares none of them.

[relations]: https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html
