---
layout: post
title: "Scope and Qualifiers Make Links Precise"
date: 2026-11-04
published: false
author: Clemens Vasters
image: /social-cards/scope-and-qualifiers-make-links-precise.png
description: >-
  Resolve relations against explicit in-document collections and attach
  version, locale, channel, and validity facts to the link where they belong.
---

A product identity alone does not tell a resolver which catalog collection to
search, nor does it record the dates or sales channel for a storefront listing.
The relations extension uses [`scope`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#scope-keyword) to bound resolution and [`qualifiertype`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#qualifiertype-keyword) to
describe the listing itself. Those qualifier values do not become properties
of the storefront or the catalog entry.

## A localized, versioned catalog link

A storefront selects entries from a product catalog. Product number, catalog
version, and locale together identify an entry. The link also records its
sales channel and effective dates; those dates qualify the listing rather than
the catalog entry.

```json
{
  "$schema": "https://json-structure.org/meta/relations/v0/#",
  "$id": "https://schemas.example.com/catalog/storefront/v1",
  "$uses": ["JSONStructureRelations"],
  "name": "StorefrontCatalogDocument",
  "$root": "#/definitions/CatalogDocument",
  "definitions": {
    "CatalogEntry": {
      "name": "CatalogEntry",
      "type": "object",
      "identity": ["productNumber", "catalogVersion", "locale"],
      "properties": {
        "productNumber": { "type": "string" },
        "catalogVersion": { "type": "string" },
        "locale": { "type": "string" },
        "displayName": { "type": "string" }
      },
      "required": ["productNumber", "catalogVersion", "locale", "displayName"],
      "additionalProperties": false
    },
    "ListingQualifier": {
      "name": "ListingQualifier",
      "type": "object",
      "properties": {
        "channel": {
          "type": "string",
          "enum": ["web", "store", "partner"]
        },
        "effectiveFrom": { "type": "datetime" },
        "effectiveUntil": { "type": "datetime" }
      },
      "required": ["channel", "effectiveFrom"],
      "additionalProperties": false
    },
    "Storefront": {
      "name": "Storefront",
      "type": "object",
      "identity": ["storefrontId"],
      "relations": {
        "featuredEntries": {
          "targettype": { "$ref": "#/definitions/CatalogEntry" },
          "cardinality": "multiple",
          "scope": "#/definitions/CatalogDocument/properties/entries",
          "qualifiertype": { "$ref": "#/definitions/ListingQualifier" }
        }
      },
      "properties": {
        "storefrontId": { "type": "string" },
        "market": { "type": "string" }
      },
      "required": ["storefrontId", "market"],
      "additionalProperties": false
    },
    "CatalogDocument": {
      "name": "CatalogDocument",
      "type": "object",
      "properties": {
        "entries": {
          "type": "array",
          "items": { "type": { "$ref": "#/definitions/CatalogEntry" } }
        },
        "storefronts": {
          "type": "array",
          "items": { "type": { "$ref": "#/definitions/Storefront" } }
        }
      },
      "required": ["entries", "storefronts"],
      "additionalProperties": false
    }
  }
}
```

The relation instance carries the composite identity and a separate qualifier:

```json
{
  "$schema": "https://schemas.example.com/catalog/storefront/v1",
  "entries": [
    {
      "productNumber": "P-410",
      "catalogVersion": "2026.11",
      "locale": "de-DE",
      "displayName": "Drucksensor"
    },
    {
      "productNumber": "P-410",
      "catalogVersion": "2026.11",
      "locale": "en-GB",
      "displayName": "Pressure sensor"
    }
  ],
  "storefronts": [
    {
      "storefrontId": "de-industrial",
      "market": "DE",
      "featuredEntries": [
        {
          "identity": ["P-410", "2026.11", "de-DE"],
          "qualifier": {
            "channel": "web",
            "effectiveFrom": "2026-11-18T00:00:00Z",
            "effectiveUntil": "2026-12-01T00:00:00Z"
          }
        }
      ]
    }
  ]
}
```

## Scope is a schema pointer

The [`scope`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#scope-keyword) value is an RFC 6901 JSON Pointer to a schema location, not a JSON
Path query over the instance. The pointed-to property must hold an [`array`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#array),
[`set`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#set), or [`map`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#map) compatible with [`targettype`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#targettype-keyword). For maps, resolution searches the
values rather than treating map keys as target identities.

At runtime, the schema pointer identifies the corresponding collection in the
document. The resolver then compares the relation's [`identity`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#identity-keyword) with each
candidate's declared identity. Here all three values must match in declaration
order, so the German entry does not accidentally resolve to the English entry
for the same product and version.

[`scope`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#scope-keyword) may also be an array of pointers when candidates live in several
collections. `"#"` identifies the document root only when the root itself is a
compatible collection. Omitting [`scope`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#scope-keyword) means external resolution; it does not
mean “search the entire document.”

## Qualifiers describe the edge

[`qualifiertype`](https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html#qualifiertype-keyword) must be a [`$ref`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#ref-keyword) to a reusable type. Its instance appears under
`qualifier` inside each relation object. The `channel` and effective dates
describe this storefront-to-entry link. Another storefront can link to the
same catalog identity with different dates without duplicating or mutating the
catalog entry.

The qualifier does not participate in target identity or resolution. It cannot
repair a missing target, and it does not filter the scope unless an application
adds that policy. The draft gives it typed link properties, not query-language
semantics.

[relations]: https://json-structure.github.io/relations/draft-vasters-json-structure-relations.html
