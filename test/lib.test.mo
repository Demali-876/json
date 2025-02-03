import Json "../src/lib";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
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
test(
    "get",
    func() {
        assert (Json.get(json, "string") == ?#string("test"));
        assert (Json.get(json, "positive-integer") == ?#number(#int(42)));
        assert (Json.get(json, "negative-integer") == ?#number(#int(-1)));
        assert (Json.get(json, "zero") == ?#number(#int(0)));
        assert (Json.get(json, "float") == ?#number(#float(3.14)));
        assert (Json.get(json, "array") == ?#array([#string("a"), #number(#int(1))]));
        assert (Json.get(json, "array.[0]") == ?#string("a"));
        assert (Json.get(json, "array.[1]") == ?#number(#int(1)));
        assert (Json.get(json, "array.[2]") == null);
        assert (Json.get(json, "object") == ?#object_([("a", #string("b")), ("c", #number(#int(2)))]));
        assert (Json.get(json, "object.a") == ?#string("b"));
        assert (Json.get(json, "object.c") == ?#number(#int(2)));
        assert (Json.get(json, "object.d") == null);
        assert (Json.get(json, "null") == ?#null_);
        assert (Json.get(json, "bool") == ?#bool(true));
        assert (Json.get(json, "a") == null);
    },
);

test(
    "getAsNat",
    func() {
        assert (Json.getAsNat(json, "string") == #err(#typeMismatch));
        assert (Json.getAsNat(json, "positive-integer") == #ok(42));
        assert (Json.getAsNat(json, "negative-integer") == #err(#typeMismatch));
        assert (Json.getAsNat(json, "zero") == #ok(0));
        assert (Json.getAsNat(json, "float") == #err(#typeMismatch));
        assert (Json.getAsNat(json, "array") == #err(#typeMismatch));
        assert (Json.getAsNat(json, "array.[0]") == #err(#typeMismatch));
        assert (Json.getAsNat(json, "array.[1]") == #ok(1));
        assert (Json.getAsNat(json, "object") == #err(#typeMismatch));
        assert (Json.getAsNat(json, "object.a") == #err(#typeMismatch));
        assert (Json.getAsNat(json, "object.c") == #ok(2));
        assert (Json.getAsNat(json, "null") == #err(#typeMismatch));
        assert (Json.getAsNat(json, "bool") == #err(#typeMismatch));
        assert (Json.getAsNat(json, "a") == #err(#pathNotFound));
    },
);

test(
    "getAsInt",
    func() {
        assert (Json.getAsInt(json, "string") == #err(#typeMismatch));
        assert (Json.getAsInt(json, "positive-integer") == #ok(42));
        assert (Json.getAsInt(json, "negative-integer") == #ok(-1));
        assert (Json.getAsInt(json, "zero") == #ok(0));
        assert (Json.getAsInt(json, "float") == #err(#typeMismatch));
        assert (Json.getAsInt(json, "array") == #err(#typeMismatch));
        assert (Json.getAsInt(json, "array.[0]") == #err(#typeMismatch));
        assert (Json.getAsInt(json, "array.[1]") == #ok(1));
        assert (Json.getAsInt(json, "object") == #err(#typeMismatch));
        assert (Json.getAsInt(json, "object.a") == #err(#typeMismatch));
        assert (Json.getAsInt(json, "object.c") == #ok(2));
        assert (Json.getAsInt(json, "null") == #err(#typeMismatch));
        assert (Json.getAsInt(json, "bool") == #err(#typeMismatch));
        assert (Json.getAsInt(json, "a") == #err(#pathNotFound));
    },
);

test(
    "getAsFloat",
    func() {
        assert (Json.getAsFloat(json, "string") == #err(#typeMismatch));
        assert (Json.getAsFloat(json, "positive-integer") == #ok(42.0));
        assert (Json.getAsFloat(json, "negative-integer") == #ok(-1.0));
        assert (Json.getAsFloat(json, "zero") == #ok(0.0));
        assert (Json.getAsFloat(json, "float") == #ok(3.14));
        assert (Json.getAsFloat(json, "array") == #err(#typeMismatch));
        assert (Json.getAsFloat(json, "array.[0]") == #err(#typeMismatch));
        assert (Json.getAsFloat(json, "array.[1]") == #ok(1.0));
        assert (Json.getAsFloat(json, "object") == #err(#typeMismatch));
        assert (Json.getAsFloat(json, "object.a") == #err(#typeMismatch));
        assert (Json.getAsFloat(json, "object.c") == #ok(2.0));
        assert (Json.getAsFloat(json, "null") == #err(#typeMismatch));
        assert (Json.getAsFloat(json, "bool") == #err(#typeMismatch));
        assert (Json.getAsFloat(json, "a") == #err(#pathNotFound));
    },
);

test(
    "getAsBool",
    func() {
        assert (Json.getAsBool(json, "string") == #err(#typeMismatch));
        assert (Json.getAsBool(json, "positive-integer") == #err(#typeMismatch));
        assert (Json.getAsBool(json, "negative-integer") == #err(#typeMismatch));
        assert (Json.getAsBool(json, "zero") == #err(#typeMismatch));
        assert (Json.getAsBool(json, "float") == #err(#typeMismatch));
        assert (Json.getAsBool(json, "array") == #err(#typeMismatch));
        assert (Json.getAsBool(json, "array.[0]") == #err(#typeMismatch));
        assert (Json.getAsBool(json, "array.[1]") == #err(#typeMismatch));
        assert (Json.getAsBool(json, "object") == #err(#typeMismatch));
        assert (Json.getAsBool(json, "object.a") == #err(#typeMismatch));
        assert (Json.getAsBool(json, "object.c") == #err(#typeMismatch));
        assert (Json.getAsBool(json, "null") == #err(#typeMismatch));
        assert (Json.getAsBool(json, "bool") == #ok(true));
        assert (Json.getAsBool(json, "a") == #err(#pathNotFound));
    },
);

test(
    "getAsText",
    func() {
        assert (Json.getAsText(json, "string") == #ok("test"));
        assert (Json.getAsText(json, "positive-integer") == #err(#typeMismatch));
        assert (Json.getAsText(json, "negative-integer") == #err(#typeMismatch));
        assert (Json.getAsText(json, "zero") == #err(#typeMismatch));
        assert (Json.getAsText(json, "float") == #err(#typeMismatch));
        assert (Json.getAsText(json, "array") == #err(#typeMismatch));
        assert (Json.getAsText(json, "array.[0]") == #ok("a"));
        assert (Json.getAsText(json, "array.[1]") == #err(#typeMismatch));
        assert (Json.getAsText(json, "object") == #err(#typeMismatch));
        assert (Json.getAsText(json, "object.a") == #ok("b"));
        assert (Json.getAsText(json, "object.c") == #err(#typeMismatch));
        assert (Json.getAsText(json, "null") == #err(#typeMismatch));
        assert (Json.getAsText(json, "bool") == #err(#typeMismatch));
        assert (Json.getAsText(json, "a") == #err(#pathNotFound));
    },
);

test(
    "getAsArray",
    func() {
        assert (Json.getAsArray(json, "string") == #err(#typeMismatch));
        assert (Json.getAsArray(json, "positive-integer") == #err(#typeMismatch));
        assert (Json.getAsArray(json, "negative-integer") == #err(#typeMismatch));
        assert (Json.getAsArray(json, "zero") == #err(#typeMismatch));
        assert (Json.getAsArray(json, "float") == #err(#typeMismatch));
        assert (Json.getAsArray(json, "array") == #ok([#string("a"), #number(#int(1))]));
        assert (Json.getAsArray(json, "array.[0]") == #err(#typeMismatch));
        assert (Json.getAsArray(json, "array.[1]") == #err(#typeMismatch));
        assert (Json.getAsArray(json, "object") == #err(#typeMismatch));
        assert (Json.getAsArray(json, "object.a") == #err(#typeMismatch));
        assert (Json.getAsArray(json, "object.c") == #err(#typeMismatch));
        assert (Json.getAsArray(json, "null") == #err(#typeMismatch));
        assert (Json.getAsArray(json, "bool") == #err(#typeMismatch));
        assert (Json.getAsArray(json, "a") == #err(#pathNotFound));
    },
);

test(
    "getAsObject",
    func() {
        assert (Json.getAsObject(json, "string") == #err(#typeMismatch));
        assert (Json.getAsObject(json, "positive-integer") == #err(#typeMismatch));
        assert (Json.getAsObject(json, "negative-integer") == #err(#typeMismatch));
        assert (Json.getAsObject(json, "zero") == #err(#typeMismatch));
        assert (Json.getAsObject(json, "float") == #err(#typeMismatch));
        assert (Json.getAsObject(json, "array") == #err(#typeMismatch));
        assert (Json.getAsObject(json, "array.[0]") == #err(#typeMismatch));
        assert (Json.getAsObject(json, "array.[1]") == #err(#typeMismatch));
        assert (Json.getAsObject(json, "object") == #ok([("a", #string("b")), ("c", #number(#int(2)))]));
        assert (Json.getAsObject(json, "object.a") == #err(#typeMismatch));
        assert (Json.getAsObject(json, "object.c") == #err(#typeMismatch));
        assert (Json.getAsObject(json, "null") == #err(#typeMismatch));
        assert (Json.getAsObject(json, "bool") == #err(#typeMismatch));
        assert (Json.getAsObject(json, "a") == #err(#pathNotFound));
    },
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
        ("[1,2,3,null,false,true]", #err(#invalidKeyword("Invalid keyword starting with 'n'"))), // Array with mixed types
        ("{\"nested\":{\"array\":[1,2,3],\"null\": null}}", #ok(#object_([("nested", #object_([("array", #array([#number(#int(1)), #number(#int(2)), #number(#int(3))])), ("null", #null_)]))]))),
        ("{ \"users\": [ { \"id\": 1, \"name\": \"Alice\", \"email\": \"alice@example.com\", \"orders\": [ { \"orderId\": \"A123\", \"items\": [ {\"product\": \"Laptop\", \"price\": 999.99}, {\"product\": \"Mouse\", \"price\": 24.99} ] } ] }, { \"id\": 2, \"name\": \"Bob\", \"email\": \"bob@example.com\", \"orders\": [] } ], \"metadata\": { \"lastUpdated\": \"2024-01-10\" } }", #ok(#object_([("users", #array([#object_([("id", #number(#int(1))), ("name", #string("Alice")), ("email", #string("alice@example.com")), ("orders", #array([#object_([("orderId", #string("A123")), ("items", #array([#object_([("product", #string("Laptop")), ("price", #number(#float(999.99)))]), #object_([("product", #string("Mouse")), ("price", #number(#float(24.99)))])]))])]))]), #object_([("id", #number(#int(2))), ("name", #string("Bob")), ("email", #string("bob@example.com")), ("orders", #array([]))])])), ("metadata", #object_([("lastUpdated", #string("2024-01-10"))]))]))),
    ],
);
