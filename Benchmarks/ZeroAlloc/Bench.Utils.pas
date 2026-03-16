unit Bench.Utils;

interface

function GetAllocatedBytes: Int64;

implementation

function GetAllocatedBytes: Int64;
var
  MemState: TMemoryManagerState;
  I: Integer;
begin
  Result := 0;
  {$WARN SYMBOL_PLATFORM OFF}
  GetMemoryManagerState(MemState);
  {$WARN SYMBOL_PLATFORM ON}
  for I := Low(MemState.SmallBlockTypeStates) to High(MemState.SmallBlockTypeStates) do
    Inc(Result, Int64(MemState.SmallBlockTypeStates[I].AllocatedBlockCount) * MemState.SmallBlockTypeStates[I].UseableBlockSize);
  Inc(Result, MemState.TotalAllocatedMediumBlockSize);
  Inc(Result, MemState.TotalAllocatedLargeBlockSize);
end;

end.
