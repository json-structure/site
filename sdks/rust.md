---
layout: default
title: Rust SDK
---

# Rust SDK

The official JSON Structure SDK for Rust.

## Installation

```bash
cargo add json-structure
```

Or add to `Cargo.toml`:

```toml
[dependencies]
json-structure = "0.5.3"
```

## Package Links

- **crates.io**: [json-structure](https://crates.io/crates/json-structure)
- **docs.rs**: [json-structure](https://docs.rs/json-structure)
- **GitHub**: [json-structure/sdk/rust](https://github.com/json-structure/sdk/tree/master/rust)

## Usage

```rust
use json_structure::{SchemaValidator, InstanceValidator};

fn main() {
    // Validate a schema
    let schema_validator = SchemaValidator::new();
    let schema_result = schema_validator.validate(&schema);

    // Validate an instance against a schema
    let instance_validator = InstanceValidator::new();
    let instance_result = instance_validator.validate(&instance, &schema);
}
```

## Features

- Schema validation against JSON Structure meta-schemas
- Instance validation against JSON Structure schemas
- Rust 2021 edition
- No unsafe code
- Serde integration

## Documentation

See the [README](https://github.com/json-structure/sdk/tree/master/rust#readme) for full documentation.
