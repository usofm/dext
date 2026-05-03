unit Dext.Configuration.Hashing.Tests;

interface

uses
  Dext.Testing,
  Dext.Configuration.Core,
  Dext.Configuration.Interfaces,
  Dext.Collections,
  Dext.Collections.Dict,
  System.SysUtils;

type
  [TestFixture]
  TConfigurationHashingTests = class
  public
    [Test]
    procedure Test_Deep_Key_Lookup_Stability;
    [Test]
    procedure Test_Cache_Invalidation_On_Set;
  end;

implementation

{ TConfigurationHashingTests }

procedure TConfigurationHashingTests.Test_Deep_Key_Lookup_Stability;
var
  Config: IConfigurationRoot;
  Dict: IDictionary<string, string>;
  Providers: IList<IConfigurationProvider>;
  Source: IConfigurationSource;
begin
  Dict := TCollections.CreateDictionary<string, string>;
  Dict.Add('App:Database:FireDAC:Connection:Params:DriverID', 'SQLite');
  Dict.Add('A:B:C:D:E:F:G', 'DeepValue');
  
  Providers := TCollections.CreateList<IConfigurationProvider>;
  Source := TMemoryConfigurationSource.Create(Dict.ToArray);
  Providers.Add(Source.Build(nil));

  Config := TConfigurationRoot.Create(Providers, False, 0);
  
  // First lookup (populates cache)
  Should(Config['App:Database:FireDAC:Connection:Params:DriverID']).Be('SQLite');
  Should(Config['A:B:C:D:E:F:G']).Be('DeepValue');
  
  // Second lookup (uses hash cache)
  Should(Config['App:Database:FireDAC:Connection:Params:DriverID']).Be('SQLite');
  Should(Config['A:B:C:D:E:F:G']).Be('DeepValue');
end;

procedure TConfigurationHashingTests.Test_Cache_Invalidation_On_Set;
var
  Config: IConfigurationRoot;
  Dict: IDictionary<string, string>;
  Providers: IList<IConfigurationProvider>;
  Source: IConfigurationSource;
begin
  Dict := TCollections.CreateDictionary<string, string>;
  Dict.Add('Key1', 'OldValue');
  
  Providers := TCollections.CreateList<IConfigurationProvider>;
  Source := TMemoryConfigurationSource.Create(Dict.ToArray);
  Providers.Add(Source.Build(nil));

  Config := TConfigurationRoot.Create(Providers, False, 0);
    
  Should(Config['Key1']).Be('OldValue');
  
  // Modifying should invalidate hash cache
  Config['Key1'] := 'NewValue';
  
  Should(Config['Key1']).Be('NewValue');
end;

initialization
  TTestRunner.RegisterFixture(TConfigurationHashingTests);

end.
