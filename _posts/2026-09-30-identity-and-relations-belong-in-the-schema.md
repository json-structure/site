---
layout: post
title: "Identity and Relations Belong in the Schema"
date: 2026-09-30
published: false
author: Clemens Vasters
specification_scope: Core with the Relations companion specification.
image: /social-cards/identity-and-relations-belong-in-the-schema.png
description: >-
  Declare object identity and typed relations with target types, cardinality,
  and scope instead of leaving foreign-key meaning in property names.
---

A property named `customerId` suggests a relation but does not declare its
target or resolution rules.

The string might identify a customer, an account, or a CRM import row. It might
be unique in this document, unique in a database, or not unique at all. The name
suggests a foreign key while leaving its target and resolution rules in prose.

The relations extension gives the schema vocabulary for those rules:
[`identity`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#identity-keyword), [`relations`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#relations-keyword), [`targettype`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#targettype-keyword), [`cardinality`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#cardinality-keyword), and [`scope`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#scope-keyword).

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
      "total": "149.50",
      "customer": { "identity": "C-1042" }
    }
  ]
}
```

The familiar conceptual link `Order.customerId -> Customer.id` is present, but
it is not modeled as a bare `customerId` property. The draft gives relation
instances their own shape. A single relation is an object whose [`identity`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#identity-keyword)
member matches the target type's identity.

## Target and cardinality are explicit

Every relation declaration requires [`targettype`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#targettype-keyword) and [`cardinality`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#cardinality-keyword).

[`targettype`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#targettype-keyword) is a schema containing a [`$ref`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#ref-keyword) to a type with an [`identity`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#identity-keyword)
declaration. That rule prevents a relation from pointing vaguely at an object
shape that has no declared matching key.

[`cardinality`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#cardinality-keyword) is either [`single`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#cardinality-keyword) or [`multiple`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#cardinality-keyword). [`single`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#cardinality-keyword) means exactly one
target instance and is represented by one relation object. [`multiple`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#cardinality-keyword) means zero
or more targets and is represented by an array of relation objects.

Cardinality is not inferred from an English plural or a property name. The
schema says it.

## Scope says where to look

[`scope`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#scope-keyword) is a JSON Pointer, or an array of JSON Pointers, to schema locations for
collections in the same document. A target collection must be an [`array`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#array),
[`set`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#set), or [`map`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#map) compatible with [`targettype`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#targettype-keyword). Map resolution searches values,
not keys.

In the example, the resolver follows
`#/definitions/CommerceDocument/properties/customers`, then finds the customer
whose declared identity equals `C-1042`.

Omit [`scope`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#scope-keyword) and the meaning changes: the target exists outside the document.
The application must resolve it through an external database, service, or other
source. The absence of [`scope`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#scope-keyword) is therefore not shorthand for “search
everywhere in this JSON document.”

## Composite identities preserve order

If a target declares [`"identity": ["isbn", "edition"]`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#identity-keyword), a relation instance
uses an array in that same order:

```json
{ "identity": ["978-0-123456-78-9", 2] }
```

That order is part of the contract. It is the relation equivalent of a composite
primary key.

## Resolution remains a processor task

`identity` and `relations` make reference intent machine-readable, but they do
not prescribe an external query protocol. A core-only validator need not
enforce uniqueness across a collection or dereference an external service. A
relations-aware processor must perform those checks.

[relations]: https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html
