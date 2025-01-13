import Types "./Types";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Nat "mo:base/Nat";

module {
  type JSON = Types.JSON;
  public class Parser(tokens : [Types.Token]) {
    var position = 0;

    private func current() : ?Types.Token {
      if (position < tokens.size()) ?tokens[position] else null
    };
    
    private func advance() {
      position += 1
    };

    public func parse() : Result.Result<Types.JSON, Types.Error> {
      switch (parseValue()) {
        case (#ok(json)) {
          switch (current()) {
            case (null) {#ok(json)};
            case (?_) {#err(#UnexpectedToken("Expected end of input"))}
          }
        };
        case (#err(e)) {#err(e)}
      }
    };

    private func parseValue() : Result.Result<Types.JSON, Types.Error> {
      switch (current()) {
        case (null) {#err(#UnexpectedEOF)};
        case (?token) {
          switch (token) {
            case (#BeginObject) {parseObject()};
            case (#BeginArray) {parseArray()};
            case (#String(s)) {advance(); #ok(#String(s))};
            case (#Number(n)) {advance(); #ok(#Number(n))};
            case (#True) {advance(); #ok(#Bool(true))};
            case (#False) {advance(); #ok(#Bool(false))};
            case (#Null) {advance(); #ok(#Null)};
            case (_) {#err(#UnexpectedToken("Expected value"))}
          }
        }
      }
    };

    private func parseObject() : Result.Result<Types.JSON, Types.Error> {
      advance();
      var fields : [(Text, Types.JSON)] = [];

      switch (current()) {
        case (? #EndObject) {
          advance();
          #ok(#Object(fields))
        };
        case (? #String(_)) {
          switch (parseMember()) {
            case (#err(e)) {#err(e)};
            case (#ok(field)) {
              fields := [(field.0, field.1)];
              loop {
                switch (current()) {
                  case (? #ValueSeparator) {
                    advance();
                    switch (parseMember()) {
                      case (#ok(next)) {
                        fields := Array.append(fields, [(next.0, next.1)])
                      };
                      case (#err(e)) {return #err(e)}
                    }
                  };
                  case (? #EndObject) {
                    advance();
                    return #ok(#Object(fields))
                  };
                  case (null) {return #err(#UnexpectedEOF)};
                  case (_) {
                    return #err(#UnexpectedToken("Expected ',' or '}'"))
                  }
                }
              }
            }
          }
        };
        case (null) {#err(#UnexpectedEOF)};
        case (_) {#err(#UnexpectedToken("Expected string or '}'"))}
      }
    };

    private func parseMember() : Result.Result<(Text, Types.JSON), Types.Error> {
      switch (current()) {
        case (? #String(key)) {
          advance();
          switch (current()) {
            case (? #NameSeparator) {
              advance();
              switch (parseValue()) {
                case (#ok(value)) {#ok((key, value))};
                case (#err(e)) {#err(e)}
              }
            };
            case (null) {#err(#UnexpectedEOF)};
            case (_) {#err(#UnexpectedToken("Expected ':'"))}
          }
        };
        case (null) {#err(#UnexpectedEOF)};
        case (_) {#err(#UnexpectedToken("Expected string"))}
      }
    };

    private func parseArray() : Result.Result<Types.JSON, Types.Error> {
      advance();
      var elements : [Types.JSON] = [];

      switch (current()) {
        case (? #EndArray) {
          advance();
          #ok(#Array(elements))
        };
        case (null) {
          #err(#UnexpectedEOF)
        };
        case (_) {
          switch (parseValue()) {
            case (#err(e)) {#err(e)};
            case (#ok(value)) {
              elements := [value];
              loop {
                switch (current()) {
                  case (? #ValueSeparator) {
                    advance();
                    switch (parseValue()) {
                      case (#ok(next)) {
                        elements := Array.append(elements, [next])
                      };
                      case (#err(e)) {return #err(e)}
                    }
                  };
                  case (? #EndArray) {
                    advance();
                    return #ok(#Array(elements))
                  };
                  case (null) {return #err(#UnexpectedEOF)};
                  case (_) {
                    return #err(#UnexpectedToken("Expected ',' or ']'"))
                  }
                }
              }
            }
          }
        }
      }
    }
  };

  public func parsePath(path : Text) : [Types.PathPart] {
    let chars = path.chars();
    let parts = Buffer.Buffer<Types.PathPart>(8);
    var current = Buffer.Buffer<Char>(16);
    var inBracket = false;

    for (c in chars) {
      switch (c) {
        case '[' {
          if (current.size() > 0) {
            parts.add(#Key(Text.fromIter(current.vals())));
            current.clear()
          };
          inBracket := true
        };
        case ']' {
          if (current.size() > 0) {
            let indexText = Text.fromIter(current.vals());
            if (indexText == "*") {
              parts.add(#Wildcard)
            } else {
              switch (Nat.fromText(indexText)) {
                case (?idx) {parts.add(#Index(idx))};
                case null {}
              }
            };
            current.clear()
          };
          inBracket := false
        };
        case '.' {
          if (current.size() > 0) {
            let key = Text.fromIter(current.vals());
            if (key == "*") {
              parts.add(#Wildcard)
            } else {
              parts.add(#Key(key))
            };
            current.clear()
          }
        };
        case c {current.add(c)}
      }
    };
    if (current.size() > 0) {
      let final = Text.fromIter(current.vals());
      if (final == "*") {
        parts.add(#Wildcard)
      } else {
        parts.add(#Key(final))
      }
    };

    Buffer.toArray(parts)
  };

  public func getWithParts(json : JSON, parts : [Types.PathPart]) : ?JSON {
    if (parts.size() == 0) {return ?json};

    switch (parts[0], json) {
      case (#Key(key), #Object(entries)) {
        for ((k, v) in entries.vals()) {
          if (k == key) {
            return getWithParts(
              v,
              Array.tabulate<Types.PathPart>(
                parts.size() - 1,
                func(i) = parts[i + 1]
              )
            )
          }
        };
        null
      };
      case (#Index(i), #Array(items)) {
        if (i < items.size()) {
          getWithParts(
            items[i],
            Array.tabulate<Types.PathPart>(
              parts.size() - 1,
              func(i) = parts[i + 1]
            )
          )
        } else {
          null
        }
      };
      case (#Wildcard, #Object(entries)) {
        ? #Array(
          Array.mapFilter<(Text, JSON), JSON>(
            entries,
            func((_, v)) = getWithParts(
              v,
              Array.tabulate<Types.PathPart>(
                parts.size() - 1,
                func(i) = parts[i + 1]
              )
            )
          )
        )
      };
      case (#Wildcard, #Array(items)) {
        ? #Array(
          Array.mapFilter<JSON, JSON>(
            items,
            func(item) = getWithParts(
              item,
              Array.tabulate<Types.PathPart>(
                parts.size() - 1,
                func(i) = parts[i + 1]
              )
            )
          )
        )
      };
      case _ {null}
    }
  };

  public func setWithParts(json : JSON, parts : [Types.PathPart], newValue : JSON) : JSON {
    if (parts.size() == 0) {
      return newValue
    };

    switch (parts[0], json) {
      case (#Key(key), #Object(entries)) {
        let remaining = Array.tabulate<Types.PathPart>(
          parts.size() - 1,
          func(i) = parts[i + 1]
        );

        var found = false;
        let newEntries = Array.map<(Text, JSON), (Text, JSON)>(
          entries,
          func((k, v) : (Text, JSON)) : (Text, JSON) {
            if (k == key) {
              found := true;
              (k, setWithParts(v, remaining, newValue))
            } else {(k, v)}
          }
        );

        if (not found) {
          #Object(Array.append(newEntries, [(key, setWithParts(#Null, remaining, newValue))]))
        } else {
          #Object(newEntries)
        }
      };

      case (#Index(i), #Array(items)) {
        let remaining = Array.tabulate<Types.PathPart>(
          parts.size() - 1,
          func(i) = parts[i + 1]
        );

        if (i < items.size()) {
          #Array(
            Array.tabulate<JSON>(
              items.size(),
              func(idx : Nat) : JSON {
                if (idx == i) {
                  setWithParts(items[idx], remaining, newValue)
                } else {
                  items[idx]
                }
              }
            )
          )
        } else {
          let nulls = Array.tabulate<JSON>(
            i - items.size(),
            func(_) = #Null
          );
          #Array(
            Array.append(
              Array.append(items, nulls),
              [setWithParts(#Null, remaining, newValue)]
            )
          )
        }
      };

      case (#Key(key), _) {
        let remaining = Array.tabulate<Types.PathPart>(
          parts.size() - 1,
          func(i) = parts[i + 1]
        );
        #Object([(key, setWithParts(#Null, remaining, newValue))])
      };

      case (#Index(i), _) {
        let remaining = Array.tabulate<Types.PathPart>(
          parts.size() - 1,
          func(i) = parts[i + 1]
        );
        let items = Array.tabulate<JSON>(
          i + 1,
          func(idx : Nat) : JSON {
            if (idx == i) {
              setWithParts(#Null, remaining, newValue)
            } else {
              #Null
            }
          }
        );
        #Array(items)
      };

      case _ {json}
    }
  };

  public func removeWithParts(json : JSON, parts : [Types.PathPart]) : JSON {
    if (parts.size() == 0) {
      return #Null
    };

    switch (parts[0], json) {
      case (#Key(key), #Object(entries)) {
        if (parts.size() == 1) {
          #Object(
            Array.filter<(Text, JSON)>(
              entries,
              func((k, _) : (Text, JSON)) : Bool {k != key}
            )
          )
        } else {
          let remaining = Array.tabulate<Types.PathPart>(
            parts.size() - 1,
            func(i) = parts[i + 1]
          );

          #Object(
            Array.map<(Text, JSON), (Text, JSON)>(
              entries,
              func((k, v) : (Text, JSON)) : (Text, JSON) {
                if (k == key) {(k, removeWithParts(v, remaining))} else {(k, v)}
              }
            )
          )
        }
      };

      case (#Index(i), #Array(items)) {
        if (i >= items.size()) {
          return json
        };

        if (parts.size() == 1) {
          #Array(
            Array.tabulate<JSON>(
              items.size() - 1,
              func(idx : Nat) : JSON {
                if (idx < i) {
                  items[idx]
                } else {
                  items[idx + 1]
                }
              }
            )
          )
        } else {
          let remaining = Array.tabulate<Types.PathPart>(
            parts.size() - 1,
            func(i) = parts[i + 1]
          );

          #Array(
            Array.tabulate<JSON>(
              items.size(),
              func(idx : Nat) : JSON {
                if (idx == i) {
                  removeWithParts(items[idx], remaining)
                } else {
                  items[idx]
                }
              }
            )
          )
        }
      };
      case _ {json}
    }
  };

public func validate(instance : JSON, schema : Types.Schema) : Result.Result<(), Types.ValidationError> {
  switch(schema) {
    case (#Object{properties; required}) {
      switch(instance) {
        case (#Object(entries)) {
          switch(required) {
            case (?requiredFields) {
              for (requiredKey in requiredFields.vals()) {
                var found = false;
                label checking for ((key, _) in entries.vals()) {
                  if (key == requiredKey) {
                    found := true;
                    break checking;
                  };
                };
                if (not found) {
                  return #err(#RequiredField(requiredKey));
                };
              };
            };
            case null {};
          };
          for ((schemaKey, schemaType) in properties.vals()) {
            for ((key, value) in entries.vals()) {
              if (key == schemaKey) {
                switch(validate(value, schemaType)) {
                  case (#err(e)) return #err(e);
                  case (#ok()) {};
                };
              };
            };
          };
          #ok();
        };
        case (_) {
          #err(#TypeError{
            expected = "object";
            got = Types.getTypeString(instance);
            path = "";
          });
        };
      };
    };
    case (#Array{items}) {
      switch(instance) {
        case (#Array(values)) {
          for (value in values.vals()) {
            switch(validate(value, items)) {
              case (#err(e)) return #err(e);
              case (#ok()) {};
            };
          };
          #ok();
        };
        case (_) {
          #err(#TypeError{
            expected = "array";
            got = Types.getTypeString(instance);
            path = "";
          });
        };
      };
    };
    case (#String) {
      switch(instance) {
        case (#String(_)) #ok();
        case (_) {
          #err(#TypeError{
            expected = "string";
            got = Types.getTypeString(instance);
            path = "";
          });
        };
      };
    };
    case (#Number) {
      switch(instance) {
        case (#Number(_)) #ok();
        case (_) {
          #err(#TypeError{
            expected = "number";
            got = Types.getTypeString(instance);
            path = "";
          });
        };
      };
    };
    case (#Boolean) {
      switch(instance) {
        case (#Bool(_)) #ok();
        case (_) {
          #err(#TypeError{
            expected = "boolean";
            got = Types.getTypeString(instance);
            path = "";
          });
        };
      };
    };
    case (#Null) {
      switch(instance) {
        case (#Null) #ok();
        case (_) {
          #err(#TypeError{
            expected = "null";
            got = Types.getTypeString(instance);
            path = "";
          });
        };
      };
    };
  };
};
}