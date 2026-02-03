---
layout: default
title: TypeScript/JavaScript SDK
---

# <img src="/media/logo.svg" alt="" class="inline-logo">TypeScript/JavaScript SDK

The official JSON Structure SDK for TypeScript and JavaScript.

## Installation

```bash
npm install @json-structure/sdk
```

Or with yarn:

```bash
yarn add @json-structure/sdk
```

## Package Links

- **npm**: [@json-structure/sdk](https://www.npmjs.com/package/@json-structure/sdk)
- **GitHub**: [json-structure/sdk/typescript](https://github.com/json-structure/sdk/tree/master/typescript)

## Usage

```typescript
import { SchemaValidator, InstanceValidator } from '@json-structure/sdk';

// Validate a schema
const schemaValidator = new SchemaValidator();
const schemaResult = schemaValidator.validate(schema);

// Validate an instance against a schema
const instanceValidator = new InstanceValidator();
const instanceResult = instanceValidator.validate(instance, schema);
```

## Features

- Schema validation against JSON Structure meta-schemas
- Instance validation against JSON Structure schemas
- Full TypeScript type definitions
- Works in Node.js and browsers
- Zero runtime dependencies

## Documentation

See the [README](https://github.com/json-structure/sdk/tree/master/typescript#readme) for full documentation.
