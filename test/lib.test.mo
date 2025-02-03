import JSON "../src/lib";
import { test } "mo:test";

let fields = [
    ("string", #String("test")),
    ("positive-integer", #Number(#Int(42))),
    ("negative-integer", #Number(#Int(-1))),
    ("zero", #Number(#Int(0))),
    ("float", #Number(#Float(3.14))),
    ("array", #Array([#String("a"), #Number(#Int(1))])),
    ("object", #Object([("a", #String("b")), ("c", #Number(#Int(2)))])),
    ("null", #Null),
    ("bool", #Bool(true)),
];
let json = JSON.obj(fields);
test(
    "get",
    func() {
        assert (JSON.get(json, "string") == ?#String("test"));
        assert (JSON.get(json, "positive-integer") == ?#Number(#Int(42)));
        assert (JSON.get(json, "negative-integer") == ?#Number(#Int(-1)));
        assert (JSON.get(json, "zero") == ?#Number(#Int(0)));
        assert (JSON.get(json, "float") == ?#Number(#Float(3.14)));
        assert (JSON.get(json, "array") == ?#Array([#String("a"), #Number(#Int(1))]));
        assert (JSON.get(json, "array.[0]") == ?#String("a"));
        assert (JSON.get(json, "array.[1]") == ?#Number(#Int(1)));
        assert (JSON.get(json, "array.[2]") == null);
        assert (JSON.get(json, "object") == ?#Object([("a", #String("b")), ("c", #Number(#Int(2)))]));
        assert (JSON.get(json, "object.a") == ?#String("b"));
        assert (JSON.get(json, "object.c") == ?#Number(#Int(2)));
        assert (JSON.get(json, "object.d") == null);
        assert (JSON.get(json, "null") == ?#Null);
        assert (JSON.get(json, "bool") == ?#Bool(true));
        assert (JSON.get(json, "a") == null);
    },
);

test(
    "getAsNat",
    func() {
        assert (JSON.getAsNat(json, "string") == #err(#typeMismatch));
        assert (JSON.getAsNat(json, "positive-integer") == #ok(42));
        assert (JSON.getAsNat(json, "negative-integer") == #err(#typeMismatch));
        assert (JSON.getAsNat(json, "zero") == #ok(0));
        assert (JSON.getAsNat(json, "float") == #err(#typeMismatch));
        assert (JSON.getAsNat(json, "array") == #err(#typeMismatch));
        assert (JSON.getAsNat(json, "array.[0]") == #err(#typeMismatch));
        assert (JSON.getAsNat(json, "array.[1]") == #ok(1));
        assert (JSON.getAsNat(json, "object") == #err(#typeMismatch));
        assert (JSON.getAsNat(json, "object.a") == #err(#typeMismatch));
        assert (JSON.getAsNat(json, "object.c") == #ok(2));
        assert (JSON.getAsNat(json, "null") == #err(#typeMismatch));
        assert (JSON.getAsNat(json, "bool") == #err(#typeMismatch));
        assert (JSON.getAsNat(json, "a") == #err(#pathNotFound));
    },
);

test(
    "getAsInt",
    func() {
        assert (JSON.getAsInt(json, "string") == #err(#typeMismatch));
        assert (JSON.getAsInt(json, "positive-integer") == #ok(42));
        assert (JSON.getAsInt(json, "negative-integer") == #ok(-1));
        assert (JSON.getAsInt(json, "zero") == #ok(0));
        assert (JSON.getAsInt(json, "float") == #err(#typeMismatch));
        assert (JSON.getAsInt(json, "array") == #err(#typeMismatch));
        assert (JSON.getAsInt(json, "array.[0]") == #err(#typeMismatch));
        assert (JSON.getAsInt(json, "array.[1]") == #ok(1));
        assert (JSON.getAsInt(json, "object") == #err(#typeMismatch));
        assert (JSON.getAsInt(json, "object.a") == #err(#typeMismatch));
        assert (JSON.getAsInt(json, "object.c") == #ok(2));
        assert (JSON.getAsInt(json, "null") == #err(#typeMismatch));
        assert (JSON.getAsInt(json, "bool") == #err(#typeMismatch));
        assert (JSON.getAsInt(json, "a") == #err(#pathNotFound));
    },
);

test(
    "getAsFloat",
    func() {
        assert (JSON.getAsFloat(json, "string") == #err(#typeMismatch));
        assert (JSON.getAsFloat(json, "positive-integer") == #ok(42.0));
        assert (JSON.getAsFloat(json, "negative-integer") == #ok(-1.0));
        assert (JSON.getAsFloat(json, "zero") == #ok(0.0));
        assert (JSON.getAsFloat(json, "float") == #ok(3.14));
        assert (JSON.getAsFloat(json, "array") == #err(#typeMismatch));
        assert (JSON.getAsFloat(json, "array.[0]") == #err(#typeMismatch));
        assert (JSON.getAsFloat(json, "array.[1]") == #ok(1.0));
        assert (JSON.getAsFloat(json, "object") == #err(#typeMismatch));
        assert (JSON.getAsFloat(json, "object.a") == #err(#typeMismatch));
        assert (JSON.getAsFloat(json, "object.c") == #ok(2.0));
        assert (JSON.getAsFloat(json, "null") == #err(#typeMismatch));
        assert (JSON.getAsFloat(json, "bool") == #err(#typeMismatch));
        assert (JSON.getAsFloat(json, "a") == #err(#pathNotFound));
    },
);

test(
    "getAsBool",
    func() {
        assert (JSON.getAsBool(json, "string") == #err(#typeMismatch));
        assert (JSON.getAsBool(json, "positive-integer") == #err(#typeMismatch));
        assert (JSON.getAsBool(json, "negative-integer") == #err(#typeMismatch));
        assert (JSON.getAsBool(json, "zero") == #err(#typeMismatch));
        assert (JSON.getAsBool(json, "float") == #err(#typeMismatch));
        assert (JSON.getAsBool(json, "array") == #err(#typeMismatch));
        assert (JSON.getAsBool(json, "array.[0]") == #err(#typeMismatch));
        assert (JSON.getAsBool(json, "array.[1]") == #err(#typeMismatch));
        assert (JSON.getAsBool(json, "object") == #err(#typeMismatch));
        assert (JSON.getAsBool(json, "object.a") == #err(#typeMismatch));
        assert (JSON.getAsBool(json, "object.c") == #err(#typeMismatch));
        assert (JSON.getAsBool(json, "null") == #err(#typeMismatch));
        assert (JSON.getAsBool(json, "bool") == #ok(true));
        assert (JSON.getAsBool(json, "a") == #err(#pathNotFound));
    },
);

test(
    "getAsText",
    func() {
        assert (JSON.getAsText(json, "string") == #ok("test"));
        assert (JSON.getAsText(json, "positive-integer") == #err(#typeMismatch));
        assert (JSON.getAsText(json, "negative-integer") == #err(#typeMismatch));
        assert (JSON.getAsText(json, "zero") == #err(#typeMismatch));
        assert (JSON.getAsText(json, "float") == #err(#typeMismatch));
        assert (JSON.getAsText(json, "array") == #err(#typeMismatch));
        assert (JSON.getAsText(json, "array.[0]") == #ok("a"));
        assert (JSON.getAsText(json, "array.[1]") == #err(#typeMismatch));
        assert (JSON.getAsText(json, "object") == #err(#typeMismatch));
        assert (JSON.getAsText(json, "object.a") == #ok("b"));
        assert (JSON.getAsText(json, "object.c") == #err(#typeMismatch));
        assert (JSON.getAsText(json, "null") == #err(#typeMismatch));
        assert (JSON.getAsText(json, "bool") == #err(#typeMismatch));
        assert (JSON.getAsText(json, "a") == #err(#pathNotFound));
    },
);

test(
    "getAsArray",
    func() {
        assert (JSON.getAsArray(json, "string") == #err(#typeMismatch));
        assert (JSON.getAsArray(json, "positive-integer") == #err(#typeMismatch));
        assert (JSON.getAsArray(json, "negative-integer") == #err(#typeMismatch));
        assert (JSON.getAsArray(json, "zero") == #err(#typeMismatch));
        assert (JSON.getAsArray(json, "float") == #err(#typeMismatch));
        assert (JSON.getAsArray(json, "array") == #ok([#String("a"), #Number(#Int(1))]));
        assert (JSON.getAsArray(json, "array.[0]") == #err(#typeMismatch));
        assert (JSON.getAsArray(json, "array.[1]") == #err(#typeMismatch));
        assert (JSON.getAsArray(json, "object") == #err(#typeMismatch));
        assert (JSON.getAsArray(json, "object.a") == #err(#typeMismatch));
        assert (JSON.getAsArray(json, "object.c") == #err(#typeMismatch));
        assert (JSON.getAsArray(json, "null") == #err(#typeMismatch));
        assert (JSON.getAsArray(json, "bool") == #err(#typeMismatch));
        assert (JSON.getAsArray(json, "a") == #err(#pathNotFound));
    },
);

test(
    "getAsObject",
    func() {
        assert (JSON.getAsObject(json, "string") == #err(#typeMismatch));
        assert (JSON.getAsObject(json, "positive-integer") == #err(#typeMismatch));
        assert (JSON.getAsObject(json, "negative-integer") == #err(#typeMismatch));
        assert (JSON.getAsObject(json, "zero") == #err(#typeMismatch));
        assert (JSON.getAsObject(json, "float") == #err(#typeMismatch));
        assert (JSON.getAsObject(json, "array") == #err(#typeMismatch));
        assert (JSON.getAsObject(json, "array.[0]") == #err(#typeMismatch));
        assert (JSON.getAsObject(json, "array.[1]") == #err(#typeMismatch));
        assert (JSON.getAsObject(json, "object") == #ok([("a", #String("b")), ("c", #Number(#Int(2)))]));
        assert (JSON.getAsObject(json, "object.a") == #err(#typeMismatch));
        assert (JSON.getAsObject(json, "object.c") == #err(#typeMismatch));
        assert (JSON.getAsObject(json, "null") == #err(#typeMismatch));
        assert (JSON.getAsObject(json, "bool") == #err(#typeMismatch));
        assert (JSON.getAsObject(json, "a") == #err(#pathNotFound));
    },
);
