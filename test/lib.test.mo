import Json "../src/lib";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Text "mo:base/Text";
import { test } "mo:test";
import Types "../src/Types";

func testCases<TCase, TExpected>(
    name : Text,
    f : (TCase) -> TExpected,
    equal : (TExpected, TExpected) -> Bool,
    toTextCase : (TCase) -> Text,
    toTextExpected : (TExpected) -> Text,
    cases : [(TCase, TExpected)],
) {
    for ((c, expected) in cases.vals()) {
        let fullName = name # " - " # toTextCase(c);
        test(
            fullName,
            func() {
                let result = f(c);
                if (not equal(result, expected)) {
                    Debug.trap(fullName # " failed\nInput: " # toTextCase(c) # "\nExpected: " # toTextExpected(expected) # "\nActual: " # toTextExpected(result));
                };
            },
        );
    };
};

let fields = [
    ("string", #string("test")),
    ("positive-integer", #number(#int(42))),
    ("negative-integer", #number(#int(-1))),
    ("zero", #number(#int(0))),
    ("float", #number(#float(3.14))),
    ("array", #array([#string("a"), #number(#int(1))])),
    ("object", #object_([("a", #string("b")), ("c", #number(#int(2)))])),
    ("null", #null_),
    ("bool", #bool(true)),
];
let json = Json.obj(fields);

testCases<Text, ?Json.Json>(
    "get",
    func(c : Text) : ?Json.Json {
        Json.get(json, c);
    },
    func(x : ?Json.Json, y : ?Json.Json) : Bool = x == y,
    func(x : Text) : Text = x,
    func(x : ?Json.Json) : Text = debug_show (x),
    [
        ("string", ?#string("test")),
        ("positive-integer", ?#number(#int(42))),
        ("negative-integer", ?#number(#int(-1))),
        ("zero", ?#number(#int(0))),
        ("float", ?#number(#float(3.14))),
        ("array", ?#array([#string("a"), #number(#int(1))])),
        ("array.[0]", ?#string("a")),
        ("array.[1]", ?#number(#int(1))),
        ("array.[2]", null),
        ("object", ?#object_([("a", #string("b")), ("c", #number(#int(2)))])),
        ("object.a", ?#string("b")),
        ("object.c", ?#number(#int(2))),
        ("object.d", null),
        ("null", ?#null_),
        ("bool", ?#bool(true)),
        ("a", null),
    ],
);

testCases<Text, Result.Result<Nat, Json.GetAsError>>(
    "getAsNat",
    func(c : Text) : Result.Result<Nat, Json.GetAsError> = Json.getAsNat(json, c),
    func(x : Result.Result<Nat, Json.GetAsError>, y : Result.Result<Nat, Json.GetAsError>) : Bool = x == y,
    func(x : Text) : Text = x,
    func(x : Result.Result<Nat, Json.GetAsError>) : Text = debug_show (x),
    [
        ("string", #err(#typeMismatch)),
        ("positive-integer", #ok(42)),
        ("negative-integer", #err(#typeMismatch)),
        ("zero", #ok(0)),
        ("float", #err(#typeMismatch)),
        ("array", #err(#typeMismatch)),
        ("array.[0]", #err(#typeMismatch)),
        ("array.[1]", #ok(1)),
        ("object", #err(#typeMismatch)),
        ("object.a", #err(#typeMismatch)),
        ("object.c", #ok(2)),
        ("null", #err(#typeMismatch)),
        ("bool", #err(#typeMismatch)),
        ("a", #err(#pathNotFound)),
    ],
);

testCases<Text, Result.Result<Int, Json.GetAsError>>(
    "getAsInt",
    func(c : Text) : Result.Result<Int, Json.GetAsError> = Json.getAsInt(json, c),
    func(x : Result.Result<Int, Json.GetAsError>, y : Result.Result<Int, Json.GetAsError>) : Bool = x == y,
    func(x : Text) : Text = x,
    func(x : Result.Result<Int, Json.GetAsError>) : Text = debug_show (x),
    [
        ("string", #err(#typeMismatch)),
        ("positive-integer", #ok(42)),
        ("negative-integer", #ok(-1)),
        ("zero", #ok(0)),
        ("float", #err(#typeMismatch)),
        ("array", #err(#typeMismatch)),
        ("array.[0]", #err(#typeMismatch)),
        ("array.[1]", #ok(1)),
        ("object", #err(#typeMismatch)),
        ("object.a", #err(#typeMismatch)),
        ("object.c", #ok(2)),
        ("null", #err(#typeMismatch)),
        ("bool", #err(#typeMismatch)),
        ("a", #err(#pathNotFound)),
    ],
);

testCases<Text, Result.Result<Float, Json.GetAsError>>(
    "getAsFloat",
    func(c : Text) : Result.Result<Float, Json.GetAsError> = Json.getAsFloat(json, c),
    func(x : Result.Result<Float, Json.GetAsError>, y : Result.Result<Float, Json.GetAsError>) : Bool = x == y,
    func(x : Text) : Text = x,
    func(x : Result.Result<Float, Json.GetAsError>) : Text = debug_show (x),
    [
        ("string", #err(#typeMismatch)),
        ("positive-integer", #ok(42.0)),
        ("negative-integer", #ok(-1.0)),
        ("zero", #ok(0.0)),
        ("float", #ok(3.14)),
        ("array", #err(#typeMismatch)),
        ("array.[0]", #err(#typeMismatch)),
        ("array.[1]", #ok(1.0)),
        ("object", #err(#typeMismatch)),
        ("object.a", #err(#typeMismatch)),
        ("object.c", #ok(2.0)),
        ("null", #err(#typeMismatch)),
        ("bool", #err(#typeMismatch)),
        ("a", #err(#pathNotFound)),
    ],
);

testCases<Text, Result.Result<Bool, Json.GetAsError>>(
    "getAsBool",
    func(c : Text) : Result.Result<Bool, Json.GetAsError> = Json.getAsBool(json, c),
    func(x : Result.Result<Bool, Json.GetAsError>, y : Result.Result<Bool, Json.GetAsError>) : Bool = x == y,
    func(x : Text) : Text = x,
    func(x : Result.Result<Bool, Json.GetAsError>) : Text = debug_show (x),
    [
        ("string", #err(#typeMismatch)),
        ("positive-integer", #err(#typeMismatch)),
        ("negative-integer", #err(#typeMismatch)),
        ("zero", #err(#typeMismatch)),
        ("float", #err(#typeMismatch)),
        ("array", #err(#typeMismatch)),
        ("array.[0]", #err(#typeMismatch)),
        ("array.[1]", #err(#typeMismatch)),
        ("object", #err(#typeMismatch)),
        ("object.a", #err(#typeMismatch)),
        ("object.c", #err(#typeMismatch)),
        ("null", #err(#typeMismatch)),
        ("bool", #ok(true)),
        ("a", #err(#pathNotFound)),
    ],
);

testCases<Text, Result.Result<Text, Json.GetAsError>>(
    "getAsText",
    func(c : Text) : Result.Result<Text, Json.GetAsError> = Json.getAsText(json, c),
    func(x : Result.Result<Text, Json.GetAsError>, y : Result.Result<Text, Json.GetAsError>) : Bool = x == y,
    func(x : Text) : Text = x,
    func(x : Result.Result<Text, Json.GetAsError>) : Text = debug_show (x),
    [
        ("string", #ok("test")),
        ("positive-integer", #err(#typeMismatch)),
        ("negative-integer", #err(#typeMismatch)),
        ("zero", #err(#typeMismatch)),
        ("float", #err(#typeMismatch)),
        ("array", #err(#typeMismatch)),
        ("array.[0]", #ok("a")),
        ("array.[1]", #err(#typeMismatch)),
        ("object", #err(#typeMismatch)),
        ("object.a", #ok("b")),
        ("object.c", #err(#typeMismatch)),
        ("null", #err(#typeMismatch)),
        ("bool", #err(#typeMismatch)),
        ("a", #err(#pathNotFound)),
    ],
);

testCases<Text, Result.Result<[Json.Json], Json.GetAsError>>(
    "getAsArray",
    func(c : Text) : Result.Result<[Json.Json], Json.GetAsError> = Json.getAsArray(json, c),
    func(x : Result.Result<[Json.Json], Json.GetAsError>, y : Result.Result<[Json.Json], Json.GetAsError>) : Bool = x == y,
    func(x : Text) : Text = x,
    func(x : Result.Result<[Json.Json], Json.GetAsError>) : Text = debug_show (x),
    [
        ("string", #err(#typeMismatch)),
        ("positive-integer", #err(#typeMismatch)),
        ("negative-integer", #err(#typeMismatch)),
        ("zero", #err(#typeMismatch)),
        ("float", #err(#typeMismatch)),
        ("array", #ok([#string("a"), #number(#int(1))])),
        ("array.[0]", #err(#typeMismatch)),
        ("array.[1]", #err(#typeMismatch)),
        ("object", #err(#typeMismatch)),
        ("object.a", #err(#typeMismatch)),
        ("object.c", #err(#typeMismatch)),
        ("null", #err(#typeMismatch)),
        ("bool", #err(#typeMismatch)),
        ("a", #err(#pathNotFound)),
    ],
);

testCases<Text, Result.Result<[(Text, Json.Json)], Json.GetAsError>>(
    "getAsObject",
    func(c : Text) : Result.Result<[(Text, Json.Json)], Json.GetAsError> = Json.getAsObject(json, c),
    func(x : Result.Result<[(Text, Json.Json)], Json.GetAsError>, y : Result.Result<[(Text, Json.Json)], Json.GetAsError>) : Bool = x == y,
    func(x : Text) : Text = x,
    func(x : Result.Result<[(Text, Json.Json)], Json.GetAsError>) : Text = debug_show (x),
    [
        ("string", #err(#typeMismatch)),
        ("positive-integer", #err(#typeMismatch)),
        ("negative-integer", #err(#typeMismatch)),
        ("zero", #err(#typeMismatch)),
        ("float", #err(#typeMismatch)),
        ("array", #err(#typeMismatch)),
        ("array.[0]", #err(#typeMismatch)),
        ("array.[1]", #err(#typeMismatch)),
        (
            "object",
            #ok([("a", #string("b")), ("c", #number(#int(2)))]),
        ),
        ("object.a", #err(#typeMismatch)),
        ("object.c", #err(#typeMismatch)),
        ("null", #err(#typeMismatch)),
        ("bool", #err(#typeMismatch)),
        ("a", #err(#pathNotFound)),
    ],
);

testCases<Text, Result.Result<Json.Json, Types.Error>>(
    "parse",
    Json.parse,
    func(x : Result.Result<Json.Json, Types.Error>, y : Result.Result<Json.Json, Types.Error>) : Bool = x == y,
    func(x : Text) : Text = x,
    func(x : Result.Result<Json.Json, Types.Error>) : Text = debug_show (x),
    [
        ("{", #err(#unexpectedEOF)),
        ("{}", #ok(#object_([]))),
        ("true", #ok(#bool(true))),
        ("false", #ok(#bool(false))),
        ("null", #ok(#null_)),
        ("[1,2,3]", #ok(#array([#number(#int(1)), #number(#int(2)), #number(#int(3))]))),
        ("\"\"", #ok(#string(""))),
        ("\"hello\"", #ok(#string("hello"))),
        ("123", #ok(#number(#int(123)))),
        ("123.456", #ok(#number(#float(123.456)))),
        ("-123.456e-10", #ok(#number(#float(-1.234_56e-08)))),
        ("{\"name\":\"John\",\"age\":30}", #ok(#object_([("name", #string("John")), ("age", #number(#int(+30)))]))),
        (
            "\"hello\\u0048\\u0065\\u006C\\u006C\\u006F\"",
            #ok(#string("helloHello")),
        ),
        ("[1,2,3,null,false,true]", #ok(#array([#number(#int(+1)), #number(#int(+2)), #number(#int(+3)), #null_, #bool(false), #bool(true)]))), // Array with mixed types
        ("{\"nested\":{\"array\":[1,2,3],\"null\": null}}", #ok(#object_([("nested", #object_([("array", #array([#number(#int(1)), #number(#int(2)), #number(#int(3))])), ("null", #null_)]))]))),
        ("{ \"users\": [ { \"id\": 1, \"name\": \"Alice\", \"email\": \"alice@example.com\", \"orders\": [ { \"orderId\": \"A123\", \"items\": [ {\"product\": \"Laptop\", \"price\": 999.99}, {\"product\": \"Mouse\", \"price\": 24.99} ] } ] }, { \"id\": 2, \"name\": \"Bob\", \"email\": \"bob@example.com\", \"orders\": [] } ], \"metadata\": { \"lastUpdated\": \"2024-01-10\" } }", #ok(#object_([("users", #array([#object_([("id", #number(#int(1))), ("name", #string("Alice")), ("email", #string("alice@example.com")), ("orders", #array([#object_([("orderId", #string("A123")), ("items", #array([#object_([("product", #string("Laptop")), ("price", #number(#float(999.99)))]), #object_([("product", #string("Mouse")), ("price", #number(#float(24.99)))])]))])]))]), #object_([("id", #number(#int(2))), ("name", #string("Bob")), ("email", #string("bob@example.com")), ("orders", #array([]))])])), ("metadata", #object_([("lastUpdated", #string("2024-01-10"))]))]))),
    ],
);

test(
    "stringify",
    func() {
        type TestCase = {
            value : Json.Json;
            expectedText : Text;
        };
        let testCases : [TestCase] = [
            { value = #string("test"); expectedText = "\"test\"" },
            { value = #number(#int(42)); expectedText = "42" },
            {
                value = #number(#float(3.14));
                expectedText = "3.1400000000000001"; // Float precision does not match exactly
            },
            {
                value = #number(#float(1.125));
                expectedText = "1.125";
            },
            { value = #bool(true); expectedText = "true" },
            { value = #null_; expectedText = "null" },
            {
                value = #array([#string("a"), #number(#int(1))]);
                expectedText = "[\"a\",1]";
            },
            {
                value = #object_([("key", #string("value"))]);
                expectedText = "{\"key\":\"value\"}";
            },
        ];

        for (testCase in testCases.vals()) {
            let result = Json.stringify(testCase.value, null);
            if (result != testCase.expectedText) {
                Debug.trap(
                    "stringify failed\nInput: " # debug_show (testCase.value) # "\nExpected: " # testCase.expectedText # "\nActual: " # result
                );
            };
        };
    },
);

test(
    "stringify - special character escaping (Comprehensive)",
    func() {
        type TestCase = {
            name: Text;
            value : Json.Json;
            expectedText : Text;
        };

        // A comprehensive list of test cases covering the JSON spec.
        let testCases : [TestCase] = [
            // --- Basic Required Escapes ---
            {
                name = "String with quotes";
                value = #string("hello \"world\"");
                expectedText = "\"hello \\\"world\\\"\"";
            },
            {
                name = "String with backslash";
                value = #string("C:\\Users\\");
                expectedText = "\"C:\\\\Users\\\\\"";
            },
            {
                name = "String with newline";
                value = #string("line1\nline2");
                expectedText = "\"line1\\nline2\"";
            },
            {
                name = "String with carriage return";
                value = #string("line1\rline2");
                expectedText = "\"line1\\rline2\"";
            },
            {
                name = "String with tab";
                value = #string("col1\tcol2");
                expectedText = "\"col1\\tcol2\"";
            },
            {
                // Motoko uses \u{...} for unicode literals. 0x8 is backspace.
                name = "String with backspace (\\b)";
                value = #string("a\u{8}b");
                expectedText = "\"a\\bb\"";
            },
            {
                // 0xC is form feed.
                name = "String with form feed (\\f)";
                value = #string("a\u{c}b");
                expectedText = "\"a\\fb\"";
            },

            // --- Control Character Escapes (\uXXXX) ---
            {
                // U+0000 (null character) must be escaped.
                name = "Control character NULL (U+0000)";
                value = #string("\u{0}");
                expectedText = "\"\\u0000\"";
            },
            {
                // U+001F (unit separator) is the last control character.
                name = "Control character Unit Separator (U+001F)";
                value = #string("\u{1f}");
                expectedText = "\"\\u001f\"";
            },

            // --- Edge Cases and Combinations ---
            {
                name = "Empty string";
                value = #string("");
                expectedText = "\"\"";
            },
            {
                name = "String containing only a quote";
                value = #string("\"");
                expectedText = "\"\\\"\"";
            },
            {
                name = "String containing only a backslash";
                value = #string("\\");
                expectedText = "\"\\\\\"";
            },
            {
                name = "The exact problem case: a string that is a JSON object";
                value = #string("{\"key\":\"value\"}");
                expectedText = "\"{\\\"key\\\":\\\"value\\\"}\"";
            },
            {
                name = "A mix of all special characters";
                value = #string("key:\"val\"\n\t\\path/\u{1}end");
                expectedText = "\"key:\\\"val\\\"\\n\\t\\\\path/\\u0001end\"";
            }
        ];

        for (testCase in testCases.vals()) {
            let result = Json.stringify(testCase.value, null);

            if (result != testCase.expectedText) {
                Debug.trap(
                    "stringify test case '" # testCase.name # "' failed\nInput:    "
                    # debug_show (testCase.value)
                    # "\nExpected: " # testCase.expectedText
                    # "\nActual:   " # result
                );
            };
        };
    },
);