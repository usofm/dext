unit DextStore.Models;

interface

uses
  Dext,
  Dext.Json,
  System.SysUtils;

type
  // ===========================================================================
  // 📦 Entities
  // ===========================================================================
  
  TProduct = class
  private
    FId: Integer;
    FName: string;
    FPrice: Currency;
    FStock: Integer;
    FCategory: string;
  public
    [JSONName('id')]
    property Id: Integer read FId write FId;
    [JSONName('name')]
    property Name: string read FName write FName;
    [JSONName('price')]
    property Price: Currency read FPrice write FPrice;
    [JSONName('stock')]
    property Stock: Integer read FStock write FStock;
    [JSONName('category')]
    property Category: string read FCategory write FCategory;
  end;

  TCartItem = class
  private
    FProductId: Integer;
    FQuantity: Integer;
    FProductName: string;
    FUnitPrice: Currency;
    function GetTotal: Currency;
  public
    [JSONName('productId')]
    property ProductId: Integer read FProductId write FProductId;
    [JSONName('productName')]
    property ProductName: string read FProductName write FProductName;
    [JSONName('quantity')]
    property Quantity: Integer read FQuantity write FQuantity;
    [JSONName('unitPrice')]
    property UnitPrice: Currency read FUnitPrice write FUnitPrice;
    
    [JSONName('total')]
    property Total: Currency read GetTotal;
  end;

  TOrder = class
  private
    FId: Integer;
    FUserId: string;
    FItems: TArray<TCartItem>;
    FTotalAmount: Currency;
    FCreatedAt: TDateTime;
    FStatus: string;
  public
    [JSONName('id')]
    property Id: Integer read FId write FId;
    [JSONName('userId')]
    property UserId: string read FUserId write FUserId;
    [JSONName('items')]
    property Items: TArray<TCartItem> read FItems write FItems;
    [JSONName('totalAmount')]
    property TotalAmount: Currency read FTotalAmount write FTotalAmount;
    [JSONName('createdAt')]
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;
    [JSONName('status')]
    property Status: string read FStatus write FStatus;

    destructor Destroy; override;
  end;

  // ===========================================================================
  // 📝 DTOs (Data Transfer Objects)
  // ===========================================================================

  TLoginRequest = record
    [Required]
    [JSONName('username')]
    Username: string;
    [Required]
    [JSONName('password')]
    Password: string;
  end;

  TCartResponse = record
    [JSONName('items')]
    Items: TArray<TCartItem>;
    [JSONName('totalAmount')]
    TotalAmount: Currency;
    [JSONName('userId')]
    UserId: string;
  end;

  TCreateProductRequest = record
    [Required]
    [StringLength(3, 100)]
    [JSONName('name')]
    Name: string;
    
    [Required]
    [JSONName('price')]
    Price: Currency;
    
    [Required]
    [JSONName('stock')]
    Stock: Integer;
    
    [JSONName('category')]
    Category: string;
  end;

  TAddToCartRequest = record
    [Required]
    [JSONName('productId')]
    ProductId: Integer;
    
    [Required]
    [JSONName('quantity')]
    Quantity: Integer;
  end;

  TOrderResponse = record
    [JSONName('orderId')]
    OrderId: Integer;
    [JSONName('total')]
    Total: Currency;
    [JSONName('status')]
    Status: string;
    [JSONName('message')]
    Message: string;
  end;

implementation

{ TCartItem }

function TCartItem.GetTotal: Currency;
begin
  Result := FQuantity * FUnitPrice;
end;

{ TOrder }

destructor TOrder.Destroy;
var
  Item: TCartItem;
begin
  for Item in FItems do
    if Assigned(Item) then
      Item.Free;
  inherited;
end;

end.
