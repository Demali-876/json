import Array "mo:base/Array";
import Bool "mo:base/Bool";
import Lexer "../Lexer";
import Parser "../Parser";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Types "../Types";
import Json "../lib";
import { str; int; float; bool; nullable; obj; arr } "../lib";
import IC "mo:base/ExperimentalInternetComputer";
import Nat64 "mo:base/Nat64";
actor {

  public func testLexer(input : Text) : async Result.Result<[Types.Token], Types.Error> {
    let lexer = Lexer.Lexer(input);
    return lexer.tokenize();
  };
  public func testParser(input : Text) : async Result.Result<Types.Json, Types.Error> {
    let lexer = Lexer.Lexer(input);
    let tokens = switch (lexer.tokenize()) {
      case (#ok(tokens)) { tokens };
      case (#err(e)) { return #err(e) };
    };
    let parser = Parser.Parser(tokens);
    parser.parse();
  };
  /*func countInstructions() :  Text {


    var output = "Instruction counts:\n\n";
    var totalCount : Nat64 = 0;

    for (testCase in cases.vals()) {
        let count = IC.countInstructions(func() {
            ignore testLexer(testCase);
        });
        totalCount += count;
        output #= "Input: " # testCase # "\nCount: " # Nat64.toText(count) # "\n\n";
    };

    output #= "Total instructions: " # Nat64.toText(totalCount);
    output
  };*/
  var testLog : [(Text, Bool, ?Text)] = [];

  private func logTest(name : Text, passed : Bool, error : ?Text) {
    testLog := Array.append(testLog, [(name, passed, error)]);
  };

  private func parseJson(jsonText : Text) : Result.Result<Types.Json, Types.Error> {
    let lexer = Lexer.Lexer(jsonText);
    switch (lexer.tokenize()) {
      case (#err(err)) { #err(err) };
      case (#ok(tokens)) {
        let parser = Parser.Parser(tokens);
        parser.parse();
      };
    };
  };

  public func runTests() {
    let emptyObj = parseJson("{}");
    assert (emptyObj == #ok(obj([])));
    logTest("Empty Object", true, null);

    for ((name, passed, error) in testLog.vals()) {
      Debug.print(
        "Test: " # name #
        " | Passed: " # debug_show (passed) #
        " | Error: " # (
          switch (error) {
            case (?e) e;
            case null "None";
          }
        )
      );
    };
  };

  public func fulltest() : async () {
    let jsonText = "{ \"users\": [ { \"id\": 1, \"name\": \"Alice\", \"email\": \"alice@example.com\", \"orders\": [ { \"orderId\": \"A123\", \"items\": [ {\"product\": \"Laptop\", \"price\": 999.99}, {\"product\": \"Mouse\", \"price\": 24.99} ] } ] }, { \"id\": 2, \"name\": \"Bob\", \"email\": \"bob@example.com\", \"orders\": [] } ], \"metadata\": { \"lastUpdated\": \"2024-01-10\" } }";

    switch (Json.parse(jsonText)) {
      case (#err(e)) {
        Debug.print("Parse error: " # debug_show (e));
      };
      case (#ok(data)) {
        let aliceEmail = Json.get(data, "users[0].email");
        Debug.print(debug_show (aliceEmail));

        let laptopPrice = Json.get(data, "users[0].orders[0].items[0].price");
        Debug.print(debug_show (laptopPrice));

        let withPhones = Json.set(data, "users[0].phone", str("+1234567890"));

        let newItem = obj([
          ("product", str("Headphones")),
          ("price", float(79.99)),
        ]);
        let withNewItem = Json.set(withPhones, "users[0].orders[0].items[2]", newItem);

        let withoutEmails = Json.remove(withNewItem, "users[0].email");

        let finalJson = Json.stringify(withoutEmails, null);
        Debug.print("Final Json: " # finalJson);
      };
    };
  };
};
