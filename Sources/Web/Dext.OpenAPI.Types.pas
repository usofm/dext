{***************************************************************************}
{                                                                           }
{           Dext Framework                                                  }
{                                                                           }
{           Copyright (C) 2025 Cesar Romero & Dext Contributors             }
{                                                                           }
{           Licensed under the Apache License, Version 2.0 (the "License"); }
{           you may not use this file except in compliance with the License.}
{           You may obtain a copy of the License at                         }
{                                                                           }
{               http://www.apache.org/licenses/LICENSE-2.0                  }
{                                                                           }
{           Unless required by applicable law or agreed to in writing,      }
{           software distributed under the License is distributed on an     }
{           "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,    }
{           either express or implied. See the License for the specific     }
{           language governing permissions and limitations under the        }
{           License.                                                        }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Author:  Cesar Romero                                                    }
{  Created: 2025-12-08                                                      }
{                                                                           }
{***************************************************************************}
unit Dext.OpenAPI.Types;

interface

uses
  System.SysUtils,
  Dext.Collections,
  Dext.Collections.Dict;

type
  /// <summary>
  ///   Represents the data type of a schema property in OpenAPI.
  /// </summary>
  TOpenAPIDataType = (
    odtString,
    odtNumber,
    odtInteger,
    odtBoolean,
    odtArray,
    odtObject
  );

  /// <summary>
  ///   Represents a schema definition in OpenAPI.
  /// </summary>
  TOpenAPISchema = class
  private
    FType: TOpenAPIDataType;
    FFormat: string;
    FDescription: string;
    FRequired: TArray<string>;
    FProperties: IDictionary<string, TOpenAPISchema>;
    FItems: TOpenAPISchema;
    FRef: string; // For $ref references
    FEnum: TArray<string>;
    FExample: string; // Stores the example value
  public
    constructor Create;
    destructor Destroy; override;
    
    property DataType: TOpenAPIDataType read FType write FType;
    property Format: string read FFormat write FFormat;
    property Description: string read FDescription write FDescription;
    property Required: TArray<string> read FRequired write FRequired;
    property Properties: IDictionary<string, TOpenAPISchema> read FProperties;
    property Items: TOpenAPISchema read FItems write FItems;
    property Ref: string read FRef write FRef;
    property Enum: TArray<string> read FEnum write FEnum;
    property Example: string read FExample write FExample;
  end;

  /// <summary>
  ///   Represents a parameter in an OpenAPI operation.
  /// </summary>
  TOpenAPIParameterLocation = (oplQuery, oplPath, oplHeader, oplCookie);

  TOpenAPIParameter = class
  private
    FName: string;
    FIn: TOpenAPIParameterLocation;
    FDescription: string;
    FRequired: Boolean;
    FSchema: TOpenAPISchema;
  public
    constructor Create;
    destructor Destroy; override;
    
    property Name: string read FName write FName;
    property Location: TOpenAPIParameterLocation read FIn write FIn;
    property Description: string read FDescription write FDescription;
    property Required: Boolean read FRequired write FRequired;
    property Schema: TOpenAPISchema read FSchema write FSchema;
  end;

  /// <summary>
  ///   Represents a request body in an OpenAPI operation.
  /// </summary>
  TOpenAPIRequestBody = class
  private
    FDescription: string;
    FRequired: Boolean;
    FContent: IDictionary<string, TOpenAPISchema>; // MediaType -> Schema
  public
    constructor Create;
    destructor Destroy; override;
    
    property Description: string read FDescription write FDescription;
    property Required: Boolean read FRequired write FRequired;
    property Content: IDictionary<string, TOpenAPISchema> read FContent;
  end;

  /// <summary>
  ///   Represents a response in an OpenAPI operation.
  /// </summary>
  TOpenAPIResponse = class
  private
    FDescription: string;
    FContent: IDictionary<string, TOpenAPISchema>; // MediaType -> Schema
  public
    constructor Create;
    destructor Destroy; override;
    
    property Description: string read FDescription write FDescription;
    property Content: IDictionary<string, TOpenAPISchema> read FContent;
  end;

  /// <summary>
  ///   Represents an operation (GET, POST, etc.) in OpenAPI.
  /// </summary>
  TOpenAPIOperation = class
  private
    FSummary: string;
    FDescription: string;
    FOperationId: string;
    FTags: TArray<string>;
    FParameters: IList<TOpenAPIParameter>;
    FRequestBody: TOpenAPIRequestBody;
    FResponses: IDictionary<string, TOpenAPIResponse>; // Status Code -> Response
    FSecurity: IList<IDictionary<string, TArray<string>>>;
  public
    constructor Create;
    destructor Destroy; override;
    
    property Summary: string read FSummary write FSummary;
    property Description: string read FDescription write FDescription;
    property OperationId: string read FOperationId write FOperationId;
    property Tags: TArray<string> read FTags write FTags;
    property Parameters: IList<TOpenAPIParameter> read FParameters;
    property RequestBody: TOpenAPIRequestBody read FRequestBody write FRequestBody;
    property Responses: IDictionary<string, TOpenAPIResponse> read FResponses;
    property Security: IList<IDictionary<string, TArray<string>>> read FSecurity;
  end;

  /// <summary>
  ///   Represents a path item (endpoint) in OpenAPI.
  /// </summary>
  TOpenAPIPathItem = class
  private
    FGet: TOpenAPIOperation;
    FPost: TOpenAPIOperation;
    FPut: TOpenAPIOperation;
    FDelete: TOpenAPIOperation;
    FPatch: TOpenAPIOperation;
  public
    destructor Destroy; override;
    
    property Get: TOpenAPIOperation read FGet write FGet;
    property Post: TOpenAPIOperation read FPost write FPost;
    property Put: TOpenAPIOperation read FPut write FPut;
    property Delete: TOpenAPIOperation read FDelete write FDelete;
    property Patch: TOpenAPIOperation read FPatch write FPatch;
  end;

  /// <summary>
  ///   Represents server information in OpenAPI.
  /// </summary>
  TOpenAPIServer = record
    Url: string;
    Description: string;
  end;

  /// <summary>
  ///   Represents contact information in OpenAPI.
  /// </summary>
  TOpenAPIContact = class
  private
    FName: string;
    FEmail: string;
    FUrl: string;
  public
    property Name: string read FName write FName;
    property Email: string read FEmail write FEmail;
    property Url: string read FUrl write FUrl;
  end;

  /// <summary>
  ///   Represents license information in OpenAPI.
  /// </summary>
  TOpenAPILicense = class
  private
    FName: string;
    FUrl: string;
  public
    property Name: string read FName write FName;
    property Url: string read FUrl write FUrl;
  end;

  /// <summary>
  ///   Represents API information in OpenAPI.
  /// </summary>
  TOpenAPIInfo = class
  private
    FTitle: string;
    FDescription: string;
    FVersion: string;
    FContact: TOpenAPIContact;
    FLicense: TOpenAPILicense;
  public
    destructor Destroy; override;
    
    property Title: string read FTitle write FTitle;
    property Description: string read FDescription write FDescription;
    property Version: string read FVersion write FVersion;
    property Contact: TOpenAPIContact read FContact write FContact;
    property License: TOpenAPILicense read FLicense write FLicense;
  end;

  /// <summary>
  ///   Types of security schemes supported by OpenAPI.
  /// </summary>
  TSecuritySchemeType = (sstApiKey, sstHttp, sstOAuth2, sstOpenIdConnect);

  /// <summary>
  ///   Location of API key for apiKey security scheme.
  /// </summary>
  TApiKeyLocation = (aklQuery, aklHeader, aklCookie);

  /// <summary>
  ///   Represents a security scheme in OpenAPI.
  /// </summary>
  TOpenAPISecurityScheme = class
  private
    FType: TSecuritySchemeType;
    FDescription: string;
    FName: string;              // For apiKey
    FIn: TApiKeyLocation;       // For apiKey
    FScheme: string;            // For http (e.g., 'bearer', 'basic')
    FBearerFormat: string;      // For http bearer (e.g., 'JWT')
  public
    property SchemeType: TSecuritySchemeType read FType write FType;
    property Description: string read FDescription write FDescription;
    property Name: string read FName write FName;
    property Location: TApiKeyLocation read FIn write FIn;
    property Scheme: string read FScheme write FScheme;
    property BearerFormat: string read FBearerFormat write FBearerFormat;
  end;


  /// <summary>
  ///   Represents a complete OpenAPI 3.0 document.
  /// </summary>
  TOpenAPIDocument = class
  private
    FOpenAPI: string;
    FInfo: TOpenAPIInfo;
    FServers: IList<TOpenAPIServer>;
    FPaths: IDictionary<string, TOpenAPIPathItem>;
    FSchemas: IDictionary<string, TOpenAPISchema>;
    FSecuritySchemes: IDictionary<string, TOpenAPISecurityScheme>;
  public
    constructor Create;
    destructor Destroy; override;
    
    property OpenAPI: string read FOpenAPI write FOpenAPI;
    property Info: TOpenAPIInfo read FInfo write FInfo;
    property Servers: IList<TOpenAPIServer> read FServers;
    property Paths: IDictionary<string, TOpenAPIPathItem> read FPaths;
    property Schemas: IDictionary<string, TOpenAPISchema> read FSchemas;
    property SecuritySchemes: IDictionary<string, TOpenAPISecurityScheme> read FSecuritySchemes;
  end;

implementation

{ TOpenAPISchema }

constructor TOpenAPISchema.Create;
begin
  inherited;
  FProperties := TCollections.CreateDictionary<string, TOpenAPISchema>;
end;

destructor TOpenAPISchema.Destroy;
begin
  for var Pair in FProperties do
    Pair.Value.Free;
  // FProperties is ARC
  
  if Assigned(FItems) then
    FItems.Free;
    
  inherited;
end;

{ TOpenAPIParameter }

constructor TOpenAPIParameter.Create;
begin
  inherited;
  FSchema := TOpenAPISchema.Create;
end;

destructor TOpenAPIParameter.Destroy;
begin
  FSchema.Free;
  inherited;
end;

{ TOpenAPIRequestBody }

constructor TOpenAPIRequestBody.Create;
begin
  inherited;
  FContent := TCollections.CreateDictionary<string, TOpenAPISchema>;
end;

destructor TOpenAPIRequestBody.Destroy;
begin
  for var Pair in FContent do
    Pair.Value.Free;
  // FContent is ARC
  inherited;
end;

{ TOpenAPIResponse }

constructor TOpenAPIResponse.Create;
begin
  inherited;
  FContent := TCollections.CreateDictionary<string, TOpenAPISchema>;
end;

destructor TOpenAPIResponse.Destroy;
begin
  for var Pair in FContent do
    Pair.Value.Free;
  // FContent is ARC
  inherited;
end;

{ TOpenAPIOperation }

constructor TOpenAPIOperation.Create;
begin
  inherited;
  FParameters := TCollections.CreateObjectList<TOpenAPIParameter>(True);
  FResponses := TCollections.CreateDictionary<string, TOpenAPIResponse>;
  FSecurity := TCollections.CreateList<IDictionary<string, TArray<string>>>(True);
end;

destructor TOpenAPIOperation.Destroy;
begin
  // FParameters is ARC
  
  for var Pair in FResponses do
    Pair.Value.Free;
  // FResponses is ARC
  
  // FSecurity items are freed by ARC since it's an object list

  
  if Assigned(FRequestBody) then
    FRequestBody.Free;
    
  inherited;
end;

{ TOpenAPIPathItem }

destructor TOpenAPIPathItem.Destroy;
begin
  if Assigned(FGet) then FGet.Free;
  if Assigned(FPost) then FPost.Free;
  if Assigned(FPut) then FPut.Free;
  if Assigned(FDelete) then FDelete.Free;
  if Assigned(FPatch) then FPatch.Free;
  inherited;
end;

{ TOpenAPIInfo }

destructor TOpenAPIInfo.Destroy;
begin
  if Assigned(FContact) then
    FContact.Free;
  if Assigned(FLicense) then
    FLicense.Free;
  inherited;
end;

{ TOpenAPIDocument }

constructor TOpenAPIDocument.Create;
begin
  inherited;
  FOpenAPI := '3.0.0';
  FInfo := TOpenAPIInfo.Create;
  FServers := TCollections.CreateList<TOpenAPIServer>;
  FPaths := TCollections.CreateDictionary<string, TOpenAPIPathItem>;
  FSchemas := TCollections.CreateDictionary<string, TOpenAPISchema>;
  FSecuritySchemes := TCollections.CreateDictionary<string, TOpenAPISecurityScheme>;
end;

destructor TOpenAPIDocument.Destroy;
begin
  FInfo.Free;
  // FServers is ARC
  
  for var Pair in FPaths do
    Pair.Value.Free;
  // FPaths is ARC
  
  for var Pair in FSchemas do
    Pair.Value.Free;
  // FSchemas is ARC
  
  for var Pair in FSecuritySchemes do
    Pair.Value.Free;
  // FSecuritySchemes is ARC
  
  inherited;
end;

end.

