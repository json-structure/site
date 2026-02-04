---
layout: post
title: "Welcome to JSON Structure"
date: 2026-02-04
author: Clemens Vasters
social_image: /social-cards/welcome-to-json-structure.svg
---

JSON Structure is here, and with it comes a fresh perspective on how we define data types and structures for modern applications.

## What is JSON Structure?

JSON Structure is a schema language designed to describe data types and structures that map cleanly to programming language types, database constructs, and the ubiquitous JSON data encoding. If you've worked with JSON Schema, the syntax will feel familiar – but the philosophy is different.

Where JSON Schema focuses primarily on document validation (asking "does this JSON document conform to these rules?"), JSON Structure focuses on being a strong **data definition language**. It's about defining types that your code, your databases, and your APIs can share and understand consistently.

## Why Another Schema Language?

The landscape of data definition is fragmented. You have Protocol Buffers for efficient binary serialization, Avro for Hadoop ecosystems, JSON Schema for validation, OpenAPI for API definitions, and countless language-specific type systems. Each serves its purpose, but none quite hits the sweet spot for developers who want:

- **Clear mapping to programming language types** – Your schema types should translate directly to `string`, `int32`, `decimal`, `datetime`, and so on in your favorite language. No ambiguity about what "number" means.

- **Precise numeric and temporal types** – JSON Structure supports `int8`, `int16`, `int32`, `int64`, `float`, `double`, `decimal` with precision and scale, plus proper `date`, `time`, `datetime`, and `duration` types. No more guessing whether your "integer" is 32 or 64 bits.

- **First-class support for common constructs** – Sets, maps, enums with explicit values, and nullable types are built in, not bolted on.

- **Modularity through imports** – Split your schemas across files, reference types from other schemas, and compose complex models without copy-paste.

- **Rich annotations** – Add multilingual descriptions, alternate names for different serialization formats, scientific units, and currency codes directly in your schema.

## The Core Philosophy

JSON Structure schemas are deterministic. Given a schema, there's exactly one way to interpret it. This might sound obvious, but it's a departure from JSON Schema's flexibility, where the same data might validate differently depending on interpretation.

The type system is designed to be **generative** – you can generate code, database schemas, API documentation, and validation logic from a single source of truth. Your schema isn't just a validation artifact; it's the canonical definition of your data model.

## What You'll Find on This Blog

This blog exists to go beyond the specification. While the [Core Specification](https://json-structure.github.io/core) provides the normative definition of the language, here we'll explore:

- **Practical applications** – How to model real-world domains with JSON Structure
- **Feature deep dives** – Detailed explanations of specific capabilities like the import system, alternate names, units and currencies, and validation rules
- **SDK guides** – Tips and patterns for using the official SDKs across TypeScript, Python, .NET, Java, Go, Rust, Ruby, Perl, PHP, Swift, and C
- **Integration patterns** – How JSON Structure fits with databases, message queues, API frameworks, and code generation pipelines
- **Migration guides** – Moving from JSON Schema or other formats to JSON Structure

## Getting Started

If you're new to JSON Structure, start with the [Primer](/json-structure-primer.html) for a high-level overview, then dive into the [Core Specification](https://json-structure.github.io/core) when you're ready for the details.

The official SDKs are available for all major languages – check the [homepage](/) for installation instructions. Each SDK provides schema validation and instance validation, with consistent behavior across platforms.

We're excited to have you here. JSON Structure is designed to make data definition cleaner, more precise, and more useful across your entire stack. We hope you find it as practical as we do.

Stay tuned for more posts exploring specific features and real-world applications.
