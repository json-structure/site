---
layout: post
title: "Samples Are Evidence, Not a Contract"
date: 2026-09-01
published: true
author: Clemens Vasters
specification_scope: Core with the Units and Semantic Annotations companion specifications.
uses_structurize: true
image: /social-cards/samples-are-evidence-not-a-contract.png
description: >-
  Structurize turns observed records into a useful JSON Structure draft. Domain
  knowledge then refines the inferred types, presence rules, and value domains.
---

The earlier post, [Structurize Turns Sample JSON into Typed Schemas]({% post_url 2026-02-04-structurize-json2s-command %}),
shows how the `json2s` command turns JSON and JSONL samples into a useful JSON
Structure draft. Turning that draft into a reviewed contract requires decisions
that no collection of samples can make.

The draft describes the evidence in the sample set. A week of shipment records,
for example, may contain `carrierService` in every row and only three status
values. Structurize can capture both observations. It cannot determine whether
the producer guarantees the field, whether the three states are the complete
lifecycle, what the fields mean, or which future changes consumers must accept.

Contract owners must supply those facts. At minimum, add a
[`description`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#description-keyword)
to each type and property so that readers know what it represents. Add the
[Units](https://json-structure.github.io/units/draft-vasters-json-structure-units.html)
companion when numbers represent measurements or money. Add the
[Semantic and Reference-System Annotations](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html)
companion when consumers need machine-readable concepts, observation roles,
time semantics, code-list identities, or reference systems. Structurize can
then project the reviewed contract into documentation and code.

> The examples use [Structurize 3.9.0](https://pypi.org/project/structurize/3.9.0/).
> Install the pinned release from PyPI:
>
> ```powershell
> python -m pip install structurize==3.9.0
> ```

## Begin with what happened

Assume a fulfillment team has collected newline-delimited JSON from a dispatch
feed:

```jsonl
{"orderId":"c28788fa-73bd-4b39-a209-2f75f82c6653","status":"allocated","carrierService":"priority-ground","dispatchAt":"2026-08-25T16:30:00Z","contact":"ops@example.com"}
{"orderId":"9b51a282-d3dd-476b-a7d7-97ace6318312","status":"dispatched","carrierService":"priority-ground","dispatchAt":"2026-08-26T09:15:00Z","contact":"dock@example.com"}
{"orderId":"dd4e44b5-aae8-4c40-8c57-5535d66e7b9d","status":"allocated","carrierService":"economy","contact":"night@example.com"}
```

[Structurize 3.9.0](https://pypi.org/project/structurize/3.9.0/) can infer a
JSON Structure schema from JSON or JSONL. Its
[CLI definition](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/commands.json)
lists the controls for input scope and inference:

```bash
structurize json2s dispatch.jsonl \
  --out shipment-observed.struct.json \
  --type-name ShipmentObservation \
  --base-id https://example.com/schemas/ \
  --sample-size 10000 \
  --infer-enums
```

`--sample-size` limits the records considered. `--infer-enums` permits enum
inference from observed value cardinality. For heterogeneous documents,
`--infer-choices` and `--choice-depth` control choice inference. Those switches
change the analysis. They do not turn the resulting file into an approved
contract.

For these three records, Structurize 3.9.0 emits this schema:

<details class="generated-output" markdown="1">
<summary>Generated output: <code>shipment-observed.struct.json</code></summary>

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://example.com/schemas/ShipmentObservation",
  "type": "object",
  "name": "ShipmentObservation",
  "properties": {
    "carrierService": {
      "type": "string"
    },
    "contact": {
      "type": "string"
    },
    "dispatchAt": {
      "type": "datetime"
    },
    "orderId": {
      "type": "string"
    },
    "status": {
      "type": "string"
    }
  },
  "required": [
    "carrierService",
    "contact",
    "orderId",
    "status"
  ]
}
```

</details>

No enum is inferred from only three records, `dispatchAt` is optional because
it is absent once, and UUID- and email-shaped values remain strings. The draft
is ready for the domain decisions that the observations alone cannot supply.

## Presence is not obligation

`json2s` derives requiredness from observed presence and nulls. A property
becomes required only when it is present in every sample and no observed value
is null. One missing or null value keeps it out of `required`.

That is a faithful statement about the input. It can still be wrong for the
contract.

In the three records above, `orderId`, `status`, `carrierService`, and `contact`
are always present. `dispatchAt` is absent once. The sample therefore supports
a presence distinction, but it provides no reason for that distinction.
Perhaps `dispatchAt` is valid only after dispatch. Perhaps one producer omitted
a mandatory value. If carrier assignment becomes asynchronous,
`carrierService` may be temporarily unavailable.

Review each inferred [`required`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#required-keyword) entry against a lifecycle rule or an API
guarantee. Also review every omission. Frequency tells you where to ask; domain
policy supplies the answer.

## Strings conceal several decisions

UUID-, URI-, email-, and Base64-like values remain strings during inference.
Leaving those values as strings avoids turning coincidental spelling into a
contract. A string that happens to parse as a UUID in the sample may be an
opaque identifier whose future syntax is wider. An email-like contact may
permit a queue name later. Base64-looking text may simply be text.

When the domain guarantee is real, promote the declaration deliberately:

```json
{
  "orderId": {
    "type": "uuid",
    "description": "Stable identifier assigned when the order is accepted."
  },
  "contact": {
    "type": "string",
    "description": "Fulfillment contact address or routing name."
  }
}
```

[`uuid`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uuid) is justified here by the order identity contract, not by three matching
lexical forms. `contact` stays a [`string`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#string) because its domain is intentionally broader
than email syntax.

The same review applies to binary data. Declaring [`binary`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#binary) carries decoding semantics,
and annotations such as [`contentEncoding`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#contentencoding-keyword) describe a processing contract. A
run of plausible characters does not establish either one.

## Review inferred date and time types

Structurize considers temporal types only when all observed non-null values for
a field are strings. If it does not infer an enum first, it selects `datetime`,
`date`, or `time` when at least 80% of those strings match its pattern for that
type. These patterns are inference heuristics, not complete RFC 3339 validators.

Check every inferred temporal type before retaining it. JSON Structure requires
[`datetime`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#datetime),
[`date`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#date),
and [`time`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#time)
values to use their corresponding RFC 3339 forms. The two observed
`dispatchAt` values end in `Z`, so `datetime` describes them. Keep that type
only if all valid future values will also satisfy the Core definition.

The type still does not say what instant the field represents. Add that meaning
in a description:

```jsonc
"dispatchAt": {
  "type": "datetime",
  "description": "Time at which the shipment left the fulfillment site."
}
```

The missing third value still requires a presence decision. The type controls
the value's representation, `required` controls its presence, and the
description states its meaning for readers. If software must distinguish an
event time from a result or ingestion time, use the Semantic Annotations
companion to state that role in machine-readable form.

## Small value sets are not automatically enums

With `--infer-enums`, enum inference requires at least five observed string
values, 2 through 50 unique values, and a unique-to-sample ratio no greater
than 10%. It also rejects values that look like UUIDs, structured IDs,
timestamps, strings longer than 50 characters, long paths or URLs, or numeric
strings. A candidate that passes those lexical and cardinality filters is still
not proof that the observed values form a closed set.

The feed currently shows `allocated` and `dispatched`. The fulfillment process
may also define `cancelled`, `held`, and `returned`, even if none occurred in
the selected records. Publishing an enum with only the observed pair would
reject valid future messages.

If the lifecycle owns a closed set, declare the full domain:

```jsonc
"status": {
  "type": "string",
  "enum": ["allocated", "dispatched", "cancelled", "held", "returned"]
}
```

If producers may add states independently, keep a string or establish an
evolution policy before closing the set. The right answer comes from ownership
and compatibility requirements, not a cardinality cutoff.

## Review the draft as a contract change

A practical inference workflow has distinct stages:

1. Run `json2s` against a named, reproducible sample set and retain the command
   options with the review.
2. Compare inferred presence, primitive types, temporal candidates, enums, and
   choices with producer guarantees and consumer requirements.
3. Add a description to every type and property. Add constraints and domain
  types that the data alone cannot establish.
4. Add units to measurements and monetary values. Add semantic annotations
  where consumers need machine-readable meaning or reference systems.
5. Validate the source samples against the edited schema. Passing confirms
   coverage of those observations; it says nothing about unobserved valid cases.
6. Publish the reviewed JSON Structure document as the source contract, with
   normal versioning and ownership.

Then project artifacts from that contract:

```powershell
New-Item -ItemType Directory -Force generated | Out-Null
structurize s2md shipment.struct.json --out generated/shipment.md
structurize s2cs shipment.struct.json --out generated/dotnet --namespace Fulfillment.Contracts
```

For complex code generation, the prebuilt Avrotize
[Inventory to C# gallery example](https://avrotize.com/gallery/struct-to-csharp-stjson/)
shows the complete source schema and generated project. One representative
output file from that gallery example is:

<details class="generated-output" markdown="1">
<summary>Generated output: <code>CategoryEnum.cs</code></summary>

```csharp
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Csharp
{
  /// <summary>
  /// CategoryEnum
  /// </summary>
  [System.Text.Json.Serialization.JsonConverter(typeof(CategoryEnumConverter))]
  public enum CategoryEnum
  {
    Electronics,
    Clothing,
    Food,
    Furniture,
    Toys,
    Books,
    Other
  }

  /// <summary>
  /// System.Text.Json converter for CategoryEnum that maps to schema values
  /// </summary>
  public class CategoryEnumConverter : System.Text.Json.Serialization.JsonConverter<CategoryEnum>
  {
    /// <inheritdoc/>
    public override CategoryEnum Read(ref System.Text.Json.Utf8JsonReader reader, Type typeToConvert, System.Text.Json.JsonSerializerOptions options)
    {
      var stringValue = reader.GetString();
      return stringValue switch
      {
        "electronics" => CategoryEnum.Electronics,
        "clothing" => CategoryEnum.Clothing,
        "food" => CategoryEnum.Food,
        "furniture" => CategoryEnum.Furniture,
        "toys" => CategoryEnum.Toys,
        "books" => CategoryEnum.Books,
        "other" => CategoryEnum.Other,
        _ => throw new System.Text.Json.JsonException($"Unknown value '{stringValue}' for CategoryEnum")
      };
    }

    /// <inheritdoc/>
    public override void Write(System.Text.Json.Utf8JsonWriter writer, CategoryEnum value, System.Text.Json.JsonSerializerOptions options)
    {
      var stringValue = value switch
      {
        CategoryEnum.Electronics => "electronics",
        CategoryEnum.Clothing => "clothing",
        CategoryEnum.Food => "food",
        CategoryEnum.Furniture => "furniture",
        CategoryEnum.Toys => "toys",
        CategoryEnum.Books => "books",
        CategoryEnum.Other => "other",
        _ => throw new System.ArgumentOutOfRangeException(nameof(value))
      };
      writer.WriteStringValue(stringValue);
    }
  }
}
```

</details>

Publish the schema only after its owners have confirmed the producer guarantees
and added the descriptions, units, and semantic annotations that its consumers
need.
