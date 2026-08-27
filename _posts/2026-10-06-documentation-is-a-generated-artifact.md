---
layout: post
title: "Documentation Is a Generated Artifact"
date: 2026-10-06
published: false
author: Clemens Vasters
specification_scope: Core with the Alternate Names, Units, and Validation companion specifications.
uses_structurize: true
image: /social-cards/documentation-is-a-generated-artifact.png
description: >-
  Generate reference documentation from JSON Structure while keeping the
  schema, not the rendered page, authoritative.
---

Generate reference documentation from the schema. When people maintain a
property table beside the schema, a field can change while the table continues
to describe the old contract. Both files still look valid, so review alone may
not expose the difference.

A rendered page cannot recover declarations that were never copied into it.
JSON Structure keeps names, descriptions, required properties, choices,
constraints, units, alternate names, defaults, and examples with the types they
qualify.

Structurize's `s2md` converter reads those declarations and renders its
supported subset as Markdown. In the pinned version tested below, it preserves
reader-facing descriptions and type details, transforms the schema graph into
property lists and sections, and omits the root `name` and `$root`. It cannot
derive workflow rationale from type declarations. Regenerate the reference
with every contract change, and write operational guidance around it rather
than into it.

> The examples use [Structurize 3.9.0](https://pypi.org/project/structurize/3.9.0/).
> Install the pinned release from PyPI:
>
> ```powershell
> python -m pip install structurize==3.9.0
> ```

## Start with the fulfillment contract

Consider a fulfillment service that receives orders from several sales
channels. The abbreviated schema below defines the root object, a reusable
address, a choice of delivery methods, and a weight with a unit annotation:

```json
{
  "$schema": "https://json-structure.org/meta/validation/v0/#",
  "$id": "https://schemas.example.com/fulfillment-order",
  "name": "FulfillmentOrderSchema",
  "$uses": ["JSONStructureAlternateNames", "JSONStructureUnits", "JSONStructureValidation"],
  "$root": "#/definitions/FulfillmentOrder",
  "definitions": {
    "Address": {
      "name": "Address",
      "description": "A postal delivery address.",
      "type": "object",
      "properties": {
        "street": { "type": "string" },
        "city": { "type": "string" },
        "postalCode": {
          "type": "string",
          "altnames": { "warehouseCsv": "postal_code" }
        }
      },
      "required": ["street", "city", "postalCode"]
    },
    "Delivery": {
      "name": "Delivery",
      "type": "choice",
      "choices": {
        "ship": { "type": { "$ref": "#/definitions/Address" } },
        "collectAt": { "type": "string" }
      }
    },
    "FulfillmentOrder": {
      "name": "FulfillmentOrder",
      "description": "An order released to fulfillment.",
      "type": "object",
      "properties": {
        "orderId": { "type": "uuid" },
        "delivery": {
          "type": { "$ref": "#/definitions/Delivery" }
        },
        "packageWeight": {
          "type": "double",
          "minimum": 0,
          "unit": "kg",
          "default": 0,
          "examples": [1.25]
        }
      },
      "required": ["orderId", "delivery"]
    }
  }
}
```

The schema is intentionally richer than a page of prose. Names, descriptions,
references, constraints, units, alternate names, defaults, and examples sit
next to the declarations they qualify. A reviewer can discuss one change in one
place.

That concentration matters. If `packageWeight` changes from kilograms to grams,
the type can remain `double` while the scale changes from one kilogram to one
gram, a factor of 1,000. A hand-maintained table that records only `double`
remains syntactically correct but no longer states the same unit. The schema
records the type and unit together.

## Render the page with `s2md`

The Structurize command is deliberately unceremonious:

```powershell
New-Item -ItemType Directory -Force generated | Out-Null
structurize s2md fulfillment-order.struct.json --out generated/fulfillment-order.md
```

The [`s2md` command registration](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/commands.json)
connects that command to the Markdown converter. The
[`structuretomd.py` implementation](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/structuretomd.py)
emits a `# schema` heading, the schema ID and extension list, then a
`## Definitions` section. It renders the `Address`, `Delivery`, and
`FulfillmentOrder` descriptions and property or choice lists. The weight entry
contains `unit: kg`, `examples: [1.25]`, `default: 0`, and `minimum: 0`; the
postal-code entry contains its alternate name. References appear as literal
dictionaries such as `{'$ref': '#/definitions/Address'}` rather than linked
type names. The output omits the root `name` and `$root`.

<details class="generated-output" markdown="1">
<summary>Generated output: <code>fulfillment-order.md</code></summary>

```markdown
# fulfillment-order.struct
**Schema ID:** `https://schemas.example.com/fulfillment-order`
**Uses Extensions:** JSONStructureAlternateNames, JSONStructureUnits, JSONStructureValidation
## Definitions

### Address

A postal delivery address.
**Properties:**
- **street** (required): `string`
- **city** (required): `string`
- **postalCode** (required): `string`
  - Extensions: altnames: {warehouseCsv: postal_code}

### Delivery

**Choices:**
- **ship**: `{'$ref': '#/definitions/Address'}`
- **collectAt**: `string`

### FulfillmentOrder

An order released to fulfillment.
**Properties:**
- **orderId** (required): `uuid`
- **delivery** (required): `{'$ref': '#/definitions/Delivery'}`
- **packageWeight**: `double`
  - Extensions: unit: kg, examples: [1.25], default: 0
  - Constraints: minimum: 0
```

</details>

The directory component in the output path is intentional. With this release,
`--out fulfillment-order.md` fails on Windows with `The system cannot find the
path specified: ''`; `generated/fulfillment-order.md` succeeds once
`generated` exists.

Check the generated file into a documentation site if that makes reviews and
publishing easier, or build it on demand. Either policy works as long as the
build can reproduce the page and detects stale output. A simple check for a
repository that commits generated Markdown looks like this:

```powershell
New-Item -ItemType Directory -Force docs/reference | Out-Null
structurize s2md schemas/fulfillment-order.struct.json `
  --out docs/reference/fulfillment-order.md
git diff --exit-code -- docs/reference/fulfillment-order.md
```

The first command refreshes the projection. The second fails when a schema
change arrived without its generated documentation. Reviewers then see both the
contract edit and its reader-facing consequence in the same change.

## Add prose around the artifact

Generated reference material answers precise questions: Which properties are
required? What does this choice contain? Which unit qualifies the number? It
does not explain why store collection and postal shipment share one operation,
how warehouse allocation works, or what to do when a carrier rejects an
address.

Generate declarations, constraints, defaults, and examples from the schema.
Write workflows, rationale, failure handling, and operational guidance by hand.
Link the authored guidance to the generated reference instead of copying its
property tables.

Avoid editing the generated Markdown, even for a tiny correction. Fix a wrong
description in the schema. Fix a rendering defect in the converter. Put a
workflow explanation in an authored article. A local patch to generated output
will disappear at the next build, which is exactly what generated output ought
to do.

## Regenerate in CI

Generation removes transcription drift, but it does not remove review. Inspect
the schema first, then inspect the rendered descriptions and examples. In CI,
run the exact `structurize s2md` command used by the repository and follow it
with `git diff --exit-code` for the generated Markdown. A stale reference page
then fails the build instead of becoming a second contract.
