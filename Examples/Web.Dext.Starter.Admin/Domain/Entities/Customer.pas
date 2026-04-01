unit Customer;

interface

uses
  Dext.Entity,
  Dext.Core.SmartTypes; // Correct unit

type
  TCustomerStatus = (Active, Inactive, Blocked);

  [Table('Customers')]
  TCustomer = class
  private
    FId: IntType;
    FName: StringType;
    FEmail: StringType;
    FStatus: TCustomerStatus;
    FTotalSpent: FloatType;
  public
    [PK, AutoInc]
    property Id: IntType read FId write FId;
    
    [Column('name')]
    property Name: StringType read FName write FName;
    
    [Column('email')]
    property Email: StringType read FEmail write FEmail;
    
    [Column('status')]
    property Status: TCustomerStatus read FStatus write FStatus;
    
    [Column('total_spent')]
    property TotalSpent: FloatType read FTotalSpent write FTotalSpent;
  end;

implementation

end.
