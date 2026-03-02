unit Bench.Orm;

interface

type
  TBenchOrm = class
  public
    class procedure Run;
  end;

implementation

uses
  System.SysUtils,
  System.Diagnostics,
  System.Classes,
  System.Rtti,
  Dext.Specifications.Base,
  Dext.Specifications.Types,
  Dext.Specifications.Interfaces,
  Dext.Entity.Query,
  Dext.Entity.Context,
  Bench.Utils;

{ TBenchOrm }

type
  TTestEntity = class
  private
    FId: Integer;
    FName: string;
    FAge: Integer;
    FIsActive: Boolean;
  public
    property Id: Integer read FId write FId;
    property Name: string read FName write FName;
    property Age: Integer read FAge write FAge;
    property IsActive: Boolean read FIsActive write FIsActive;
  end;

class procedure TBenchOrm.Run;
const
  ITERATIONS = 100000;
var
  SW: TStopwatch;
  I: Integer;
  AllocCountStart: Int64;
  AllocDelta: Int64;
  Exp: IExpression;
begin
  Writeln('--- ORM Specification Benchmark ---');
  Writeln('Iterations: ', ITERATIONS);

  // Warm-up to skip static allocations
  Exp := (Prop('Age') > 18) and (Prop('IsActive') = True) and (Prop('Name').Like('John%'));
  Exp := nil;

  SW := TStopwatch.StartNew;
  AllocCountStart := GetAllocatedBytes;
  
  for I := 1 to ITERATIONS do
  begin
    // Simulate typical Where clause building with fluent queries
    Exp := (Prop('Age') > 18) and (Prop('IsActive') = True) and (Prop('Name').Like('John%'));
  end;
  Exp := nil;
  SW.Stop;

  AllocDelta := GetAllocatedBytes - AllocCountStart;

  Writeln('1. Expression Tree Building (3 conditions)');
  Writeln(Format('   Time: %.2f ms', [SW.Elapsed.TotalMilliseconds]));
  Writeln(Format('   Net Allocations (bytes): %d', [AllocDelta])); 
  Writeln('--------------------------------');

  // Benchmark for Specification
  var SpecStartAlloc := GetAllocatedBytes;
  SW := TStopwatch.StartNew;
  for I := 1 to ITERATIONS do
  begin
    var Spec := TSpecification<TTestEntity>.Create;
    try
      Spec.Where((Prop('Age') > 18));
      Spec.Include('Orders');
      Spec.Include('Items');
      Spec.Select('Id');
      Spec.Select('Name');
      Spec.ApplyPaging(0, 50);
    finally
      Spec.Free;
    end;
  end;
  SW.Stop;
  
  var SpecAllocDelta := GetAllocatedBytes - SpecStartAlloc;

  Writeln('2. Specification Building (Where, Include, Select, Paging)');
  Writeln(Format('   Time: %.2f ms', [SW.Elapsed.TotalMilliseconds]));
  Writeln(Format('   Net Allocations (bytes): %d', [SpecAllocDelta])); 
  Writeln('--------------------------------');
end;

end.
