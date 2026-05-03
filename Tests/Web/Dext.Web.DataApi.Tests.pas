unit Dext.Web.DataApi.Tests;

{$RTTI EXPLICIT METHODS([vcPublic]) FIELDS([vcPublic])}

interface

uses
  System.SysUtils,
  Dext.Testing.Attributes,
  Dext.Assertions,
  Dext.Web.Interfaces,
  Dext.Web.Core,
  Dext.Web.DataApi,
  Dext.Entity,
  System.Classes,
  Dext.Web.Pipeline;

type
  [DataApi] // Deve resultar em /api/conventiontest
  TConventionTest = class(TPersistent)
  private
    FId: Integer;
    FName: string;
  public
    property Id: Integer read FId write FId;
    property Name: string read FName write FName;
  end;

  [DataApi('/api/custom')]
  TCustomPathTest = class(TPersistent)
  private
    FId: Integer;
  public
    property Id: Integer read FId write FId;
  end;

  [TestFixture('DataAPI RTTI Convention Tests')]
  TDataApiConventionTests = class
  public
    [Test('Should register APIs automatically using [DataApi] attribute')]
    procedure Should_Register_Apis_By_Attribute_Convention;
    [Test('Should respect custom path defined in [DataApi] attribute')]
    procedure Should_Respect_Custom_Path_In_Attribute;
    [Test('Should strip "T" prefix from class name by default')]
    procedure Should_Strip_T_Prefix_From_Class_Name;
  end;

implementation

uses
  Dext.Web.Routing;

procedure TDataApiConventionTests.Should_Register_Apis_By_Attribute_Convention;
var
  App: IApplicationBuilder;
  Routes: TArray<TEndpointMetadata>;
  Found: Boolean;
  Route: TEndpointMetadata;
begin
  App := TApplicationBuilder.Create(nil);
  
  // Act
  TDataApi.MapAll(App); 
  
  // Assert
  Routes := App.GetRoutes;
  Found := False;
  for Route in Routes do
    if Route.Path.StartsWith('/api/conventiontest') then
    begin
      Found := True;
      Break;
    end;
    
  Should(Found).BeTrue;
end;

procedure TDataApiConventionTests.Should_Respect_Custom_Path_In_Attribute;
var
  App: IApplicationBuilder;
  Routes: TArray<TEndpointMetadata>;
  Found: Boolean;
  Route: TEndpointMetadata;
begin
  App := TApplicationBuilder.Create(nil);
  
  // Act
  TDataApi.MapAll(App);
  
  // Assert
  Routes := App.GetRoutes;
  Found := False;
  for Route in Routes do
    if Route.Path.StartsWith('/api/custom') then
    begin
      Found := True;
      Break;
    end;
    
  Should(Found).BeTrue;
end;

procedure TDataApiConventionTests.Should_Strip_T_Prefix_From_Class_Name;
var
  App: IApplicationBuilder;
  Routes: TArray<TEndpointMetadata>;
  Found: Boolean;
  Route: TEndpointMetadata;
begin
  App := TApplicationBuilder.Create(nil);
  
  TDataApi.MapAll(App);
  
  Routes := App.GetRoutes;
  Found := False;
  for Route in Routes do
    if Route.Path.Equals('/api/conventiontest') then // Sem o 'T'
    begin
      Found := True;
      Break;
    end;
    
  Should(Found).BeTrue;
end;

initialization
  RegisterClass(TConventionTest);
  RegisterClass(TCustomPathTest);

end.
