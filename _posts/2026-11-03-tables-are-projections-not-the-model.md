---
layout: post
title: "Tables Are Projections, Not the Model"
date: 2026-11-03
published: false
author: Clemens Vasters
image: /social-cards/tables-are-projections-not-the-model.png
description: >-
  Treat SQL, Kusto, Parquet, and Iceberg outputs as explicit projections of a
  richer JSON Structure model, with losses recorded as policy.
---

Structurize's current SQL projection can turn every required property into part
of a primary key. The pinned
[`structuretodb.py`](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/structuretodb.py)
collects the required properties and emits them together in `PRIMARY KEY`; the
corresponding
[`test_structuretodb.py`](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/test/test_structuretodb.py#L210-L257)
expects inherited `id` and local `name` to appear there. In JSON Structure,
`required` means that a property is present. It says nothing about relational
identity, uniqueness, indexing, or keys. Generated DDL therefore needs explicit
review before anyone applies it.

That is one vivid example of the larger rule. A table has columns. A JSON
Structure model has named types, arrays, sets, maps, tuples, and choices.
Converting the latter into the former applies target policy; it does not reveal
that the source was secretly a table all along.

> [Structurize](https://pypi.org/project/structurize/3.9.0/) is the JSON
> Structure-focused command-line interface from the
> [Avrotize project](https://github.com/clemensv/avrotize). The 3.9.0 wheel
> omits templates and other assets required by most converters. The examples
> here were tested on Python 3.12.10 with the wheel's dependencies and entry
> point, but with the complete pinned source tree on `PYTHONPATH`:
>
> ```powershell
> py -3.12 -m venv .venv
> .\.venv\Scripts\Activate.ps1
> python -m pip install structurize==3.9.0
> git clone https://github.com/clemensv/avrotize.git structurize-source
> git -C structurize-source checkout 8dbb19a3a48239679f0df097399c5ddc8cd48c76
> $env:PYTHONPATH = (Resolve-Path .\structurize-source).Path
> ```

## One fulfillment model, several table shapes

This order type contains the awkward parts on purpose:

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://schemas.example.com/order-document",
  "name": "Order",
  "type": "object",
  "properties": {
    "orderId": { "type": "string" },
    "createdAt": { "type": "datetime" },
    "tags": { "type": "set", "items": { "type": "string" } },
    "attributes": { "type": "map", "values": { "type": "string" } },
    "destination": {
      "type": "choice",
      "name": "Destination",
      "choices": {
        "postal": {
          "type": "object",
          "name": "PostalDestination",
          "properties": {
            "address": { "type": "string" }
          },
          "required": ["address"]
        },
        "pickupPoint": {
          "type": "object",
          "name": "PickupDestination",
          "properties": {
            "locationId": { "type": "string" }
          },
          "required": ["locationId"]
        }
      }
    }
  },
  "required": ["orderId", "createdAt", "destination"]
}
```

The model says that tags are unique, attributes are keyed, and destination is a
choice. It does not say `JSONB`, repeated field, nested struct, primary key, or
partition column. Those belong to a target projection.

## SQL applies database policy

Structurize's pinned command registry exposes `s2sql` and accepts `postgres` as
a dialect in
[`commands.json`](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/commands.json).
A PostgreSQL projection is explicit:

```powershell
New-Item -ItemType Directory -Force generated/postgres | Out-Null
structurize s2sql order.resolved.struct.json --dialect postgres --out generated/postgres/order.sql
```

At the pinned revision, the PostgreSQL type map in
[`structuretodb.py`](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/structuretodb.py)
maps arrays, sets, maps, objects, choices, and tuples to `JSONB`; the PostgreSQL
converter test checks that complex fields produce `JSONB` in the generated
script. That column type stores the value, but it does not encode JSON
Structure's set uniqueness or a map's declared value type as relational
constraints. If those contracts matter at the database boundary, application
validation or explicit database constraints must carry them.

For this example, the same SQL policy can make `orderId`, `createdAt`, and
`destination` one composite key. The result follows the converter. It does not
follow from the JSON Structure contract.

The generated table makes both policies concrete:

```sql
CREATE TABLE "Order" (
  "orderId" VARCHAR(512),
  "createdAt" TIMESTAMP,
  "tags" JSONB,
  "attributes" JSONB,
  "destination" JSONB,
  PRIMARY KEY ("orderId", "createdAt", "destination")
);
```

This point is not pedantry. Presence and identity answer different questions.
Conflating them can produce a technically valid composite key that no one
intended to operate.

## Kusto, Parquet, and Iceberg make different compromises

The pinned registry exposes Kusto as a separate conversion:

```powershell
New-Item -ItemType Directory -Force generated/kusto | Out-Null
structurize s2k order.resolved.struct.json --out generated/kusto/order.kql
```

Do not infer its shape from the SQL output. The generated Kusto table uses
`dynamic` for all three complex properties:

```kusto
.create-merge table [Order] (
  [orderId]: string,
  [createdAt]: datetime,
  [tags]: dynamic,
  [attributes]: dynamic,
  [destination]: dynamic
);
```

For data-lake formats, the pinned
[`structuretoparquet.py`](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/structuretoparquet.py)
and
[`structuretoiceberg.py`](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/structuretoiceberg.py)
map JSON Structure sets to Arrow lists and choices to Arrow structs with one
nullable field per alternative. In those generated schemas, a list does not
assert uniqueness, and the struct does not assert that exactly one alternative
is populated. Those are specific losses in these converter outputs, not a claim
that every Parquet or Iceberg modeling strategy must make the same compromise.

Both commands expose inspection JSON with `--format schema` in the pinned
command registry:

```powershell
New-Item -ItemType Directory -Force generated/parquet, generated/iceberg | Out-Null
structurize s2pq order.resolved.struct.json --format schema --out generated/parquet/order.schema.json
structurize s2ib order.resolved.struct.json --format schema --out generated/iceberg/order.schema.json
```

For `s2pq`, this selects JSON instead of the default empty Parquet file carrying
the schema. For `s2ib`, it selects JSON instead of the default Arrow IPC output.
Diff that JSON, examine list element nullability, inspect the choice struct, and
verify field names before a pipeline writes its first record.

The generated Parquet inspection JSON portrays `tags` and `destination` as
follows (unrelated fields omitted):

```json
{
  "name": "tags",
  "type": "list<item: string>",
  "nullable": true
},
{
  "name": "destination",
  "type": "struct<postal: struct<address: string not null>, pickupPoint: struct<locationId: string not null>>",
  "nullable": false
}
```

Iceberg renders the same choice as a required outer struct containing optional
`postal` and `pickupPoint` fields. That output preserves neither exclusivity nor
the requirement that one alternative be present:

```json
{
  "id": 12,
  "name": "destination",
  "required": true,
  "type": {
    "type": "struct",
    "fields": [
      { "id": 9, "name": "postal", "required": false, "type": { "type": "struct", "fields": [] } },
      { "id": 11, "name": "pickupPoint", "required": false, "type": { "type": "struct", "fields": [] } }
    ]
  }
}
```

The empty nested `fields` arrays above are an editorial abbreviation; the
generated file contains required `address` and `locationId` fields inside the
respective structs.

## Review the projection as an artifact

A useful review does not ask whether the generated table is equivalent in some
vague sense. It asks concrete questions:

- Which source constraints survive in the physical schema?
- Which collections become opaque JSON, and which become typed lists?
- Where did set uniqueness go?
- How is a choice represented, and what enforces one selected alternative?
- Which nullable source fields became optional target fields?
- Which key, partition, and clustering decisions came from converter policy?

Keep the answers beside the generated files. If a team modifies generated SQL
to choose `orderId` as the sole primary key, record that as a target-specific
overlay or post-processing step. Do not backfill a relational key fiction into
the JSON Structure model unless identity is genuinely part of the shared
contract and represented with the appropriate JSON Structure facilities.

Each target serves a different workload. SQL DDL prepares an operational or
warehouse database. Kusto commands prepare an ingestion and query surface.
Parquet and Iceberg describe columnar storage. Generating all four from one
source does not make their outputs interchangeable; it makes their differences
visible and reviewable.

The [`8dbb19a` Structurize source](https://github.com/clemensv/avrotize/tree/8dbb19a3a48239679f0df097399c5ddc8cd48c76)
makes these policies inspectable and repeatable. That is exactly what a
converter should provide. JSON Structure defines the model; SQL, Kusto,
Parquet, and Iceberg files are useful, target-shaped views of it. A projection
can be excellent without becoming authoritative.