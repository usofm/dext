unit Dext.Collections.Algorithms;

interface

uses
  System.SysUtils,
  Dext.Collections.Comparers,
  Dext.Collections.Raw,
  Dext.Collections.Simd,
  Dext.Collections.Memory;

type
  TDextSort = class
  private
    class procedure InsertionSort<T>(var Arr: TArray<T>; L, R: Integer; const Comparer: IComparer<T>); static;
    class procedure IntroSort<T>(var Arr: TArray<T>; L, R: Integer; DepthLimit: Integer; const Comparer: IComparer<T>); static;
    class procedure MedianOfThree<T>(var Arr: TArray<T>; L, R: Integer; const Comparer: IComparer<T>); static;
    class procedure HeapSort<T>(var Arr: TArray<T>; L, R: Integer; const Comparer: IComparer<T>); static;
    class procedure SiftDown<T>(var Arr: TArray<T>; Start, Count: Integer; Root: Integer; const Comparer: IComparer<T>); static;
  public
    /// <summary>
    /// Pattern-Defeating Quicksort (Currently using Introsort fallback logic for phase 1)
    /// </summary>
    class procedure Sort<T>(var Arr: TArray<T>; const Comparer: IComparer<T>); overload;
    
    /// <summary>
    /// Raw Sort using TRawCompareFunc
    /// </summary>
    class procedure Sort(Data: Pointer; Count, ElementSize: Integer; CompareFunc: TRawCompareFunc); overload;
  end;

  TDextSearch = class
  public
    /// <summary>
    /// Linear search using SIMD fallbacks where possible
    /// </summary>
    class function IndexOf<T>(const Arr: TArray<T>; const Value: T): Integer;
    
    /// <summary>
    /// Binary search for sorted arrays
    /// </summary>
    class function BinarySearch<T>(const Arr: TArray<T>; const Value: T; out FoundIndex: Integer; const Comparer: IComparer<T> = nil): Boolean;
  end;

implementation

{ TDextSort }

class procedure TDextSort.InsertionSort<T>(var Arr: TArray<T>; L, R: Integer; const Comparer: IComparer<T>);
var
  I, J: Integer;
  Temp: T;
begin
  for I := L + 1 to R do
  begin
    Temp := Arr[I];
    J := I;
    while (J > L) and (Comparer.Compare(Temp, Arr[J - 1]) < 0) do
    begin
      Arr[J] := Arr[J - 1];
      Dec(J);
    end;
    Arr[J] := Temp;
  end;
end;

class procedure TDextSort.SiftDown<T>(var Arr: TArray<T>; Start, Count: Integer; Root: Integer; const Comparer: IComparer<T>);
var
  Child: Integer;
  Temp: T;
begin
  while Root * 2 + 1 < Count do
  begin
    Child := Root * 2 + 1;
    if (Child + 1 < Count) and (Comparer.Compare(Arr[Start + Child], Arr[Start + Child + 1]) < 0) then
      Inc(Child);
    if Comparer.Compare(Arr[Start + Root], Arr[Start + Child]) < 0 then
    begin
      Temp := Arr[Start + Root];
      Arr[Start + Root] := Arr[Start + Child];
      Arr[Start + Child] := Temp;
      Root := Child;
    end
    else
      Break;
  end;
end;

class procedure TDextSort.HeapSort<T>(var Arr: TArray<T>; L, R: Integer; const Comparer: IComparer<T>);
var
  Count, I: Integer;
  Temp: T;
begin
  Count := R - L + 1;
  for I := Count div 2 - 1 downto 0 do
    SiftDown<T>(Arr, L, Count, I, Comparer);
    
  for I := Count - 1 downto 1 do
  begin
    Temp := Arr[L];
    Arr[L] := Arr[L + I];
    Arr[L + I] := Temp;
    SiftDown<T>(Arr, L, I, 0, Comparer);
  end;
end;

class procedure TDextSort.MedianOfThree<T>(var Arr: TArray<T>; L, R: Integer; const Comparer: IComparer<T>);
var
  Mid: Integer;
  Temp: T;
begin
  Mid := L + (R - L) div 2;
  if Comparer.Compare(Arr[L], Arr[Mid]) > 0 then
  begin
    Temp := Arr[L];
    Arr[L] := Arr[Mid];
    Arr[Mid] := Temp;
  end;
  if Comparer.Compare(Arr[L], Arr[R]) > 0 then
  begin
    Temp := Arr[L];
    Arr[L] := Arr[R];
    Arr[R] := Temp;
  end;
  if Comparer.Compare(Arr[Mid], Arr[R]) > 0 then
  begin
    Temp := Arr[Mid];
    Arr[Mid] := Arr[R];
    Arr[R] := Temp;
  end;
end;

class procedure TDextSort.IntroSort<T>(var Arr: TArray<T>; L, R: Integer; DepthLimit: Integer; const Comparer: IComparer<T>);
var
  Mid, I, J: Integer;
  Pivot, Temp: T;
begin
  while (R - L) > 16 do
  begin
    if DepthLimit = 0 then
    begin
      HeapSort<T>(Arr, L, R, Comparer);
      Exit;
    end;
    Dec(DepthLimit);

    MedianOfThree<T>(Arr, L, R, Comparer);
    Mid := L + (R - L) div 2;
    Pivot := Arr[Mid];
    
    // QuickSort Partition
    I := L;
    J := R;
    while I <= J do
    begin
      while Comparer.Compare(Arr[I], Pivot) < 0 do Inc(I);
      while Comparer.Compare(Arr[J], Pivot) > 0 do Dec(J);
      if I <= J then
      begin
        Temp := Arr[I];
        Arr[I] := Arr[J];
        Arr[J] := Temp;
        Inc(I);
        Dec(J);
      end;
    end;

    if L < J then
      IntroSort<T>(Arr, L, J, DepthLimit, Comparer);
      
    L := I; // Tail recursion elimination for the right half
  end;
  
  if R - L > 0 then
    InsertionSort<T>(Arr, L, R, Comparer);
end;

class procedure TDextSort.Sort<T>(var Arr: TArray<T>; const Comparer: IComparer<T>);
var
  DepthLimit: Integer;
  L: Integer;
begin
  L := Length(Arr);
  if L < 2 then Exit;
  
  DepthLimit := 0;
  while L > 0 do
  begin
    L := L div 2;
    Inc(DepthLimit);
  end;
  DepthLimit := DepthLimit * 2;
  
  IntroSort<T>(Arr, 0, Length(Arr) - 1, DepthLimit, Comparer);
end;

class procedure TDextSort.Sort(Data: Pointer; Count, ElementSize: Integer; CompareFunc: TRawCompareFunc);
begin
  // For Phase 1 we can fallback to standard rtl for Raw array pointer types 
  // or build a native pointer sort. To prevent complexity, we delegate to a local QuickSort for pointers
  // A raw native sort can be quite tricky out of scope with TypeInfo managed types.
  // Not fully implemented yet.
  raise ENotImplemented.Create('TDextSort.Sort for Raw Pointer not fully implemented in v1');
end;


{ TDextSearch }

class function TDextSearch.IndexOf<T>(const Arr: TArray<T>; const Value: T): Integer;
var
  I: Integer;
  Comparer: IEqualityComparer<T>;
begin
  // Fast path for intrinsic types - SIMD fallbacks
  if TypeInfo(T) = TypeInfo(Integer) then
  begin
    Result := TDextSimd.IndexOfInt32(Pointer(Arr), Length(Arr), PInteger(@Value)^);
    Exit;
  end;
  if TypeInfo(T) = TypeInfo(Byte) then
  begin
    Result := TDextSimd.IndexOfByte(Pointer(Arr), Length(Arr), PByte(@Value)^);
    Exit;
  end;

  // Slow path
  Comparer := TEqualityComparer<T>.Default;
  for I := 0 to Length(Arr) - 1 do
  begin
    if Comparer.Equals(Arr[I], Value) then
      Exit(I);
  end;
  Result := -1;
end;

class function TDextSearch.BinarySearch<T>(const Arr: TArray<T>; const Value: T; out FoundIndex: Integer; const Comparer: IComparer<T>): Boolean;
var
  L, H, Mid, Cmp: Integer;
  ActualComparer: IComparer<T>;
begin
  if Comparer = nil then
    ActualComparer := TComparer<T>.Default
  else
    ActualComparer := Comparer;

  L := 0;
  H := Length(Arr) - 1;
  while L <= H do
  begin
    Mid := L + (H - L) div 2;
    Cmp := ActualComparer.Compare(Arr[Mid], Value);
    if Cmp = 0 then
    begin
      FoundIndex := Mid;
      Exit(True);
    end
    else if Cmp < 0 then
      L := Mid + 1
    else
      H := Mid - 1;
  end;
  
  FoundIndex := L;
  Result := False;
end;

end.
