---
layout: post
title: "Tensor Shape Does Not Define Tensor Meaning"
date: 2026-10-02
published: false
author: Clemens Vasters
specification_scope: Core with the Units, Validation, and Semantic Annotations companion specifications.
image: /social-cards/describing-tensors.png
description: >-
  Describe a tensor's frame, index binding, variance, and symmetry in the schema
  so a small grid of numbers carries more than shape alone.
---

Nine doubles in a 3x3 may be a stress tensor, a rotation matrix, or a
covariance. Shape alone cannot tell you which.

A tensor gets its meaning from the range of each index and from how its
components respond when the frame changes. Without this annotation, a consumer must find that information in a
format manual or a variable name. [`tensorReferenceFrames`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#tensor-reference-frames) records it in the
schema.

## Shape is only the first layer

A rank-2 tensor is nested two levels deep. With the validation extension,
[`minItems`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#minItems) and [`maxItems`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#maxItems) can fix each extent. The innermost schema gives the
numeric type and unit.

That describes a correctly shaped grid. It still does not say what row 1,
column 2 means.

[`tensorReferenceFrames`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#tensor-reference-frames) adds three pieces:

- [`frames`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#tensor-reference-frames-frames) names one frame per index. Its length is the tensor rank and must be
  at least two.
- [`components`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#tensor-reference-frames-components) binds the tensor positions to one nested property or to named
  scalar properties.
- [`symmetry`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#tensor-reference-frames) optionally states [`symmetric`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#tensor-reference-frames), [`skewSymmetric`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#tensor-reference-frames), or [`none`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#tensor-reference-frames) for an
  eligible rank-2 tensor.

## Six values can determine nine

The Global CMT earthquake catalogue publishes a symmetric seismic moment tensor
as six scalars. The following complete schema assigns each scalar to an index in
a spherical frame ordered as up, south, east.

```json
{
  "$schema": "https://json-structure.org/meta/semantic-annotations/v0/#",
  "$id": "https://example.com/schemas/moment-tensor",
  "name": "MomentTensorDocument",
  "$uses": ["JSONStructureSemanticAnnotations"],
  "$root": "#/definitions/MomentTensor",
  "definitions": {
    "UseFrame": {
      "name": "UseFrame",
      "type": "tuple",
      "description": "Spherical frame ordered as up, south, east.",
      "properties": {
        "r": { "type": "double", "description": "Up." },
        "t": { "type": "double", "description": "South." },
        "p": { "type": "double", "description": "East." }
      },
      "tuple": ["r", "t", "p"]
    },
    "MomentTensor": {
      "name": "MomentTensor",
      "type": "object",
      "tensorReferenceFrames": [
        {
          "frames": [
            {
              "reference": { "$ref": "#/definitions/UseFrame" },
              "kind": "type"
            },
            {
              "reference": { "$ref": "#/definitions/UseFrame" },
              "kind": "type"
            }
          ],
          "symmetry": "symmetric",
          "components": [
            { "index": [0, 0], "property": "mrr" },
            { "index": [1, 1], "property": "mtt" },
            { "index": [2, 2], "property": "mpp" },
            { "index": [0, 1], "property": "mrt" },
            { "index": [0, 2], "property": "mrp" },
            { "index": [1, 2], "property": "mtp" }
          ]
        }
      ],
      "properties": {
        "eventName": { "type": "string" },
        "mrr": { "type": "double", "ucumUnit": "dyn.cm" },
        "mtt": { "type": "double", "ucumUnit": "dyn.cm" },
        "mpp": { "type": "double", "ucumUnit": "dyn.cm" },
        "mrt": { "type": "double", "ucumUnit": "dyn.cm" },
        "mrp": { "type": "double", "ucumUnit": "dyn.cm" },
        "mtp": { "type": "double", "ucumUnit": "dyn.cm" }
      },
      "required": ["eventName", "mrr", "mtt", "mpp", "mrt", "mrp", "mtp"],
      "additionalProperties": false
    }
  }
}
```

This instance is adapted from the catalogue's sample earthquake below El
Salvador on 1 January 2005:

```json
{
  "$schema": "https://example.com/schemas/moment-tensor",
  "eventName": "C200501010120A",
  "mrr": 0.838e23,
  "mtt": -0.005e23,
  "mpp": -0.833e23,
  "mrt": 1.050e23,
  "mrp": -0.369e23,
  "mtp": 0.044e23
}
```

`mtp` occupies row 1, column 2. Because the tensor is symmetric, it also
determines row 2, column 1. The six carried numbers determine all nine
components only after the schema states the frame, each index, and the
symmetry.

Every scalar declares its own index, so the processor does not need a separate
packing-order convention. That removes the guesswork among the several
Voigt-style orders in circulation.

## Variance changes the interpretation

Each frame entry may include [`variance`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#variance), either [`contravariant`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#variance) or [`covariant`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#variance).
When omitted, it defaults to [`contravariant`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#variance).

A stress tensor is contravariant in both indices. A Jacobian may be
contravariant in the first and covariant in the second. Two rank-2 arrays can
therefore have identical shapes and units while transforming differently under
a change of frame.

Symmetry is allowed only when the two entries name the same frame and declare
the same variance, or both omit it. Exchanging indices with different variance
would not preserve the stated relation.

## Two component forms

The example uses named scalar properties. Every component supplies a unique
[`index`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#tensor-reference-frames-components) and [`property`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#tensor-reference-frames-components). With [`symmetric`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#tensor-reference-frames) or [`skewSymmetric`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#tensor-reference-frames), one member of each
mirrored pair is enough. With [`none`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#tensor-reference-frames), every position must be named.

The other form names one nested [`array`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#array) or [`tuple`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#tuple) property. Its nesting depth
must equal the rank, and each level must have the extent of the corresponding
frame. In that form a symmetric tensor is still written out in full because the
nested value carries every position.

## Where the annotation stops

Higher-rank symmetries, including the minor and major symmetries of an elastic
stiffness tensor, are not expressible. A rank-2 object that represents a
transformation is a different case. The draft recommends [`frameTransforms`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#frame-transforms)
its indices range over, not that the numbers perform a transformation.

Large machine-learning tensors can be carried as binary data with
shape metadata. An opaque payload gives up schema-level shape validation. Its
size and processing cost depend on the chosen encoding and workload. For six
out the components also carries the frame that gives them meaning.

[semantic-annotations]: https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-semantic-annotations.html
