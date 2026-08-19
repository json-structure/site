---
layout: post
title: "Importing Types Without Copying Them"
date: 2026-09-18
published: false
author: Clemens Vasters
image: /social-cards/importing-types-without-copying-them.png
description: >-
  Share a postal-address schema with $import or $importdefs while preserving
  local namespaces, URI rules, and explicit shadowing.
---

The title needs a qualification. The author does not copy a shared type, but a
JSON Structure processor does. It fetches the external schema, copies its types
into the importing document's [`definitions`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#definitions-keyword), and treats the result as local.

This is deliberate copy semantics, not a live cross-document reference. The
maintained declaration still has one source; consumers of the processed schema
see a self-contained type library.

## Start with the published type

Suppose the postal team publishes this schema at
`https://schemas.example.com/postal-address.json`:

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://schemas.example.com/postal-address.json",
  "name": "PostalAddress",
  "type": "object",
  "properties": {
    "street": { "type": "string" },
    "city": { "type": "string" },
    "postalCode": {
      "type": { "$ref": "#/definitions/PostalCode" }
    }
  },
  "required": ["street", "city", "postalCode"],
  "definitions": {
    "PostalCode": {
      "type": "string",
      "maxLength": 12
    }
  }
}
```

The root declares `PostalAddress`, and its [`definitions`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#definitions-keyword) section contributes
the reusable `PostalCode` type.

## Bring both into a namespace

An order schema can import the complete document into a local `Postal`
namespace:

```json
{
  "$schema": "https://json-structure.org/meta/extended/v0/#",
  "$id": "https://schemas.example.com/order.json",
  "type": "object",
  "properties": {
    "orderId": { "type": "uuid" },
    "shipTo": {
      "type": { "$ref": "#/definitions/Postal/PostalAddress" }
    }
  },
  "required": ["orderId", "shipTo"],
  "definitions": {
    "Postal": {
      "$import": "https://schemas.example.com/postal-address.json"
    }
  }
}
```

[`$import`](https://json-structure.github.io/import/draft-vasters-json-structure-import.html#import-keyword) brings in the external root type and its [`definitions`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#definitions-keyword). After
processing, `Postal/PostalAddress` and `Postal/PostalCode` behave as local
reusable types. The processor prefixes cross-references inside the imported
material with the local namespace. `PostalAddress` therefore still reaches the
imported `PostalCode`, even if the importing schema declares another type with
that short name.

Processors handle imports before other schema keywords. One schema may import
several documents into separate local namespaces.

## Leave the root behind with [`$importdefs`](https://json-structure.github.io/import/draft-vasters-json-structure-import.html#importdefs-keyword)

Sometimes the external document's root describes a message you do not need,
while its [`definitions`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#definitions-keyword) section is the useful library. Replace the import with:

```json
{
  "definitions": {
    "Postal": {
      "$importdefs": "https://schemas.example.com/postal-address.json"
    }
  }
}
```

Now `#/definitions/Postal/PostalCode` exists, but
`#/definitions/Postal/PostalAddress` does not. [`$importdefs`](https://json-structure.github.io/import/draft-vasters-json-structure-import.html#importdefs-keyword) has the same merge
and namespace behavior as [`$import`](https://json-structure.github.io/import/draft-vasters-json-structure-import.html#import-keyword); its only difference is that it omits the
external root type.

Choose [`$import`](https://json-structure.github.io/import/draft-vasters-json-structure-import.html#import-keyword) when the published root belongs in the local contract. Choose
[`$importdefs`](https://json-structure.github.io/import/draft-vasters-json-structure-import.html#importdefs-keyword) when only the external type library is relevant.

## The URI is the identity

The values of [`$import`](https://json-structure.github.io/import/draft-vasters-json-structure-import.html#import-keyword) and [`$importdefs`](https://json-structure.github.io/import/draft-vasters-json-structure-import.html#importdefs-keyword) must be absolute URIs. Processors
resolve them according to RFC 3986 and RFC 3987. The import specification adds
no package-name search, filesystem convention, registry protocol, or fallback
rule.

A processor must resolve the URI and verify that the result is a schema
document. Implementations should cache remote documents, use secure transport,
and detect circular or excessively deep import chains. A local cache may satisfy
the request; it does not replace the URI as the schema's identity.

## Shadowing replaces; it does not merge

A local declaration with the same name in the same namespace replaces the
imported declaration entirely:

```json
{
  "definitions": {
    "Postal": {
      "$import": "https://schemas.example.com/postal-address.json",
      "PostalCode": {
        "type": "string",
        "maxLength": 8
      }
    }
  }
}
```

The local `Postal/PostalCode` wins. It does not merge with the imported type,
and the shadowing declaration cannot refer back to the imported type it
replaced.

Shadowing is blunt. It can adapt an imported library, and it can also redirect
every imported cross-reference to the replacement. Use another local name when
both versions must remain available.

Authors maintain one published declaration. Processors turn each import into a
local library with deterministic pointers and no external type references left
to resolve.
