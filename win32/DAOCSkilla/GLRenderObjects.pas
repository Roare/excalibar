unit GLRenderObjects;

interface

uses
  Windows, SysUtils, Classes, Graphics, Contnrs, GL, GLext, DDSImage;

type
  TGLRenderObject = class(TObject)
  private
  protected
    FColor:   TColor;
    FName:    string;
    FOffsetY: integer;
    FOffsetX: integer;
    FUseColor: boolean;
  public
    constructor Create; virtual;

    procedure SetColorFromString(const AColor: string);

    procedure GLInitialize; virtual;
    procedure GLRender; virtual;
    procedure GLCleanup; virtual;

    property Color: TColor read FColor write FColor;
    property Name: string read FName write FName;
    property OffsetX: integer read FOffsetX write FOffsetX;
    property OffsetY: integer read FOffsetY write FOffsetY;
  end;

  TGLCallListObject = class(TGLRenderObject)
  protected
    FGLList:    GLuint;
  public
    procedure GLInitialize; override;
    procedure GLRender; override;
    procedure GLCleanup; override;
  end;

  TRangeCircle = class(TGLCallListObject)
  private
    FRange:       integer;
    FSmoothness:  integer;
    procedure SetSmoothness(const Value: integer);
  public
    constructor Create; override;
    constructor CreateRange(ARange, ASmoothness: integer);

    procedure GLInitialize; override;

    property Range: integer read FRange write FRange;
    property Smoothness: integer read FSmoothness write SetSmoothness;
  end;

  TRangeCircleList = class(TGLRenderObject)
  private
    FList:  TObjectList;
    function GetItems(I: integer): TRangeCircle;
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure GLInitialize; override;
    procedure GLRender; override;
    procedure GLCleanup; override;

    procedure Add(ACircle: TRangeCircle);
    property Items[I: integer]: TRangeCircle read GetItems; default;
  end;

  TMapElementPoint = class(TGLRenderObject)
  private
    FY: GLuint;
    FX: GLuint;
    FZ: GLuint;
  public
    constructor Create; override;
    procedure GLRender; override;

    property X: GLuint read FX write FX;
    property Y: GLuint read FY write FY;
    property Z: GLuint read FZ write FZ;
  end;

  PMapElementLinePoint = ^TMapElementLinePoint;
  TMapElementLinePoint = record
    X, Y, Z:    GLint;
  end;

  TMapElementLine = class(TGLCallListObject)
  private
    FBounds: TRect;
  protected
    FPoints:    TList;
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure GLInitialize; override;

    procedure AddPoint(X, Y, Z: GLint);
    procedure ClearPoints;

    property Bounds: TRect read FBounds;
  end;

  TMapElementTerrrainTexture = class(TGLRenderObject)
  private
    FGLTexture:   GLuint;
    FDDSChunk:    TDDSImagePixelsChunk;
    FBounds: TRect;
    
    procedure UploadTexture;
  public
    destructor Destroy; override;

    procedure GLRender; override;
    procedure GLCleanup; override;

    procedure TakeDDSChunk(X, Y, AScale: integer; ADDSChunk: TDDSImagePixelsChunk);

    property Bounds: TRect read FBounds;
  end;

  T3DArrowHead = class(TGLCallListObject)
  private
    FSize: integer;
    procedure SetSize(const Value: integer);
  public
    constructor Create; override;
    procedure GLInitialize; override;

    property Size: integer read FSize write SetSize;
  end;

  T3DPyramid = class(TGLCallListObject)
  private
    FSize: integer;
    procedure SetSize(const Value: integer);
  public
    constructor Create; override;
    procedure GLInitialize; override;

    property Size: integer read FSize write SetSize;
  end;

procedure SetGLColorFromTColor(AColor: TColor; AAlpha: GLfloat);
procedure SetGLColorFromTColorDarkened(AColor: TColor; AAlpha: GLfloat; ADark: GLfloat);

implementation

uses Types;

const
  D_TO_R = PI / 180;
  RGB_SCALE = 1 / 255;

procedure SetGLColorFromTColor(AColor: TColor; AAlpha: GLfloat);
var
  R, G, B: BYTE;
begin
  R := GetRValue(AColor);
  G := GetGValue(AColor);
  B := GetBValue(AColor);
  glColor4f(R * RGB_SCALE, G  * RGB_SCALE, B  * RGB_SCALE, AAlpha);
end;

procedure SetGLColorFromTColorDarkened(AColor: TColor; AAlpha: GLfloat; ADark: GLfloat);
begin
  glColor4f(
    GetRValue(AColor) * ADark * RGB_SCALE,
    GetGValue(AColor) * ADark * RGB_SCALE,
    GetBValue(AColor) * ADark * RGB_SCALE,
    AAlpha);
end;

{ TRangeCircle }

constructor TRangeCircle.Create;
begin
  inherited;
  FColor := clWhite;
  FRange := 500;
  FSmoothness := 36;
end;

constructor TRangeCircle.CreateRange(ARange, ASmoothness: integer);
begin
  inherited Create;

  FColor := clWhite;
  FRange := ARange;
  FSmoothness := ASmoothness;
end;

procedure TRangeCircle.GLInitialize;
var
  I:    integer;
begin
  inherited;

  glNewList(FGLList, GL_COMPILE);

  I := -180;
  glBegin(GL_LINE_LOOP);
  while I < 180 do begin
    glVertex3f(FRange * cos(I * D_TO_R), FRange * sin(I * D_TO_R), 0);
    inc(I, 360 div FSmoothness);
  end;
  glEnd();

  glEndList;
end;

procedure TRangeCircle.SetSmoothness(const Value: integer);
begin
  if 360 mod Value <> 0 then
    raise Exception.Create('Range Cicle smoothness must divide 360 evenly'); 
  FSmoothness := Value;
end;

{ TRangeCircleList }

procedure TRangeCircleList.Add(ACircle: TRangeCircle);
begin
  FList.Add(ACircle);
end;

constructor TRangeCircleList.Create;
begin
  inherited;
  FList := TObjectList.Create;
end;

destructor TRangeCircleList.Destroy;
begin
  FList.Free;
  inherited;
end;

function TRangeCircleList.GetItems(I: integer): TRangeCircle;
begin
  Result := TRangeCircle(FList[I]);
end;

procedure TRangeCircleList.GLCleanup;
var
  I:    integer;
begin
  for I := 0 to FList.Count - 1 do
    Items[I].GLCleanup;
    
  inherited;
end;

procedure TRangeCircleList.GLInitialize;
var
  I:    integer;
begin
  for I := 0 to FList.Count - 1 do
    Items[I].GLInitialize;

  inherited;
end;

procedure TRangeCircleList.GLRender;
var
  I:    integer;
begin
  inherited;

  glLineWidth(1.0);
  for I := 0 to FList.Count - 1 do
    Items[I].GLRender;
end;

{ TGLRenderObject }

constructor TGLRenderObject.Create;
begin
  FColor := clWhite;
  FUseColor := true;
end;

procedure TGLRenderObject.GLCleanup;
begin
;
end;

procedure TGLRenderObject.GLInitialize;
begin
;
end;

procedure TGLRenderObject.GLRender;
begin
  if FUseColor then
    SetGLColorFromTColor(FColor, 1);
end;

procedure TGLRenderObject.SetColorFromString(const AColor: string);
begin
  if AnsiSameText(AColor, 'white') then
    FColor := clWhite
  else if AnsiSameText(AColor, 'gray') then
    FColor := clSilver
  else if AnsiSameText(AColor, 'green') then
    FColor := clLime
  else if AnsiSameText(AColor, 'brown') then
    FColor := $004080
  else if AnsiSameText(AColor, 'orange') then
    FColor := $007fff
  else if AnsiSameText(AColor, 'blue') then
    FColor := clBlue
  else if AnsiSameText(AColor, 'red') then
    FColor := clRed
  else if AnsiSameText(AColor, 'pink') then
    FColor := $ffcff
  else if AnsiSameText(AColor, 'yellow') then
    FColor := clYellow
  else if AnsiSameText(AColor, 'cyan') then
    FColor := clAqua
  else if AnsiSameText(AColor, 'magenta') then
    FColor := clMaroon
  else if AnsiSameText(AColor, 'gold') then
    FColor := $00ccff
  else if AnsiSameText(AColor, 'darkgreen') then
    FColor := clGreen
  else if AnsiSameText(AColor, 'purple') then
    FColor := clFuchsia
  else if AnsiSameText(AColor, 'silver') then
    FColor := clSilver
  else if AnsiSameText(AColor, 'black') then
    FColor := clBlack
  else if AnsiSameText(AColor, 'darkgray') then
    FColor := clGray
  else
    FColor := clFuchsia;
end;

{ TGLCallListObject }

procedure TGLCallListObject.GLCleanup;
begin
  if FGLList <> 0 then begin
    glDeleteLists(FGLList, 1);
    FGLList := 0;
  end;

  inherited;
end;

procedure TGLCallListObject.GLInitialize;
begin
  inherited;

  FGLList := glGenLists(1);
end;

procedure TGLCallListObject.GLRender;
begin
  inherited;
  glCallList(FGLList);
end;

{ TMapElementPoint }

constructor TMapElementPoint.Create;
begin
  inherited;
  FColor := clWhite;
end;

procedure TMapElementPoint.GLRender;
begin
  inherited;

  glBegin(GL_POINTS);
    glVertex3i(X, Y, 0);  // Z
  glEnd();
end;

{ TMapElementLine }

procedure TMapElementLine.AddPoint(X, Y, Z: GLint);
var
  pTmp:   PMapElementLinePoint;
begin
  inc(X, FOffsetX);
  inc(Y, FOffsetY);

  New(pTmp);
  FPoints.Add(pTmp);
  pTmp^.X := X;
  pTmp^.Y := Y;
  pTmp^.Z := Z;

  if FPoints.Count = 1 then
    FBounds := Rect(X, Y, X, Y)
  else begin
    if X < FBounds.Left then
      FBounds.Left := X;
    if Y < FBounds.Top then
      FBounds.Top := Y;
    if X > FBounds.Right then
      FBounds.Right := Y;
    if Y > FBounds.Bottom then
      FBounds.Bottom := Y;
  end;
end;

procedure TMapElementLine.ClearPoints;
var
  I:    integer;
begin
  for I := 0 to FPoints.Count - 1 do
    Dispose(PMapElementLinePoint(FPoints[I]));
  FPoints.Clear;
end;

constructor TMapElementLine.Create;
begin
  inherited;
  FPoints := TList.Create;
end;

destructor TMapElementLine.Destroy;
begin
  ClearPoints;
  FPoints.Free;
  inherited;
end;

procedure TMapElementLine.GLInitialize;
var
  I:  integer;
begin
  inherited;
  glNewList(FGLList, GL_COMPILE);

  glBegin(GL_LINE_STRIP);
  for I := 0 to FPoints.Count - 1 do
    with PMapElementLinePoint(FPoints[I])^ do
      glVertex3f(X, Y, 0);  // Z
  glEnd();

  glEndList();
end;

{ TMapElementTerrrainTexture }

destructor TMapElementTerrrainTexture.Destroy;
begin
  FDDSChunk.Free;
  FDDSChunk := nil;
  inherited;
end;

procedure TMapElementTerrrainTexture.GLCleanup;
begin
  if FGLTexture <> 0 then begin
    glDeleteTextures(1, @FGLTexture);
    FGLTexture := 0;
  end;

  FreeAndNil(FDDSChunk);

  inherited;
end;

procedure TMapElementTerrrainTexture.GLRender;
begin
  inherited;

  if (FGLTexture = 0) and Assigned(FDDSChunk) then
    UploadTexture;

  glColor3f(1, 1, 1);
  glBindTexture(GL_TEXTURE_2D, FGLTexture);
  glBegin(GL_QUADS);
    glTexCoord2f(0, 0);
    glVertex2i(FBounds.Left, FBounds.Top);
    glTexCoord2f(1, 0);
    glVertex2i(FBounds.Right, FBounds.Top);
    glTexCoord2f(1, 1);
    glVertex2i(FBounds.Right, FBounds.Bottom);
    glTexCoord2f(0, 1);
    glVertex2i(FBounds.Left, FBounds.Bottom);
  glEnd;
end;

procedure TMapElementTerrrainTexture.TakeDDSChunk(X, Y, AScale: integer;
  ADDSChunk: TDDSImagePixelsChunk);
begin
  FBounds.Left := FOffsetX + (X * AScale);
  FBounds.Top := FOffsetY + (Y * AScale);
  FBounds.Right := FBounds.Left + (ADDSChunk.Width * AScale);
  FBounds.Bottom := FBounds.Top + (ADDSChunk.Height * AScale);

  FreeAndNil(FDDSChunk);
  FDDSChunk := ADDSChunk;
end;

procedure TMapElementTerrrainTexture.UploadTexture;
begin
  if not Assigned(FDDSChunk) then
    exit;

  glGenTextures(1, @FGLTexture);
  glBindTexture(GL_TEXTURE_2D, FGLTexture);

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

  glCompressedTexImage2D(GL_TEXTURE_2D, 0, FDDSChunk.internalFormat,
    FDDSChunk.Width, FDDSChunk.Height, 0, FDDSChunk.PixelsSize, FDDSChunk.Pixels);

  FreeAndNil(FDDSChunk);
end;

{ T3DArrowHead }

constructor T3DArrowHead.Create;
begin
  inherited;
  FSize := 150;
  FUseColor := false;
end;

procedure T3DArrowHead.GLInitialize;
var
  w:  integer;
  l:  integer;
begin
  inherited;
  w := FSize;
  l := w * 2;

  glEdgeFlag(GL_TRUE);
  glNewList(FGLList, GL_COMPILE);

  glBegin(GL_TRIANGLE_FAN);
    glVertex3i(0, 0, w);

    glNormal3f(-(l+w), w, l);
    glVertex3i(-w, -w, 0);
    glVertex3i(0, l, 0);

    glNormal3f(l+w, w, l);
    glVertex3i(w, -w, 0);

    glNormal3f(0, -w, w);
    glVertex3i(-w, -w, 0);
  glEnd();
  glEndList();
end;

procedure T3DArrowHead.SetSize(const Value: integer);
begin
  FSize := Value;
end;

{ T3DPyramid }

constructor T3DPyramid.Create;
begin
  inherited;
  FSize := 150;
end;

procedure T3DPyramid.GLInitialize;

begin
  inherited;

  glEdgeFlag(GL_TRUE);
  glNewList(FGLList, GL_COMPILE);

  glBegin(GL_TRIANGLE_FAN);
    glVertex3i(0,0,FSize);

    glNormal3f(0,FSize,FSize);
    glVertex3i(-FSize,FSize,-FSize);
    glVertex3i(FSize,FSize,-FSize);

    glNormal3f(FSize,0,FSize);
    glVertex3i(FSize,-FSize,-FSize);

    glNormal3f(0,-FSize,FSize);
    glVertex3i(-FSize,-FSize,-FSize);

    glNormal3f(-FSize,0,FSize);
    glVertex3i(-FSize,FSize,-FSize);
  glEnd();
  glEndList();
end;

procedure T3DPyramid.SetSize(const Value: integer);
begin
  FSize := Value;
end;

end.
