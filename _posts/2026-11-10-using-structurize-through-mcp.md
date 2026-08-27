---
layout: post
title: "Using Structurize Through MCP"
date: 2026-11-10
published: false
author: Clemens Vasters
specification_scope: Core with the Import companion specification.
uses_structurize: true
image: /social-cards/using-structurize-through-mcp.png
description: >-
  Discover and run Structurize conversions through its local MCP server, then
  inspect the generated artifacts and report target-specific projection losses.
---

Structurize exposes its conversion catalog through a local Model Context
Protocol (MCP) server. An MCP client can discover a conversion, inspect its
options, invoke it, and examine the generated files. The converter remains the
single implementation of the mapping, which makes the result repeatable.

JSON Structure distinguishes required presence, set uniqueness, keyed maps,
choices, and reusable named types. Imported definitions must already be
resolved into a closed schema because the Structurize 3.9.0 converters tested here do
not implement `$import` or `$importdefs`; import resolution turns those dependencies
into references the converters can process.

Through MCP, the client discovers the exact Structurize command and options,
invokes the converter, and inspects the files it produced. Structurize parses
the closed schema, follows local references, applies its target policy, and
writes the artifact.

The client can then report what happened to the contract. A PostgreSQL projection
may turn required properties into a composite primary key and store sets, maps,
or choices as `JSONB`; a Parquet projection may turn a set into a list. Invoke
the converter, inspect its output, and describe those transformations.

> The examples use [Structurize 3.9.0](https://pypi.org/project/structurize/3.9.0/).
> Install the pinned release from PyPI:
>
> ```powershell
> python -m pip install structurize==3.9.0
> ```

## Expose the conversion catalog

Avrotize and Structurize expose the same conversion catalog through a local
Model Context Protocol (MCP) server. Each package installs a console script that
calls `avrotize.avrotize:main`, and both read the packaged `commands.json`
registry. Therefore either command is valid when the corresponding package is
installed:

```powershell
avrotize mcp
structurize mcp
```

The full Avrotize distribution also installs a dedicated entry point:

```powershell
avrotize-mcp
```

The evidence is in Avrotize's
[`pyproject.toml`](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/pyproject.toml),
Structurize's
[`pyproject.toml`](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/structurize/pyproject.toml),
and the shared
[`commands.json`](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/commands.json).

The server supports `stdio` only and identifies itself as `avrotize`, regardless
of which entry point launched it. With the Structurize installation shown
above, a client configuration can therefore be as small as:

```json
{
  "mcpServers": {
    "avrotize": {
      "command": "structurize",
      "args": ["mcp"],
      "transport": "stdio"
    }
  }
}
```

The server exposes four tools:

- `describe_capabilities` explains the server's purpose and recommended flow.
- `list_conversions` returns the available conversion and code-generation commands.
- `get_conversion` returns the arguments for one command.
- `run_conversion` executes that command with an input path or inline content,
  an output path, and command options.

These names, the `avrotize` server identity, and the `stdio`-only check come
directly from
[`mcp_server.py`](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/mcp_server.py).
Together with the command registry, they form a discoverable contract. The
agent does not need to guess
that PostgreSQL is spelled `postgres` or that schema inspection uses
`--format schema`; it can ask.

In the tested end-to-end `stdio` session with Structurize 3.9.0, the server
reported protocol version `2025-03-26`, server name `avrotize`, and exactly those four tools.
`describe_capabilities` and `list_conversions` reported 105 conversion
commands, including `s2sql` and `s2pq`. `get_conversion` exposed `--dialect`
for `s2sql` and `--format` for `s2pq`; those are the options used below.

## Discovery precedes execution

Suppose the fulfillment team wants PostgreSQL DDL and a reviewable Parquet
schema from `order.resolved.struct.json`. The client follows the tool flow
advertised by the server:

1. Call `describe_capabilities` to confirm that schema conversion is in scope.
2. Call `list_conversions` and select `s2sql` and `s2pq`.
3. Call `get_conversion` for each command and inspect its required options.
4. Call `run_conversion` with explicit input and output paths.
5. Open and inspect the generated artifacts.

This sequence was also executed, rather than inferred from the unit tests.
Both `run_conversion` calls returned `success: true`, created the requested
files, and produced files byte-for-byte identical to the equivalent CLI
outputs. The server reports the installed Structurize package version, which
identifies the implementation used for the conversion.

The equivalent CLI operations make the intended arguments easy to see:

```powershell
New-Item -ItemType Directory -Force generated/postgres, generated/parquet

structurize s2sql order.resolved.struct.json `
  --dialect postgres `
  --out generated/postgres/order.sql

structurize s2pq order.resolved.struct.json `
  --format schema `
  --out generated/parquet/order.schema.json
```

<details class="generated-output" markdown="1">
<summary>Generated output: <code>order.sql</code></summary>

```sql
CREATE TABLE "Order" (
    "orderId" VARCHAR(512),
    "createdAt" TIMESTAMP,
    "tags" JSONB,
    "attributes" JSONB,
    "destination" JSONB,
    PRIMARY KEY ("orderId", "createdAt", "destination")
);

COMMENT ON COLUMN "Order"."tags" IS '{"schema": {"type": "set", "items": {"type": "string"}}}';
COMMENT ON COLUMN "Order"."attributes" IS '{"schema": {"type": "map", "values": {"type": "string"}}}';
COMMENT ON COLUMN "Order"."destination" IS '{"schema": {"type": "choice", "name": "Destination", "choices": {"postal": {"type": "object", "name": "PostalDestination", "properties": {"address": {"type": "string"}}, "required": ["address"]}, "pickupPoint": {"type": "object", "name": "PickupDestination", "properties": {"locationId": {"type": "string"}}, "required": ["locationId"]}}}}';
```

</details>

<details class="generated-output" markdown="1">
<summary>Generated output: <code>order.schema.json</code></summary>

```json
{
  "type": "struct",
  "fields": [
    {
      "name": "orderId",
      "type": "string",
      "nullable": false
    },
    {
      "name": "createdAt",
      "type": "timestamp[us]",
      "nullable": false
    },
    {
      "name": "tags",
      "type": "list<item: string>",
      "nullable": true
    },
    {
      "name": "attributes",
      "type": "map<string, string>",
      "nullable": true
    },
    {
      "name": "destination",
      "type": "struct<postal: struct<address: string not null>, pickupPoint: struct<locationId: string not null>>",
      "nullable": false
    }
  ]
}
```

</details>

Explicit output locations matter. Some conversions produce one schema file;
code generators may produce a directory of source files, project metadata, and
supporting assets. The [prebuilt Structurize examples in the Avrotize
gallery](https://avrotize.com/gallery/#structurize) show representative
multi-file projects. An agent should create a dedicated output directory, pass
it to the conversion, enumerate what appeared, and inspect one representative
file plus the project metadata and supporting assets relevant to the review. A
successful tool response is evidence that the function returned. It is not a
review of every generated artifact.

## Respect the boundary of current evidence

The MCP tests exercise protocol initialization, all four tools, argument
plumbing, the `stdio` loop, and a real end-to-end single-file `cddl2s`
conversion. The Copilot CLI integration tests also exercise single-file schema
conversions with inline content and explicit file paths. See
[`test_mcp_server.py`](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/test/test_mcp_server.py)
and
[`test_mcp_copilot_cli.py`](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/test/test_mcp_copilot_cli.py).

Those tests do not establish end-to-end MCP coverage for directory-producing
code generation. That does not make directory generation unusable. It means the
agent must avoid claiming evidence that the tests do not provide. Use an
explicit output directory, inspect the generated tree, and run the target
language's formatter, compiler, and tests where available.

The same honesty applies to imports. The Structurize 3.9.0 converters tested here do not
process JSON Structure `$import` or `$importdefs`; they resolve local references
only. An agent must first invoke a conforming import resolver and produce a
closed schema, then call `s2...` on that artifact. It must not silently fetch a
document, splice definitions by intuition, and describe the result as
Structurize output. Source imports are resolved before conversion. Any imports
emitted in generated code or target schemas are target-native artifacts with
their own rules.

## Report policy and loss

Generation is not the end of the agent's task. For each conversion, report
every source construct weakened by the generated artifact. The evidence must be
the output you inspected or the converter code that produced it. A
generic inventory copied from another target is not evidence.

For example, if generated PostgreSQL DDL contains `JSONB`, cite that DDL and
identify the source set or map contract it no longer expresses as relational
constraints. If the DDL contains a composite `PRIMARY KEY`, cite it and the
[`structuretodb.py`](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/structuretodb.py)
policy that collects required properties into the key. If a generated Parquet
schema represents a source set as an Arrow list, cite the inspected schema or
the
[`structuretoparquet.py`](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/structuretoparquet.py)
mapping. Make the claim as narrow as its evidence.

My recommendation is that the agent report four things:

- The authoritative input, including the resolved schema artifact and its provenance.
- The exact converter command, options, version or commit, and output path.
- The generated files it inspected and the validation commands it ran.
- The source constraints that the target cannot express or that converter
  policy changes into target-specific constructs.

It should never repair a surprising output by quietly synthesizing a different
schema from memory. Re-run with corrected options, apply an explicit
target-specific overlay, or file a converter defect.

Keep the deterministic artifact and the explanation connected.

