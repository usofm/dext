program Benchmarks.ZeroAlloc;

{$APPTYPE CONSOLE}

uses
  Dext.MM,
  Dext.Utils,
  System.SysUtils,
  System.Diagnostics,
  Bench.Routing in 'Bench.Routing.pas',
  Bench.Orm in 'Bench.Orm.pas',
  Bench.Middleware in 'Bench.Middleware.pas',
  Bench.Json in 'Bench.Json.pas',
  Bench.HttpRequest in 'Bench.HttpRequest.pas';

begin
  ReportMemoryLeaksOnShutdown := True;
  try
    Writeln('============================================');
    Writeln('   Dext Framework - Zero-Alloc Benchmarks   ');
    Writeln('============================================');
    Writeln;

    TBenchRouting.Run;
    TBenchMiddleware.Run;
    TBenchOrm.Run;
    Writeln;
    TBenchJson.Run;
    Writeln;
    TBenchHttpRequest.Run;

    Writeln;
    Writeln('Done. Press ENTER to close.');
    //Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  ConsolePause;
end.
