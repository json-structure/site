---
layout: post
title: "A Set Should Not Become a List by Accident"
date: 2026-09-08
published: false
author: Clemens Vasters
specification_scope: Core only.
uses_structurize: true
image: /social-cards/a-set-should-not-become-a-list-by-accident.png
description: >-
  Follow a JSON Structure set through generated code and serialization targets,
  preserving uniqueness where possible and making semantic loss explicit.
---

Suppose a shipment acquires the handling tag `fragile` twice: once from the
product catalog and once from a warehouse rule. A list retains both copies and
exposes their positions. Code can then start counting tags or depending on
arrival order, even though neither behavior belongs to the fulfillment
contract.

JSON alone cannot distinguish that list from a collection in which membership
is unique and order is meaningless; both appear as arrays. JSON Structure can:
it declares `handlingTags` as a [`set`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#set).

The Structurize 3.9.0 outputs tested below map that declaration to set-like
collections in five language targets. Protocol Buffers and an unconstrained
SQL table can carry the values but do not enforce uniqueness. A projection must
either preserve the set semantics or identify the boundary where validation
restores them.

> The examples use [Structurize 3.9.0](https://pypi.org/project/structurize/3.9.0/).
> Install the pinned release from PyPI:
>
> ```powershell
> python -m pip install structurize==3.9.0
> ```

## Declare membership at the source

The fulfillment contract uses handling tags to activate independent processing
rules. A tag is either present or absent. Its position has no significance.

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://example.com/schemas/shipment-plan",
  "name": "ShipmentPlan",
  "type": "object",
  "properties": {
    "orderId": { "type": "uuid" },
    "handlingTags": {
      "type": "set",
      "items": {
        "type": "string",
        "enum": ["fragile", "keep-dry", "temperature-controlled"]
      }
    }
  },
  "required": ["orderId", "handlingTags"],
  "additionalProperties": false
}
```

The JSON representation still uses an array:

```json
{
  "orderId": "c28788fa-73bd-4b39-a209-2f75f82c6653",
  "handlingTags": ["fragile", "keep-dry"]
}
```

Under the core [`set`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#set) rules, elements are unique and order is insignificant. Repeating
`"fragile"` makes the instance invalid. Reversing the two elements does not
change its data-model meaning.

That differs from an [`array`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#array), where order is significant and duplicate elements are
allowed. Both use square brackets. Only the schema tells a consumer which
operations belong to the model.

## Native collections preserve the intent

Structurize's code generators can carry a JSON Structure set into native
collection types. For this property, the relevant mappings are:

- C#: `HashSet<T>` ([converter](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/structuretocsharp.py#L318-L326), [tests](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/test/test_structuretocsharp.py#L664-L705)
- Java: `Set<T>` ([converter](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/structuretojava.py#L312-L314))
- TypeScript: `Set<T>` ([converter](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/structuretots.py#L317-L321))
- Rust: `HashSet<T>` ([converter](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/structuretorust.py#L254-L257))
- Go: `map[T]bool` ([converter](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/structuretogo.py#L257-L264))

Generate those bindings from the same source contract:
```bash
structurize s2cs shipment-plan.struct.json --out generated/dotnet --namespace Fulfillment.Contracts
structurize s2java shipment-plan.struct.json --out generated/java --package com.example.fulfillment
structurize s2ts shipment-plan.struct.json --out generated/typescript --package fulfillment-contracts
structurize s2rust shipment-plan.struct.json --out generated/rust --package fulfillment_contracts
structurize s2go shipment-plan.struct.json --out generated/go --package fulfillment
```

For a complex generated project and its full file tree, see the prebuilt
Avrotize [Inventory to C# gallery example](https://avrotize.com/gallery/struct-to-csharp-stjson/).
For this small schema, the TypeScript enum below is the single representative
multi-file code-generation output shown here.

The exact API idiom varies. In C#, adding `"fragile"` twice to a
`HashSet<string>` leaves one member. Java sets, Rust's `HashSet<String>`, and
Go's membership map express the same basic operation: test whether the value
is present. The generated TypeScript property is
`Set<HandlingTagsSetEnum>`, which would provide the same membership behavior,
but this particular generated project is not usable as emitted. Structurize
writes the string values as bare enum member names:

<details class="generated-output" markdown="1">
<summary>Generated output: <code>HandlingTagsSetEnum.ts</code></summary>

```typescript
/** A HandlingTagsSetEnum enum. */
export enum HandlingTagsSetEnum {
    fragile = "fragile",
    keep-dry = "keep-dry",
    temperature-controlled = "temperature-controlled"
}
```

</details>

`npm run build` rejects the hyphenated members, beginning with `TS1357: An enum
member name must be followed by a ',', '=', or '}'`. The intended `Set<T>`
shape is visible in the generated source, but TypeScript cannot enforce it
until the generator produces legal enum identifiers.

A native set also denies accidental positional APIs. Code cannot ask for "the
first handling tag" unless it first creates an ordering policy. That
friction is useful. The source contract never defined a first tag.

## JSON preserves values, not set behavior

Serialization crosses into a representation with fewer collection types. JSON
has arrays, not a distinct set token, so a serializer emits a sequence of
values. A receiver that reads the payload without the schema sees only an
array.

This creates two contract boundaries.

First, JSON Structure assigns no meaning to set order. Unless another protocol
defines an order, serializers can produce either of these
payloads:

```json
{"handlingTags":["fragile","keep-dry"]}
```

```json
{"handlingTags":["keep-dry","fragile"]}
```

They carry the same set. Byte-wise comparison, byte-wise signatures, snapshots,
and cache keys will see different strings unless the surrounding protocol adds
a canonical ordering rule. JSON Structure's set declaration does not create
that rule because order is outside the value's meaning.

Second, a generic decoder may materialize a list and accept duplicates. A
schema-aware boundary must validate uniqueness or construct the target set in a
way that detects duplicate input. Silently collapsing duplicates can hide a
producer defect. Rejecting them preserves the contract and gives the producer
a useful failure.

## Some projections lose the distinction

Protocol Buffers has `repeated` fields rather than a set field. Project the
schema with the exact `s2p` command:

```bash
structurize s2p shipment-plan.struct.json --out generated/proto
```

The target shape can carry several tag values, but `repeated` does not itself
promise uniqueness or erase ordering. The source `set` semantics therefore
need validation around the generated protocol boundary. A downstream user who
sees only the `.proto` cannot recover that promise from the repeated field:

<details class="generated-output" markdown="1">
<summary>Generated output: <code>proto.proto</code></summary>

```proto
syntax = "proto3";

package proto;

message ShipmentPlan {
  enum HandlingTagsItemEnumEnum {
    fragile = 0;
    keep-dry = 1;
    temperature-controlled = 2;
  }
  string orderId = 1;
  repeated HandlingTagsItemEnumEnum handlingTags = 2;
}
```

</details>

This is the exact Structurize 3.9.0 fragment, and it has a second defect:
`grpc_tools.protoc` rejects the two hyphenated enum members with `Missing
numeric value for enum constant`. The source-to-Proto command succeeds, but
the emitted schema does not compile for these enum values.

Tabular projections have a related mismatch. Run the direct SQL projection
with `s2sql`:

```bash
structurize s2sql shipment-plan.struct.json --out generated/shipment-plan.sql --dialect postgres
```

<details class="generated-output" markdown="1">
<summary>Generated output: <code>shipment-plan.sql</code></summary>

```sql
CREATE TABLE "ShipmentPlan" (
  "orderId" UUID,
  "handlingTags" JSONB,
  PRIMARY KEY ("orderId", "handlingTags")
);

COMMENT ON COLUMN "ShipmentPlan"."handlingTags" IS '{"schema": {"type": "set", "items": {"type": "string", "enum": ["fragile", "keep-dry", "temperature-controlled"]}}}';
```

</details>

A tabular list of tag values does not inherently retain JSON Structure's set
meaning. A relational design can enforce uniqueness with a key or unique
constraint over the shipment and tag columns, but that is a target-specific
representation decision. Without such enforcement, the table can hold two
`fragile` rows even though the source contract rejects the corresponding JSON
instance.

Proto repeated fields and unconstrained SQL rows do not preserve set
uniqueness. Enforce it at those boundaries or record the loss.

## Test behavior at every boundary

A set projection review answers four questions:

1. Does the generated in-memory type prevent duplicate membership?
2. Does deserialization reject duplicate input instead of quietly normalizing
   it?
3. Does any byte-sensitive operation define a canonical element order outside
   the set contract?
4. Does a narrower target, such as Proto or a tabular list, enforce uniqueness
   elsewhere?

Those answers belong in projection tests. Feed duplicate tags to each inbound
adapter and expect rejection. Serialize the same logical set after different
insertion orders and avoid asserting incidental byte order unless the protocol
defines one. Insert duplicate membership into the storage projection and verify
the selected database policy.

A list is not a harmless implementation substitute for a set. It adds position
and repetition, then invites application code to depend on both. Keep
`handlingTags` as a set in the JSON Structure source, use native sets where the
target offers them, and mark every narrower projection as a deliberate policy
boundary. Accidents make poor contracts.
