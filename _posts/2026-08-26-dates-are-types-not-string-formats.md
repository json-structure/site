---
layout: post
title: "Dates Are Types, Not String Formats"
date: 2026-08-26
published: false
author: Clemens Vasters
image: /social-cards/dates-are-types-not-string-formats.png
description: >-
  JSON Structure declares date, time, datetime, and duration as distinct types
  with RFC 3339 representations instead of treating them as decorated strings.
---

`2026-09-10`, `09:30:00+02:00`, and `P0DT2H` all sit inside JSON quotes. Nobody
writing application code would treat them as the same kind of value. JSON
Structure declares `date`, `time`, `datetime`, and `duration` as core types, so
consumers do not have to recover temporal intent from property names or a
format convention.

## Four types, four meanings

The distinctions are small in syntax and large in use:

- `date` is an RFC 3339 `full-date`, such as `2026-09-10`.
- `time` is an RFC 3339 `full-time`, including a UTC offset, such as
  `09:30:00+02:00`.
- `datetime` is an RFC 3339 `date-time`, including a UTC offset, such as
  `2026-09-10T09:30:00+02:00`.
- `duration` is an RFC 3339 duration, such as `P2DT3H`.

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

`datetime` is deliberately offset-aware. It is not a local date and time whose
time zone must be guessed from a server setting. If a domain needs a named time
zone such as `Europe/Berlin`, that is additional domain data; an RFC 3339 offset
records an offset, not the complete rules of an IANA time zone.

A `duration` is not an endpoint. Adding one to a date-time requires calendar and
application rules, especially when months, varying day lengths, or daylight
saving transitions are involved. The type says what the value is; it does not
invent those policies.

## Formats leave a tooling decision

JSON Schema commonly expresses these values as `type: "string"` with `format:
"date"`, `"time"`, `"date-time"`, or `"duration"`. The format vocabulary gives
those strings useful semantics, but assertion behavior depends on the dialect,
vocabulary, and validator configuration. Many integrations also treat [`format`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#format)
as an annotation.

For validation, that flexibility can be desirable. For data definition, tools
still need a policy that says a recognized format should become a particular
language or storage type. JSON Structure removes that extra inference: the
schema element's [`type`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#type-keyword) is already `date`, `datetime`, `time`, or `duration`.

The lexical standards substantially overlap. JSON Structure puts the semantic
choice in the type declaration rather than a string annotation.

## Avro uses numeric storage

Avro adds temporal semantics through logical types over primitive storage.
`date` counts days from the Unix epoch in an `int`. Time logical types count
milliseconds or microseconds after midnight. Timestamp logical types count from
the Unix epoch in a `long`, with separate local-timestamp forms where no time
zone is implied.

Avro's duration is different again: a 12-byte fixed value stores months, days,
and milliseconds as three unsigned little-endian integers. Those choices are
compact and precise for Avro binary data, but their JSON form is not the familiar
RFC 3339 text shown above.

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
