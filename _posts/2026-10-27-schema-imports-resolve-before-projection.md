---
layout: post
title: "Schema Imports Resolve Before Projection"
date: 2026-10-27
published: false
author: Clemens Vasters
specification_scope: Core with the Import companion specification.
uses_structurize: true
image: /social-cards/schema-imports-resolve-before-projection.png
description: >-
  Resolve JSON Structure imports into one closed type graph before projecting
  that graph into a target schema or generated program.
---

A converter can project only the types it has loaded. If a JSON Structure
document refers to definitions supplied through `$import` or `$importdefs`, the
converter needs the resolved type graph, not a promise that another document
exists somewhere.

That ordering matters for the Structurize 3.9.0 setup tested here because it
does not process either import keyword. Its JSON Structure converters resolve local references, but they do not
fetch imported documents, copy their definitions, rewrite their internal
pointers, or apply import shadowing. The correct pipeline therefore has two
processors: first resolve and flatten imports with a conforming JSON Structure
processor; then pass the closed schema to an `s2...` converter.

Do not pretend the second processor performed the first one's job.

> The examples use [Structurize 3.9.0](https://pypi.org/project/structurize/3.9.0/).
> Install the pinned release from PyPI:
>
> ```powershell
> python -m pip install structurize==3.9.0
> ```

## The source graph comes first

Consider a fulfillment schema that keeps shared postal types in a separate
document:

```json
{
  "$schema": "https://json-structure.org/meta/extended/v0/#",
  "$id": "https://schemas.example.com/fulfillment/order/v1",
  "name": "OrderDocument",
  "$uses": ["JSONStructureImport"],
  "$root": "#/definitions/Order",
  "definitions": {
    "Shared": {
      "$importdefs": "https://schemas.example.com/fulfillment/shared/v1"
    },
    "Order": {
      "name": "Order",
      "type": "object",
      "properties": {
        "orderId": { "type": "string" },
        "shipTo": { "type": { "$ref": "#/definitions/Shared/PostalAddress" } }
      },
      "required": ["orderId", "shipTo"]
    }
  }
}
```

The local `$ref` is not enough by itself. It points into the namespace where an
import processor must place `PostalAddress`. Until that placement has happened,
the source graph has a hole in it.

The [JSON Structure import draft](https://json-structure.github.io/import/draft-vasters-json-structure-import.html)
defines the missing operation. It distinguishes importing a complete schema
with [`$import`](https://json-structure.github.io/import/draft-vasters-json-structure-import.html#import-keyword)
from importing only its definitions with
[`$importdefs`](https://json-structure.github.io/import/draft-vasters-json-structure-import.html#importdefs-keyword).
It also defines namespace placement, internal pointer rewriting, and local
shadowing. Those are schema semantics, not file concatenation rules.

The following flattened document is illustrative. Producing it requires a
conforming JSON Structure import processor; no current Structurize converter
performs this step.

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://schemas.example.com/fulfillment/order/v1/resolved",
  "name": "OrderDocument",
  "type": "object",
  "properties": {
    "orderId": { "type": "string" },
    "shipTo": { "type": { "$ref": "#/definitions/Shared/PostalAddress" } }
  },
  "required": ["orderId", "shipTo"],
  "definitions": {
    "Shared": {
      "PostalAddress": {
        "name": "PostalAddress",
        "type": "object",
        "properties": {
          "street": { "type": "string" },
          "city": { "type": "string" },
          "countryCode": { "type": "string" }
        },
        "required": ["street", "city", "countryCode"]
      }
    }
  }
}
```

Here `Shared` is a namespace object and `PostalAddress` is the named type within
it. The resolver has also materialized the selected `Order` root as the
top-level object because the Parquet converter requires top-level `type:
"object"`; a document that only identifies its root with `$root` is rejected.
The slash separates JSON Pointer path segments; it is not part of an
identifier. The important property is closure: every reference needed for
projection resolves within the supplied artifact.

## Run the converter after flattening

Once a conforming processor has written `order.resolved.struct.json`, validate
that artifact as a closed JSON Structure schema before invoking Structurize.
Normal Structurize commands can then consume the validated boundary artifact:

```powershell
structurize s2sql order.resolved.struct.json `
  --dialect postgres `
  --out generated/order.sql

structurize s2pq order.resolved.struct.json `
  --format schema `
  --out generated/order.parquet.schema.json
```

<details class="generated-output" markdown="1">
<summary>Generated output: <code>order.sql</code></summary>

```sql
CREATE TABLE "OrderDocument" (
    "orderId" VARCHAR(512),
    "shipTo" VARCHAR(512),
    PRIMARY KEY ("orderId", "shipTo")
);
```

</details>

The first command projects the closed JSON Structure graph into PostgreSQL DDL.
The second command does not complete in Structurize 3.9.0: the nested reference
reaches a converter path that fails with `unhashable type: 'dict'`. Closure
removes the import dependency, but it does not guarantee that every target
converter supports the resulting local-reference shape. Keep this command as a
capability test and do not claim a Parquet artifact when it fails.

The unresolved source is a useful negative test. In the tested setup,
Structurize 3.9.0 does not
reject it: `s2sql` exits successfully and emits `shipTo VARCHAR(512)`. The
missing `PostalAddress` type has disappeared rather than producing an import or
reference error. Validate closure before conversion; converter success does not
establish it.

This separation also gives a build a useful inspection point. Check in or retain
the resolved schema as an artifact, record the resolver version and source
URIs, and compare the flattened graph when an upstream library changes. A
projection diff then answers a narrower question: what did the target mapping
change? Without that boundary, an import update and a converter update become
one undifferentiated surprise.

The Structurize implementation makes the current boundary visible in its
[`commands.json`](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/commands.json)
and JSON Structure converter modules at the
[linked source tree](https://github.com/clemensv/avrotize/tree/8dbb19a3a48239679f0df097399c5ddc8cd48c76).
They accept a schema file and resolve references from the loaded document. They
contain no implementation of the import draft's retrieval and copying
algorithm.

## Source imports are not target imports

Some projection targets have their own import or include mechanisms. Protocol
Buffers has `import`; SQL tools may split DDL across scripts; programming
languages have modules and packages. Those mechanisms organize generated
artifacts in the target system. They do not resolve JSON Structure source
imports.

A converter may choose to emit several target files and connect them with
target-native imports. That happens after the source graph is known. It must not
translate `$importdefs` mechanically into a target `import`, because the two
operations have different namespace, shadowing, identity, and retrieval rules.
Matching vocabulary is not matching semantics.

The safe pipeline is deliberately boring:

1. Retrieve source documents according to the JSON Structure import rules.
2. Apply namespace placement, pointer rewriting, recursion limits, and shadowing.
3. Validate the resulting artifact as a closed JSON Structure schema.
4. Give that graph to Structurize for projection.
5. Inspect the target artifacts and any target-native imports it emits.

The recommendation is to fail resolution with the source URI and unresolved
pointer when it cannot
achieve closure. Record redirects, cached representations, and
cycle or depth failures. Those diagnostics explain why the authoritative graph
could not be assembled. Passing a partly resolved document downstream merely
trades a precise import error for a misleading converter failure.

JSON Structure remains the authority throughout. The flattened schema records
what the source model means; Structurize projects that model into another
system's available shapes. Until Structurize implements `$import` and
`$importdefs`, resolving first is not optional plumbing. It is the step that
makes the input complete.