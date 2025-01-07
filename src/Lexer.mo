import Types "Types";
import Cursor "Cursor";
import Buffer "mo:base/Buffer";
import Char "mo:base/Char";
import Text "mo:base/Text";
import Nat32 "mo:base/Nat32";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
module {
  public class Lexer(text : Text) {
    let cursor = Cursor.Cursor(text);
    let tokenBuffer = Buffer.Buffer<Types.Token>(128);
   public type Error = {
    #InvalidString : Text;
    #InvalidNumber : Text;
    #InvalidKeyword : Text;
    #InvalidChar : Text;
  };

    private func tokenizeString() : Result.Result<Types.Token, Error> {
      cursor.inc();
      var strBuffer = Buffer.Buffer<Char>(64);
      var escaped = false;

      while (cursor.hasNext()) {
        let c = cursor.current();

        if (escaped) {
          escaped := false;
          switch (c) {
            case '\"' {strBuffer.add(Char.fromNat32(0x22))};
            case '\\' {strBuffer.add(Char.fromNat32(0x5C))};
            case '/' {strBuffer.add(Char.fromNat32(0x2F))};
            case 'b' {strBuffer.add(Char.fromNat32(0x08))};
            case 'f' {strBuffer.add(Char.fromNat32(0x0C))};
            case 'n' {strBuffer.add(Char.fromNat32(0x0A))};
            case 'r' {strBuffer.add(Char.fromNat32(0x0D))};
            case 't' {strBuffer.add(Char.fromNat32(0x09))};
            case 'u' {
              cursor.inc();
              if (cursor.getPos() + 4 <= text.size()) {
                let hexCode = cursor.substring(text, cursor.getPos(), (cursor.getPos() + 4));

                var validHex = true;
                var hexCount = 0;
                label isHex for (c in hexCode.chars()) {
                  if (not isHexDigit(c)) {
                    validHex := false;
                    break isHex
                  };
                  hexCount += 1
                };
                if (not validHex or hexCount != 4) {
                  return #err(#InvalidString("Invalid Unicode escape sequence: Expected exactly 4 hex digits"))
                };

                switch (Nat.fromText("0x" # hexCode)) {
                  case (?natValue) {
                    if (natValue <= 0x10FFFF) {
                      strBuffer.add(Char.fromNat32(Nat32.fromNat(natValue)));
                      cursor.advance(4)
                    } else {
                      return #err(#InvalidString("Unicode value exceeds maximum allowed (0x10FFFF)"))
                    }
                  };
                  case null {
                    return #err(#InvalidString("Invalid Unicode escape sequence: Invalid hex value"))
                  }
                }
              } else {
                return #err(#InvalidString("Incomplete Unicode escape sequence"))
              }
            };
            case _ {
              return #err(#InvalidString("Invalid escape character: \\" # Text.fromChar(c)))
            }
          }
        } else if (c == '\\') {
          escaped := true
        } else if (c == '\"') {
          cursor.inc();
          return #ok(#String(Text.fromIter(Iter.fromArray(Buffer.toArray(strBuffer)))))
        } else {
          let code = Char.toNat32(c);
          if (
            (code >= 0x20 and code <= 0x21) or
            (code >= 0x23 and code <= 0x5B) or
            (code >= 0x5D and code <= 0x10FFFF)
          ) {
            strBuffer.add(c)
          } else {
            return #err(#InvalidString("Invalid character in string: " # Text.fromChar(c)))
          }
        };
        cursor.inc()
      };

      return #err(#InvalidString("Unterminated string literal"))
    };

    private func isHexDigit(c : Char) : Bool {
      let code = Char.toNat32(c);
      (code >= 0x30 and code <= 0x39) or
      (code >= 0x41 and code <= 0x46) or
      (code >= 0x61 and code <= 0x66)
    };

    private func tokenizeNumber() : Result.Result<Types.Token, Error> {
      var numberBuffer = Buffer.Buffer<Char>(16);
      var isFloat = false;

      if (cursor.current() == '-') {
        numberBuffer.add('-');
        cursor.inc()
      };

      if (cursor.current() == '0') {
        numberBuffer.add('0');
        cursor.inc()
      } else if (Char.isDigit(cursor.current()) and cursor.current() != '0') {
        while (cursor.hasNext() and Char.isDigit(cursor.current())) {
          numberBuffer.add(cursor.current());
          cursor.inc()
        }
      } else {
        return #err(#InvalidNumber("Invalid number: Expected digit after minus sign"))
      };

      if (cursor.hasNext() and cursor.current() == '.') {
        isFloat := true;
        numberBuffer.add('.');
        cursor.inc();

        if (not Char.isDigit(cursor.current())) {
          return #err(#InvalidNumber("Invalid number: Decimal point must be followed by digits"))
        };

        while (cursor.hasNext() and Char.isDigit(cursor.current())) {
          numberBuffer.add(cursor.current());
          cursor.inc()
        }
      };

      if (cursor.hasNext() and (cursor.current() == 'e' or cursor.current() == 'E')) {
        isFloat := true;
        numberBuffer.add(cursor.current());
        cursor.inc();

        if (cursor.hasNext() and (cursor.current() == '+' or cursor.current() == '-')) {
          numberBuffer.add(cursor.current());
          cursor.inc()
        };

        if (not Char.isDigit(cursor.current())) {
          return #err(#InvalidNumber("Invalid number: Exponent must be followed by digits"))
        };

        while (cursor.hasNext() and Char.isDigit(cursor.current())) {
          numberBuffer.add(cursor.current());
          cursor.inc()
        }
      };

      let numberStr = Text.fromIter(Iter.fromArray(Buffer.toArray(numberBuffer)));

      if (isFloat) {
        switch (Types.parseFloat(numberStr)) {
          case (?num) {#ok(#Number(#Float(num)))};
          case null {#err(#InvalidNumber("Invalid floating point number format"))}
        }
      } else {
        switch (Types.parseInt(numberStr)) {
          case (?num) {#ok(#Number(#Int(num)))};
          case null {return #err(#InvalidNumber("Invalid integer number format"))}
        }
      }
    };
    private func tokenizeKeyWord() : ?Types.Token {
      if (cursor.getPos() + 4 <= text.size()) {
        let falsejson = cursor.substring(text, cursor.getPos(), (cursor.getPos() + 4));
        if (Text.equal(falsejson, "false")) {
          cursor.advance(5);
          return ? #False
        }
      };
      if (cursor.getPos() + 3 <= text.size()) {
        let nullortrue = cursor.substring(text, cursor.getPos(), (cursor.getPos() + 3));
        if (Text.equal(nullortrue, "true")) {
          cursor.advance(4);
          ? #True
        } else if (Text.equal(nullortrue, "null")) {
          cursor.advance(4);
          ? #Null
        } else {
          null
        }
      } else {
        null
      }
    };
    public func tokenize() : Result.Result<[Types.Token], Error> {
      label tokenizing while (cursor.hasNext()) {
        let c = cursor.current();

        switch (c) {
          case (' ' or '\t' or '\n' or '\r') {
            cursor.inc();
            continue tokenizing
          };
          case ('{') {
            cursor.inc();
            tokenBuffer.add(#BeginObject)
          };
          case ('}') {
            cursor.inc();
            tokenBuffer.add(#EndObject)
          };
          case ('[') {
            cursor.inc();
            tokenBuffer.add(#BeginArray)
          };
          case (']') {
            cursor.inc();
            tokenBuffer.add(#EndArray)
          };
          case (':') {
            cursor.inc();
            tokenBuffer.add(#NameSeparator)
          };
          case (',') {
            cursor.inc();
            tokenBuffer.add(#ValueSeparator)
          };

          case ('\"') {
            switch (tokenizeString()) {
              case (#ok(token)) {tokenBuffer.add(token)};
              case (#err(e)) {return #err(e)}
            }
          };

          case (c) {
            if (c == '-' or Char.isDigit(c)) {
              switch (tokenizeNumber()) {
                case (#ok(token)) { tokenBuffer.add(token) };
                case (#err(e)) { return #err(e) };
              };
            } else if (c == 'f' or c == 'n' or c == 't') {
              switch (tokenizeKeyWord()) {
                case (?token) { tokenBuffer.add(token) };
                case null {
                  return #err(#InvalidKeyword("Invalid keyword starting with '" # Text.fromChar(c) # "'"));
                };
              };
            } else {
              return #err(#InvalidChar("Unexpected character: " # Text.fromChar(c)));
            };
          };
        }
      };

      #ok(Buffer.toArray(tokenBuffer))
    }
  }
}