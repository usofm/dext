{***************************************************************************}
{                                                                           }
{           Dext Framework                                                  }
{                                                                           }
{           Copyright (c) 2024 Dext Framework                               }
{                                                                           }
{           https://github.com/dext-framework/dext                          }
{                                                                           }
{***************************************************************************}

unit Dext.Collections.Queue;

interface

uses
  System.SysUtils,
  System.TypInfo,
  Dext.Collections.Base,
  Dext.Collections.Memory,
  Dext.Collections;

type
  /// <summary>High-performance record-based enumerator for TQueue<T></summary>
  TQueueRecordEnumerator<T> = record
  private
    FData: PByte;
    FHead: Integer;
    FCapacity: Integer;
    FCount: Integer;
    FIndex: Integer;
    FElementSize: Integer;
    FTypeInfo: PTypeInfo;
  public
    constructor Create(AData: PByte; AHead, ACapacity, ACount, AElementSize: Integer; ATypeInfo: PTypeInfo);
    function MoveNext: Boolean; inline;
    function GetCurrent: T; inline;
    property Current: T read GetCurrent;
  end;

  /// <summary>Base class avoiding Delphi explicit interface method mapping bug</summary>
  TQueueBase<T> = class(TInterfacedObject, IEnumerable<T>)
  public
    function GetInterfaceEnumerator: IEnumerator<T>; virtual; abstract;
    function GetEnumerator: IEnumerator<T>;
  end;


  /// <summary>Queue implementation using a circular buffer for O(1) ops</summary>
  TQueue<T> = class(TQueueBase<T>, IQueue<T>)
  private
    FData: PByte;
    FCount: Integer;
    FCapacity: Integer;
    FHead: Integer;
    FTail: Integer;
    FElementSize: Integer;
    FTypeInfo: PTypeInfo;
    FIsManaged: Boolean;

    procedure SetCapacity(ACapacity: Integer);
    procedure Grow;
    function GetCount: Integer; inline;
  public
    function GetInterfaceEnumerator: IEnumerator<T>; override;

    constructor Create;
    destructor Destroy; override;

    procedure Enqueue(const Value: T); inline;
    function Dequeue: T; inline;
    function Peek: T; inline;
    function TryDequeue(out Value: T): Boolean; inline;
    function TryPeek(out Value: T): Boolean; inline;
    procedure Clear; inline;
    function Contains(const Value: T): Boolean;
    function ToArray: TArray<T>;

    function GetEnumerator: TQueueRecordEnumerator<T>; reintroduce; inline;
    
    property Count: Integer read GetCount;
  end;

  /// <summary>FIFO enumerator for circular buffer (Class-based for interface compatibility)</summary>
  TQueueEnumerator<T> = class(TInterfacedObject, IEnumerator<T>)
  private
    FData: PByte;
    FHead: Integer;
    FCapacity: Integer;
    FCount: Integer;
    FIndex: Integer;
    FElementSize: Integer;
    FTypeInfo: PTypeInfo;
  public
    constructor Create(AData: PByte; AHead, ACapacity, ACount, AElementSize: Integer; ATypeInfo: PTypeInfo);
    function GetCurrent: T;
    function MoveNext: Boolean;
    procedure Reset;
    property Current: T read GetCurrent;
  end;

implementation

const
  INITIAL_CAPACITY = 4;

{ TQueueBase<T> }

function TQueueBase<T>.GetEnumerator: IEnumerator<T>;
begin
  Result := GetInterfaceEnumerator;
end;

{ TQueue<T> }

constructor TQueue<T>.Create;
begin
  inherited Create;
  FElementSize := SizeOf(T);
  FTypeInfo := TypeInfo(T);
  FIsManaged := IsManagedType(FTypeInfo);
  FData := nil;
  FCount := 0;
  FCapacity := 0;
  FHead := 0;
  FTail := 0;
end;

destructor TQueue<T>.Destroy;
begin
  Clear;
  if FData <> nil then
    FreeMem(FData);
  inherited;
end;

procedure TQueue<T>.Clear;
var
  I, Idx: Integer;
begin
  if (FCount > 0) and FIsManaged then
  begin
    for I := 0 to FCount - 1 do
    begin
      Idx := (FHead + I) mod FCapacity;
      RawFinalizeElement(FData + (Idx * FElementSize), FElementSize, FTypeInfo);
    end;
  end;
  
  if FCapacity > 0 then
    FillChar(FData^, FCapacity * FElementSize, 0);
    
  FCount := 0;
  FHead := 0;
  FTail := 0;
end;

function TQueue<T>.Contains(const Value: T): Boolean;
var
  I, Idx: Integer;
begin
  for I := 0 to FCount - 1 do
  begin
    Idx := (FHead + I) mod FCapacity;
    if CompareMem(FData + (Idx * FElementSize), @Value, FElementSize) then
      Exit(True);
  end;
  Result := False;
end;

function TQueue<T>.Dequeue: T;
begin
  if not TryDequeue(Result) then
    raise Exception.Create('Queue is empty');
end;

procedure TQueue<T>.Enqueue(const Value: T);
begin
  if FCount = FCapacity then
    Grow;
    
  RawCopyElement(FData + (FTail * FElementSize), @Value, FElementSize, FTypeInfo);
  FTail := (FTail + 1) mod FCapacity;
  Inc(FCount);
end;

function TQueue<T>.GetCount: Integer;
begin
  Result := FCount;
end;

function TQueue<T>.GetEnumerator: TQueueRecordEnumerator<T>;
begin
  Result := TQueueRecordEnumerator<T>.Create(FData, FHead, FCapacity, FCount, FElementSize, FTypeInfo);
end;

function TQueue<T>.GetInterfaceEnumerator: IEnumerator<T>;
begin
  Result := TQueueEnumerator<T>.Create(FData, FHead, FCapacity, FCount, FElementSize, FTypeInfo);
end;

procedure TQueue<T>.Grow;
var
  NewCap: Integer;
begin
  if FCapacity = 0 then
    NewCap := INITIAL_CAPACITY
  else
    NewCap := FCapacity * 2;
  SetCapacity(NewCap);
end;

function TQueue<T>.Peek: T;
begin
  if not TryPeek(Result) then
    raise Exception.Create('Queue is empty');
end;

procedure TQueue<T>.SetCapacity(ACapacity: Integer);
var
  NewData: PByte;
  I, Idx: Integer;
begin
  if ACapacity < FCount then
    ACapacity := FCount;
    
  if ACapacity = FCapacity then
    Exit;
    
  GetMem(NewData, ACapacity * FElementSize);
  FillChar(NewData^, ACapacity * FElementSize, 0);
  
  if FCount > 0 then
  begin
    for I := 0 to FCount - 1 do
    begin
      Idx := (FHead + I) mod FCapacity;
      System.Move((FData + (Idx * FElementSize))^, (NewData + (I * FElementSize))^, FElementSize);
    end;
  end;
  
  if FData <> nil then
    FreeMem(FData);
    
  FData := NewData;
  FCapacity := ACapacity;
  FHead := 0;
  FTail := FCount;
  if (FTail = FCapacity) and (FCapacity > 0) then
    FTail := 0;
end;

function TQueue<T>.ToArray: TArray<T>;
var
  I, Idx: Integer;
begin
  SetLength(Result, FCount);
  for I := 0 to FCount - 1 do
  begin
    Idx := (FHead + I) mod FCapacity;
    RawCopyElement(@Result[I], FData + (Idx * FElementSize), FElementSize, FTypeInfo);
  end;
end;

function TQueue<T>.TryDequeue(out Value: T): Boolean;
begin
  if FCount = 0 then
  begin
    Value := Default(T);
    Exit(False);
  end;
  
  RawMove(@Value, FData + (FHead * FElementSize), 1, FElementSize, FTypeInfo);
  
  FHead := (FHead + 1) mod FCapacity;
  Dec(FCount);
  Result := True;
end;

function TQueue<T>.TryPeek(out Value: T): Boolean;
begin
  if FCount = 0 then
  begin
    Value := Default(T);
    Exit(False);
  end;
  RawCopyElement(@Value, FData + (FHead * FElementSize), FElementSize, FTypeInfo);
  Result := True;
end;

{ TQueueRecordEnumerator<T> }

constructor TQueueRecordEnumerator<T>.Create(AData: PByte; AHead, ACapacity, ACount, AElementSize: Integer; ATypeInfo: PTypeInfo);
begin
  FData := AData;
  FHead := AHead;
  FCapacity := ACapacity;
  FCount := ACount;
  FElementSize := AElementSize;
  FTypeInfo := ATypeInfo;
  FIndex := -1;
end;

function TQueueRecordEnumerator<T>.GetCurrent: T;
var
  RealIdx: Integer;
begin
  RealIdx := (FHead + FIndex) mod FCapacity;
  RawCopyElement(@Result, FData + (RealIdx * FElementSize), FElementSize, FTypeInfo);
end;

function TQueueRecordEnumerator<T>.MoveNext: Boolean;
begin
  Inc(FIndex);
  Result := FIndex < FCount;
end;

{ TQueueEnumerator<T> }

constructor TQueueEnumerator<T>.Create(AData: PByte; AHead, ACapacity, ACount, AElementSize: Integer; ATypeInfo: PTypeInfo);
begin
  inherited Create;
  FData := AData;
  FHead := AHead;
  FCapacity := ACapacity;
  FCount := ACount;
  FElementSize := AElementSize;
  FTypeInfo := ATypeInfo;
  FIndex := -1;
end;

function TQueueEnumerator<T>.GetCurrent: T;
var
  RealIdx: Integer;
begin
  RealIdx := (FHead + FIndex) mod FCapacity;
  RawCopyElement(@Result, FData + (RealIdx * FElementSize), FElementSize, FTypeInfo);
end;

function TQueueEnumerator<T>.MoveNext: Boolean;
begin
  Inc(FIndex);
  Result := FIndex < FCount;
end;

procedure TQueueEnumerator<T>.Reset;
begin
  FIndex := -1;
end;

end.
