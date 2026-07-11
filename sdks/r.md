---
layout: default
title: R SDK
---

# R SDK

The official JSON Structure SDK for R. It binds the native JSON Structure **C
engine** through a small compiled shim, so validation runs in native code while
the API stays idiomatic R.

## Installation

The package is not on CRAN (it downloads a prebuilt native library at first use,
which CRAN policy does not allow). Install from GitHub:

```r
# install.packages("remotes")
remotes::install_github("json-structure/sdk", subdir = "r")
```

On first validation the package downloads a prebuilt `json_structure` shared
library for your platform from the project's GitHub Releases and caches it. To
use a locally built library instead, set the `JSONSTRUCTURE_LIB_PATH`
environment variable to its full path.

## Package Links

- **GitHub**: [json-structure/sdk/r](https://github.com/json-structure/sdk/tree/master/r)
- **Note**: not published on CRAN

## Usage

```r
library(jsonstructure)

# Validate a schema (accepts a JSON string or an R list)
schema <- list(
  "$schema" = "https://json-structure.org/meta/core/v0/#",
  name = "Person",
  type = "object",
  properties = list(
    name = list(type = "string"),
    age  = list(type = "int32")
  )
)
schema_result <- js_validate_schema(schema)
is_valid(schema_result)                 # TRUE

# Validate an instance against a schema
instance_result <- js_validate_instance(list(name = "Alice", age = 30L), schema)
is_valid(instance_result)               # TRUE

# Inspect problems
bad <- js_validate_instance('123', '{"type": "string"}')
is_valid(bad)                           # FALSE
js_error_messages(bad)
as.data.frame(bad)                      # code / severity / message / path / line ...
```

## Features

- Schema validation against JSON Structure meta-schemas
- Instance validation against JSON Structure schemas
- Accepts JSON strings **or** native R lists (auto-serialized via `jsonlite`)
- Tidy S3 result objects: `is_valid()`, `js_error_messages()`, `as.data.frame()`
- Native-speed validation via the JSON Structure C engine
- Cross-platform: Linux, macOS, and Windows

## Documentation

See the [README](https://github.com/json-structure/sdk/tree/master/r#readme) for
full documentation, including development setup and the `JSONSTRUCTURE_LIB_PATH`
override.
