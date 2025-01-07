import Text "mo:base/Text";
import Array "mo:base/Array";
import Char "mo:base/Char";
import Int32 "mo:base/Int32";
import Float "mo:base/Float";

module{
  public type Token = {
    #BeginArray;
    #BeginObject;
    #EndArray;
    #EndObject;
    #NameSeparator;
    #ValueSeparator;
    #Whitespace;
    #False;
    #Null;
    #True;
     #Number : {
      #Int : Int;
      #Float : Float
      };
    #String: Text;
  };
  public type JSON = {
    #Object : [(Text, JSON)];
    #Array : [JSON];
    #String : Text;
    #Number : {
        #Int : Int;
        #Float : Float;
    };
    #Bool : Bool;
    #Null;
  };
  
  public type Error = {
    #InvalidString : Text;
    #InvalidNumber : Text;
    #InvalidKeyword : Text;
    #InvalidChar : Text;
    #InvalidValue : Text;
    #UnexpectedEOF;
    #UnexpectedToken :Text;
  };
  

  public func charAt(i : Nat, t : Text) : Char {
    let arr = Text.toArray(t);
      arr[i]
  };
  
  public func parseFloat(text : Text) : ?Float {
  var integer : Int = 0;
  var fraction : Float = 0;
  var exponent : Int = 0;
  var isNegative = false;
  var position = 0;
  let chars = text.chars();
  
  switch(chars.next()) {
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
    switch(chars.next()) {
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
    switch(chars.next()) {
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
  switch(chars.next()) {
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
    switch(chars.next()) {
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
  
  switch(chars.next()) {
    case (?'-') { 
      isNegative := true;
    };
    case (?d) if (Char.isDigit(d)) {
      int := Int32.toInt(Int32.fromNat32(Char.toNat32(d) - 48));
    };
    case (_) { return null };
  };
  
  label parsing loop {
    switch(chars.next()) {
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
}