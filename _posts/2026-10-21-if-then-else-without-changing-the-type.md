---
layout: post
title: "if/then/else Without Changing the Type"
display_title: "[`if`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#if-then-else)/[`then`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#if-then-else)/[`else`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#if-then-else) Without Changing the Type"
date: 2026-10-21
published: false
author: Clemens Vasters
specification_scope: Core with the Validation and Conditional Composition companion specifications.
image: /social-cards/if-then-else-without-changing-the-type.png
description: >-
  Keep one stable address type and apply country-specific postal-code rules as
  conditional validation overlays with if, then, and else.
---

A German address and a Canadian address need different postal-code checks.
Both still have the same structural type. The country selects an additional
validation rule for `postalCode`.

Conditional composition evaluates overlays against the current JSON node. It
leaves the data's representation alone: no new [`choice`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#choice), no derived type.

## One address, conditional policy

The object below always has the same four properties. The condition examines
`country`; the selected branch adds the corresponding pattern constraint to
`postalCode`.

```json
{
  "$schema": "https://json-structure.org/meta/validation/v0/#",
  "$id": "https://schemas.example.com/postal-address-policy",
  "name": "PostalAddress",
  "type": "object",
  "properties": {
    "street": { "type": "string" },
    "city": { "type": "string" },
    "country": { "type": "string" },
    "postalCode": { "type": "string" }
  },
  "required": ["street", "city", "country", "postalCode"],
  "additionalProperties": false,
  "if": {
    "properties": {
      "country": { "type": "string", "const": "DE" }
    },
    "required": ["country"]
  },
  "then": {
    "properties": {
      "postalCode": { "type": "string", "pattern": "^[0-9]{5}$" }
    }
  },
  "else": {
    "if": {
      "properties": {
        "country": { "type": "string", "const": "CA" }
      },
      "required": ["country"]
    },
    "then": {
      "properties": {
        "postalCode": {
          "type": "string",
          "pattern": "^[A-Z][0-9][A-Z] [0-9][A-Z][0-9]$"
        }
      }
    }
  }
}
```

This Canadian instance keeps the ordinary address shape:

```json
{
  "street": "111 Wellington Street",
  "city": "Ottawa",
  "country": "CA",
  "postalCode": "K1A 0A9"
}
```

The engine first evaluates the complete object against the base schema. It then
evaluates the [`if`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#if-then-else) schema against that same object. Since `country` is not `DE`,
the outer [`else`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#if-then-else) applies. Its nested condition matches `CA`, so the Canadian
postal-code overlay must also match.

For another country, neither [`then`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#if-then-else) branch applies. `postalCode` remains a
required string, but this schema imposes no country-specific pattern.

## A branch adds constraints

The base [`properties`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#properties-keyword) and [`required`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#required-keyword) constraints remain in force after a branch
is selected. The branch adds constraints to the current node, and all of them
must hold.

That is why the branches mention only the policy delta. Repeating the full
address schema in each branch would invite drift and suggest separate types
where none exist.

The [`required`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#required-keyword) inside each [`if`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#if-then-else) is deliberate. Without it, a condition that
only constrains `country` may succeed vacuously when the property is absent.
The base schema already requires `country`, but keeping the condition complete
makes its matching rule explicit and reusable.

Use a core [`choice`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#choice) when alternatives have different representations or
structures selected by a discriminator. Use conditional composition when one
stable type carries policies that depend on its values or property presence.

## Which vocabulary the example uses

The conditional-composition draft calls its feature
[`JSONSchemaConditionalComposition`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#enabling-the-extensions); the extended meta-schema offers
[`JSONStructureConditionalComposition`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#enabling-the-extensions). The validation meta-schema enables the
repository spelling by default, so the example needs no explicit [`$uses`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#uses-keyword)
entry.

Core defines [`const`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#const-keyword), and the validation add-in defines [`pattern`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#pattern). As checked on
25 August 2026, the `CompositionObjectAddIn` in
`meta/extended/v0/index.json` does not admit the no-type object schemas used
for these branches. The JSON is syntactically valid and follows the draft's
evaluation model. Meta-schema validation can therefore fail before it examines
an address instance.
