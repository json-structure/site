---
layout: post
title: "Binary Data Has a Shape Too"
date: 2026-08-28
published: true
author: Clemens Vasters
image: /social-cards/binary-data-has-a-shape-too.png
description: >-
  JSON Structure defines binary values together with their text encoding,
  compression, and media type, so consumers know how to recover the payload.
---

You receive a Base64 string. After decoding it, do you have a PNG, a PDF, or a
gzip stream containing a CSV file? Base64 cannot answer. JSON Structure's
[`binary`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#binary) type records the processing contract with [`contentEncoding`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#contentencoding-keyword),
[`contentCompression`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#contentcompression-keyword), and [`contentMediaType`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#contentmediatype-keyword).

## Describe the decoding pipeline

Suppose an export record carries a CSV attachment compressed with gzip and then
encoded as Base64 for JSON. The operations happened in this order:

1. Serialize the table as CSV bytes.
2. Compress those bytes with gzip.
3. Encode the compressed bytes as Base64 text.

A consumer reverses the sequence: Base64-decode, gzip-decompress, then interpret
the result as CSV.

The schema declares every step in that pipeline:

```json
{
  "$schema": "https://json-structure.org/meta/core/v0/#",
  "$id": "https://example.com/schemas/csv-export",
  "name": "CsvExport",
  "type": "object",
  "properties": {
    "fileName": {
      "type": "string",
      "maxLength": 255
    },
    "attachment": {
      "type": "binary",
      "contentEncoding": "base64",
      "contentCompression": "gzip",
      "contentMediaType": "text/csv"
    }
  },
  "required": ["fileName", "attachment"],
  "additionalProperties": false
}
```

A real compressed export would be long, so this illustrative instance carries a
small gzip member as Base64 text:

```json
{
  "fileName": "customers.csv.gz",
  "attachment": "H4sIAAAAAAAAA0tMSgYAwkEkNQMAAAA="
}
```

The instance remains opaque on its own. The schema supplies the order of
operations and identifies the decoded content.

## Encoding is the outer layer

The [`binary`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#binary) type has JSON [`string`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#string) as its base representation. Its default
encoding is Base64, and [`contentEncoding`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#contentencoding-keyword) can select one of the RFC 4648
encodings:

- [`base64`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#contentencoding-keyword)
- [`base64url`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#contentencoding-keyword)
- [`base16`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#contentencoding-keyword)
- [`base32`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#contentencoding-keyword)
- [`base32hex`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#contentencoding-keyword)

These names describe how the final byte sequence is represented as JSON text.
They do not describe the payload's character encoding. A `text/csv` payload may
still need a media-type parameter or an external agreement to establish its
character set.

Writing the annotation can still be useful when it repeats the Base64 default:
the pipeline stays visible, and readers need not remember the implicit choice.

## Compression happens before encoding

[`contentCompression`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#contentcompression-keyword) says that the binary payload was compressed before its
bytes were text-encoded. The core specification permits [`gzip`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#contentcompression-keyword), [`deflate`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#contentcompression-keyword),
[`zlib`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#contentcompression-keyword), and [`brotli`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#contentcompression-keyword).

Those names are not interchangeable. Raw DEFLATE, the zlib wrapper, and gzip
use related compression machinery but different wrappers and metadata. A
consumer should not probe until one happens to work. The schema already knows.

Compression is optional. When it is absent, decoding the text yields the media
payload directly. When it is present, decoding yields compressed bytes, and
decompression yields the media payload.

The separate attributes also prevent a common naming muddle. Base64 is an
encoding and increases size. Gzip compresses bytes but does not make them safe
as JSON text. They solve different transport problems.

## Media type describes the result

[`contentMediaType`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#contentmediatype-keyword) is a valid media type as defined by RFC 6838. It describes the
payload after decoding and decompression: `text/csv` in this example,
`image/png` for a PNG image, or `application/pdf` for a PDF document.

The media type does not validate the full internal grammar of that payload. A
schema-aware consumer can route the bytes to a CSV parser, but CSV parsing and
column validation are separate work. JSON Structure defines the outer binary
contract here, not a nested schema language for every media format.

## JSON Schema annotates string content

JSON Schema also defines [`contentEncoding`](https://json-schema.org/draft/2020-12/json-schema-validation.html#section-8.3) and [`contentMediaType`](https://json-schema.org/draft/2020-12/json-schema-validation.html#section-8.4) for strings,
and newer dialects can associate a [`contentSchema`](https://json-schema.org/draft/2020-12/json-schema-validation.html#section-8.5) with decoded content. These
keywords are annotations by default; the specification does not require every
validator to decode and inspect payloads.

JSON Structure attaches encoding and media annotations to a first-class
[`binary`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#binary) type and adds [`contentCompression`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#contentcompression-keyword) to distinguish an intermediate
compression layer. The type tells generators and bindings that the application
value is bytes rather than ordinary text.

## Avro carries native bytes

Avro has a native `bytes` type and `fixed` for byte sequences of a declared
size. In Avro's binary encoding, the payload remains binary; it does not need a
Base64 wrapper. Logical types can add domain meaning to underlying bytes, as
Avro decimal does.

Avro does not use core schema attributes equivalent to this trio for arbitrary
payload encoding, compression, and media type. Container-level codecs solve a
different problem: they compress Avro data blocks, not one field whose decoded
content is a CSV document.

## XML Schema names the text encoding

XML Schema provides `xs:base64Binary` and `xs:hexBinary`. Those types define how
binary octets appear as XML character content. They do not, by themselves,
declare gzip compression or an Internet media type for the recovered bytes.
Applications commonly carry that information in separate attributes or a
surrounding protocol such as MIME.

For the export record, the consumer does not guess from `customers.csv.gz`.
It Base64-decodes, gzip-decompresses, and hands the resulting `text/csv` bytes
to the appropriate parser because the schema says so. The file name can be
wrong; the contract does not depend on it.
