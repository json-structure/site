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
  Code generation adapts a JSON Structure choice to the type system,
  serialization model, and artifact boundaries of each target.
---

A fulfillment event permits exactly one outcome: a shipment was dispatched, or
an order is ready for collection. Generated code with two nullable properties
also permits both outcomes and no outcome. That larger state space violates the
contract before application logic has done any useful work.

JSON Structure represents the event as a
[`choice`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#choice)
with a closed set of named alternatives. The declaration makes the alternatives
mutually exclusive; optional fields do not.

Structurize adapts this root `choice` to the idioms and artifact boundaries of
each target. Rust uses a data-carrying enum, Java a Jackson-compatible class
hierarchy, C# a serializer-oriented wrapper, and ASN.1 its native `CHOICE`.
For a root choice, TypeScript, Go, and Protocol Buffers emit the branch
declarations rather than synthesizing a root envelope, while Parquet and
Iceberg require an object-shaped root. Each mapping follows the target's type
system, serialization model, or document shape. The declarations are therefore
expected to differ. The sections below show which commands produce a complete
root representation and which produce components for an application-defined
root.

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

The object represents one value whose type is the selected alternative.

## Sum types have several dialects

In the [Avrotize implementation](https://github.com/clemensv/avrotize),
the five language commands used here are registered as `s2cs`, `s2java`,
`s2ts`, `s2go`, and `s2rust` in the
[command registry](https://github.com/clemensv/avrotize/blob/main/avrotize/commands.json).
Run the five registered language commands:

```bash
structurize s2cs fulfillment-event.struct.json --out generated/csharp
structurize s2java fulfillment-event.struct.json --out generated/java
structurize s2ts fulfillment-event.struct.json --out generated/typescript
structurize s2go fulfillment-event.struct.json --out generated/go
structurize s2rust fulfillment-event.struct.json --out generated/rust
```

Compare the resulting type shapes. The C#
[converter](https://github.com/clemensv/avrotize/blob/main/avrotize/structuretocsharp.py#L960-L1110)
projects the choice as a wrapper with nullable `object` members.
Java's [choice template](https://github.com/clemensv/avrotize/blob/main/avrotize/structuretojava/choice_core.jinja)
uses nested alternative classes named after the branches. The TypeScript
[converter](https://github.com/clemensv/avrotize/blob/main/avrotize/structuretots.py)
can return a union expression while resolving a choice. For this root choice,
the command emits `ShipmentDispatched.ts` and `PickupReady.ts`. Rust's
[converter](https://github.com/clemensv/avrotize/blob/main/avrotize/structuretorust.py)
emits enum variants.

For a complete multi-file code-generation example, the prebuilt Avrotize
[Inventory to C# gallery example](https://avrotize.com/gallery/struct-to-csharp-stjson/)
shows its source schema and output tree. For the small schema here, each
expandable section shows one representative generated file.

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

Each generator exposes the choice through conventions appropriate to its
target. Rust materializes the root as an enum and Java as a Jackson hierarchy.
C# uses a mutable wrapper, while TypeScript and Go emit reusable branch types
without synthesizing a root declaration. The first group provides a root API;
the second provides the branch components from which an application can define
one according to its serialization conventions.

The [Java tests](https://github.com/clemensv/avrotize/blob/main/test/test_structuretojava.py),
[TypeScript tests](https://github.com/clemensv/avrotize/blob/main/test/test_structuretots.py), and
[Rust tests](https://github.com/clemensv/avrotize/blob/main/test/test_structuretorust.py)
exercise those generators.

The C# wrapper itself permits both members or neither. Its reader loops over
properties and can accept more than one recognized branch. Its writer chooses
the first non-null branch in generated branch order. The
[C# tests](https://github.com/clemensv/avrotize/blob/main/test/test_structuretocsharp.py)
cover the generator, but the schema still forbids states that the generated
class permits.
In this example, both C# branch payloads resolve to `object`. The generated
overloads `FulfillmentEvent(object shipmentdispatched)` and
`FulfillmentEvent(object pickupready)` therefore have the same CLR signature;
parameter names do not distinguish overloads. A C# integration can use the
mutable properties directly or introduce distinct payload types so that the
constructor signatures differ. This constraint is separate from the decision
to represent the choice as a serializer-oriented wrapper.

## Root choices across target formats

TypeScript and Go emit the branch declarations without synthesizing a root
envelope. An application that needs such an envelope can define one according
to its serialization and validation conventions.

Protocol Buffers has a `oneof` construct, but the
[`structuretoproto.py` converter](https://github.com/clemensv/avrotize/blob/main/avrotize/structuretoproto.py)
emits the two branch messages for this root choice rather than synthesizing an
enclosing `oneof`:

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

ASN.1 represents the root branch set with
[`CHOICE`](https://github.com/clemensv/avrotize/blob/main/avrotize/structuretoasn1.py):

<details class="generated-output" markdown="1">
<summary>Generated output: <code>fulfillment-event.asn</code></summary>

```asn1
FulfillmentEvent ::= CHOICE { shipmentDispatched ShipmentDispatched, pickupReady PickupReady }
```

</details>

The Parquet and Iceberg converters require an object-shaped row root. For this
input, both report `Expected a JSON Structure schema with type 'object' at the
top level`. Wrap the choice in a root object when evaluating their nested-choice
mapping.

## Evaluate each target contract

The Rust enum, Java hierarchy, C# wrapper, and ASN.1 `CHOICE` are
target-specific root representations. The TypeScript, Go, and Protocol Buffers
outputs provide branch declarations for a target-specific root defined by the
application. Review each result for its intended wire behavior, construction
rules, and tooling integration.

The JSON Structure declaration remains the common contract. Target-specific
code can enforce additional construction rules or supply an envelope where the
target integration requires one, without changing the source choice.
