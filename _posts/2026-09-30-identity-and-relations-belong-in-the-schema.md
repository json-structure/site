---
layout: post
title: "Identity and Relations Belong in the Schema"
date: 2026-09-30
published: false
author: Clemens Vasters
image: /social-cards/identity-and-relations-belong-in-the-schema.png
description: >-
  Declare object identity and typed relations with target types, cardinality,
  and scope instead of leaving foreign-key meaning in property names.
---

A property named `customerId` tells a story, but the schema cannot verify the
plot.

The string might identify a customer, an account, or a CRM import row. It might
be unique in this document, unique in a database, or not unique at all. The name
suggests a foreign key while leaving its target and resolution rules in prose.

The relations extension gives the schema vocabulary for those rules:
`identity`, `relations`, `targettype`, `cardinality`, and `scope`.

## Identity starts at the target

An identity belongs to an object or tuple type. Its value is an ordered array of
property names. One property gives a simple identity; several give a composite
identity.

The complete example below declares `Customer.id` as the customer identity and
`Order.id` as the order identity. The `customer` relation on `Order` targets
`Customer` and resolves within the document's `customers` collection.

```json
{
  "$schema": "https://json-structure.org/meta/extended/v0/#",
  "$id": "https://example.com/schemas/commerce-document",
  "name": "CommerceDocumentSchema",
  "$root": "#/definitions/CommerceDocument",
  "definitions": {
    "Customer": {
      "name": "Customer",
      "type": "object",
      "properties": {
        "id": { "type": "string" },
        "name": { "type": "string" }
      },
      "required": ["id", "name"],
      "additionalProperties": false,
      "identity": ["id"]
    },
    "Order": {
      "name": "Order",
      "type": "object",
      "properties": {
        "id": { "type": "string" },
        "total": { "type": "decimal" }
      },
      "relations": {
        "customer": {
          "targettype": { "$ref": "#/definitions/Customer" },
          "cardinality": "single",
          "scope": "#/definitions/CommerceDocument/properties/customers"
        }
      },
      "required": ["id", "total"],
      "additionalProperties": false,
      "identity": ["id"]
    },
    "CommerceDocument": {
      "name": "CommerceDocument",
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

A corresponding document contains the relation as an ordinary JSON property:

```json
{
  "$schema": "https://example.com/schemas/commerce-document",
  "customers": [
    { "id": "C-1042", "name": "Ada Lovelace" }
  ],
  "orders": [
    {
      "id": "O-9001",
      "total": 149.50,
      "customer": { "identity": "C-1042" }
    }
  ]
}
```

The familiar conceptual link `Order.customerId -> Customer.id` is present, but
it is not modeled as a bare `customerId` property. The draft gives relation
instances their own shape. A single relation is an object whose `identity`
member matches the target type's identity.

## Target and cardinality are explicit

Every relation declaration requires `targettype` and `cardinality`.

`targettype` is a schema containing a `$ref` to a type with an `identity`
declaration. That rule prevents a relation from pointing vaguely at an object
shape that has no declared matching key.

`cardinality` is either `single` or `multiple`. `single` means exactly one
target instance and is represented by one relation object. `multiple` means zero
or more targets and is represented by an array of relation objects.

Cardinality is not inferred from an English plural or a property name. The
schema says it.

## Scope says where to look

`scope` is a JSON Pointer, or an array of JSON Pointers, to schema locations for
collections in the same document. A target collection must be an `array`,
`set`, or `map` compatible with `targettype`. Map resolution searches values,
not keys.

In the example, the resolver follows
`#/definitions/CommerceDocument/properties/customers`, then finds the customer
whose declared identity equals `C-1042`.

Omit `scope` and the meaning changes: the target exists outside the document.
The application must resolve it through an external database, service, or other
source. The absence of `scope` is therefore not shorthand for “search
everywhere in this JSON document.”

## Composite identities preserve order

If a target declares `"identity": ["isbn", "edition"]`, a relation instance
uses an array in that same order:

```json
{ "identity": ["978-0-123456-78-9", 2] }
```

That order is part of the contract. It is the relation equivalent of a composite
primary key.

## The declaration has limits

The declaration makes identity and reference intent machine-readable. It says
which properties form identity, which type is targeted, how many targets exist,
and where in-document resolution starts.

It does not prescribe an external query protocol. Nor does a core-only
validator necessarily enforce uniqueness across a collection or dereference an
external service. A relations-aware processor has to perform those semantic
checks.

That leaves less room for wishful readings of `customerId`. The relation is no
longer hidden in a string property's spelling; its declaration records the
target, cardinality, and scope.

[relations]: https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html
