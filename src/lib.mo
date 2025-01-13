import Lexer "Lexer";
import Parser "Parser";
import Types "Types";
import Result "mo:base/Result";
import Text "mo:base/Text";
module JSON {
  public type JSON = Types.JSON;
  public type Replacer = {
    #Function : (Text, JSON) -> ?JSON;
    #Keys : [Text]
  };
  //JSON Type constructors
  public func str(text : Text) : JSON = #String(text);
  public func int(n : Int) : JSON = #Number(#Int(n));
  public func float(n : Float) : JSON = #Number(#Float(n));
  public func bool(b : Bool) : JSON = #Bool(b);
  public func nullable() : JSON = #Null;
  public func obj(entries: [(Text, JSON)]) : JSON = #Object(entries);
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
    required : ?[Text]
  ) : Types.Schema = #Object({
    properties;
    required;
  });

  public func parse(input : Text) : Result.Result<Types.JSON, Types.Error> {
    let lexer = Lexer.Lexer(input);
    let tokens = switch (lexer.tokenize()) {
      case (#ok(tokens)) {tokens};
      case (#err(e)) {return #err(e)}
    };
    let parser = Parser.Parser(tokens);
    parser.parse()
  };

  public func stringify(json : JSON, replacer : ?Replacer) : Text {
    switch (replacer) {
      case (null) {
        Types.toText(json)
      };
      case (? #Function(fn)) {
        Types.toText(Types.transform(json, fn, ""))
      };
      case (? #Keys(allowedKeys)) {
        Types.toText(Types.filterByKeys(json, allowedKeys))
      }
    }
  };
  public func get(json : JSON, path : Types.Path) : ?JSON {
    let parts = Parser.parsePath(path);
    Parser.getWithParts(json, parts)
  };
  public func set(json : JSON, path : Types.Path, newValue : JSON) : JSON {
    let parts = Parser.parsePath(path);
    Parser.setWithParts(json, parts, newValue)
  };
  public func remove(json : JSON, path : Types.Path) : JSON {
    let parts = Parser.parsePath(path);
    Parser.removeWithParts(json, parts)
  };
  public func validate(json : JSON, schema : Types.Schema): Result.Result<(), Types.ValidationError> {
    Parser.validate(json, schema)
  };
}