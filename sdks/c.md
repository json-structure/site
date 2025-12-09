---
layout: default
title: C SDK
---

# C SDK

The official JSON Structure SDK for C (and C++).

## Installation

### vcpkg

```bash
vcpkg install json-structure
```

### CMake FetchContent

```cmake
include(FetchContent)
FetchContent_Declare(
    json-structure
    GIT_REPOSITORY https://github.com/json-structure/sdk.git
    GIT_TAG v0.5.3
    SOURCE_SUBDIR c
)
FetchContent_MakeAvailable(json-structure)

target_link_libraries(your_target PRIVATE json-structure)
```

## Package Links

- **vcpkg**: [json-structure](https://vcpkg.io/en/package/json-structure)
- **GitHub**: [json-structure/sdk/c](https://github.com/json-structure/sdk/tree/master/c)

## Usage

```c
#include <json_structure.h>

int main() {
    // Validate a schema
    js_schema_validator_t* schema_validator = js_schema_validator_new();
    js_validation_result_t* schema_result = js_schema_validator_validate(schema_validator, schema);
    
    // Validate an instance against a schema
    js_instance_validator_t* instance_validator = js_instance_validator_new();
    js_validation_result_t* instance_result = js_instance_validator_validate(instance_validator, instance, schema);
    
    // Cleanup
    js_validation_result_free(schema_result);
    js_validation_result_free(instance_result);
    js_schema_validator_free(schema_validator);
    js_instance_validator_free(instance_validator);
    
    return 0;
}
```

## Features

- Schema validation against JSON Structure meta-schemas
- Instance validation against JSON Structure schemas
- C11 standard
- Cross-platform (Windows, Linux, macOS)
- Uses cJSON for JSON parsing

## Documentation

See the [README](https://github.com/json-structure/sdk/tree/master/c#readme) for full documentation.
