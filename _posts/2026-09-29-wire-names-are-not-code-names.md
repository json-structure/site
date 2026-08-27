---
layout: post
title: "Wire Names Are Not Code Names"
date: 2026-09-29
published: false
author: Clemens Vasters
specification_scope: Core with the Alternate Names companion specification.
uses_structurize: true
image: /social-cards/wire-names-are-not-code-names.png
description: >-
  Serializer annotations preserve JSON wire names while generated identifiers
  follow each target language's naming and sanitization rules.
---

A published JSON key is part of the wire contract. C#, Java, Go, Rust,
and TypeScript use different case conventions and reserve different words.
Letting those rules choose the wire spelling turns routine code generation into
a protocol-change mechanism.

JSON Structure keeps the property name as its contract identity and uses
[`altnames`](https://json-structure.github.io/alternate-names/draft-vasters-json-structure-alternate-names.html#the-altnames-keyword)
when its JSON representation needs another spelling. That mapping lets
`fulfillmentId` describe the property while `fulfillment_id` remains the
published wire key.

Structurize sanitizes and case-converts identifiers for each language. With the
target's serializer annotations enabled, it binds those identifiers back to
the declared JSON name. The code spelling changes while the wire spelling
survives. In the tested outputs, that mapping is absent without the generated
boundary.

> The examples use [Structurize 3.9.0](https://pypi.org/project/structurize/3.9.0/).
> Install the pinned release from PyPI:
>
> ```powershell
> python -m pip install structurize==3.9.0
> ```

## The wire already has a spelling

Suppose the fulfillment API has published `fulfillment_id` and
`pickup_location`, while the schema uses its regular identifiers for references
and required-property declarations:

```json
{
  "$schema": "https://json-structure.org/meta/extended/v0/#",
  "$id": "https://schemas.example.com/fulfillment-event.json",
  "name": "FulfillmentEventSchema",
  "$uses": ["JSONStructureAlternateNames"],
  "$root": "#/definitions/PickupReady",
  "definitions": {
    "PickupReady": {
      "name": "PickupReady",
      "type": "object",
      "properties": {
        "fulfillmentId": {
          "type": "uuid",
          "altnames": { "json": "fulfillment_id" }
        },
        "pickupLocation": {
          "type": "string",
          "altnames": { "json": "pickup_location" }
        },
        "readyAt": {
          "type": "datetime",
          "altnames": { "json": "ready_at" }
        }
      },
      "required": ["fulfillmentId", "pickupLocation", "readyAt"],
      "additionalProperties": false
    }
  }
}
```

The schema still requires `fulfillmentId`. An extension-aware JSON serializer
uses the reserved `json` alternate name and emits this representation:

```json
{
  "fulfillment_id": "4d616677-5a1b-4d1d-86df-1fc4a0236bc8",
  "pickup_location": "SEA-042",
  "ready_at": "2026-09-29T16:30:00Z"
}
```

The article
[One Property, Several Names]({% post_url 2026-09-23-one-property-several-names %})
explains what the annotation means in the schema. Here the concern is narrower:
whether generated serializers preserve that meaning after identifiers have
been adapted to a programming language.

## Annotation flags carry the mapping

The [alternate-name tests](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/test/test_structure_altnames.py)
cover JSON wire names for C#, Java, TypeScript, Go, and Rust when their
serializer annotations are enabled, including nested collection values. The
relevant CLI forms are:

```bash
structurize s2cs fulfillment-event.struct.json --out generated/csharp \
  --system_text_json_annotation
structurize s2java fulfillment-event.struct.json --out generated/java
structurize s2ts fulfillment-event.struct.json --out generated/typescript \
  --typedjson-annotation
structurize s2go fulfillment-event.struct.json --out generated/go \
  --json-annotation
structurize s2rust fulfillment-event.struct.json --out generated/rust \
  --json-annotation
```

Java uses Jackson by default in this converter. The switches are recorded
in the [command registry](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/commands.json).
The underscore spelling of `--system_text_json_annotation` is exact.
Without the serializer mode, a generator may still produce legal code names,
but the generated serializer has no obligation to emit the alternate JSON key.
That difference belongs in build configuration, not in tribal memory.

For a complete multi-file code-generation example, the prebuilt Avrotize
[Inventory to C# gallery example](https://avrotize.com/gallery/struct-to-csharp-stjson/)
shows its source schema and output tree. The disclosures below use the small
article-specific schema and one representative file per target.

The generated forms are idiomatic for their ecosystems. Condensed to one
property, they carry the same mapping:

<details class="generated-output" markdown="1">
<summary>Generated output: <code>PickupReady.cs</code></summary>

```csharp
[System.Text.Json.Serialization.JsonPropertyName("fulfillment_id")]
public required Guid fulfillmentId { get; set; }
```

</details>

<details class="generated-output" markdown="1">
<summary>Generated output: <code>PickupReady.java</code></summary>

```java
@JsonProperty("fulfillment_id")
private UUID fulfillmentId;
```

</details>

<details class="generated-output" markdown="1">
<summary>Generated output: <code>PickupReady.ts</code></summary>

```typescript
@jsonMember(String, { name: 'fulfillment_id' })
public fulfillmentId: string;
```

</details>

<details class="generated-output" markdown="1">
<summary>Generated output: <code>PickupReady.go</code></summary>

```go
FulfillmentId string `json:"fulfillment_id"`
```

</details>

<details class="generated-output" markdown="1">
<summary>Generated output: <code>pickupready.rs</code></summary>

```rust
pub fulfillment_id: uuid::Uuid,
```

</details>

The Rust output has no rename attribute because its snake-case identifier is
already the declared wire spelling. C#, Java, TypeScript, and Go carry explicit
metadata because their member identifiers differ. The current TypeScript
template passes the wire name through TypedJSON's `name` option, and the
[Go template](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/structuretogo/go_struct.jinja)
puts it in a `json` struct tag.

## Sanitization is not a contract rename

Even without `altnames`, code generation must cope with target conventions.
PascalCase properties are normal in C#. Exported Go fields begin with an upper-
case letter. Rust commonly uses snake case. Reserved words and otherwise
illegal identifiers need sanitization. Those transformations create usable
source code; they do not authorize a serializer to improvise a new JSON key.

This distinction matters in reviews. A diff from `fulfillmentId` to
`FulfillmentId` in generated C# may be a harmless projection. A wire diff from
`fulfillment_id` to `FulfillmentId` is an interoperability break unless the
contract changed. Looking only at the class declaration hides that difference;
look at the annotation and serialized output as well.

The reverse path matters just as much. Deserialization must accept the declared
wire name and populate the generated member. A round-trip test that serializes
and then deserializes its own output is useful, but insufficient: both halves
can agree on the same wrong spelling. Include a fixture written directly from
the JSON Structure contract.

## Purpose keys are not universal generator switches

The reserved `json` purpose has defined meaning in the alternate-names
extension. Custom purposes do not acquire universal behavior merely because
they appear in `altnames`. A key such as `warehouse`, `protobuf`, or `sql` is an
application-defined annotation unless a particular tool explicitly documents
how it uses that purpose.

In particular, an `altnames.sql` entry is not guaranteed to control SQL
generation. The tests verify that a non-JSON purpose does not replace the
JSON wire name. A custom purpose needs a policy that defines its meaning and a
tool that implements that policy; the purpose-key name alone is not a storage
contract.

## Test the boundary, retain the source

For each generated language, keep a small contract fixture and assert the exact
JSON keys. Also inspect the generated identifier, because sanitization can
create collisions: two distinct schema names may collapse to one code spelling
after case conversion. The generator needs a deterministic response rather
than a silent merge.

Do not edit generated annotations as the primary fix. Regeneration will erase
the repair, and another language will still be wrong. Correct the JSON
Structure annotation or the generator configuration, regenerate, and test the
wire form.

A codebase may have five idiomatic names for one property. That is fine. The
wire has one declared name, and the JSON Structure schema remains the source
contract that tells every generated serializer what it is.
