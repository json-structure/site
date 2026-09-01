---
layout: post
title: "One Schema, Many Artifacts"
date: 2026-08-25
published: true
author: Clemens Vasters
specification_scope: Core only.
uses_structurize: true
image: /social-cards/one-schema-many-artifacts.png
description: >-
  Keep one JSON Structure schema as the source contract and project disposable
  documentation, protocols, database definitions, and code from it.
---

A C# class, a `.proto` file, and a SQL script can all represent the same
shipment, but each expresses the model through a different target type system.
One preserves a UUID, another exposes a string, and the database may accept
null. None of those artifacts can serve as the neutral definition without
making its target's constraints and omissions authoritative for every other
consumer.

JSON Structure provides that target-independent definition. It records the
intended types, presence rules, and collection semantics once, before any
language, protocol, or database narrows them. In the Structurize version pinned
below, the listed commands read that schema and project it into target
artifacts. A target may preserve a declaration, translate it into a native
type, or represent it more weakly; that result describes the projection, not a
revision of the model. The generated outputs remain useful, but the JSON
Structure schema is the contract from which they can be rebuilt.

> The examples use [Structurize 3.9.0](https://pypi.org/project/structurize/3.9.0/).
> Install the pinned release from PyPI:
>
> ```powershell
> python -m pip install structurize==3.9.0
> ```

## Put the decisions in the contract

Consider a fulfillment service that plans a shipment after an order has been
allocated to a warehouse. The contract needs an order identifier, a carrier
service, a dispatch time, a monetary value, and a collection of handling tags.

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://example.com/schemas/shipment-plan",
  "name": "ShipmentPlan",
  "type": "object",
  "description": "A shipment plan prepared after an order is allocated to a warehouse.",
  "properties": {
    "orderId": {
      "type": "uuid",
      "description": "The order for which the shipment is planned."
    },
    "carrierService": {
      "type": "string",
      "description": "The carrier service selected to transport the shipment.",
      "maxLength": 80
    },
    "dispatchAt": {
      "type": "datetime",
      "description": "The time at which the shipment is scheduled to leave the warehouse."
    },
    "declaredValue": {
      "type": "decimal",
      "description": "The monetary value declared for carriage.",
      "precision": 12,
      "scale": 2
    },
    "handlingTags": {
      "type": "set",
      "description": "Handling instructions that apply to the shipment.",
      "items": {
        "type": "string",
        "description": "A handling instruction assigned to the shipment."
      }
    }
  },
  "required": [
    "orderId",
    "carrierService",
    "dispatchAt",
    "declaredValue",
    "handlingTags"
  ],
  "additionalProperties": false
}
```

These declarations are not hints to a generator. [`uuid`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uuid),
[`datetime`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#datetime), [`decimal`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#decimal), and [`set`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#set) are types in the
contract. [`required`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#required-keyword) fixes presence. [`additionalProperties`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#additionalproperties-keyword) closes the object against undeclared
fields.

The instance remains ordinary JSON:

```json
{
  "orderId": "c28788fa-73bd-4b39-a209-2f75f82c6653",
  "carrierService": "priority-ground",
  "dispatchAt": "2026-08-25T16:30:00Z",
  "declaredValue": "184.50",
  "handlingTags": ["fragile", "keep-dry"]
}
```

The schema carries the information that the JSON text cannot carry by itself.
Every schema element also has a description, including the `items` schema
inside `handlingTags`. The array under `handlingTags` is unordered and
duplicate-free because its declared type is `set`. The quoted amount belongs
to a base-10 decimal domain. The identifier is more specific than arbitrary
text.

## Project views, do not maintain copies

[Structurize 3.9.0](https://pypi.org/project/structurize/3.9.0/) exposes the
direct JSON Structure projections used here. The commands and options are defined in the
[3.9.0 CLI manifest](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/commands.json).
From the same `shipment-plan.struct.json`, a build can produce several views:

```powershell
New-Item -ItemType Directory -Force generated | Out-Null
structurize s2md shipment-plan.struct.json --out generated/shipment-plan.md
structurize s2p shipment-plan.struct.json --out generated/proto
structurize s2sql shipment-plan.struct.json --out generated/shipment-plan.sql --dialect postgres
structurize s2cs shipment-plan.struct.json --out generated/dotnet --namespace Fulfillment.Contracts
structurize s2java shipment-plan.struct.json --out generated/java --package com.example.fulfillment
```

<details class="generated-output" markdown="1">
<summary>Generated output: <code>shipment-plan.md</code></summary>

```markdown
# shipment-plan.struct
A shipment plan prepared after an order is allocated to a warehouse.
**Schema ID:** `https://example.com/schemas/shipment-plan`
## Objects

### ShipmentPlan

A shipment plan prepared after an order is allocated to a warehouse.
**Properties:**
- **orderId** (required): `uuid`
  - Description: The order for which the shipment is planned.
- **carrierService** (required): `string`
  - Description: The carrier service selected to transport the shipment.
  - Constraints: maxLength: 80
- **dispatchAt** (required): `datetime`
  - Description: The time at which the shipment is scheduled to leave the warehouse.
- **declaredValue** (required): `decimal`
  - Description: The monetary value declared for carriage.
  - Constraints: precision: 12, scale: 2
- **handlingTags** (required): set&lt;`string`&gt;
  - Description: Handling instructions that apply to the shipment.
```

</details>

For a complex multi-file code-generation example, use the prebuilt Avrotize
[Inventory to C# gallery example](https://avrotize.com/gallery/struct-to-csharp-stjson/),
which shows its source schema and complete output tree. The small schema here
emits this representative file from its generated C# project:

<details class="generated-output" markdown="1">
<summary>Generated output: <code>ShipmentPlan.cs</code></summary>

```csharp
using System;
using System.Collections.Generic;
using System.Linq;

namespace Fulfillment.Contracts
{
    /// <summary>
    /// A shipment plan prepared after an order is allocated to a warehouse.
    /// </summary>
    public sealed partial class ShipmentPlan
    {
        /// <summary>
      /// The order for which the shipment is planned.
        /// </summary>
        public required Guid orderId { get; set; }

        /// <summary>
      /// The carrier service selected to transport the shipment.
        /// </summary>
        [System.ComponentModel.DataAnnotations.StringLength(80)]
        public required string carrierService { get; set; }

        /// <summary>
      /// The time at which the shipment is scheduled to leave the warehouse.
        /// </summary>
        public required DateTimeOffset dispatchAt { get; set; }

        /// <summary>
      /// The monetary value declared for carriage.
        /// </summary>
        public required decimal declaredValue { get; set; }

        /// <summary>
      /// Handling instructions that apply to the shipment.
        /// </summary>
        public required HashSet<string> handlingTags { get; set; }

        /// <summary>
        /// Default constructor
        /// </summary>
        public ShipmentPlan()
        {
        }
        /// <summary>
        /// Determines whether the specified object is equal to the current object.
        /// </summary>
        public override bool Equals(object? obj)
        {
            if (obj is not ShipmentPlan other) return false;
            return this.orderId == other.orderId
                && this.carrierService == other.carrierService
                && this.dispatchAt == other.dispatchAt
                && this.declaredValue == other.declaredValue
                && this.handlingTags.SequenceEqual(other.handlingTags);
        }

        /// <summary>
        /// Serves as the default hash function.
        /// </summary>
        public override int GetHashCode()
        {
            return HashCode.Combine(orderId, carrierService, dispatchAt, declaredValue, handlingTags.Aggregate(0, (acc, item) => HashCode.Combine(acc, item)));
        }
    }
}
```

</details>

`s2md` emits a Markdown contract view, `s2p` adapts the model to Protocol
Buffers, and `s2sql` projects it into the selected SQL dialect. The code
generators create language-facing APIs; the same manifest also defines `s2ts`,
`s2go`, and `s2rust`.

Each output answers a different consumer's question. None gains authority over
the schema merely because people read it more often.

## A projection can be narrower

Projection is not photocopying. Target systems have different type systems,
collection models, naming rules, and representation constraints. A generator
must sometimes choose the closest available construct.

Protocol Buffers, for example, has repeated fields but no native set field.
SQL dialects differ in their types and in how they represent nested
collections. Language targets can preserve a set directly, but their concrete
types differ. Those differences do not make the source contract vague. They
make the projection policy visible.

This distinction matters during review. If `handlingTags` appears as a
repeated field in the generated `.proto`, changing the JSON Structure type from
`set` to `array` merely to make both files look alike would reverse the
authority. The source says membership is unique and order has no meaning. A
target that cannot express that fact needs enforcement at its boundary or a
documented loss of semantics.

The generated artifact is evidence of how one tool version projected one
contract. It is not a second contract.

## Regeneration makes drift observable

Treat the projections like compiler output. Keep the command line and tool
version in the build, then regenerate from a known schema revision.

```powershell
New-Item -ItemType Directory -Force generated | Out-Null
structurize s2md shipment-plan.struct.json --out generated/shipment-plan.md
structurize s2p shipment-plan.struct.json --out generated/proto
structurize s2sql shipment-plan.struct.json --out generated/shipment-plan.sql --dialect postgres
```

<details class="generated-output" markdown="1">
<summary>Generated output: <code>proto.proto</code></summary>

```proto
syntax = "proto3";

package proto;

// A shipment plan prepared after an order is allocated to a warehouse.
message ShipmentPlan {
  // The order for which the shipment is planned.
  string orderId = 1;
  // The carrier service selected to transport the shipment.
  // Max length: 80
  string carrierService = 2;
  // The time at which the shipment is scheduled to leave the warehouse.
  string dispatchAt = 3;
  // The monetary value declared for carriage.
  // Precision: 12
  // Scale: 2
  string declaredValue = 4;
  // Handling instructions that apply to the shipment.
  repeated string handlingTags = 5;
}
```

</details>

<details class="generated-output" markdown="1">
<summary>Generated output: <code>shipment-plan.sql</code></summary>

```sql
CREATE TABLE "ShipmentPlan" (
    "orderId" UUID,
    "carrierService" VARCHAR(80),
    "dispatchAt" TIMESTAMP,
    "declaredValue" NUMERIC(18,6),
    "handlingTags" JSONB,
    PRIMARY KEY ("orderId", "carrierService", "dispatchAt", "declaredValue", "handlingTags")
);

  COMMENT ON TABLE "ShipmentPlan" IS 'A shipment plan prepared after an order is allocated to a warehouse.';
  COMMENT ON COLUMN "ShipmentPlan"."orderId" IS '{"doc": "The order for which the shipment is planned."}';
  COMMENT ON COLUMN "ShipmentPlan"."carrierService" IS '{"doc": "The carrier service selected to transport the shipment."}';
  COMMENT ON COLUMN "ShipmentPlan"."dispatchAt" IS '{"doc": "The time at which the shipment is scheduled to leave the warehouse."}';
  COMMENT ON COLUMN "ShipmentPlan"."declaredValue" IS '{"doc": "The monetary value declared for carriage."}';
  COMMENT ON COLUMN "ShipmentPlan"."handlingTags" IS '{"doc": "Handling instructions that apply to the shipment.", "schema": {"type": "set", "description": "Handling instructions that apply to the shipment.", "items": {"type": "string", "description": "A handling instruction assigned to the shipment."}}}';
```

</details>

  Descriptions travel according to each target's documentation model. Markdown
  renders the root and property descriptions as prose. C# turns them into XML
  documentation comments, Proto turns them into source comments, and PostgreSQL
  stores them in table and column comments. The nested `items.description` does
  not appear in the Markdown, C#, or Proto projection because none emits a
  separate artifact for the string item. The SQL projection retains it inside
  the JSON schema metadata attached to `handlingTags`. That difference is
  another visible part of the projection policy.

Whether generated files belong in source control is a repository policy. The
authority rule stays the same either way. If they are committed for packaging,
review, or downstream tools, a clean regeneration can detect manual edits. If
they are omitted, the build must recreate them before use.

Version pinning matters because a projection includes the behavior of a
specific generator implementation as well as schema content. An upgrade can
change naming, type selection, or layout without a contract change. Review
that movement as a tooling change,
separate from a change to `ShipmentPlan`.

## Change the model once

Suppose fulfillment adds an optional `warehouseNote`. Add it to
`properties`, leave it out of `required`, and regenerate. Documentation then
shows the field as optional, code receives the target language's optional
shape, and storage or protocol projections apply their corresponding policy.

Do not begin by adding a nullable column, then a nullable C# property, then a
Proto field, and finally trying to reconstruct the schema from the debris.
That workflow asks every editor to repeat the same decision and creates several
places where the answer can differ.

One source contract does not imply that every target has identical syntax or
capabilities. It means every target starts from the same declared intent, and
every loss in translation has one place to be noticed. Keep the JSON Structure
schema deliberate. Make the artifacts cheap.
