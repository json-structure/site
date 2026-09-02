---
layout: post
title: "Three Validation Gates for JSON Structure Builds"
date: 2026-10-13
published: false
author: Clemens Vasters
specification_scope: Core with the Units and Validation companion specifications.
uses_structurize: true
image: /social-cards/three-validation-gates-for-json-structure-builds.png
description: >-
  Make schema, input syntax, and instance validation separate build gates so
  malformed or invalid fulfillment data cannot pass unnoticed.
---

A build can report success without validating anything useful. `structurize
validate` checks parsed instances against a schema, but it does not validate the
JSON Structure schema document. Its JSON Lines reader also skips malformed
lines, so a file with no parseable records can pass.

JSON Structure separates two contracts that a one-line check conflates: the
schema must satisfy the schema language, and each instance must satisfy the
schema's types, required properties, choices, and constraints. A JSON Structure
SDK validates the first. Structurize validates the second.

The build therefore needs three gates: validate the schema, reject malformed or
empty input, and then run instance validation. These gates stop invalid schemas
and discarded input from being mistaken for evidence of conformance.

## Use three gates, not one

The repository contains `schemas/fulfillment-order.struct.json`:

```json
{
    "$schema": "https://json-structure.org/meta/validation/v0/#",
    "$id": "https://schemas.example.com/fulfillment-order",
    "name": "FulfillmentOrderSchema",
    "$uses": ["JSONStructureAlternateNames", "JSONStructureUnits", "JSONStructureValidation"],
    "$root": "#/definitions/FulfillmentOrder",
    "definitions": {
        "Address": {
            "name": "Address",
            "type": "object",
            "properties": {
                "street": { "type": "string" },
                "city": { "type": "string" },
                "postalCode": { "type": "string" }
            },
            "required": ["street", "city", "postalCode"]
        },
        "Delivery": {
            "name": "Delivery",
            "type": "choice",
            "choices": {
                "ship": { "type": { "$ref": "#/definitions/Address" } },
                "collectAt": { "type": "string" }
            }
        },
        "FulfillmentOrder": {
            "name": "FulfillmentOrder",
            "type": "object",
            "properties": {
                "orderId": { "type": "uuid" },
                "delivery": { "type": { "$ref": "#/definitions/Delivery" } },
                "packageWeight": {
                    "type": "double",
                    "minimum": 0,
                    "unit": "kg"
                }
            },
            "required": ["orderId", "delivery"]
        }
    }
}
```

It also contains a [JSON Lines](https://jsonlines.org/) file with examples:

```jsonl
{"orderId":"0a55838a-4577-4d9d-8ee8-23df75c99f31","delivery":{"collectAt":"BER-17"},"packageWeight":1.25}
{"orderId":"953ce057-faba-4702-a303-ee2c4c7327d9","delivery":{"ship":{"street":"1 Main St","city":"Seattle","postalCode":"98101"}}}
```

The build must answer three questions:

1. Is the schema file parseable JSON and a valid JSON Structure schema?
2. Is every nonempty line in the input parseable JSON, and is there at least one
   record?
3. Does every parsed instance satisfy the fulfillment schema?

Combining those questions into one command hides failure modes. Keeping them
separate produces useful diagnostics and prevents an empty test from looking
like a successful test.

## Validate the schema with an SDK

Use a JSON Structure SDK `SchemaValidator` for the schema document. The Python
SDK documents this constructor and `validate` call in its
[`SchemaValidator` API reference](https://github.com/json-structure/sdk/blob/master/python/README.md#schemavalidator):

```python
# ci/validate_schema.py
import json
import sys

from json_structure import SchemaValidator

schema_path = sys.argv[1]

try:
    with open(schema_path, encoding="utf-8") as schema_file:
        schema = json.load(schema_file)
except (OSError, json.JSONDecodeError) as error:
    print(f"{schema_path}: {error}", file=sys.stderr)
    raise SystemExit(1)

validator = SchemaValidator(extended=True)
errors = validator.validate(schema)
if errors:
    for error in errors:
        print(error, file=sys.stderr)
    raise SystemExit(1)
```

This gate catches two classes of failure. `json.load` catches broken JSON
syntax; `SchemaValidator` catches a JSON document that does not satisfy the
schema language. `structurize` has no schema-validation command, so this gate
uses the SDK API.

Use the validator options required by the contract. For example, a schema using
imports needs the SDK's import configuration and resolvable imported schemas.
Enable only the features required by the schema contract.

## Reject malformed and empty JSON Lines

Next, inspect every input line before asking Structurize to validate instances.
This small script rejects malformed records, permits blank lines, and rejects a
file with no JSON values:

```python
# ci/check_jsonl.py
import json
import sys

failed = False
records = 0

for path in sys.argv[1:]:
    file_records = 0
    try:
        with open(path, encoding="utf-8") as input_file:
            for line_number, line in enumerate(input_file, start=1):
                if not line.strip():
                    continue
                try:
                    json.loads(line)
                    file_records += 1
                    records += 1
                except json.JSONDecodeError as error:
                    print(f"{path}:{line_number}: {error}", file=sys.stderr)
                    failed = True
    except OSError as error:
        print(f"{path}: {error}", file=sys.stderr)
        failed = True
    if file_records == 0:
        print(f"{path}: no JSON records", file=sys.stderr)
        failed = True

if failed or records == 0:
    raise SystemExit(1)
```

Syntax preflight is required because the
[`validate.py` implementation](https://github.com/clemensv/avrotize/blob/main/avrotize/validate.py)
silently skips malformed JSON Lines. If all lines are malformed, no instance is
checked and the command can still return zero.

## Run instance validation last

Once schema and input syntax have passed, validate the instances with the exact
command shape registered in
[`commands.json`](https://github.com/clemensv/avrotize/blob/main/avrotize/commands.json):

```bash
structurize validate input [input ...] \
  --schema schema.struct.json \
  --schema-type jstruct \
  --quiet
```

For the fulfillment repository, the complete fail-fast CI step is:

```bash
set -euo pipefail

python ci/validate_schema.py schemas/fulfillment-order.struct.json
python ci/check_jsonl.py samples/fulfillment-orders.jsonl
structurize validate samples/fulfillment-orders.jsonl \
  --schema schemas/fulfillment-order.struct.json \
  --schema-type jstruct \
  --quiet
```

`structurize validate` exits with status 1 if any parsed instance is invalid and
status 0 otherwise. With `set -e`, a nonzero exit stops the build and zero
advances it. The preceding syntax gate ensures that “otherwise” cannot mean
“the tool found nothing it could parse.”

In the Structurize test, a file containing the two
examples above returned 0. A parseable record with `orderId: "not-a-uuid"` and
`packageWeight: -1` returned 1. A file containing only malformed lines returned
0, and an empty file also returned 0. The `check_jsonl.py` script above returned
1 for both of those false-success cases; it intentionally returned 0 for the
parseable but schema-invalid record, leaving that verdict to Structurize. The
three gates therefore fail for distinct reasons rather than duplicating one
another.

<details class="generated-output" markdown="1">
<summary>Command output: <code>structurize validate valid.jsonl</code></summary>

```text
✓ Valid: valid.jsonl:1
✓ Valid: valid.jsonl:2

Validation summary: 2/2 instances valid
```

</details>

<details class="generated-output" markdown="1">
<summary>Command output: <code>structurize validate invalid.jsonl</code></summary>

```text
✗ Invalid: invalid.jsonl: Invalid uuid format at #/orderId; Value at #/packageWeight is less than minimum 0

Validation summary: 0/1 instances valid
```

</details>

<details class="generated-output" markdown="1">
<summary>Command output: <code>structurize validate malformed.jsonl</code></summary>

```text
Validation summary: 0/0 instances valid
```

</details>

In a matrix build, run the JSON Lines preflight and instance validation for each
sample file. Do not concatenate exit codes or let a later success overwrite an
earlier failure. Run the gates in sequence and stop at the first failure.

## Keep the evidence distinct

These gates produce different evidence. Schema validation says the contract is
a valid schema document. Syntax validation says the test inputs are actual JSON
records. Instance validation says those records conform to the contract. None
of the three implies either of the others.

Separate results identify the failing layer. A malformed line points to an
input producer. A schema error points to the contract change. An invalid
instance points to a disagreement between data and contract. A combined failure
does not identify which contract failed. Report each gate separately.

Run all three checks in every build: validate the schema, reject malformed or
empty input, and validate every instance. Any failure should stop delivery.