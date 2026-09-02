---
layout: post
title: "Three Clocks in One Observation"
date: 2026-11-06
published: false
author: Clemens Vasters
specification_scope: Core with the Units and Semantic Annotations companion specifications.
image: /social-cards/three-clocks-in-one-observation.png
description: >-
  Separate phenomenon, result, and ingestion time in telemetry so event-time
  analysis, production latency, and pipeline latency remain distinguishable.
---

Keep separate timestamps for separate events. A weather observation can carry three:

[`phenomenonTime`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#phenomenon-time) says when the value applied to the world, [`resultTime`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#result-time) says
when the result became available, and [`ingestionTime`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#ingestion-time) says when a declared
receiving system accepted the record. The values may be close or even equal,
but a generic `timestamp` leaves consumers guessing which event it records.

## A weather observation with three timestamps

This station samples air temperature, computes a quality-controlled result, and
then sends the record through a telemetry gateway:

```json
{
  "$schema": "https://json-structure.org/meta/semantic-annotations/v0/#",
  "$id": "https://schemas.example.com/weather/temperature-observation/v1",
  "$uses": ["JSONStructureSemanticAnnotations"],
  "name": "TemperatureObservationDocument",
  "$root": "#/definitions/TemperatureObservation",
  "definitions": {
    "TemperatureObservation": {
      "name": "TemperatureObservation",
      "type": "object",
      "observedProperty": {
        "reference": "http://qudt.org/vocab/quantitykind/Temperature",
        "kind": "qudt-quantity-kind"
      },
      "properties": {
        "stationId": {
          "type": "string",
          "semanticRole": "featureOfInterest"
        },
        "observedAt": {
          "type": "datetime",
          "semanticRole": "phenomenonTime"
        },
        "resultAvailableAt": {
          "type": "datetime",
          "semanticRole": "resultTime"
        },
        "gatewayAcceptedAt": {
          "type": "datetime",
          "semanticRole": "ingestionTime"
        },
        "airTemperature": {
          "type": "double",
          "unit": "°C",
          "semanticRole": "observationValue"
        }
      },
      "required": [
        "stationId",
        "observedAt",
        "resultAvailableAt",
        "gatewayAcceptedAt",
        "airTemperature"
      ],
      "additionalProperties": false
    }
  }
}
```

The corresponding record makes the timing visible:

```json
{
  "$schema": "https://schemas.example.com/weather/temperature-observation/v1",
  "stationId": "WX-BER-042",
  "observedAt": "2026-11-20T06:15:00Z",
  "resultAvailableAt": "2026-11-20T06:15:04Z",
  "gatewayAcceptedAt": "2026-11-20T06:15:19Z",
  "airTemperature": 7.4
}
```

In this example, the temperature applies at 06:15:00. Sensor processing and quality checks
make the result available 4 seconds later, at 06:15:04. Network transit and gateway work add 15 seconds before acceptance at 06:15:19.

## Use phenomenon time for event-time analysis

[`phenomenonTime`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#phenomenon-time) is the time during which the result applies to the observed
property. For an instantaneous reading, it annotates a temporal position. It
may also annotate a named object or tuple representing a period; flattened
periods use the separate [`phenomenonTimeStart`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#phenomenon-time-start) and [`phenomenonTimeEnd`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#phenomenon-time-end) roles.

Windowing observations by `gatewayAcceptedAt` would move delayed records into
the wrong weather interval. Joining temperature with wind by result production
time would align processing schedules, not atmospheric conditions. Event-time
analytics therefore needs the phenomenon clock.

## Compare result and phenomenon time for production delay

[`resultTime`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#result-time) is the temporal position at which the result became available.
The difference between result and phenomenon time describes observation
production delay. That delay may come from sensor integration, laboratory
analysis, model execution, quality control, or publication.

The role does not say that result time must follow phenomenon time in every
domain. Forecasts are observations whose result time precedes their phenomenon
time. The roles remain useful because they do not require result time to follow
phenomenon time.

## Ingestion time depends on a receiving system

[`ingestionTime`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#ingestion-time) is an operational event-time role: the temporal position when a
declared system accepted the record. In this schema that system is the telemetry
gateway named by the property. A data lake could add its own acceptance time in
a downstream record because ingestion is relative to an operational boundary.

The difference between ingestion and result time measures transport and
pipeline delay to that boundary. On replay, an old observation can acquire a
new ingestion time without acquiring a new phenomenon or result time.

## One timestamp cannot answer three questions

A generic `timestamp` forces every consumer to guess whether the field is safe
for event-time windows, measures sensor latency, or can drive a pipeline
freshness alert. One value cannot answer all three unless the system guarantees
the events coincide, and even then the roles describe different events.

[`semanticRole`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#semantic-role) carries the distinction without changing the instance encoding.
All three fields remain ordinary [`datetime`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#datetime) values. The annotation tells a
processor which temporal concern each value serves; the Core type and any
temporal reference-system binding tell it how the position is represented.

Cadence, statistics, derivation, and temporal reference systems can add more
context later. They cannot recover which event an undifferentiated `timestamp`
was meant to record.

[semantic-annotations]: https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html