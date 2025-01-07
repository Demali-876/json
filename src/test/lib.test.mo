
import Array "mo:base/Array";
import Bool "mo:base/Bool";
import Lexer "../Lexer";
import Parser "../Parser";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Types "../Types";
import IC "mo:base/ExperimentalInternetComputer";
import Nat64 "mo:base/Nat64";
actor {
  
      public func testLexer(input: Text) : async Result.Result<[Types.Token], Types.Error> {
        let lexer = Lexer.Lexer(input);
        return lexer.tokenize();
    };
    public func testParser(input:Text) : async Result.Result<Types.JSON, Types.Error> {
        let lexer = Lexer.Lexer(input);
        let tokens = switch (lexer.tokenize()){
          case (#ok(tokens)){tokens};
          case (#err(e)){return #err(e)};
        };
        let parser = Parser.Parser(tokens);
        parser.parse();
    };
     /*func countInstructions() :  Text {
    let cases = [
        "{",
        "true", 
        "\"hello\"",
        "123",
        "123.456",
        "-123.456e-10",
        "{\"name\":\"John\",\"age\":30}",
        "\"hello\\u0048\\u0065\\u006C\\u006C\\u006F\"",  
        "[1,2,3,null,false,true]", // Array with mixed types
        "{\"nested\":{\"array\":[1,2,3],\"null\":null}}"
    ];
    
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

    private func parseJSON(jsonText : Text) : Result.Result<Types.JSON, Types.Error> {
        let lexer = Lexer.Lexer(jsonText);
        switch (lexer.tokenize()) {
            case (#err(err)) { #err(err) };
            case (#ok(tokens)) {
                let parser = Parser.Parser(tokens);
                parser.parse()
            };
        }
    };

    public func runTests() {
        let emptyObj = parseJSON("{}");
        assert(emptyObj == #ok(#Object([])));
        logTest("Empty Object", true, null);
        
        for ((name, passed, error) in testLog.vals()) {
            Debug.print("Test: " # name # 
                       " | Passed: " # debug_show(passed) # 
                       " | Error: " # (switch (error) {
                           case (?e) e;
                           case null "None";
                       }));
        };
    };
};
