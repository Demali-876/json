# Motoko JSON Parser

![JSONXMOTOKO](motokoxjson.png)

A fast, standards-compliant JSON parser and serializer for Motoko, implementing the ECMA-404 (JSON Data Interchange Syntax) standard.

## Features

- Full compliance with ECMA-404 / RFC 8259 JSON standard
- Direct parsing without intermediate formats
- High performance with optimized lexing and parsing
- Proper Unicode support with complete escape sequence handling
- Accurate number parsing (integers and floating-point)

## Installation

```bash
mops add json
```

## Quick Start

```motoko
import JSON "mo:json";

// Parse JSON to Motoko
let jsonText = "{\"name\": \"John\", \"age\": 30}";
let parseResult = JSON.parse(jsonText);

// Serialize Motoko to JSON
let person = {
    name = "John";
    age = 30;
};
let jsonResult = JSON.stringify(person);
```

## Supported Types

The library supports all JSON data types as specified in ECMA-404:

| JSON Type | Motoko Type |
|-----------|-------------|
| string    | Text        |
| number    | Int/Float   |
| object    | Record      |
| array     | Array       |
| boolean   | Bool        |
| null      | Null        |

## Standard Compliance

This library implements the full JSON standard (ECMA-404 / RFC 8259), including:

- Complete Unicode support (including surrogate pairs)
- All escape sequences (\", \\, \/, \b, \f, \n, \r, \t, \uXXXX)
- Full numeric precision for integers and floating-point numbers
- Proper handling of nested structures
- Strict syntax validation

## API Reference

### Parsing

```motoko
public func parse(text: Text) : Result.Result<JSON, Error>
```

Parses a JSON string into a Motoko value. Returns either the parsed value or a detailed error.

### Serialization

```motoko
public func stringify(value: Any) : Result.Result<Text, Error>
```

Converts a Motoko value into a JSON string representation.

### Error Handling

The library provides detailed error information:

```motoko
public type Error = {
    #InvalidString : Text;
    #InvalidNumber : Text;
    #InvalidKeyword : Text;
    #InvalidChar : Text;
    #InvalidValue : Text;
    #UnexpectedEOF;
    #UnexpectedToken :Text;
  };
```

## Example Usage

### Parsing Complex JSON

```motoko
let jsonText = """
{
    "name": "John Doe",
    "age": 30,
    "address": {
        "street": "123 Main St",
        "city": "Anytown"
    },
    "phones": [
        "+1-555-555-1234",
        "+1-555-555-5678"
    ]
}
""";

switch (JSON.parse(jsonText)) {
    case (#ok(parsed)) {
        // Use parsed JSON
    };
    case (#err(error)) {
        // Handle error
    };
};
```

### Working with Arrays

```motoko
let arrayJson = "[1, 2, 3, 4, 5]";
switch (JSON.parse(arrayJson)) {
    case (#ok(#Array(values))) {
        // Process array values
    };
    case (_) {
        // Handle error
    };
};
```

## Support & Acknowledgements

This project was developed with the support of a developer grant from the DFINITY Foundation. This implementation is based on the ECMA-404 standard and incorporates best practices from various JSON parser implementations while being specifically optimized for the Motoko language and Internet Computer platform.

### Community Feedback

Your feedback is invaluable in improving this and future projects. Feel free to share your thoughts and suggestions through issues or discussions.

### Support the Developer

If you find this project valuable and would like to support my work on this and other open-source initiatives, you can send ICP donations to:

```motoko
8c4ebbad19bf519e1906578f820ca4f6732ceecc1d5396e5a5713046dca251c1
```
