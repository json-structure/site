---
layout: post
title: "An Agent Should Invoke the Converter, Not Imitate It"
date: 2026-11-10
published: false
author: Clemens Vasters
image: /social-cards/an-agent-should-invoke-the-converter-not-imitate-it.png
description: >-
  Let agents choose deterministic Structurize conversions, inspect generated
  artifacts, and report projection losses instead of inventing target schemas.
---

An agent that improvises SQL from a JSON Structure schema is writing a new
converter from memory. The result may parse and may even look sensible, but
neither property makes the mapping repeatable.

JSON Structure distinguishes required presence, set uniqueness, keyed maps,
choices, and reusable named types. Imported definitions must already be
resolved into a closed schema because current Structurize converters do not
implement `$import` or `$importdefs`; import resolution turns those dependencies
into references the converters can process.

Through the local MCP server, an agent can discover the exact Structurize
command and options, invoke the deterministic converter, and inspect the files
it produced. Structurize parses the closed schema, follows local references,
applies its pinned target policy, and writes the artifact.

The agent then reports what happened to the contract. A PostgreSQL projection
may turn required properties into a composite primary key and store sets, maps,
or choices as `JSONB`; a Parquet projection may turn a set into a list. Invoke
first, inspect second, and describe those transformations instead of quietly
replacing them with hand-written output.

> [Structurize](https://pypi.org/project/structurize/3.9.0/) is the JSON
> Structure-focused command-line interface from the
> [Avrotize project](https://github.com/clemensv/avrotize). The 3.9.0 wheel
> omits templates and other assets required by most converters. The examples
> here were tested on Python 3.12.10 with the wheel's dependencies and entry
> point, but with the complete pinned source tree on `PYTHONPATH`:
>
> ```powershell
> py -3.12 -m venv .venv
> .\.venv\Scripts\Activate.ps1
> python -m pip install structurize==3.9.0
> git clone https://github.com/clemensv/avrotize.git structurize-source
> git -C structurize-source checkout 8dbb19a3a48239679f0df097399c5ddc8cd48c76
> $env:PYTHONPATH = (Resolve-Path .\structurize-source).Path
> ```

## Give the agent a tool contract

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

An end-to-end `stdio` session against the pinned source confirmed protocol
version `2025-03-26`, server name `avrotize`, and exactly those four tools.
`describe_capabilities` and `list_conversions` reported 105 conversion
commands, including `s2sql` and `s2pq`. `get_conversion` exposed `--dialect`
for `s2sql` and `--format` for `s2pq`; those are the options used below.

## Discovery precedes execution

Suppose the fulfillment team wants PostgreSQL DDL and a reviewable Parquet
schema from `order.resolved.struct.json`. A disciplined agent follows the tool
flow advertised by the server:

1. Call `describe_capabilities` to confirm that schema conversion is in scope.
2. Call `list_conversions` and select `s2sql` and `s2pq`.
3. Call `get_conversion` for each command and inspect its required options.
4. Call `run_conversion` with explicit input and output paths.
5. Open and inspect the generated artifacts.

This sequence was also executed, rather than inferred from the unit tests.
Both `run_conversion` calls returned `success: true`, created the requested
files, and produced files byte-for-byte identical to the equivalent CLI
outputs. Because the complete source tree is selected through `PYTHONPATH`,
the server reports its package version as `dev`; record the pinned commit from
the setup block as the implementation identity for this workaround.

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

Explicit output locations matter. Some conversions produce one schema file;
code generators may produce a directory of source files, project metadata, and
supporting assets. An agent should create a dedicated output directory, pass it
to the conversion, enumerate what appeared, and inspect the relevant files. A
successful tool response is evidence that the function returned. It is not a
review of every generated artifact.

## Respect the boundary of current evidence

The pinned MCP tests exercise protocol initialization, all four tools, argument
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

The same honesty applies to imports. Current Structurize converters do not
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
the output you inspected or the pinned converter code that produced it. A
generic inventory copied from another target is not evidence.

For example, if generated PostgreSQL DDL contains `JSONB`, cite that DDL and
identify the source set or map contract it no longer expresses as relational
constraints. If the DDL contains a composite `PRIMARY KEY`, cite it and the
pinned
[`structuretodb.py`](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/structuretodb.py)
policy that collects required properties into the key. If a generated Parquet
schema represents a source set as an Arrow list, cite the inspected schema or
the pinned
[`structuretoparquet.py`](https://github.com/clemensv/avrotize/blob/8dbb19a3a48239679f0df097399c5ddc8cd48c76/avrotize/structuretoparquet.py)
mapping. Make the claim as narrow as its evidence.

The agent should report four things:

- The authoritative input, including the resolved schema artifact and its provenance.
- The exact converter command, options, version or commit, and output path.
- The generated files it inspected and the validation commands it ran.
- The source constraints that the target cannot express or that converter
  policy changes into target-specific constructs.

It should never repair a surprising output by quietly synthesizing a different
schema from memory. Re-run with corrected options, apply an explicit
target-specific overlay, or file a converter defect.

Keep the deterministic artifact and the explanation connected.

