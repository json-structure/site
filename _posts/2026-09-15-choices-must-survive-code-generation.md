---
layout: post
title: "Choices Must Survive Code Generation"
date: 2026-09-15
published: false
author: Clemens Vasters
specification_scope: Core only.
uses_structurize: true
image: /social-cards/choices-must-survive-code-generation.png
description: >-
  Code generation should preserve a JSON Structure choice as an explicit sum
  type, and make any weaker projection visible.
---

A fulfillment event permits exactly one outcome: a shipment was dispatched, or
an order is ready for collection. Generated code with two nullable properties
also permits both outcomes and no outcome. That larger state space violates the
contract before application logic has done any useful work.

JSON Structure represents the event as a
[`choice`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#choice)
with a closed set of named alternatives. The declaration carries the
exclusivity that a bag of optional fields cannot recover from its own shape.

Structurize 3.9.0 does not project this root choice consistently. Rust emits an
enum and Java emits a class hierarchy. C# emits two nullable `object` members.
TypeScript and Go emit the branch types but no root choice declaration, while
the Protocol Buffers converter emits the branch messages without a `oneof`.
ASN.1 does emit `CHOICE`. Those differences are observable output, not a survey
of what the target languages could express.

> The examples use [Structurize 3.9.0](https://pypi.org/project/structurize/3.9.0/).
> Install the pinned release from PyPI:
>
> ```powershell
> python -m pip install structurize==3.9.0
> ```

## One event, two possible outcomes

Consider a fulfillment event that reports either a dispatched shipment or an
order ready for collection. The tagged form carries the selected alternative
as the single property of a wrapper object:

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://schemas.example.com/fulfillment-event.json",
  "name": "FulfillmentEvent",
  "type": "choice",
  "choices": {
    "shipmentDispatched": {
      "type": { "$ref": "#/definitions/ShipmentDispatched" }
    },
    "pickupReady": {
      "type": { "$ref": "#/definitions/PickupReady" }
    }
  },
  "definitions": {
    "ShipmentDispatched": {
      "type": "object",
      "name": "ShipmentDispatched",
      "properties": {
        "fulfillmentId": { "type": "uuid" },
        "trackingCode": { "type": "string" }
      },
      "required": ["fulfillmentId", "trackingCode"]
    },
    "PickupReady": {
      "type": "object",
      "name": "PickupReady",
      "properties": {
        "fulfillmentId": { "type": "uuid" },
        "pickupLocation": { "type": "string" }
      },
      "required": ["fulfillmentId", "pickupLocation"]
    }
  }
}
```

The JSON value makes the branch explicit:

```json
{
  "shipmentDispatched": {
    "fulfillmentId": "4d616677-5a1b-4d1d-86df-1fc4a0236bc8",
    "trackingCode": "ZK-20418"
  }
}
```

This is not merely an object with two possible property names. It is one value
whose type is the selected alternative.

## Sum types have several dialects

In the [Avrotize implementation](https://github.com/clemensv/avrotize/tree/8dbb19a3a48239679f0df097399c5ddc8cd48c76),
the five language commands used here are registered as `s2cs`, `s2java`,
`s2ts`, `s2go`, and `s2rust` in the
[command registry](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/commands.json).
The invocation is intentionally unsurprising:

```bash
structurize s2cs fulfillment-event.struct.json --out generated/csharp
structurize s2java fulfillment-event.struct.json --out generated/java
structurize s2ts fulfillment-event.struct.json --out generated/typescript
structurize s2go fulfillment-event.struct.json --out generated/go
structurize s2rust fulfillment-event.struct.json --out generated/rust
```

The interesting part is the resulting type shape. The C#
[converter](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/structuretocsharp.py#L960-L1110)
projects the choice as a wrapper with nullable `object` members.
Java's [choice template](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/structuretojava/choice_core.jinja)
uses nested alternative classes named after the branches. The TypeScript
[converter](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/structuretots.py)
can return a union expression while resolving a choice, but this root-choice
command emits only `ShipmentDispatched.ts` and `PickupReady.ts`. Rust's
[converter](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/structuretorust.py)
emits enum variants.

For a complete multi-file code-generation example, the prebuilt Avrotize
[Inventory to C# gallery example](https://avrotize.com/gallery/struct-to-csharp-stjson/)
shows its source schema and output tree. For the small schema here, each
disclosure shows one representative generated file.

These excerpts come from the generated C#, Java, and Rust files:

<details class="generated-output" markdown="1">
<summary>Generated output: <code>FulfillmentEvent.cs</code></summary>

```csharp
public partial class FulfillmentEvent
{
  /// <summary>
  /// Gets or sets the ShipmentDispatched value
  /// </summary>
  public object? ShipmentDispatched { get; set; } = null;
  /// <summary>
  /// Gets or sets the PickupReady value
  /// </summary>
  public object? PickupReady { get; set; } = null;
```

</details>

<details class="generated-output" markdown="1">
<summary>Generated output: <code>FulfillmentEvent.java</code></summary>

```java
@JsonTypeInfo(use = JsonTypeInfo.Id.NAME, include = JsonTypeInfo.As.WRAPPER_OBJECT, property = "type")
@JsonSubTypes({
  @JsonSubTypes.Type(value = ShipmentDispatched.class, name = "shipmentDispatched"),
  @JsonSubTypes.Type(value = PickupReady.class, name = "pickupReady")
})
public abstract class FulfillmentEvent {
  public FulfillmentEvent() {}

  /** shipmentDispatched variant */
  public static class ShipmentDispatched extends FulfillmentEvent {
    private java.ShipmentDispatched value;

    public ShipmentDispatched() {}

    public ShipmentDispatched(java.ShipmentDispatched value) {
      this.value = value;
    }

    public java.ShipmentDispatched getValue() { return value; }
    public void setValue(java.ShipmentDispatched value) { this.value = value; }
  }

  /** pickupReady variant */
  public static class PickupReady extends FulfillmentEvent {
    private java.PickupReady value;

    public PickupReady() {}

    public PickupReady(java.PickupReady value) {
      this.value = value;
    }

    public java.PickupReady getValue() { return value; }
    public void setValue(java.PickupReady value) { this.value = value; }
  }
}
```

</details>

<details class="generated-output" markdown="1">
<summary>Generated output: <code>fulfillmentevent.rs</code></summary>

```rust
pub enum FulfillmentEvent {
    ShipmentDispatched(ShipmentDispatched),
    PickupReady(PickupReady)
}
```

</details>

Rust expresses exclusivity in the type itself, and Java encodes the branch set
through a class hierarchy. TypeScript produces no `FulfillmentEvent.ts` or
named alias for this input. Go similarly writes the two branch structs but no
root choice declaration. Treating an internal converter type expression or a
hypothetical envelope as generated output would overstate what the commands
produced.

The [Java tests](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/test/test_structuretojava.py),
[TypeScript tests](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/test/test_structuretots.py), and
[Rust tests](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/test/test_structuretorust.py)
exercise those generators.

The C# wrapper itself permits both members or neither. Its reader loops over
properties and can accept more than one recognized branch. Its writer chooses
the first non-null branch in generated branch order. The
[C# tests](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/test/test_structuretocsharp.py)
cover the generator, but the schema remains the stronger exclusivity statement.
The generated project also fails `dotnet build`: because both branch payloads
become `object`, the class contains `FulfillmentEvent(object
shipmentdispatched)` and `FulfillmentEvent(object pickupready)`. Parameter names
do not distinguish constructor signatures, so the compiler reports `CS0111`.
The wrapper above is generated output, not a claim that this release emits a
buildable C# choice type.

## Some projections weaken the choice

The absence of a root declaration in the TypeScript and Go output is stronger
than a weak representation: callers receive no generated type for the choice
at all. Generated adapters must recover the root contract from the source
schema.

Protocol Buffers has a `oneof` construct, but the
[`structuretoproto.py` converter](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/structuretoproto.py)
does not emit one for this root choice. The generated `.proto` contains only
the two branch messages:

<details class="generated-output" markdown="1">
<summary>Generated output: <code>proto.proto</code></summary>

```proto
message ShipmentDispatched {
  string fulfillmentId = 1;
  string trackingCode = 2;
}

message PickupReady {
  string fulfillmentId = 1;
  string pickupLocation = 2;
}
```

</details>

ASN.1 does preserve the root branch set with
[`CHOICE`](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/structuretoasn1.py):

<details class="generated-output" markdown="1">
<summary>Generated output: <code>fulfillment-event.asn</code></summary>

```asn1
FulfillmentEvent ::= CHOICE { shipmentDispatched ShipmentDispatched, pickupReady PickupReady }
```

</details>

The Parquet and Iceberg commands do not produce a storage shape for this input.
Both reject it with `Expected a JSON Structure schema with type 'object' at the
top level`. Their internal choice mapping is therefore not evidence of an
artifact generated from this root-choice schema. Wrap the choice in a root
object before evaluating those projections, then inspect the result rather
than inferring one from converter code.

## Keep the loss at the boundary

In these tested Structurize 3.9.0 outputs, the Rust enum and ASN.1 `CHOICE`
preserve the branch set, Java provides a hierarchy, C# weakens branch values to
`object`, and three commands omit or reject the root choice. Those observations
describe this implementation; they do not limit what the target
languages or formats can express.

Review generated output by asking one question: which values can this artifact
represent that the JSON Structure contract forbids? If the answer is "both
alternatives," "no alternative," or "anything at all," put the missing check
at that boundary. Do not weaken the source schema to make the generated shape
look more honest. Keep the choice in the contract, where every projection can
return to it.
