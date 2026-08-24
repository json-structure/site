---
layout: post
title: "Every Target Format Has a Semantic Budget"
date: 2026-10-20
published: false
author: Clemens Vasters
image: /social-cards/every-target-format-has-a-semantic-budget.png
description: >-
  Treat Protocol Buffers, XSD, and ASN.1 outputs as format-specific projections
  whose preserved semantics must be tested explicitly.
---

A generated schema can compile cleanly and still weaken the contract. Protocol
Buffers, XML Schema (XSD), and ASN.1 have different type systems; none can
recover a meaning that its vocabulary or the converter does not encode.

JSON Structure distinguishes set uniqueness, choice alternatives, numeric
bounds and units, and tuple positions. Structurize reads those declarations and
projects them through a target-specific mapping.

The current commands make concrete compromises and expose defects. Protocol
Buffers produces no artifact for the complete schema below; it exits with
`unhashable type: 'dict'`. XSD emits `xs:choice`, but writes a Python dictionary
as one alternative's `type` attribute, which an independent XSD reader rejects.
ASN.1 preserves `SET OF`, `CHOICE`, and tuple structure and compiles with
`asn1tools`, but it does not carry the `double` range into the generated module.

That preserved and discarded meaning is the target's semantic budget. Review
it before treating a successful compile as evidence of equivalence.

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

## One order, three projections

Use the same fulfillment contract throughout. Its complete form contains an
order identifier, a delivery choice, a set of handling codes, a package-weight
range in kilograms, and a tuple that records warehouse aisle and shelf:

```json
{
  "$schema": "https://json-structure.org/meta/extended/v0/#",
  "$id": "https://schemas.example.com/fulfillment/order/v1",
  "name": "FulfillmentOrder",
  "type": "object",
  "$uses": ["JSONStructureValidation", "JSONStructureUnits"],
  "definitions": {
    "Address": {
      "name": "Address",
      "type": "object",
      "properties": {
        "street": { "type": "string" },
        "city": { "type": "string" },
        "postalCode": { "type": "string" }
      },
      "required": ["street", "city", "postalCode"]
    }
  },
  "properties": {
    "orderId": { "type": "uuid" },
    "delivery": {
      "type": "choice",
      "name": "Delivery",
      "choices": {
        "ship": { "type": { "$ref": "#/definitions/Address" } },
        "collectAt": { "type": "string" }
      }
    },
    "handlingCodes": {
      "type": "set",
      "items": {
        "type": "string",
        "enum": ["fragile", "keep-dry", "upright"]
      }
    },
    "packageWeight": {
      "type": "double",
      "minimum": 0,
      "maximum": 31.5,
      "unit": "kg"
    },
    "warehouseSlot": {
      "type": "tuple",
      "name": "WarehouseSlot",
      "properties": {
        "aisle": { "type": "string" },
        "shelf": { "type": "uint16" }
      },
      "tuple": ["aisle", "shelf"]
    }
  },
  "required": ["orderId", "delivery", "handlingCodes"]
}
```

Generate the three artifacts independently:

```bash
structurize s2p fulfillment-order.struct.json --out generated/proto
structurize s2x fulfillment-order.struct.json --out fulfillment-order.xsd
structurize s2asn fulfillment-order.struct.json --out fulfillment-order.asn
```

The command names and options are defined in the pinned
[`commands.json`](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/commands.json).
Running all three commands does not promise three semantically identical
contracts. It asks three converters to spend three different budgets.

## Protocol Buffers fails before spending uniqueness

Protocol Buffers does not have a native set whose type promises uniqueness, and
the converter maps simpler sets to `repeated`. That mapping is not the result of
the command shown here, however. Both the regular invocation and the
`--allow-optional` invocation fail with `unhashable type: 'dict'` before writing
a `.proto` file. The tuple property triggers a code path that treats a nested
schema dictionary as a hashable primitive type.

Remove or separately model the unsupported construct before evaluating how the
remaining set and numeric fields project. Do not show a plausible `repeated`
field as output from a command that produced no artifact.

Presence also needs an explicit decision. Nullable handling in this conversion
requires `--allow-optional`:

```bash
structurize s2p fulfillment-order.struct.json \
  --out generated/proto \
  --allow-optional
```

Do not add that switch mechanically. Review how absent, null, and default values
map into the generated API and wire representation. Similar-looking values can
carry different business meaning in an order workflow.

## XSD follows XML's structure

XSD is not Protocol Buffers with angle brackets. It models XML elements,
attributes, complex types, sequences, choices, and occurrence constraints. The
[`structuretoxsd.py` converter](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/structuretoxsd.py)
must place JSON-shaped declarations into that structure.

The pinned converter does emit `xs:choice` for the tagged `delivery` choice,
despite the absence of a selector. Its `ship` branch is not valid XSD: the
generated attribute is `type="{'$ref': '#/definitions/Address'}"`. The .NET XSD
reader reports that value as invalid. The tuple also becomes an empty
`xs:sequence`, while the set becomes repeated `item` elements and loses
uniqueness.

Compile the generated schema with an XSD processor before validating any XML.
For this exact output, that first check already fails. Converter success proves
only that a file was written.

## ASN.1 preserves a different subset

ASN.1 has its own structural vocabulary and encoding ecosystem. The
[`structuretoasn1.py` converter](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/structuretoasn1.py)
can map `SET OF`, `CHOICE`, enumerations, tuples, and references into ASN.1
constructs. The pinned converter does not apply `minimum` and `maximum` bounds
to a `double`, so the package-weight range is not present in that projection.

Useful is not universal. JSON number representations, annotations, defaults,
nullability, name rules, and particular encoding choices still require review.
Record the exact constructs, converter version, and encoding profile you
tested. A successful conversion is not evidence of losslessness.

## Test the meaning you depend on

Generated syntax validation is necessary. Compile the `.proto`, validate the
`.xsd`, and parse or compile the ASN.1 module with the target toolchain. Those
checks catch malformed output, unsupported syntax, and some broken references.
They provide evidence of well-formed generated artifacts, not semantic
equivalence.

Add projection tests around the source meanings that matter to fulfillment:

- Submit duplicate handling codes and verify where uniqueness is enforced.
- Exercise both delivery alternatives and reject an instance containing both.
- Try package weights at, inside, and outside the declared range.
- Round-trip the warehouse tuple and verify position is preserved.
- Test absent, explicit null, and defaulted values separately.

Some checks belong in generated validators, some in adapters, and some at the
service boundary. Their location is secondary. The important part is recording
which semantics the target carries natively and which semantics need help.

A projection ledger can be as simple as a table in the build documentation with
four columns: source construct, target representation, preserved meaning, and
compensating check. Keep it beside the generator version and command line. That
turns an implicit assumption into a reviewable engineering decision.

JSON Structure gives the system one authoritative contract. Generators make
that contract useful in ecosystems with different strengths, but they do not
erase those differences. Know each target's semantic budget, test the meanings
you spend, and treat a clean compile as the beginning of evidence rather than
the end.