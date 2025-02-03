# Motoko JSON Library

![JSONXMOTOKO](motokoxjson.png)

A standards-compliant JSON (ECMA-404/RFC 8259) library for the Motoko programming language, providing native JSON manipulation capabilities for Internet Computer applications.

## Overview

This library enables developers to:

1. Parse JSON text into native Motoko data structures
2. Manipulate JSON data directly in Motoko
3. Serialize modified JSON back to standard JSON text

## Installation

```bash
mops add json
```

## Usage

```bash
import Json "mo:json";
import {str; int; float; bool; nullable; obj; arr } "mo:json"; //JSON Types
import {string; number; boolean; nullSchema; array, schemaObject} "mo:json"; //JSON Schema Types
```

## Core Types

```motoko
public type Json = {
    #object_ : [(Text, Json)];
    #array : [Json];
    #string : Text;
    #number : {
        #int : Int;
        #float : Float;
    };
    #bool : Bool;
    #null_;
};
```

## API Reference

### 1. Parsing JSON

The `parse` function converts JSON text into Motoko's JSON type:

```motoko
public func parse(input: Text) : Result.Result<Json.Json, Json.Error>
```

Example usage:

```motoko
let jsonText = "{ \"name\": \"John\", \"age\": 30 }";

switch(Json.parse(jsonText)) {
    case (#ok(parsed)) {
        // Work with parsed JSON
    };
    case (#err(e)) {
        // Handle error
    };
};
```

### 2. Querying JSON (get)

Retrieve values from JSON using path expressions:

```motoko
public func get(json: Json.Json, Json.path: Path) : ?Json.Json
```

Path syntax:

- Use dots for object properties: "user.name"
- Use brackets for array indices: "users[0]"
- Use wildcards for multiple matches: "users.\*.name"

Example:

```motoko
let data = obj([
    ("users", arr([
        obj([
            ("name", str("John")),
            ("age", int(30))
        ])
    ]))
]);

// Get a specific value
let name = Json.get(data, "users[0].name");  // Returns ?#string("John")
// Or get text value
let nameText = Json.getAsText(data, "users[0].name"); // Returns Result.Result<Text, Json.GetAsError>

// Get multiple values using wildcard
let allNames = Json.get(data, "users.*.name");  // Returns array of all names
```

### 3. Modifying JSON (set)

Add or update values in JSON using path expressions:

```motoko
public func set(json: Json.Json, path: Json.Path, value: Json.Json) : Json.Json
```

Example:

```motoko
// Add a new field
let withPhone = Json.set(data, "users[0].phone", str("+1234567890"));

// Update existing value
let updated = Json.set(data, "users[0].age", int(31));

// Create nested structure
let nested = Json.set(data, "metadata.lastUpdated", str("2024-01-11"));
```

### 4. Removing Data (remove)

Remove values from JSON using path expressions:

```motoko
public func remove(json: Json.Json, path: Json.Path) : Json.Json
```

Example:

```motoko
// Remove a field
let withoutEmail = Json.remove(data, "users[0].email");

// Remove an array element
let withoutFirstUser = Json.remove(data, "users[0]");


```

### 5. Serializing Json (stringify)

Convert Json back to text with optional transformation:

```motoko
public type Replacer = {
    #function : (Text, Json.Json) -> ?Json.Json;
    #keys : [Text];
};

public func stringify(json: Json.Json, replacer: ?Json.Replacer) : Text
```

Example:

```motoko
// Basic stringify
let jsonText = Json.stringify(data, null);

// With replacer function to hide sensitive data
let replacer = #function(func(key: Text, value: Json.Json) : ?Json.Json {
    if (key == "password") {
        ?#string("****")
    } else {
        ?value
    }
});
let safeJson = Json.stringify(data, ?replacer);

// With key filter to include specific fields
let keys = #keys(["name", "age"]);
let filtered = Json.stringify(data, ?keys);
```

## Complete Example

Here's a full workflow example:

```motoko
// Start with JSON text
let jsonText = "{
    \"users\": [
        {
            \"name\": \"John\",
            \"email\": \"john@example.com\",
            \"age\": 30
        }
    ]
}";

// Parse it
switch(Json.parse(jsonText)) {
    case (#ok(data)) {
        // Get existing data
        let name = Json.get(data, "users[0].name");

        // Add new data
        let updated = Json.set(data, "users[0].phone", str("+1234567890"));

        // Remove sensitive data
        let cleaned = Json.remove(updated, "users[0].email");

        // Convert back to JSON text
        let finalJson = Json.stringify(cleaned, null);
    };
    case (#err(e)) {
        Debug.print("Parse error: " # debug_show(e));
    };
};
```

## 6. Schema Validation

The library supports JSON Schema validation allowing you to verify JSON data structures match an expected schema:

```motoko
public func validate(json: Json.Json, schema: Json.Schema) : Result.Result<(), Json.ValidationError>
```

Schema Type:

```motoko
public type Schema = {
  #object_ : {
    properties : [(Text, Schema)];
    required : ?[Text];
  };
  #array : {
    items : Schema;
  };
  #string;
  #number;
  #boolean;
  #null;
};
```

Example usage:

```motoko
// Define a schema
let userSchema = schemaObject([
  ("name", string()),
  ("age", number()),
  ("tags", array(string()))
], ?["name"]); // name is required

// Validate instance
switch(Json.validate(myJson, userSchema)) {
  case (#ok()) {
    // JSON is valid
  };
  case (#err(#TypeError{expected; got; path})) {
    // Type mismatch error
  };
  case (#err(#RequiredField(field))) {
    // Missing required field
  };
};
```

## Standard Compliance

This library strictly follows ECMA-404/RFC 8259:

- Proper Unicode support
- Complete escape sequence handling
- Strict number format validation
- No trailing commas
- Only double quotes for strings
- No comments

## Limitations

This library is in active development feedback and bug reports are welcome. Some important considerations:

- The `set` method allows creating new paths by default, which might lead to unintended data structure changes. Use with caution and consider validating your JSON structure with schemas before modifications.

- Schema validation is currently basic the plan is to support the full [JSON Schema specification](https://json-schema.org/) in future releases.

1. Number Precision

   - Integers are limited to Motoko's Int bounds
   - Floats follow IEEE 754 double-precision format

2. Object Keys

   - Must be strings
   - No duplicate keys (last one wins)

3. Special Values
   - JavaScript `undefined` is not supported
   - `NaN` and `Infinity` are not valid JSON values

Please report any issues or suggestions at the GitHub repository.

## Error Handling

```motoko
public type Error = {
    #invalidString : Text;
    #invalidNumber : Text;
    #invalidKeyword : Text;
    #invalidChar : Text;
    #unexpectedEOF;
    #unexpectedToken : Text;
};
```

The library provides detailed error information for debugging and validation.

## Path Expressions

The library uses a simple and intuitive path syntax for accessing and modifying JSON data:

```motoko
// Basic property access
"user.name"              // Access object property
"users[0]"              // Access array element
"users[0].name"         // Chain property and array access
"users.*.name"          // Wildcard access to all names in users
"items[*].price"        // Access price of all items
```

Path syntax rules:

1. Use dots (.) for object property access
2. Use brackets ([]) for array indices
3. Use asterisk (\*) as wildcard for multiple matches
4. Paths are case-sensitive
5. Properties can contain any valid JSON string characters

## Working with Complex Data

Example of working with nested structures:

```motoko
let complex = obj([
    ("store", obj([
        ("inventory", arr([
            obj([
                ("id", str("item1")),
                ("price", float(29.99)),
                ("tags", arr([
                    str("electronics"),
                    str("gadgets")
                ]))
            ])
        ]))
    ]))
]);

// Get nested value
let price = Json.get(complex, "store.inventory[0].price");

// Update nested array
let newTag = Json.set(complex, "store.inventory[0].tags[2]", str("new"));

// Remove all tags
let noTags = Json.remove(complex, "store.inventory[0].tags");
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
