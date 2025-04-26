import Text "mo:base/Text";
import Char "mo:base/Char";
import Int "mo:base/Int";
import Int32 "mo:base/Int32";
import Float "mo:base/Float";
import Bool "mo:base/Bool";
import Array "mo:base/Array";

module {
  public type Path = Text;
  public type PathPart = {
    #key : Text;
    #index : Nat;
    #wildcard;
  };
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
    #null_;
  };

  public type ValidationError = {
    #typeError : {
      expected : Text;
      got : Text;
      path : Text;
    };
    #requiredField : Text;
  };
  public type Token = {
    #beginArray;
    #beginObject;
    #endArray;
    #endObject;
    #nameSeperator;
    #valueSeperator;
    #whitespace;
    #false_;
    #null_;
    #true_;
    #number : {
      #int : Int;
      #float : Float;
    };
    #string : Text;
  };
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

  public type Error = {
    #invalidString : Text;
    #invalidNumber : Text;
    #invalidKeyword : Text;
    #invalidChar : Text;
    #invalidValue : Text;
    #unexpectedEOF;
    #unexpectedToken : Text;
  };
  public func errToText(e : Error) : Text {
  switch (e) {
    case (#invalidString(err)) { err };
    case (#invalidNumber(err)) { err };
    case (#invalidKeyword(err)) { err };
    case (#invalidChar(err)) { err };
    case (#invalidValue(err)) { err };
    case (#unexpectedEOF()) { "Unexpected EOF" };
    case (#unexpectedToken(err)) { err };
    };
  };

  public func transform(json : Json, replacer : (Text, Json) -> ?Json, key : Text) : Json {
    let replaced = switch (replacer(key, json)) {
      case (?newValue) { newValue };
      case (null) { json };
    };

    switch (replaced) {
      case (#object_(entries)) {
        #object_(
          Array.map<(Text, Json), (Text, Json)>(
            entries,
            func((k, v) : (Text, Json)) : (Text, Json) = (k, transform(v, replacer, k)),
          )
        );
      };
      case (#array(items)) {
        #array(
          Array.map<Json, Json>(
            items,
            func(item : Json) : Json = transform(item, replacer, key),
          )
        );
      };
      case _ { replaced };
    };
  };
  public func filterByKeys(json : Json, keys : [Text]) : Json {
    switch (json) {
      case (#object_(entries)) {
        #object_(
          Array.filter<(Text, Json)>(
            entries,
            func((k, _) : (Text, Json)) : Bool {
              for (allowedKey in keys.vals()) {
                if (k == allowedKey) return true;
              };
              false;
            },
          )
        );
      };
      case (#array(items)) {
        #array(
          Array.map<Json, Json>(
            items,
            func(item : Json) : Json = filterByKeys(item, keys),
          )
        );
      };
      case _ { json };
    };
  };

  public func charAt(i : Nat, t : Text) : Char {
    let arr = Text.toArray(t);
    arr[i];
  };
  public func toText(json : Json) : Text {
    switch (json) {
      case (#object_(entries)) {
        let fields = entries.vals();
        var result = "{";
        var first = true;
        for ((key, value) in fields) {
          if (not first) { result #= "," };
          result #= "\"" # key # "\":" # toText(value);
          first := false;
        };
        result # "}";
      };
      case (#array(items)) {
        let values = items.vals();
        var result = "[";
        var first = true;
        for (item in values) {
          if (not first) { result #= "," };
          result #= toText(item);
          first := false;
        };
        result # "]";
      };
      case (#string(text)) { "\"" # text # "\"" };
      case (#number(#int(n))) { Int.toText(n) };
      case (#number(#float(n))) { Float.toText(n) };
      case (#bool(b)) { Bool.toText(b) };
      case (#null_) { "null" };
    };
  };
  public func parseFloat(text : Text) : ?Float {
    var integer : Int = 0;
    var fraction : Float = 0;
    var exponent : Int = 0;
    var isNegative = false;
    var position = 0;
    let chars = text.chars();

    switch (chars.next()) {
      case (?'-') {
        isNegative := true;
        position += 1;
      };
      case (?d) if (Char.isDigit(d)) {
        integer := Int32.toInt(Int32.fromNat32(Char.toNat32(d) - 48));
        position += 1;
      };
      case (_) { return null };
    };

    label integerPart loop {
      switch (chars.next()) {
        case (?d) {
          if (Char.isDigit(d)) {
            integer := integer * 10 + Int32.toInt(Int32.fromNat32(Char.toNat32(d) - 48));
            position += 1;
          } else if (d == '.') {
            position += 1;
            break integerPart;
          } else if (d == 'e' or d == 'E') {
            position += 1;
            break integerPart;
          } else {
            return null;
          };
        };
        case (null) {
          return ?(Float.fromInt(if (isNegative) -integer else integer));
        };
      };
    };

    var fractionMultiplier : Float = 0.1;
    label fractionPart loop {
      switch (chars.next()) {
        case (?d) {
          if (Char.isDigit(d)) {
            fraction += fractionMultiplier * Float.fromInt(Int32.toInt(Int32.fromNat32(Char.toNat32(d) - 48)));
            fractionMultiplier *= 0.1;
            position += 1;
          } else if (d == 'e' or d == 'E') {
            position += 1;
            break fractionPart;
          } else {
            return null;
          };
        };
        case (null) {
          let result = Float.fromInt(if (isNegative) -integer else integer) +
          (if (isNegative) -fraction else fraction);
          return ?result;
        };
      };
    };

    var expIsNegative = false;
    switch (chars.next()) {
      case (?d) {
        if (d == '-') {
          expIsNegative := true;
          position += 1;
        } else if (d == '+') {
          position += 1;
        } else if (Char.isDigit(d)) {
          exponent := Int32.toInt(Int32.fromNat32(Char.toNat32(d) - 48));
          position += 1;
        } else {
          return null;
        };
      };
      case (null) { return null };
    };

    label exponentPart loop {
      switch (chars.next()) {
        case (?d) {
          if (Char.isDigit(d)) {
            exponent := exponent * 10 + Int32.toInt(Int32.fromNat32(Char.toNat32(d) - 48));
            position += 1;
          } else {
            return null;
          };
        };
        case (null) {
          let base = Float.fromInt(if (isNegative) -integer else integer) +
          (if (isNegative) -fraction else fraction);
          let multiplier = Float.pow(10, Float.fromInt(if (expIsNegative) -exponent else exponent));
          return ?(base * multiplier);
        };
      };
    };

    return null;
  };
  public func parseInt(text : Text) : ?Int {
    var int : Int = 0;
    var isNegative = false;
    let chars = text.chars();

    switch (chars.next()) {
      case (?'-') {
        isNegative := true;
      };
      case (?d) if (Char.isDigit(d)) {
        int := Int32.toInt(Int32.fromNat32(Char.toNat32(d) - 48));
      };
      case (_) { return null };
    };

    label parsing loop {
      switch (chars.next()) {
        case (?d) {
          if (Char.isDigit(d)) {
            int := int * 10 + Int32.toInt(Int32.fromNat32(Char.toNat32(d) - 48));
          } else {
            return null;
          };
        };
        case (null) {
          return ?(if (isNegative) -int else int);
        };
      };
    };
    return null;
  };
  public func getTypeString(json : Json) : Text {
    switch (json) {
      case (#object_(_)) "object";
      case (#array(_)) "array";
      case (#string(_)) "string";
      case (#number(_)) "number";
      case (#bool(_)) "boolean";
      case (#null_) "null";
    };
  };
};
