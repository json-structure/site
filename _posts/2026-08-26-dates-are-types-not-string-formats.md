---
layout: post
title: "Dates Are Types, Not String Formats"
date: 2026-08-26
published: true
author: Clemens Vasters
specification_scope: Core only.
image: /social-cards/dates-are-types-not-string-formats.png
description: >-
  JSON Structure declares date, time, datetime, and duration as distinct types
  with RFC 3339 representations instead of treating them as decorated strings.
---

`2026-09-10`, `09:30:00+02:00`, and `P0DT2H` all sit inside JSON quotes, but
they have different temporal meanings. JSON
Structure declares [`date`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#date), [`time`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#time), [`datetime`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#datetime), and [`duration`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#duration) as core types, so
consumers do not have to recover temporal intent from property names or a
format convention.

## Four types, four meanings

The distinctions are small in syntax and large in use:

- [`date`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#date) is an RFC 3339 `full-date`, such as `2026-09-10`.
- [`time`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#time) is an RFC 3339 `full-time`, including a UTC offset, such as
  `09:30:00+02:00`.
- [`datetime`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#datetime) is an RFC 3339 `date-time`, including a UTC offset, such as
  `2026-09-10T09:30:00+02:00`.
- [`duration`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#duration) is an RFC 3339 duration, such as `P2DT3H`.

A maintenance window can use all four without collapsing them into generic
strings:

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://example.com/schemas/maintenance-window",
  "name": "MaintenanceWindow",
  "type": "object",
  "properties": {
    "serviceDate": { "type": "date" },
    "localStart": { "type": "time" },
    "startsAt": { "type": "datetime" },
    "expectedDuration": { "type": "duration" }
  },
  "required": [
    "serviceDate",
    "localStart",
    "startsAt",
    "expectedDuration"
  ],
  "additionalProperties": false
}
```

A matching instance is ordinary JSON:

```json
{
  "serviceDate": "2026-09-10",
  "localStart": "09:30:00+02:00",
  "startsAt": "2026-09-10T09:30:00+02:00",
  "expectedDuration": "P0DT2H"
}
```

The schema tells a binding that `serviceDate` belongs in a date-only type and
that `startsAt` requires an offset-aware date-time type. The spelling of the
property names is irrelevant.

## Quotes are only the carrier

JSON has no temporal primitives, so all four values use strings as their
encoding. Their declared JSON Structure types still differ.

Once the data leaves the validator, a generator can choose distinct language
types, and a database mapper can keep a date-only value out of a timestamp
column. Documentation can promise that a time includes an offset without
relying on an example. The validator applies the RFC 3339 production named by
the type.

[`datetime`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#datetime) is deliberately offset-aware. It is not a local date and time whose
time zone must be guessed from a server setting. If a domain needs a named time
zone such as `Europe/Berlin`, that is additional domain data; an RFC 3339 offset
records an offset, not the complete rules of an IANA time zone.

A [`duration`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#duration) is not an endpoint. Adding one to a date-time requires calendar and
application rules, especially when months, varying day lengths, or daylight
saving transitions are involved. The type says what the value is; it does not
invent those policies.

## Formats leave a tooling decision

JSON Schema can express these values with [`type: "string"`](https://json-schema.org/draft/2020-12/json-schema-validation.html#section-6.1.1) and the
[`format`](https://json-schema.org/draft/2020-12/json-schema-validation.html#section-7.2.1) values [`"date"`](https://json-schema.org/draft/2020-12/json-schema-validation.html#section-7.3.1), [`"time"`](https://json-schema.org/draft/2020-12/json-schema-validation.html#section-7.3.1), [`"date-time"`](https://json-schema.org/draft/2020-12/json-schema-validation.html#section-7.3.1), or [`"duration"`](https://json-schema.org/draft/2020-12/json-schema-validation.html#section-7.3.1). The format vocabulary gives
those strings useful semantics, but assertion behavior depends on the dialect,
vocabulary, and validator configuration. In JSON Schema Draft 2020-12, the
Format-Annotation vocabulary requires collection of format values as
annotations; the separate Format-Assertion vocabulary enables assertion
behavior.

For validation, that flexibility can be desirable. For data definition, tools
still need a policy that says a recognized format should become a particular
language or storage type. JSON Structure removes that extra inference: the
schema element's [`type`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#type-keyword) is already [`date`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#date), [`datetime`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#datetime), [`time`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#time), or [`duration`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#duration).

The lexical standards substantially overlap. JSON Structure puts the semantic
choice in the type declaration rather than a string annotation.

## Avro uses numeric storage

Avro adds temporal semantics through [logical types](https://avro.apache.org/docs/1.12.0/specification/#logical-types) over primitive storage.
[`date`](https://avro.apache.org/docs/1.12.0/specification/#date) counts days from the Unix epoch in an `int`. Time logical types count
milliseconds or microseconds after midnight. Timestamp logical types count from
the Unix epoch in a `long`, with separate local-timestamp forms where no time
zone is implied.

That is Avro's weakness for offset-aware date-times: a timestamp preserves the
instant, but not the original UTC offset or a named time zone. The
`2026-09-10T09:30:00+02:00` value can be reconstructed as the same instant, but
the `+02:00` representation is lost. A local timestamp preserves wall-clock
time but carries no information about which time zone made it local. An Avro
record that needs an offset or an IANA name such as `Europe/Berlin` must store
that information in a separate field.

Avro's [`duration`](https://avro.apache.org/docs/1.12.0/specification/#duration) is different again: a 12-byte fixed value stores months,
days, and milliseconds as three unsigned little-endian integers. Those choices
define Avro's binary representation, but their JSON form is not the RFC 3339
text shown above.

JSON Structure instead standardizes the human-readable JSON representation. It
does not expose an epoch unit or fixed binary layout in the instance.

## XML Schema has temporal datatypes

XML Schema has first-class temporal datatypes including `xs:date`, `xs:time`,
`xs:dateTime`, and `xs:duration`, plus duration subtypes in XML Schema 1.1. Their
lexical forms are closely related to ISO 8601, with XML Schema's own detailed
value and ordering rules.

That model is close to JSON Structure: temporal categories are datatypes rather
than patterns attached to text. JSON Structure adopts RFC 3339 forms suited to
JSON and keeps the core set compact.

In the maintenance window, `serviceDate` cannot drift into a timestamp column,
and `startsAt` cannot shed its required offset. The quotes survive on the wire;
the four generic strings do not survive in the data model.
