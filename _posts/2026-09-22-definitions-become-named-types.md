---
layout: post
title: "Compound Definitions Can Become Named Types"
date: 2026-09-22
published: false
author: Clemens Vasters
image: /social-cards/definitions-become-named-types.png
description: >-
  Inspect how each Structurize target handles local compound-definition
  references; some preserve named types while others currently erase them.
---

Two properties can contain objects with identical members and still denote
different concepts. Conversely, two references to one definition denote the
same contract even when generated code places the declaration in another file
or namespace. Copying the object shape into every use site erases that identity.

JSON Structure assigns compound declarations stable locations under
[`definitions`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#definitions-keyword)
and connects use sites with local
[`$ref`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#ref-keyword)
values. Structurize 3.9.0 emits named declarations for the example in several
targets, but it does not make every generated property refer to them. Java, Go,
and Rust preserve the `Parcel` property type. C# emits `Parcel.cs` yet types the
property as `object`; TypeScript emits neither a `Parcel` class nor a useful
reference.

Target naming rules may change the package, module, case, or legal identifier.
Whether the referenced identity survives is a converter behavior to test, not
a guarantee to infer from the source `$ref`. Primitive references fare worse in
this example and become `object`, `Object`, `interface{}`, or
`serde_json::Value` rather than constrained strings.

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

## Reuse is visible in the source

Continue the fulfillment model with a reusable parcel and tracking code. The
event and the parcel both refer to the same `TrackingCode` definition:

```json
{
  "$schema": "https://json-structure.org/meta/validation/v0/#",
  "$id": "https://schemas.example.com/fulfillment-event.json",
  "name": "FulfillmentEventSchema",
  "$uses": ["JSONStructureValidation"],
  "$root": "#/definitions/Events/ShipmentDispatched",
  "definitions": {
    "Common": {
      "TrackingCode": {
        "type": "string",
        "pattern": "^[A-Z]{2}-[0-9]{5}$"
      },
      "Parcel": {
        "name": "Parcel",
        "type": "object",
        "properties": {
          "parcelId": { "type": "uuid" },
          "trackingCode": {
            "type": { "$ref": "#/definitions/Common/TrackingCode" }
          }
        },
        "required": ["parcelId", "trackingCode"]
      }
    },
    "Events": {
      "ShipmentDispatched": {
        "name": "ShipmentDispatched",
        "type": "object",
        "properties": {
          "fulfillmentId": { "type": "uuid" },
          "trackingCode": {
            "type": { "$ref": "#/definitions/Common/TrackingCode" }
          },
          "parcel": {
            "type": { "$ref": "#/definitions/Common/Parcel" }
          }
        },
        "required": ["fulfillmentId", "trackingCode", "parcel"]
      }
    }
  }
}
```

The paths identify `Common/TrackingCode` and `Common/Parcel`, distinguish them
from declarations in other namespaces, and give every use site one stable
destination. The earlier article
[Definitions Are a Type Library]({% post_url 2026-09-16-definitions-are-a-type-library %})
explains those schema semantics. The generated-artifact question is what
happens after a language cannot use the JSON Pointer as a type name.

## A compound reference may become a target-language reference

Run the same source through the registered generators:

```bash
structurize s2cs fulfillment-event.struct.json --out generated/csharp
structurize s2java fulfillment-event.struct.json --out generated/java
structurize s2ts fulfillment-event.struct.json --out generated/typescript
structurize s2go fulfillment-event.struct.json --out generated/go
structurize s2rust fulfillment-event.struct.json --out generated/rust
```

Those commands are defined in the pinned
[Avrotize command registry](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/commands.json).
The generated files give a mixed answer. Java declares
`private java.common.Parcel parcel;`, Go declares `Parcel CommonParcel`, and
Rust declares `pub parcel: crate::common::parcel::Parcel`. Those three use sites
retain a named compound type.

C# writes `Common/Parcel.cs`, but the generated `ShipmentDispatched` property is
`public required object parcel`. The declaration exists without a typed use
site. TypeScript writes empty `Common` and `Events` classes and no `Parcel`
declaration. The same source identity therefore survives in three targets,
degrades in one, and disappears in another. The command list alone does not
promise more.

`TrackingCode` marks a broader current limitation. It becomes `object` in C#,
`Object` in Java, `interface{}` in Go, and `serde_json::Value` in Rust; no
generated wrapper carries the string pattern. Keep constraints such as the
tracking-code pattern in schema validation, and test each generated target
before treating primitive definitions as domain types.
## Namespace trees do not travel unchanged

`Common/Parcel` is a path through nested JSON objects. It is not a universal
package spelling. C# may use namespaces, Java packages, TypeScript modules,
Go packages, and Rust modules, but their rules and generator layouts differ.
Some generators flatten part of the hierarchy; others preserve more of it.
The [pinned implementation tree](https://github.com/clemensv/avrotize/tree/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize)
is authoritative for the current projection, not an imagined cross-language
namespace rule.

That difference becomes visible when two schema namespaces each contain a
`Parcel`. The schema can distinguish them by full pointer:

```text
#/definitions/Inbound/Parcel
#/definitions/Outbound/Parcel
```

A target that flattens both names must disambiguate them. Prefixing,
qualification, or another deterministic collision policy can work. Silently
merging the declarations cannot, because the source says they are different
types even if their current properties happen to match.

## Legal identifiers are projections too

Target languages reserve words and impose naming conventions. Generators
therefore sanitize identifiers and convert case. A schema property such as
`pickup_location` may become `PickupLocation` in C#, `pickupLocation` in Java,
and `pickup_location` in Rust. A definition that collides with a reserved word
needs another legal spelling.

This transformation is necessary, but it creates two identities to track:

- The schema path identifies the contract declaration.
- The generated identifier identifies its projection in one target.

Generated code should make that mapping deterministic and serializer metadata
should preserve the wire spelling where needed. Renaming a generated class by
hand is fragile because regeneration will repeat the generator's policy. If a
target name matters, treat the generator configuration and version as part of
the build, and test the public generated surface.

## Identity outranks shape

A useful review starts from references, not files. For each local `$ref`, find
the corresponding generated declaration and verify that all use sites point to
it. Then check namespace collisions, case conversion, reserved words, and the
constraints that a target type cannot express.

The generated declaration may move between packages or acquire a sanitized
name as tooling evolves. The source identity does not move with it:
`#/definitions/Common/Parcel` still means the declaration at that pointer.
That stable center is why definitions are worth preserving as named types. A
generator can adapt a supported compound name to a language without dissolving
the concept.
