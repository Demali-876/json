import Types "./Types";
import Result "mo:base/Result";
import Array "mo:base/Array";

module {
  public class Parser(tokens : [Types.Token]) {
    var position = 0;

    private func current() : ?Types.Token {
      if (position < tokens.size()) ?tokens[position] else null
    };

    private func advance() {
      position += 1;
    };

    public func parse() : Result.Result<Types.JSON, Types.Error> {
      switch(parseValue()) {
        case (#ok(json)) {
          switch(current()) {
            case (null) { #ok(json) };
            case (?_) { #err(#UnexpectedToken("Expected end of input")) };
          };
        };
        case (#err(e)) { #err(e) };
      };
    };

    private func parseValue() : Result.Result<Types.JSON, Types.Error> {
      switch(current()) {
        case (null) { #err(#UnexpectedEOF) };
        case (?token) {
          switch(token) {
            case (#BeginObject) { parseObject() };
            case (#BeginArray) { parseArray() };
            case (#String(s)) { advance(); #ok(#String(s)) };
            case (#Number(n)) { advance(); #ok(#Number(n)) };
            case (#True) { advance(); #ok(#Bool(true)) };
            case (#False) { advance(); #ok(#Bool(false)) };
            case (#Null) { advance(); #ok(#Null) };
            case (_) { #err(#UnexpectedToken("Expected value")) };
          };
        };
      };
    };

    private func parseObject() : Result.Result<Types.JSON, Types.Error> {
      advance();
      var fields : [(Text, Types.JSON)] = [];
      
      switch(current()) {
        case (?#EndObject) { 
          advance(); 
          #ok(#Object(fields)) 
        };
        case (?#String(_)) {
          switch(parseMember()) {
            case (#err(e)) { #err(e) };
            case (#ok(field)) {
              fields := [(field.0, field.1)];
              loop {
                switch(current()) {
                  case (?#ValueSeparator) {
                    advance();
                    switch(parseMember()) {
                      case (#ok(next)) {
                        fields := Array.append(fields, [(next.0, next.1)]);
                      };
                      case (#err(e)) { return #err(e) };
                    };
                  };
                  case (?#EndObject) {
                    advance();
                    return #ok(#Object(fields));
                  };
                  case (null) { return #err(#UnexpectedEOF) };
                  case (_) { return #err(#UnexpectedToken("Expected ',' or '}'")) };
                };
              };
            };
          };
        };
        case (null) { #err(#UnexpectedEOF) };
        case (_) { #err(#UnexpectedToken("Expected string or '}'")) };
      };
    };

    private func parseMember() : Result.Result<(Text, Types.JSON), Types.Error> {
      switch(current()) {
        case (?#String(key)) {
          advance();
          switch(current()) {
            case (?#NameSeparator) {
              advance();
              switch(parseValue()) {
                case (#ok(value)) { #ok((key, value)) };
                case (#err(e)) { #err(e) };
              };
            };
            case (null) { #err(#UnexpectedEOF) };
            case (_) { #err(#UnexpectedToken("Expected ':'")) };
          };
        };
        case (null) { #err(#UnexpectedEOF) };
        case (_) { #err(#UnexpectedToken("Expected string")) };
      };
    };

    private func parseArray() : Result.Result<Types.JSON, Types.Error> {
  advance();
  var elements : [Types.JSON] = [];
  
  switch(current()) {
    case (?#EndArray) { 
      advance(); 
      #ok(#Array(elements)) 
    };
    case (null) { 
      #err(#UnexpectedEOF) 
    };
    case (_) {
      switch(parseValue()) {
        case (#err(e)) { #err(e) };
        case (#ok(value)) {
          elements := [value];
          loop {
            switch(current()) {
              case (?#ValueSeparator) {
                advance();
                switch(parseValue()) {
                  case (#ok(next)) {
                    elements := Array.append(elements, [next]);
                  };
                  case (#err(e)) { return #err(e) };
                };
              };
              case (?#EndArray) {
                advance();
                return #ok(#Array(elements));
              };
              case (null) { return #err(#UnexpectedEOF) };
              case (_) { return #err(#UnexpectedToken("Expected ',' or ']'")) };
            };
          };
        };
      };
    };
  };
};
  };
};