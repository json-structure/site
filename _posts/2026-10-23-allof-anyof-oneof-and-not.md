---
layout: post
title: "Four Ways to Combine Constraints"
date: 2026-10-23
published: false
author: Clemens Vasters
image: /social-cards/allof-anyof-oneof-and-not.png
description: >-
  Compare allOf, anyOf, oneOf, and not precisely through one complete access
  request schema and the match counts each operator requires.
---

Composition keywords combine evaluation results, not property maps. Each
subschema evaluates independently against the same current JSON node. The
operator then reduces those Boolean results with a precise rule.

One access request is enough to show all four operators at work.

## A complete policy

The base shape requires a subject, an action, a resource, and authentication
methods. The composition constraints add policy:

```json
{
  "$schema": "https://json-structure.org/meta/validation/v0/#",
  "$id": "https://schemas.example.com/access-request",
  "name": "AccessRequest",
  "type": "object",
  "properties": {
    "subject": { "type": "string" },
    "action": { "type": "string" },
    "resource": { "type": "string" },
    "authMethods": {
      "type": "set",
      "items": { "type": "string" }
    },
    "breakGlassReason": { "type": "string" }
  },
  "required": ["subject", "action", "resource", "authMethods"],
  "additionalProperties": false,
  "allOf": [
    {
      "not": {
        "properties": {
          "subject": { "type": "string", "const": "anonymous" }
        },
        "required": ["subject"]
      }
    },
    {
      "anyOf": [
        {
          "properties": {
            "authMethods": {
              "type": "set",
              "contains": { "type": "string", "const": "mfa" }
            }
          }
        },
        {
          "properties": {
            "authMethods": {
              "type": "set",
              "contains": { "type": "string", "const": "hardware-key" }
            }
          }
        }
      ]
    },
    {
      "oneOf": [
        {
          "properties": {
            "action": { "type": "string", "const": "read" }
          },
          "required": ["action"]
        },
        {
          "properties": {
            "action": { "type": "string", "const": "write" },
            "breakGlassReason": { "type": "string", "minLength": 10 }
          },
          "required": ["action", "breakGlassReason"]
        }
      ]
    }
  ]
}
```

A write request satisfying the policy is:

```json
{
  "subject": "operator-42",
  "action": "write",
  "resource": "plant/7/controller",
  "authMethods": ["password", "hardware-key"],
  "breakGlassReason": "Emergency valve correction"
}
```

## Read the match counts

[`allOf`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#allOf) requires every member to evaluate true. Here the subject exclusion, the
strong-authentication rule, and the action rule must all pass. [`allOf`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#allOf) does not
merge the members before evaluation; contradictory members simply make the
combined constraint impossible to satisfy.

[`anyOf`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#anyOf) requires at least one match. A request may contain `mfa`,
`hardware-key`, or both. Two matches are valid here; [`oneOf`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#oneOf) would reject them.

[`oneOf`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#oneOf) requires exactly one match. The [`const`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#const-keyword) values make the read and write
branches disjoint, so an action cannot satisfy both. The write branch also
requires a usable explanation. If branches overlap accidentally, an instance
matching two branches fails even when each branch looks acceptable alone.

[`not`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#not) inverts one subschema result. The request passes that constraint when the
anonymous-subject schema fails. It contributes no replacement type or
affirmative shape; it only excludes a matching region.

## Closed objects belong outside the branches

The base object owns `additionalProperties: false`. Putting a closed-object
rule into each partial branch would make sibling properties appear illegal.
Composition evaluates complete instances against each member, so partial
policy overlays should generally remain open while the stable structural schema
defines the closed member set.

The draft requires non-empty type-union arrays for [`allOf`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#allOf), [`anyOf`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#anyOf), and
[`oneOf`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#oneOf); [`not`](https://json-structure.github.io/conditional-composition/draft-vasters-json-structure-cond-composition.html#not) takes one schema, which may itself be a type union. Array order
does not change the truth conditions.

## What the repository can check today

The draft calls the feature `JSONSchemaConditionalComposition`, while the
meta-schema offers `JSONStructureConditionalComposition`. The validation
meta-schema used above enables the repository name. The validation draft also
permits [`const`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#const-keyword) inside [`contains`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#contains), which gives the authentication checks their
fixed values.

Core already defines [`const`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#const-keyword), and the validation add-in defines [`minLength`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#minLength).
The checked-in extended meta-schema, however, omits [`contains`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#contains) and gives the
composition members shapes that differ from the draft text. A
draft-conforming evaluator can apply this policy, but meta-schema validation
may stop at either discrepancy.
