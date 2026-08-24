---
layout: post
title: "Samples Are Evidence, Not a Contract"
date: 2026-09-01
published: false
author: Clemens Vasters
image: /social-cards/samples-are-evidence-not-a-contract.png
description: >-
  Structurize can infer a useful JSON Structure draft from observed records,
  but people must decide the intended types, presence rules, and value domains.
---

A week of shipment records contains `carrierService` in every row and only
three status values. That proves what the exporter produced during that week.
It does not establish that the field is mandatory or that the lifecycle has
only three states.

Structurize's `json2s` command turns those observations into a draft JSON
Structure schema. Raw records cannot decide whether a string is a UUID, whether
an absent field is optional, or whether observed values form a closed enum.
Those decisions require producer guarantees and compatibility policy.

Reviewers express the decisions with JSON Structure types, `required`, enums,
and choices. Structurize can then project the reviewed schema into documentation
and code. Valid observations remain covered; accidental requiredness,
incomplete enums, and unjustified type guesses are corrected or discarded
before they escape into generated artifacts.

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

## Begin with what happened

Assume a fulfillment team has collected newline-delimited JSON from a dispatch
feed:

```jsonl
{"orderId":"c28788fa-73bd-4b39-a209-2f75f82c6653","status":"allocated","carrierService":"priority-ground","dispatchAt":"2026-08-25T16:30:00Z","contact":"ops@example.com"}
{"orderId":"9b51a282-d3dd-476b-a7d7-97ace6318312","status":"dispatched","carrierService":"priority-ground","dispatchAt":"2026-08-26T09:15:00Z","contact":"dock@example.com"}
{"orderId":"dd4e44b5-aae8-4c40-8c57-5535d66e7b9d","status":"allocated","carrierService":"economy","contact":"night@example.com"}
```

[Structurize 3.9.0](https://pypi.org/project/structurize/3.9.0/) can infer a
JSON Structure schema from JSON or JSONL. Its pinned
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

For these three records, Structurize 3.9.0 emits the following properties and
required list (formatting retained, surrounding metadata omitted):

```json
{
  "properties": {
    "carrierService": { "type": "string" },
    "contact": { "type": "string" },
    "dispatchAt": { "type": "datetime" },
    "orderId": { "type": "string" },
    "status": { "type": "string" }
  },
  "required": [
    "carrierService",
    "contact",
    "orderId",
    "status"
  ]
}
```

No enum is inferred from only three records, `dispatchAt` is optional because
it is absent once, and UUID- and email-shaped values remain strings.

The earlier [introduction to `json2s`]({% post_url 2026-02-04-structurize-json2s-command %})
covers merging, choices, clustering, and basic limitations. The next problem is
more important: deciding what the observations mean.

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
a mandatory value. Perhaps carrier assignment will become asynchronous next
month, making `carrierService` temporarily unavailable.

Review each inferred [`required`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#required-keyword) entry against a lifecycle rule or an API
guarantee. Also review every omission. Frequency tells you where to ask; domain
policy supplies the answer.

## Strings conceal several decisions

UUID-, URI-, email-, and Base64-like values remain strings during inference.
That restraint is valuable. A string that happens to parse as a UUID in the
sample may be an opaque identifier whose future syntax is wider. An email-like
contact may permit a queue name later. Base64-looking text may simply be text.

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

## Temporal shape needs a promise

Temporal inference requires all observed non-null values for the field to be
strings. It selects `datetime`, `date`, or `time` when at least 80% of those
strings match that one temporal shape; otherwise, absent enum inference, the
field remains a string.

A threshold protects the analysis from treating every date-like accident as a
type declaration, but it cannot answer the domain question. `dispatchAt` can be
a [`datetime`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#datetime) only if the producer promises an RFC 3339 date-time with an offset.
Historical consistency is evidence for that promise, not the promise itself.

This edit makes the commitment explicit:

```json
"dispatchAt": {
  "type": "datetime",
  "description": "Time at which the shipment left the fulfillment site."
}
```

The missing third value still requires a presence decision. Type and
requiredness answer different questions.

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

```json
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
3. Add stable names, descriptions, constraints, and domain types that the data
   alone cannot establish.
4. Validate the source samples against the edited schema. Passing confirms
   coverage of those observations; it says nothing about unobserved valid cases.
5. Publish the reviewed JSON Structure document as the source contract, with
   normal versioning and ownership.

Then project artifacts from that contract:

```powershell
New-Item -ItemType Directory -Force generated | Out-Null
structurize s2md shipment.struct.json --out generated/shipment.md
structurize s2cs shipment.struct.json --out generated/dotnet --namespace Fulfillment.Contracts
```

Samples record observed values. Inference summarizes those observations. Only
the reviewed schema states what producers may send and consumers must accept.
