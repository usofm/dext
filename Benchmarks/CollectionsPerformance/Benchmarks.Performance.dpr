program Benchmarks.Performance;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Dext.Utils,
  System.SysUtils,
  Bench.Core in 'Bench.Core.pas',
  Bench.Common in 'Bench.Common.pas',
  Bench.RTL in 'Bench.RTL.pas',
  Bench.Dext in 'Bench.Dext.pas';

var
  Bench: TBenchmark;
  Sizes: TArray<Integer>;
  Size: Integer;
  LogFileName: string;
begin
  SetConsoleCharSet;
  try
    Writeln('==========================================================');
    Writeln(' Dext Framework Performance Benchmark');
    Writeln('==========================================================');
    Writeln('');

    Bench := TBenchmark.Create;
    try
      Sizes := [100, 10000, 100000];

      for Size in Sizes do
      begin
        Writeln('Running tests for size: ', Size);
        
        // Primitive: Integer
        TRTLBench.RunInteger(Bench, Size);
        TDextBench.RunInteger(Bench, Size);

        // Managed: String
        TRTLBench.RunString(Bench, Size);
        TDextBench.RunString(Bench, Size);

        // Value Type: Record
        TRTLBench.RunRecordSmall(Bench, Size);
        TDextBench.RunRecordSmall(Bench, Size);

        // Fixed Point: Currency
        TRTLBench.RunCurrency(Bench, Size);
        TDextBench.RunCurrency(Bench, Size);

        // Low Level: Pointer
        TRTLBench.RunPointer(Bench, Size);
        TDextBench.RunPointer(Bench, Size);

        // Reference Type: Object
        TRTLBench.RunObject(Bench, Size);
        TDextBench.RunObject(Bench, Size);
      end;

      Writeln('');
      Writeln('Final Results:');
      Writeln('');
      Bench.PrintResults;

      LogFileName := Format('performance_results_%s.md', [FormatDateTime('yyyymmdd_hhnn', Now)]);
      Bench.SaveToMarkdown(LogFileName);
      
      Writeln('');
      Writeln('Benchmark complete. Results saved to ' + LogFileName);
    finally
      Bench.Free;
    end;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  
  if not FindCmdLineSwitch('no-pause') then
  begin
    ConsolePause;
  end;
  ReadLn;
end.
