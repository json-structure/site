---
layout: post
title: "Every Projection Has a Semantic Budget"
date: 2026-10-20
published: false
author: Clemens Vasters
specification_scope: Core with the Units and Validation companion specifications.
uses_structurize: true
image: /social-cards/every-projection-has-a-semantic-budget.png
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

With this schema, Structurize exposes semantic losses and converter
defects. The Protocol Buffers converter produces no artifact for the complete schema below; it exits with
`unhashable type: 'dict'`. XSD emits `xs:choice`, but writes a Python dictionary
as one alternative's `type` attribute, which an independent XSD reader rejects.
ASN.1 preserves `SET OF`, `CHOICE`, and tuple structure and compiles with
`asn1tools`, but it does not carry the `double` range into the generated module.

Together, the target format and converter determine the projection's semantic
budget. Review it before treating a successful compile as evidence of
equivalence.

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

The command names and options are defined in
[`commands.json`](https://github.com/clemensv/avrotize/blob/main/avrotize/commands.json).
Running all three commands does not promise three semantically identical
contracts. Each converter preserves a different subset of the source contract.

For complex multi-file code-generation examples, use the prebuilt Avrotize
[Structurize gallery](https://avrotize.com/gallery/#structurize), which shows
source schemas beside complete generated output trees. The evidence below uses
the article-specific schema above and single-file schema projections.

## The Protocol Buffers converter fails before producing output

Protocol Buffers does not have a native set whose type promises uniqueness, and
the converter maps simpler sets to `repeated`. That mapping is not the result of
the command shown here, however. Both the regular invocation and the
`--allow-optional` invocation fail with `unhashable type: 'dict'` before writing
a `.proto` file. The tuple property triggers a code path that treats a nested
schema dictionary as a hashable primitive type.

<details class="generated-output" markdown="1">
<summary>Command output: <code>structurize s2p</code></summary>

```text
Error:  unhashable type: 'dict'
```

</details>

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
[`structuretoxsd.py` converter](https://github.com/clemensv/avrotize/blob/main/avrotize/structuretoxsd.py)
must place JSON-shaped declarations into that structure.

The converter emits `xs:choice` for the tagged `delivery` choice,
despite the absence of a selector. Its `ship` branch is not valid XSD: the
generated attribute is `type="{'$ref': '#/definitions/Address'}"`. The .NET XSD
reader reports that value as invalid. The tuple also becomes an empty
`xs:sequence`, while the set becomes repeated `item` elements and loses
uniqueness.

<details class="generated-output" markdown="1">
<summary>Generated output: <code>fulfillment-order.xsd</code></summary>

```xml
<?xml version="1.0" ?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="urn:example:schema" targetNamespace="urn:example:schema" elementFormDefault="qualified">
  <xs:element name="FulfillmentOrder">
    <xs:complexType>
      <xs:sequence>
        <xs:element name="orderId" minOccurs="1" maxOccurs="1" type="xs:string"/>
        <xs:element name="delivery" minOccurs="1" maxOccurs="1" type="Delivery"/>
        <xs:element name="handlingCodes" minOccurs="1" maxOccurs="1">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="item" minOccurs="0" maxOccurs="unbounded">
                <xs:simpleType>
                  <xs:restriction base="xs:string">
                    <xs:enumeration value="fragile"/>
                    <xs:enumeration value="keep-dry"/>
                    <xs:enumeration value="upright"/>
                  </xs:restriction>
                </xs:simpleType>
              </xs:element>
            </xs:sequence>
          </xs:complexType>
        </xs:element>
        <xs:element name="packageWeight" minOccurs="0" maxOccurs="1">
          <xs:annotation>
            <xs:appinfo source="json-structure-extensions">{
  &quot;unit&quot;: &quot;kg&quot;
}</xs:appinfo>
          </xs:annotation>
          <xs:simpleType>
            <xs:restriction base="xs:double">
              <xs:minInclusive value="0"/>
              <xs:maxInclusive value="31.5"/>
            </xs:restriction>
          </xs:simpleType>
        </xs:element>
        <xs:element name="warehouseSlot" minOccurs="0" maxOccurs="1">
          <xs:complexType>
            <xs:sequence/>
          </xs:complexType>
        </xs:element>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
  <xs:complexType name="Delivery">
    <xs:choice>
      <xs:element name="ship" type="{'$ref': '#/definitions/Address'}"/>
      <xs:element name="collectAt" type="xs:string"/>
    </xs:choice>
  </xs:complexType>
  <xs:complexType name="Address">
    <xs:sequence>
      <xs:element name="street" minOccurs="1" maxOccurs="1" type="xs:string"/>
      <xs:element name="city" minOccurs="1" maxOccurs="1" type="xs:string"/>
      <xs:element name="postalCode" minOccurs="1" maxOccurs="1" type="xs:string"/>
    </xs:sequence>
  </xs:complexType>
</xs:schema>
```

</details>

Compile the generated schema with an XSD processor before validating any XML.
For this exact output, that first check already fails. Converter success proves
only that a file was written.

## ASN.1 preserves a different subset

ASN.1 has its own structural vocabulary and encoding ecosystem. The
[`structuretoasn1.py` converter](https://github.com/clemensv/avrotize/blob/main/avrotize/structuretoasn1.py)
can map `SET OF`, `CHOICE`, enumerations, tuples, and references into ASN.1
constructs. The converter does not apply `minimum` and `maximum` bounds
to a `double`, so the package-weight range is not present in that projection.

<details class="generated-output" markdown="1">
<summary>Generated output: <code>fulfillment-order.asn</code></summary>

```asn1
Fulfillment-order DEFINITIONS AUTOMATIC TAGS ::= BEGIN

Address ::= SEQUENCE {
    street UTF8String,
    city UTF8String,
    postalCode UTF8String
}

FulfillmentOrder ::= SEQUENCE {
    orderId UTF8String,
    delivery CHOICE { ship Address, collectAt UTF8String },
    handlingCodes SET OF ENUMERATED { fragile(0), keep-dry(1), upright(2) },
    packageWeight REAL OPTIONAL,
    warehouseSlot SEQUENCE { aisle UTF8String, shelf INTEGER (0..65535) } OPTIONAL
}

END
```

</details>

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

JSON Structure gives the system one authoritative contract. For each generated
projection, record what the converter preserves and what it drops. A clean
compile proves syntax, not equivalence.