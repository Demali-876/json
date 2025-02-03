import Lexer "Lexer";
import Parser "Parser";
import Types "Types";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Float "mo:base/Float";
module JSON {
  public type JSON = Types.JSON;
  public type Replacer = {
    #Function : (Text, JSON) -> ?JSON;
    #Keys : [Text];
  };
  public type GetAsError = {
    #pathNotFound;
    #typeMismatch;
  };
  public type Path = Types.Path;
  public type Error = Types.Error;
  public type Schema = Types.Schema;
  public type ValidationError = Types.ValidationError;
  //JSON Type constructors
  public func str(text : Text) : JSON = #String(text);
  public func int(n : Int) : JSON = #Number(#Int(n));
  public func float(n : Float) : JSON = #Number(#Float(n));
  public func bool(b : Bool) : JSON = #Bool(b);
  public func nullable() : JSON = #Null;
  public func obj(entries : [(Text, JSON)]) : JSON = #Object(entries);
  public func arr(items : [JSON]) : JSON = #Array(items);
  //Schema Type constructors
  public func string() : Types.Schema = #String;
  public func number() : Types.Schema = #Number;
  public func boolean() : Types.Schema = #Boolean;
  public func nullSchema() : Types.Schema = #Null;
  public func array(itemSchema : Types.Schema) : Types.Schema = #Array({
    items = itemSchema;
  });
  public func schemaObject(
    properties : [(Text, Types.Schema)],
    required : ?[Text],
  ) : Types.Schema = #Object({
    properties;
    required;
  });

  public func parse(input : Text) : Result.Result<Types.JSON, Types.Error> {
    let lexer = Lexer.Lexer(input);
    let tokens = switch (lexer.tokenize()) {
      case (#ok(tokens)) { tokens };
      case (#err(e)) { return #err(e) };
    };
    let parser = Parser.Parser(tokens);
    parser.parse();
  };

  public func stringify(json : JSON, replacer : ?Replacer) : Text {
    switch (replacer) {
      case (null) {
        Types.toText(json);
      };
      case (?#Function(fn)) {
        Types.toText(Types.transform(json, fn, ""));
      };
      case (?#Keys(allowedKeys)) {
        Types.toText(Types.filterByKeys(json, allowedKeys));
      };
    };
  };
  public func get(json : JSON, path : Types.Path) : ?JSON {
    let parts = Parser.parsePath(path);
    Parser.getWithParts(json, parts);
  };

  public func getAsNat(json : JSON, path : Types.Path) : Result.Result<Nat, GetAsError> {
    let ?value = get(json, path) else return #err(#pathNotFound);
    let #Number(#Int(intValue)) = value else return #err(#typeMismatch);
    if (intValue < 0) {
      // Must be a positive integer
      return #err(#typeMismatch);
    };
    #ok(Int.abs(intValue));
  };

  public func getAsInt(json : JSON, path : Types.Path) : Result.Result<Int, GetAsError> {
    let ?value = get(json, path) else return #err(#pathNotFound);
    let #Number(#Int(intValue)) = value else return #err(#typeMismatch);
    #ok(intValue);
  };

  public func getAsFloat(json : JSON, path : Types.Path) : Result.Result<Float, GetAsError> {
    let ?value = get(json, path) else return #err(#pathNotFound);
    let #Number(numberValue) = value else return #err(#typeMismatch);
    let floatValue = switch (numberValue) {
      case (#Int(intValue)) { Float.fromInt(intValue) };
      case (#Float(floatValue)) { floatValue };
    };
    #ok(floatValue);
  };

  public func getAsBool(json : JSON, path : Types.Path) : Result.Result<Bool, GetAsError> {
    let ?value = get(json, path) else return #err(#pathNotFound);
    let #Bool(boolValue) = value else return #err(#typeMismatch);
    #ok(boolValue);
  };

  public func getAsText(json : JSON, path : Types.Path) : Result.Result<Text, GetAsError> {
    let ?value = get(json, path) else return #err(#pathNotFound);
    let #String(text) = value else return #err(#typeMismatch);
    #ok(text);
  };

  public func getAsArray(json : JSON, path : Types.Path) : Result.Result<[JSON], GetAsError> {
    let ?value = get(json, path) else return #err(#pathNotFound);
    let #Array(items) = value else return #err(#typeMismatch);
    #ok(items);
  };

  public func getAsObject(json : JSON, path : Types.Path) : Result.Result<[(Text, JSON)], GetAsError> {
    let ?value = get(json, path) else return #err(#pathNotFound);
    let #Object(entries) = value else return #err(#typeMismatch);
    #ok(entries);
  };

  public func set(json : JSON, path : Types.Path, newValue : JSON) : JSON {
    let parts = Parser.parsePath(path);
    Parser.setWithParts(json, parts, newValue);
  };
  public func remove(json : JSON, path : Types.Path) : JSON {
    let parts = Parser.parsePath(path);
    Parser.removeWithParts(json, parts);
  };
  public func validate(json : JSON, schema : Types.Schema) : Result.Result<(), Types.ValidationError> {
    Parser.validate(json, schema);
  };
};
