unit Bench.Json;

interface

type
  TBenchJson = class
  public
    class procedure Run;
  end;

implementation

uses
  System.SysUtils,
  System.Diagnostics,
  System.Classes,
  Dext.Core.Span,
  Dext.Json.Utf8.Serializer,
  Bench.Utils;

type
  TUserDto = record
    Id: Integer;
    Name: string;
    Email: string;
    Age: Integer;
    IsActive: Boolean;
  end;

class procedure TBenchJson.Run;
const
  ITERATIONS = 50000;
var
  JsonPayload: string;
  Utf8Payload: TBytes;
  ByteSpan: TByteSpan;
  SW: TStopwatch;
  I: Integer;
  AllocCountStart: Int64;
  AllocDelta: Int64;
  ResultUser: TUserDto;
begin
  Writeln('--- JSON Deserialization Benchmark ---');
  Writeln('Iterations: ', ITERATIONS);

  JsonPayload := '{"Id": 42, "Name": "Cesar Romero", "Email": "cesar@dext.framework", "Age": 33, "IsActive": true}';
  Utf8Payload := TEncoding.UTF8.GetBytes(JsonPayload);
  ByteSpan := TByteSpan.FromBytes(Utf8Payload);

  // Warmup - ensures RTTI initialization is excluded from the benchmark time
  ResultUser := TUtf8JsonSerializer.Deserialize<TUserDto>(ByteSpan);

  SW := TStopwatch.StartNew;
  AllocCountStart := GetAllocatedBytes;
  
  for I := 1 to ITERATIONS do
  begin
    ResultUser := TUtf8JsonSerializer.Deserialize<TUserDto>(ByteSpan);
  end;
  SW.Stop;
  
  AllocDelta := GetAllocatedBytes - AllocCountStart;

  Writeln('1. JSON to Record (Direct Memory Injection)');
  Writeln(Format('   Time: %.2f ms', [SW.Elapsed.TotalMilliseconds]));
  Writeln(Format('   Allocations (approx bytes): %d', [AllocDelta])); 
  Writeln('--------------------------------');
end;

end.
