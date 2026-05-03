unit TestLazyLoadingRelationships;

interface

uses
  System.SysUtils,
  System.Rtti,
  Dext.Assertions,
  Dext.Testing.Attributes,
  Dext.Entity.Attributes,
  Dext.Collections,
  Dext.Types.Lazy,
  Dext.Core.Reflection;

type
  [Table('CoursesLazy')]
  TCourseLazy = class
  private
    FId: Integer;
    FTitle: string;
  public
    [PK] property Id: Integer read FId write FId;
    property Title: string read FTitle write FTitle;
  end;

  [Table('StudentsLazy')]
  TStudentLazyTest = class
  private
    FId: Integer;
    FCourses: Lazy<IList<TCourseLazy>>;
  public
    [PK] property Id: Integer read FId write FId;
    [ManyToMany('StudentCourses', 'student_id', 'course_id')]
    property Courses: Lazy<IList<TCourseLazy>> read FCourses write FCourses;
  end;

  [TestFixture('Lazy Loading Relationship Tests')]
  TLazyLoadingRelationshipTests = class
  public
    [Test] procedure TestManyToMany_LazyConfiguration;
  end;

implementation

{ TLazyLoadingRelationshipTests }

procedure TLazyLoadingRelationshipTests.TestManyToMany_LazyConfiguration;
var
  Ctx: TRttiContext;
  Field: TRttiField;
  Student: TStudentLazyTest;
  Typ: TRttiType;
  Prop: TRttiProperty;
begin
  Student := TStudentLazyTest.Create;
  try
    Ctx := TRttiContext.Create;
    try
      Typ := Ctx.GetType(TStudentLazyTest);
      Field := Typ.GetField('FCourses');
      
      Should(Field).NotBeNil;
      Should(Field.FieldType.Name).Contain('Lazy<');
      
      Prop := Typ.GetProperty('Courses');
      Should(Prop).NotBeNil;
      // Using non-generic HasAttribute to be extra safe with compiler stability
      Should(Prop.HasAttribute(ManyToManyAttribute)).BeTrue;
    finally
      Ctx.Free;
    end;
  finally
    Student.Free;
  end;
end;

end.
