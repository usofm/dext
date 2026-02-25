unit ModelBinding.Endpoints;

interface

uses
  System.SysUtils,
  System.StrUtils,
  Dext.Web,
  Dext.Web.Results;

type
  // -------------------------------------------------------------------------
  // MINIMAL API TEST TYPES
  // -------------------------------------------------------------------------

  // Test 1: Pure Body Binding (JSON)
  TCreateUserRequest = record
    Name: string;
    Email: string;
    Age: Integer;
    Active: Boolean;
    Balance: Currency;
  end;

  // Test 2: Header Only Binding
  TTenantRequest = record
    [FromHeader('X-Tenant-Id')]
    TenantId: string;
    [FromHeader('Authorization')]
    Token: string;
  end;

  // Test 3: Query Only Binding
  TSearchRequest = record
    [FromQuery('q')]
    Query: string;
    [FromQuery('page')]
    Page: Integer;
    [FromQuery('limit')]
    Limit: Integer;
  end;

  // Test 4: Route Only Binding
  TRouteRequest = record
    [FromRoute('id')]
    Id: Integer;
    [FromRoute('category')]
    Category: string;
  end;

  // Test 5: Mixed Binding - Header + Body (the Multi-Tenancy use case)
  TProductCreateRequest = record
    [FromHeader('X-Tenant-Id')]
    TenantId: string;
    // Fields below come from JSON body
    Name: string;
    Description: string;
    Price: Currency;
    Stock: Integer;
  end;

  // Test 6: Mixed Binding - Route + Body
  TProductUpdateRequest = record
    [FromRoute('id')]
    Id: Integer;
    // Fields below come from JSON body
    Name: string;
    Price: Currency;
  end;

  // Test 7: Mixed Binding - Route + Query
  TProductQueryRequest = record
    [FromRoute('category')]
    Category: string;
    [FromQuery('sort')]
    Sort: string;
    [FromQuery('page')]
    Page: Integer;
  end;

  // Test 8: Complex Mixed - Header + Route + Body
  TMultiSourceRequest = record
    [FromHeader('X-Tenant-Id')]
    TenantId: string;
    [FromHeader('X-Correlation-Id')]
    CorrelationId: string;
    [FromRoute('id')]
    Id: Integer;
    // Body fields
    Name: string;
    Value: Double;
  end;

  // Test 9: All Sources Combined
  TFullRequest = record
    [FromHeader('X-Api-Key')]
    ApiKey: string;
    [FromRoute('id')]
    ResourceId: Integer;
    [FromQuery('include')]
    Include: string;
    // Body fields
    Data: string;
    Count: Integer;
  end;

  // -------------------------------------------------------------------------
  // SERVICE
  // -------------------------------------------------------------------------

  IProductService = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-123456789ABC}']
    function GetProduct(Id: Integer): string;
    function CreateProduct(const Name: string; Price: Currency): Integer;
  end;

  TProductService = class(TInterfacedObject, IProductService)
  public
    function GetProduct(Id: Integer): string;
    function CreateProduct(const Name: string; Price: Currency): Integer;
  end;

  // -------------------------------------------------------------------------
  // ENDPOINTS MAPPER
  // -------------------------------------------------------------------------

  TModelBindingEndpoints = class
  public
    class procedure Map(const App: TDextAppBuilder);
  end;

implementation

var
  JsonFormat: TFormatSettings;

{ TProductService }

function TProductService.GetProduct(Id: Integer): string;
begin
  Result := Format('Product_%d', [Id]);
end;

function TProductService.CreateProduct(const Name: string; Price: Currency): Integer;
begin
  Result := Random(1000) + 1;
end;

{ TModelBindingEndpoints }

class procedure TModelBindingEndpoints.Map(const App: TDextAppBuilder);
begin
  WriteLn('[Routes] Configuring Minimal API Test Endpoints...');
  WriteLn;

  // =========================================================================
  // TEST 1: Pure Body Binding
  // =========================================================================
  WriteLn('1. POST /test/body-only - JSON body binding');
  App.MapPost<TCreateUserRequest, IResult>('/test/body-only',
    function(Req: TCreateUserRequest): IResult
    begin
      WriteLn(Format('   -> Name=%s, Email=%s, Age=%d, Active=%s, Balance=%.2f',
        [Req.Name, Req.Email, Req.Age,
         BoolToStr(Req.Active, True), Req.Balance], JsonFormat));
      Result := Results.Ok(Format(
        '{"source":"body","name":"%s","email":"%s","age":%d,"active":%s,"balance":%.2f}',
        [Req.Name, Req.Email, Req.Age,
         BoolToStr(Req.Active, True).ToLower, Double(Req.Balance)], JsonFormat));
    end
  );

  // =========================================================================
  // TEST 2: Header Only Binding
  // =========================================================================
  WriteLn('2. GET /test/header-only - X-Tenant-Id and Authorization headers');
  App.MapGet<TTenantRequest, IResult>('/test/header-only',
    function(Req: TTenantRequest): IResult
    begin
      WriteLn(Format('   -> TenantId=%s, Token=%s',
        [Req.TenantId, Copy(Req.Token, 1, 20)]));
      Result := Results.Ok(Format(
        '{"source":"header","tenantId":"%s","hasToken":%s}',
        [Req.TenantId, BoolToStr(Req.Token <> '', True).ToLower]));
    end
  );

  // =========================================================================
  // TEST 3: Query Only Binding
  // =========================================================================
  WriteLn('3. GET /test/query-only - Query parameters');
  App.MapGet<TSearchRequest, IResult>('/test/query-only',
    function(Req: TSearchRequest): IResult
    begin
      WriteLn(Format('   -> Query=%s, Page=%d, Limit=%d',
        [Req.Query, Req.Page, Req.Limit]));
      Result := Results.Ok(Format(
        '{"source":"query","query":"%s","page":%d,"limit":%d}',
        [Req.Query, Req.Page, Req.Limit]));
    end
  );

  // =========================================================================
  // TEST 4: Route Only Binding
  // =========================================================================
  WriteLn('4. GET /test/route-only/{id}/{category} - Route parameters');
  App.MapGet<TRouteRequest, IResult>('/test/route-only/{id}/{category}',
    function(Req: TRouteRequest): IResult
    begin
      WriteLn(Format('   -> Id=%d, Category=%s',
        [Req.Id, Req.Category]));
      Result := Results.Ok(Format(
        '{"source":"route","id":%d,"category":"%s"}',
        [Req.Id, Req.Category]));
    end
  );

  // =========================================================================
  // TEST 5: Mixed - Header + Body (Multi-Tenancy Use Case)
  // =========================================================================
  WriteLn('5. POST /test/header-body - Header for TenantId + JSON body');
  App.MapPost<TProductCreateRequest, IResult>('/test/header-body',
    function(Req: TProductCreateRequest): IResult
    begin
      WriteLn(Format('   -> TenantId=%s, Name=%s, Price=%.2f, Stock=%d',
        [Req.TenantId, Req.Name, Double(Req.Price), Req.Stock], JsonFormat));
      
      if Req.TenantId = '' then
        Exit(Results.BadRequest('X-Tenant-Id header is required'));

      Result := Results.Ok(Format(
        '{"source":"header+body","tenantId":"%s","name":"%s","description":"%s","price":%.2f,"stock":%d}',
        [Req.TenantId, Req.Name, Req.Description,
         Double(Req.Price), Req.Stock], JsonFormat));
    end
  );

  // =========================================================================
  // TEST 6: Mixed - Route + Body
  // =========================================================================
  WriteLn('6. PUT /test/route-body/{id} - Route for Id + JSON body');
  App.MapPut<TProductUpdateRequest, IResult>('/test/route-body/{id}',
    function(Req: TProductUpdateRequest): IResult
    begin
      WriteLn(Format('   -> Id=%d, Name=%s, Price=%.2f',
        [Req.Id, Req.Name, Double(Req.Price)], JsonFormat));
      Result := Results.Ok(Format(
        '{"source":"route+body","id":%d,"name":"%s","price":%.2f}',
        [Req.Id, Req.Name, Double(Req.Price)], JsonFormat));
    end
  );

  // =========================================================================
  // TEST 7: Mixed - Route + Query
  // =========================================================================
  WriteLn('7. GET /test/route-query/{category} - Route + Query params');
  App.MapGet<TProductQueryRequest, IResult>('/test/route-query/{category}',
    function(Req: TProductQueryRequest): IResult
    begin
      WriteLn(Format('   -> Category=%s, Sort=%s, Page=%d',
        [Req.Category, Req.Sort, Req.Page]));
      Result := Results.Ok(Format(
        '{"source":"route+query","category":"%s","sort":"%s","page":%d}',
        [Req.Category, Req.Sort, Req.Page]));
    end
  );

  // =========================================================================
  // TEST 8: Complex Mixed - Header + Route + Body
  // =========================================================================
  WriteLn('8. PUT /test/multi-source/{id} - Headers + Route + Body');
  App.MapPut<TMultiSourceRequest, IResult>('/test/multi-source/{id}',
    function(Req: TMultiSourceRequest): IResult
    begin
      WriteLn(Format('   -> TenantId=%s, CorrelationId=%s, Id=%d, Name=%s, Value=%.2f',
        [Req.TenantId, Req.CorrelationId, Req.Id,
         Req.Name, Req.Value], JsonFormat));
      Result := Results.Ok(Format(
        '{"source":"header+route+body","tenantId":"%s","correlationId":"%s","id":%d,"name":"%s","value":%.2f}',
        [Req.TenantId, Req.CorrelationId, Req.Id,
         Req.Name, Req.Value], JsonFormat));
    end
  );

  // =========================================================================
  // TEST 9: All Sources Combined
  // =========================================================================
  WriteLn('9. PUT /test/full/{id} - Header + Route + Query + Body');
  App.MapPut<TFullRequest, IResult>('/test/full/{id}',
    function(Req: TFullRequest): IResult
    begin
      WriteLn(Format('   -> ApiKey=%s, ResourceId=%d, Include=%s, Data=%s, Count=%d',
        [Req.ApiKey, Req.ResourceId, Req.Include,
         Req.Data, Req.Count]));
      Result := Results.Ok(Format(
        '{"source":"all","apiKey":"%s","resourceId":%d,"include":"%s","data":"%s","count":%d}',
        [Req.ApiKey, Req.ResourceId, Req.Include,
         Req.Data, Req.Count]));
    end
  );

  // =========================================================================
  // TEST 10: Service Injection + Model Binding
  // =========================================================================
  WriteLn('10. POST /test/service - Service injection with body binding');
  App.MapPost<IProductService, TProductCreateRequest, IResult>('/test/service',
    function(Service: IProductService; Req: TProductCreateRequest): IResult
    begin
      WriteLn(Format('   -> Service: %s, Name=%s, Price=%.2f',
        [IfThen(Service <> nil, 'OK', 'NULL'), Req.Name, Double(Req.Price)], JsonFormat));
      
      if Req.TenantId = '' then
        Exit(Results.BadRequest('X-Tenant-Id header is required'));
        
      var NewId := Service.CreateProduct(Req.Name, Req.Price);
      Result := Results.Created('/products/' + IntToStr(NewId), Format(
        '{"id":%d,"tenantId":"%s","name":"%s","price":%.2f}',
        [NewId, Req.TenantId, Req.Name, Double(Req.Price)], JsonFormat));
    end
  );

  WriteLn;
end;

initialization
  JsonFormat := TFormatSettings.Create('en-US');
  JsonFormat.DecimalSeparator := '.';

end.
