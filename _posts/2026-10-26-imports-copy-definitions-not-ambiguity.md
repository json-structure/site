---
layout: post
title: "Imports Copy Definitions, Not Ambiguity"
date: 2026-10-26
published: false
author: Clemens Vasters
image: /social-cards/imports-copy-definitions-not-ambiguity.png
description: >-
  Resolve $import and $importdefs into local namespaces with rewritten internal
  references, deterministic shadowing, and standards-based URI handling.
---

An import processor fetches a schema and then makes it local. It places copied
types in a chosen namespace, rewrites their internal pointers, and gives local
declarations deterministic precedence over imported names.

You can therefore resolve `Address` without consulting import order or guessing
which declaration a pointer meant.

## Two source documents

The first document publishes a root type and one supporting definition at
`https://schemas.example.com/people.json`:

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://schemas.example.com/people.json",
  "name": "Person",
  "type": "object",
  "properties": {
    "name": { "type": "string" },
    "address": { "type": { "$ref": "#/definitions/Address" } }
  },
  "required": ["name", "address"],
  "definitions": {
    "Address": {
      "type": "object",
      "properties": {
        "city": { "type": "string" }
      },
      "required": ["city"]
    }
  }
}
```

The second is a definition library at
`https://schemas.example.com/common.json`:

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://schemas.example.com/common.json",
  "name": "CommonDocument",
  "type": "object",
  "definitions": {
    "AuditStamp": {
      "type": "object",
      "properties": {
        "createdBy": { "type": "string" },
        "createdAt": { "type": "datetime" }
      },
      "required": ["createdBy", "createdAt"]
    }
  }
}
```

## One consumer, two import modes

The consumer imports the complete people document and only the definitions from
the common document:

```json
{
  "$schema": "https://json-structure.org/meta/extended/v0/#",
  "$id": "https://schemas.example.com/customer-record.json",
  "$uses": ["JSONStructureImport"],
  "name": "CustomerRecord",
  "type": "object",
  "properties": {
    "customer": {
      "type": { "$ref": "#/definitions/People/Person" }
    },
    "audit": {
      "type": { "$ref": "#/definitions/Common/AuditStamp" }
    }
  },
  "required": ["customer", "audit"],
  "definitions": {
    "People": {
      "$import": "https://schemas.example.com/people.json",
      "Address": {
        "type": "object",
        "properties": {
          "city": { "type": "string" },
          "country": { "type": "string" }
        },
        "required": ["city", "country"]
      }
    },
    "Common": {
      "$importdefs": "https://schemas.example.com/common.json"
    }
  }
}
```

A matching instance is ordinary JSON:

```json
{
  "customer": {
    "name": "Ada Lovelace",
    "address": {
      "city": "London",
      "country": "GB"
    }
  },
  "audit": {
    "createdBy": "migration-7",
    "createdAt": "2026-11-09T10:30:00Z"
  }
}
```

[`$import`](https://json-structure.github.io/import/draft-vasters-json-structure-import.html#import-keyword) copies the external root type as `People/Person` and copies its
[`definitions`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#definitions-keyword). [`$importdefs`](https://json-structure.github.io/import/draft-vasters-json-structure-import.html#importdefs-keyword) copies only the external [`definitions`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#definitions-keyword), so
`Common/AuditStamp` exists but `Common/CommonDocument` does not.

Placement supplies the namespace. An import at the schema root, or directly as
`definitions.$import`, targets the root namespace. An import inside
`definitions.People` targets `People`. Nested namespace objects can place it
deeper still.

## Internal pointers stay internal

The source `Person` points to `#/definitions/Address`. During import, the
processor prefixes that pointer so it resolves inside `People`, not against a
consumer-level `Address`. The rewrite also applies recursively through imported
imports and to [`$ref`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#ref-keyword), [`$extends`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#extends-keyword), and [`$addins`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#extensions-and-add-ins) pointers.

Shadowing comes next. The local `People/Address` replaces the imported type of
the same name entirely; there is no merge and no route back to the replaced
version. Consequently the imported `Person.address` resolves to the local
replacement requiring both `city` and `country`.

That precedence is deterministic, but blunt. Put both versions under different
namespaces when both must survive.

## URI resolution is not package lookup

The import draft requires absolute URI values and RFC 3986/RFC 3987 resolution.
It defines no npm-style package search, filesystem fallback, registry alias, or
version selection. Processors must fetch and validate the target as a schema;
they should cache securely and must bound circular or excessively deep chains.

Repository samples sometimes use relative paths for local development. Those
are useful fixtures, but they conflict with the draft's absolute-URI
requirement. The complete documents above follow the draft.

The extended meta-schema offers `JSONStructureImport` and enables it for its
own root import. The import draft, unlike the validation and conditional
drafts, introduces no competing [`$uses`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uses-keyword) name; it makes the extension available
through the extended meta-schema. The explicit [`$uses`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uses-keyword) above names the
repository feature so a reader can see the dependency at the point of use.
