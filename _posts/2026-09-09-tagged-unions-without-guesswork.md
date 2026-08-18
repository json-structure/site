---
layout: post
title: "Tagged Unions Without Guesswork"
date: 2026-09-09
published: false
author: Clemens Vasters
image: /social-cards/tagged-unions-without-guesswork.png
description: >-
  A JSON Structure tagged choice puts the selected payment method in the one
  property name that wraps its value. Consumers never infer a variant by shape.
---

A union should tell you which branch it contains. Otherwise a consumer must
inspect fields, try branches in order, or hope two variants never grow into the
same shape. None of those guesses belongs in a wire contract.

JSON Structure's tagged `choice` uses a one-property JSON object. The property
name is the tag; its value is the selected variant. Selection is explicit before
a consumer reads the variant's fields.

## A payment method choice

Here is a complete schema for card and bank-transfer payment methods:

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://example.com/schemas/payment-method",
  "name": "PaymentMethod",
  "type": "choice",
  "choices": {
    "card": {
      "type": { "$ref": "#/definitions/CardPayment" }
    },
    "bankTransfer": {
      "type": { "$ref": "#/definitions/BankTransferPayment" }
    }
  },
  "definitions": {
    "CardPayment": {
      "name": "CardPayment",
      "type": "object",
      "properties": {
        "network": { "type": "string" },
        "lastFour": { "type": "string" },
        "token": { "type": "string" }
      },
      "required": ["network", "lastFour", "token"],
      "additionalProperties": false
    },
    "BankTransferPayment": {
      "name": "BankTransferPayment",
      "type": "object",
      "properties": {
        "accountHolder": { "type": "string" },
        "iban": { "type": "string" }
      },
      "required": ["accountHolder", "iban"],
      "additionalProperties": false
    }
  }
}
```

A card instance is wrapped by the `card` tag:

```json
{
  "card": {
    "network": "visa",
    "lastFour": "4242",
    "token": "tok_7d91"
  }
}
```

A bank transfer uses the other property name:

```json
{
  "bankTransfer": {
    "accountHolder": "Ada Lovelace",
    "iban": "DE89370400440532013000"
  }
}
```

The keys of `choices` are the selectors. There is no separate `type`, `kind`, or
`method` field in a tagged choice. The wrapper object must have one property,
and that property's name selects the corresponding schema.

An object containing both `card` and `bankTransfer` is not two choices at once;
it is invalid. So is `{"cash": {}}`, because `cash` is not a declared choice.
The consumer dispatches on one key and validates one value.

## Tags survive schema evolution

The tag separates branch selection from the incidental shape of each variant.

Imagine that bank transfers later gain a `token` issued by a payment provider.
A shape-inferred union may now confuse the branches, depending on its matching
rules. `bankTransfer` still selects `BankTransferPayment`, even if the two
object types eventually share every property name.

Renaming a choice key is therefore a wire-format change, not a cosmetic schema
edit. Generated enum cases, serializers, and stored JSON all observe it. Variant
type names and choice keys may be similar, but they serve different roles: the
reference names a reusable schema; the key selects it in an instance.

## JSON Schema leaves the representation open

JSON Schema commonly represents unions with `oneOf`. `oneOf` requires exactly
one subschema to validate, but it does not prescribe a tag representation. A
schema may add a `const` discriminator property to each branch, use an enclosing
single-property object, or rely entirely on mutually exclusive shapes.

Some tooling recognizes OpenAPI's `discriminator`, but that keyword belongs to
the OpenAPI Schema Object and carries tooling-specific mapping behavior; it is
not a general JSON Schema keyword that changes `oneOf` evaluation. A careful
conversion must preserve the actual wrapper shape shown here. Adding a
discriminator annotation alone does not do that.

JSON Structure's `choice` permits less variation. A tagged choice has one
specified JSON representation, so processors already know how to dispatch it.

## Avro uses a similar wrapper

Avro unions are arrays of schemas, and a value must match one branch. In Avro's
JSON encoding, a non-null union value is normally wrapped in an object whose key
identifies the selected branch and whose value contains the datum. That is close
to JSON Structure's tagged representation.

The details are not interchangeable. Avro derives the JSON wrapper key from the
branch's Avro name or primitive type name, and Avro restricts union branch
composition, including duplicate branch types. JSON Structure declares selector
names explicitly as keys in `choices`, and each key maps to a schema. A converter
must choose and preserve those names rather than assume the two naming systems
are identical.

Avro also has special JSON handling for `null` in a union: the null value is
encoded directly rather than with a wrapper. JSON Structure's tagged choice rule
is the one-property object described by core; nullability is a separate type
concern, not an Avro-style exception to the tagged wrapper.

## When the selector belongs inside

Core also defines inline choices. Those extend a common abstract base type and
inject a selector property into the selected object. Use that form when the wire
contract calls for `{"method":"card", ...}` and the variants share a modeled
base.

The payment schema uses the tagged form because its alternatives need no common
base and its variant value may be any primitive or compound schema. Before
reading `network`, `iban`, or any future field, a consumer sees `card` or
`bankTransfer`. No branch order, field inventory, or hopeful guess is involved.
