---
layout: post
title: "Names Have Purposes"
date: 2026-10-28
published: false
author: Clemens Vasters
specification_scope: Core with the Alternate Names and Units companion specifications.
image: /social-cards/names-have-purposes.png
description: >-
  Use altnames purpose keys to map one stable schema property into JSON,
  storage, tooling, and localized contexts without multiplying contracts.
---

Keep one canonical schema name and label each alternate name with its purpose.
A schema property may appear as a JSON key, a SQL column, a generated
identifier, and several labels written for people. Treating all of those names
as aliases loses the reason each name exists. The [`altnames`](https://json-structure.github.io/alternate-names/draft-vasters-json-structure-alternate-names.html#the-altnames-keyword) annotation records
that reason and leaves the property declaration as the canonical name.

## The key says what the name is for

[`altnames`](https://json-structure.github.io/alternate-names/draft-vasters-json-structure-alternate-names.html#the-altnames-keyword) is a map from purpose indicators to strings. A purpose indicator says where or
why a name is used. The draft reserves two
parts of that key space:

- [`json`](https://json-structure.github.io/alternate-names/draft-vasters-json-structure-alternate-names.html#the-altnames-keyword) identifies the property key used when encoding JSON.
- [`lang:<tag>`](https://json-structure.github.io/alternate-names/draft-vasters-json-structure-alternate-names.html#the-altnames-keyword) identifies a localized display name. The suffix must be an RFC
  5646 language tag, such as `en`, `de`, or `fr-CA`.

Every other key is custom. A team may define `sql`, `typescript`, or
`warehouse`, but the draft assigns those purposes no standard behavior.
Processors must agree on their meaning.

Here is one property mapped across those contexts:

```json
{
  "$schema": "https://json-structure.org/meta/extended/v0/#",
  "$id": "https://schemas.example.com/commerce/customer/v1",
  "$uses": ["JSONStructureAlternateNames"],
  "name": "CustomerDocument",
  "$root": "#/definitions/Customer",
  "definitions": {
    "Customer": {
      "name": "Customer",
      "type": "object",
      "properties": {
        "customerNumber": {
          "type": "string",
          "altnames": {
            "json": "customer_number",
            "sql": "CUST_NO",
            "typescript": "customerNumber",
            "warehouse": "customer_key",
            "lang:en": "Customer number",
            "lang:de": "Kundennummer"
          }
        },
        "legalName": {
          "type": "string",
          "altnames": {
            "json": "legal_name",
            "sql": "LEGAL_NAME",
            "typescript": "legalName",
            "lang:en": "Legal name",
            "lang:de": "Rechtlicher Name"
          }
        }
      },
      "required": ["customerNumber", "legalName"],
      "additionalProperties": false
    }
  }
}
```

An extension-aware JSON encoder can emit the reserved JSON names:

```json
{
  "$schema": "https://schemas.example.com/commerce/customer/v1",
  "customer_number": "C-1042",
  "legal_name": "Ada Computing GmbH"
}
```

This does not make `CUST_NO` or `Kundennummer` accepted JSON keys. One is a
custom storage mapping; the other is display text. Each name applies only to
its stated purpose.

## Canonical identity stays in the schema

Within the schema, [`properties`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#properties-keyword) and [`required`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#required-keyword) still use `customerNumber`.
References to the schema use the stable [`$id`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#id-keyword), not an alternate type or
property name. A database migration can change `CUST_NO`, a generator can
change its casing rules, and a translator can edit `Kundennummer` without
renaming the schema property or minting a new schema identity. An alternate
name may remain stable for one integration without becoming the identifier of
the schema element.

## Collisions are a processor problem

The map shape prevents two entries with the same purpose key on one element.
It does not prevent two properties from both declaring
`"sql": "CUST_NO"`, or a JSON alternate from colliding with another emitted
key. Such a schema is syntactically expressible and operationally ambiguous.

My recommendation is to build the complete name table for a purpose before a
mapper generates
output. If two canonical properties map to one destination name, the mapper
should report the collision rather than choose by document order. Schemas that
cross team boundaries also need an organizational convention for custom
purposes. A generic processor cannot know whether `db`, `sql`, and `database`
mean the same thing.

## The extension name has one authoritative spelling

The repository meta-schema offers [`JSONStructureAlternateNames`](https://json-structure.github.io/alternate-names/draft-vasters-json-structure-alternate-names.html#enabling-the-annotations), which is the
value used above. The draft's enabling prose once says
[`JSONSchemaAlternateNames`](https://json-structure.github.io/alternate-names/draft-vasters-json-structure-alternate-names.html#enabling-the-annotations), while its adjacent example says
[`JSONStructureAlternateNames`](https://json-structure.github.io/alternate-names/draft-vasters-json-structure-alternate-names.html#enabling-the-annotations). That is an inconsistency, not an alias. Current
schemas should follow the offered key in the meta-schema.

Do not confuse [`altnames`](https://json-structure.github.io/alternate-names/draft-vasters-json-structure-alternate-names.html#the-altnames-keyword) with [`altenums`](https://json-structure.github.io/alternate-names/draft-vasters-json-structure-alternate-names.html#the-altenums-keyword) or [`symbol`](https://json-structure.github.io/units/draft-vasters-json-structure-units.html#symbol-keyword). [`altenums`](https://json-structure.github.io/alternate-names/draft-vasters-json-structure-alternate-names.html#the-altenums-keyword) maps members
of an enumeration, while unit symbols annotate the presentation of measured
values. Neither supplies another name for a property.

[alternate-names]: https://json-structure.github.io/alternate-names/draft-vasters-json-structure-alternate-names.html
