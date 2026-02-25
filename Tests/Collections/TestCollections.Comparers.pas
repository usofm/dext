unit TestCollections.Comparers;

interface

uses
  System.SysUtils,
  Dext.Testing,
  Dext.Collections.Comparers;

type
  [TestFixture('Collections - Comparers')]
  TComparerTests = class
  public
    // TComparer<T>.Default tests
    [Test]
    procedure Compare_Integers_ShouldReturnCorrectOrder;
    [Test]
    procedure Compare_Strings_ShouldReturnCorrectOrder;
    [Test]
    procedure Compare_Doubles_ShouldReturnCorrectOrder;
    [Test]
    procedure Compare_Currency_ShouldReturnCorrectOrder;
    [Test]
    procedure Compare_Int64_ShouldReturnCorrectOrder;
    [Test]
    procedure Compare_Bytes_ShouldReturnCorrectOrder;
    [Test]
    procedure Compare_Boolean_ShouldReturnCorrectOrder;

    // TEqualityComparer<T>.Default tests
    [Test]
    procedure Equals_Integers_ShouldMatchCorrectly;
    [Test]
    procedure Equals_Strings_ShouldMatchCorrectly;
    [Test]
    procedure Equals_Strings_CaseSensitive;
    [Test]
    procedure Equals_Doubles_ShouldMatchCorrectly;
    [Test]
    procedure Equals_Currency_ShouldMatchCorrectly;

    // GetHashCode tests
    [Test]
    procedure HashCode_SameValue_ShouldBeEqual;
    [Test]
    procedure HashCode_DifferentValues_ShouldDiffer;
    [Test]
    procedure HashCode_Strings_ShouldBeConsistent;

    // BinaryCompare fallback
    [Test]
    procedure BinaryCompare_ShouldCompareByteByByte;

    // Edge cases
    [Test]
    procedure Compare_EqualValues_ShouldReturnZero;
    [Test]
    procedure Equals_ZeroValues_ShouldBeTrue;
  end;

implementation

{ TComparerTests }

// === TComparer<T> tests ===

procedure TComparerTests.Compare_Integers_ShouldReturnCorrectOrder;
var
  Cmp: IComparer<Integer>;
begin
  Cmp := TComparer<Integer>.Default;
  Should(Cmp.Compare(1, 2) < 0).BeTrue;
  Should(Cmp.Compare(2, 1) > 0).BeTrue;
  Should(Cmp.Compare(5, 5)).Be(0);
end;

procedure TComparerTests.Compare_Strings_ShouldReturnCorrectOrder;
var
  Cmp: IComparer<string>;
begin
  Cmp := TComparer<string>.Default;
  Should(Cmp.Compare('apple', 'banana') < 0).BeTrue;
  Should(Cmp.Compare('banana', 'apple') > 0).BeTrue;
  Should(Cmp.Compare('hello', 'hello')).Be(0);
end;

procedure TComparerTests.Compare_Doubles_ShouldReturnCorrectOrder;
var
  Cmp: IComparer<Double>;
begin
  Cmp := TComparer<Double>.Default;
  Should(Cmp.Compare(1.5, 2.5) < 0).BeTrue;
  Should(Cmp.Compare(2.5, 1.5) > 0).BeTrue;
  Should(Cmp.Compare(3.14, 3.14)).Be(0);
end;

procedure TComparerTests.Compare_Currency_ShouldReturnCorrectOrder;
var
  Cmp: IComparer<Currency>;
  A, B, C: Currency;
begin
  Cmp := TComparer<Currency>.Default;
  A := 10.50;
  B := 20.75;
  C := 10.50;
  Should(Cmp.Compare(A, B) < 0).BeTrue;
  Should(Cmp.Compare(B, A) > 0).BeTrue;
  Should(Cmp.Compare(A, C)).Be(0);
end;

procedure TComparerTests.Compare_Int64_ShouldReturnCorrectOrder;
var
  Cmp: IComparer<Int64>;
begin
  Cmp := TComparer<Int64>.Default;
  Should(Cmp.Compare(-100, 100) < 0).BeTrue;
  Should(Cmp.Compare(100, -100) > 0).BeTrue;
  Should(Cmp.Compare(Int64(MaxInt) + 1, Int64(MaxInt) + 1)).Be(0);
end;

procedure TComparerTests.Compare_Bytes_ShouldReturnCorrectOrder;
var
  Cmp: IComparer<Byte>;
begin
  Cmp := TComparer<Byte>.Default;
  Should(Cmp.Compare(0, 255) < 0).BeTrue;
  Should(Cmp.Compare(255, 0) > 0).BeTrue;
  Should(Cmp.Compare(128, 128)).Be(0);
end;

procedure TComparerTests.Compare_Boolean_ShouldReturnCorrectOrder;
var
  Cmp: IComparer<Boolean>;
begin
  Cmp := TComparer<Boolean>.Default;
  // False (0) < True (1)
  Should(Cmp.Compare(False, True) < 0).BeTrue;
  Should(Cmp.Compare(True, False) > 0).BeTrue;
  Should(Cmp.Compare(True, True)).Be(0);
end;

// === TEqualityComparer<T> tests ===

procedure TComparerTests.Equals_Integers_ShouldMatchCorrectly;
var
  Eq: IEqualityComparer<Integer>;
begin
  Eq := TEqualityComparer<Integer>.Default;
  Should(Eq.Equals(42, 42)).BeTrue;
  Should(Eq.Equals(42, 43)).BeFalse;
  Should(Eq.Equals(0, 0)).BeTrue;
end;

procedure TComparerTests.Equals_Strings_ShouldMatchCorrectly;
var
  Eq: IEqualityComparer<string>;
begin
  Eq := TEqualityComparer<string>.Default;
  Should(Eq.Equals('hello', 'hello')).BeTrue;
  Should(Eq.Equals('hello', 'world')).BeFalse;
  Should(Eq.Equals('', '')).BeTrue;
end;

procedure TComparerTests.Equals_Strings_CaseSensitive;
var
  Eq: IEqualityComparer<string>;
begin
  Eq := TEqualityComparer<string>.Default;
  Should(Eq.Equals('Hello', 'hello')).BeFalse;
  Should(Eq.Equals('ABC', 'ABC')).BeTrue;
end;

procedure TComparerTests.Equals_Doubles_ShouldMatchCorrectly;
var
  Eq: IEqualityComparer<Double>;
begin
  Eq := TEqualityComparer<Double>.Default;
  Should(Eq.Equals(3.14, 3.14)).BeTrue;
  Should(Eq.Equals(3.14, 2.71)).BeFalse;
end;

procedure TComparerTests.Equals_Currency_ShouldMatchCorrectly;
var
  Eq: IEqualityComparer<Currency>;
  A, B: Currency;
begin
  Eq := TEqualityComparer<Currency>.Default;
  A := 99.99;
  B := 99.99;
  Should(Eq.Equals(A, B)).BeTrue;
  B := 100.00;
  Should(Eq.Equals(A, B)).BeFalse;
end;

// === GetHashCode tests ===

procedure TComparerTests.HashCode_SameValue_ShouldBeEqual;
var
  Eq: IEqualityComparer<Integer>;
begin
  Eq := TEqualityComparer<Integer>.Default;
  Should(Eq.GetHashCode(42)).Be(Eq.GetHashCode(42));
end;

procedure TComparerTests.HashCode_DifferentValues_ShouldDiffer;
var
  Eq: IEqualityComparer<Integer>;
begin
  Eq := TEqualityComparer<Integer>.Default;
  // Different values should (with very high probability) have different hashes
  Should(Eq.GetHashCode(1) <> Eq.GetHashCode(2)).BeTrue;
end;

procedure TComparerTests.HashCode_Strings_ShouldBeConsistent;
var
  Eq: IEqualityComparer<string>;
  H1, H2: Integer;
begin
  Eq := TEqualityComparer<string>.Default;
  H1 := Eq.GetHashCode('test');
  H2 := Eq.GetHashCode('test');
  Should(H1).Be(H2);

  // Different strings should differ
  Should(Eq.GetHashCode('foo') <> Eq.GetHashCode('bar')).BeTrue;
end;

// === BinaryCompare tests ===

procedure TComparerTests.BinaryCompare_ShouldCompareByteByByte;
var
  A, B: array[0..3] of Byte;
begin
  A[0] := 1; A[1] := 2; A[2] := 3; A[3] := 4;
  B[0] := 1; B[1] := 2; B[2] := 3; B[3] := 4;
  Should(Dext.Collections.Comparers.BinaryCompare(@A, @B, 4)).Be(0);

  B[2] := 5; // A < B at position 2
  Should(Dext.Collections.Comparers.BinaryCompare(@A, @B, 4) < 0).BeTrue;

  B[2] := 1; // A > B at position 2
  Should(Dext.Collections.Comparers.BinaryCompare(@A, @B, 4) > 0).BeTrue;
end;

// === Edge cases ===

procedure TComparerTests.Compare_EqualValues_ShouldReturnZero;
var
  IntCmp: IComparer<Integer>;
  StrCmp: IComparer<string>;
  DblCmp: IComparer<Double>;
begin
  IntCmp := TComparer<Integer>.Default;
  StrCmp := TComparer<string>.Default;
  DblCmp := TComparer<Double>.Default;

  Should(IntCmp.Compare(0, 0)).Be(0);
  Should(StrCmp.Compare('', '')).Be(0);
  Should(DblCmp.Compare(0.0, 0.0)).Be(0);
end;

procedure TComparerTests.Equals_ZeroValues_ShouldBeTrue;
var
  IntEq: IEqualityComparer<Integer>;
  StrEq: IEqualityComparer<string>;
begin
  IntEq := TEqualityComparer<Integer>.Default;
  StrEq := TEqualityComparer<string>.Default;

  Should(IntEq.Equals(0, 0)).BeTrue;
  Should(StrEq.Equals('', '')).BeTrue;
end;

end.
