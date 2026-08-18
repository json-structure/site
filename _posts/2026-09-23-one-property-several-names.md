---
layout: post
title: "One Property, Several Names"
date: 2026-09-23
published: false
author: Clemens Vasters
image: /social-cards/one-property-several-names.png
description: >-
  Keep one stable property in the schema while mapping it to JSON, database,
  Protobuf-style, and localized names with altnames and descriptions.
---

A property should have one stable identity in a schema, even when every system
around it insists on spelling that identity differently.

JSON likes `customer_id`. A database inherited `CUST_ID`. A Protobuf API uses
`customerId`. A German form should say `Kundennummer`. Renaming the schema
property for each destination would create four schemas for one fact.

The alternate-names extension keeps the schema name separate from those
external names. `altnames` holds identifiers and display labels;
`descriptions` holds localized or purpose-specific explanatory text.

## One name owns the contract

In the schema below, `customerId` is the property name. That is the name used by
`properties` and `required`, and it remains stable as mappings come and go.

```json
{
  "$schema": "https://json-structure.org/meta/extended/v0/#",
  "$id": "https://example.com/schemas/customer-record",
  "name": "CustomerRecordDocument",
  "$uses": ["JSONStructureAlternateNames"],
  "$root": "#/definitions/CustomerRecord",
  "definitions": {
    "CustomerRecord": {
      "name": "CustomerRecord",
      "type": "object",
      "altnames": {
        "json": "customer_record",
        "database": "CUSTOMER",
        "protobuf": "CustomerRecord",
        "lang:de": "Kundendatensatz"
      },
      "descriptions": {
        "lang:en": "A customer record used for order processing.",
        "lang:de": "Ein Kundendatensatz für die Auftragsbearbeitung."
      },
      "properties": {
        "customerId": {
          "type": "string",
          "altnames": {
            "json": "customer_id",
            "database": "CUST_ID",
            "protobuf": "customerId",
            "lang:en": "Customer number",
            "lang:de": "Kundennummer"
          },
          "descriptions": {
            "lang:en": "Stable identifier assigned to the customer.",
            "lang:de": "Dem Kunden zugeordnete stabile Kennung."
          }
        },
        "displayName": {
          "type": "string",
          "altnames": {
            "json": "display_name",
            "database": "DISPLAY_NAME",
            "protobuf": "displayName",
            "lang:en": "Display name",
            "lang:de": "Anzeigename"
          }
        }
      },
      "required": ["customerId", "displayName"],
      "additionalProperties": false
    }
  }
}
```

A JSON-oriented encoder that honors the reserved `json` mapping can emit this
instance:

```json
{
  "$schema": "https://example.com/schemas/customer-record",
  "customer_id": "C-1042",
  "display_name": "Ada Lovelace"
}
```

The database and `protobuf` keys are custom purpose indicators. The draft
permits them, but does not assign them behavior. A generator may interpret
`database` as a column name and `protobuf` as a field or type spelling only when
that convention is part of the toolchain's contract.

## Reserved names are deliberately few

`altnames` is a map of strings. Its keys say why a name exists:

- `json` is reserved for the property key used in JSON encoding.
- `lang:<tag>` is reserved for localized display names. The suffix is an RFC
  5646 language tag.
- Other keys are application-defined purpose indicators.

This is not an aliasing rule for validation. The annotations do not say that an
instance may contain both `customerId` and `customer_id`, nor do they define
precedence if both appear. A supporting encoder or decoder chooses the mapped
representation consistently. A validator that does not support the extension
ignores the annotations.

That limit matters. `altnames` records mappings; it does not invent a universal
name-resolution protocol for databases, IDLs, or user interfaces.

## Names and descriptions do different work

A localized `altnames` entry is short text suitable for a field label. A
localized `descriptions` entry explains the field. A paragraph under
`altnames["lang:de"]` may be syntactically possible, but it is still a
paragraph where a label belongs.

`descriptions` can appear anywhere the ordinary `description` annotation can
appear. Its values are strings keyed by purpose, with `lang:` reserved for
localized variants. It supplements `description`; it does not change the
property's type, required status, or encoded value.

## The schema name stays put

The representations plainly do not share a spelling. They share a schema
property.

Code generators can choose their naming convention. Storage adapters can keep a
legacy column. User interfaces can show a label in the reader's language. The
schema still has one `customerId`; its type and constraints stay there as the
mappings change.

[alternate-names]: https://json-structure.github.io/alternate-names/draft-vasters-json-structure-alternate-names.html
