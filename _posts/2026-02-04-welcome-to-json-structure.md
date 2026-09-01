---
layout: post
title: "JSON Structure Defines Data Models"
date: 2026-02-04
author: Clemens Vasters
specification_scope: Core only.
image: /social-cards/welcome-to-json-structure.png
description: >-
  JSON Structure is a strongly typed schema language for data models that map
  cleanly to programming languages, databases, APIs, and JSON.
---

A data model often gets defined several times: once in application code, again
in database columns, again in an API description, and once more in validation
rules. Those definitions drift because each tool sees only its own part of the
contract.

JSON Structure puts the type model in one schema. Code, databases, APIs, and
validators can then consume the same declaration instead of reconstructing it
from neighboring artifacts.

## What JSON Structure is

JSON Structure is a schema language for data types that need to cross
programming languages, databases, APIs, and JSON documents. Its object and
array syntax will look familiar if you know JSON Schema, but its primary job is
different.

[JSON Schema](https://json-schema.org/specification) defines constraints for
JSON documents. JSON Structure defines a strongly typed data model from which
tools can derive validators, code, database definitions, and API artifacts.
Validation remains part of the model, but it is not the only consumer.

## Why another schema language?

Data definition is split across specialized tools such as Protocol Buffers,
Apache Avro, JSON Schema, OpenAPI, and language-specific type systems. JSON
Structure makes a different set of design choices:

- **Clear mapping to programming language types** – Your schema types should translate directly to [`string`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#string), [`int32`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#int32), [`decimal`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#decimal), [`datetime`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#datetime), and so on in your favorite language. No ambiguity about what "number" means.

- **Precise numeric and temporal types** – JSON Structure supports [`int8`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#int8), [`int16`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#int16), [`int32`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#int32), [`int64`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#int64), [`float`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#float), [`double`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#double), [`decimal`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#decimal) with precision and scale, plus proper [`date`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#date), [`time`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#time), [`datetime`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#datetime), and [`duration`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#duration) types. No more guessing whether your "integer" is 32 or 64 bits.

- **First-class support for common constructs** – Sets, maps, enums with explicit values, and nullable types are built in, not bolted on.

- **Modularity through imports** – Split your schemas across files, reference types from other schemas, and compose complex models without copy-paste.

- **Rich annotations** – Add multilingual descriptions, alternate names for different serialization formats, scientific units, and currency codes directly in your schema.

## The core philosophy

JSON Structure defines explicit types and processing rules so that conforming
implementations can derive the same data model from the same schema. The
[Core Specification](https://json-structure.github.io/core/draft-vasters-json-structure-core.html)
is the authority for those rules.

The type system is designed to be **generative** – you can generate code, database schemas, API documentation, and validation logic from a single source of truth. The schema is both a validation artifact and the canonical definition of the data model.

## What this blog covers

This blog exists to go beyond the specification. While the [Core Specification](https://json-structure.github.io/core) provides the normative definition of the language, here we'll explore:

- **Practical applications** – How to model real-world domains with JSON Structure
- **Feature deep dives** – Detailed explanations of specific capabilities like the import system, alternate names, units and currencies, and validation rules
- **SDK guides** – Tips and patterns for using the official SDKs across TypeScript, Python, .NET, Java, Go, Rust, Ruby, Perl, PHP, Swift, and C
- **Integration patterns** – How JSON Structure fits with databases, message queues, API frameworks, and code generation pipelines
- **Migration guides** – Moving from JSON Schema or other formats to JSON Structure

## Getting started

If you're new to JSON Structure, start with the [Primer](/json-structure-primer.html) for a high-level overview, then dive into the [Core Specification](https://json-structure.github.io/core) when you're ready for the details.

The project publishes SDKs for C, .NET, Go, Java, Perl, PHP, Python, R, Ruby,
Rust, Swift, TypeScript, and Visual Studio Code. The [homepage](/) links to the
available packages and installation instructions. Consult each SDK's status
and documentation before selecting it for a production build.
