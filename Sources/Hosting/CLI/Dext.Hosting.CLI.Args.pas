unit Dext.Hosting.CLI.Args;

interface

uses
  System.Classes,
  System.SysUtils,
  Dext.Collections,
  Dext.Collections.Dict;

type
  TCommandLineArgs = class;

  IConsoleCommand = interface
    ['{A1B2C3D4-E5F6-4789-0123-456789ABCDEF}']
    function GetName: string;
    function GetDescription: string;
    procedure Execute(const Args: TCommandLineArgs);
  end;

  /// <summary>
  ///   Parses and stores command line arguments.
  ///   Supports format: command [subcommand] -flag --option=value --option value
  /// </summary>
  TCommandLineArgs = class
  private
    FCommand: string;
    FArguments: IDictionary<string, string>;
    FFlags: IList<string>;
    FValues: IList<string>;
    FRawArgs: TArray<string>; // Remaining arguments (after command)
    
    function NormalizeKey(const Key: string): string;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    ///   Parses the argument array (typically excluding the executable name).
    /// </summary>
    procedure Parse(const Args: TArray<string>);

    /// <summary>
    ///   Checks if a flag or option exists.
    /// </summary>
    function HasOption(const Name: string): Boolean;

    /// <summary>
    ///   Gets the value of an option. Returns Default if not found.
    /// </summary>
    function GetOption(const Name: string; const Default: string = ''): string;

    /// <summary>
    ///   The main command (first argument).
    /// </summary>
    property Command: string read FCommand;
    
    /// <summary>
    ///   Positional values (excluding the command).
    /// </summary>
    property Values: IList<string> read FValues;

    /// <summary>
    ///   All raw arguments passed to Parse.
    /// </summary>
    property RawArgs: TArray<string> read FRawArgs;
  end;

implementation

{ TCommandLineArgs }

constructor TCommandLineArgs.Create;
begin
  FArguments := TCollections.CreateDictionary<string, string>;
  FFlags := TCollections.CreateList<string>;
  FValues := TCollections.CreateList<string>;
end;

destructor TCommandLineArgs.Destroy;
begin
  // All fields are ARC-managed
  inherited;
end;

function TCommandLineArgs.NormalizeKey(const Key: string): string;
begin
  Result := Key;
  if Result.StartsWith('--') then
    Delete(Result, 1, 2)
  else if Result.StartsWith('-') then
    Delete(Result, 1, 1);
end;

procedure TCommandLineArgs.Parse(const Args: TArray<string>);
var
  i: Integer;
  Arg, Key, Value: string;
begin
  FRawArgs := Args;
  if Length(Args) = 0 then
    Exit;

  // First argument is typically the command, unless it starts with -
  if not Args[0].StartsWith('-') then
  begin
    FCommand := Args[0];
    i := 1;
  end
  else
    i := 0;

  while i < Length(Args) do
  begin
    Arg := Args[i];

    if Arg.StartsWith('-') then
    begin
      // It's an option or flag
      if Arg.Contains('=') then
      begin
        // --key=value
        var Parts := Arg.Split(['='], 2);
        Key := NormalizeKey(Parts[0]);
        if Length(Parts) > 1 then
          Value := Parts[1]
        else
          Value := '';
          
        FArguments.AddOrSetValue(Key, Value);
        FFlags.Add(Key); // Handle as flag too if needed
      end
      else
      begin
        // --key value OR --flag
        Key := NormalizeKey(Arg);
        FFlags.Add(Key); // Assume flag first
        
        // Peek next to see if it's a value
        if (i + 1 < Length(Args)) and (not Args[i+1].StartsWith('-')) then
        begin
          Value := Args[i+1];
          FArguments.AddOrSetValue(Key, Value);
          Inc(i); // Skip next arg as it was consumed
        end;
      end;
    end
    else
    begin
      // Positional argument
      FValues.Add(Arg);
    end;
    
    Inc(i);
  end;
end;

function TCommandLineArgs.HasOption(const Name: string): Boolean;
begin
  Result := FFlags.Contains(Name) or FArguments.ContainsKey(Name);
end;

function TCommandLineArgs.GetOption(const Name: string; const Default: string): string;
begin
  if not FArguments.TryGetValue(Name, Result) then
    Result := Default;
end;

end.
