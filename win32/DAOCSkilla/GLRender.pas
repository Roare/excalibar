unit GLRender;

interface

uses
{$IFDEF LINUX}
  QForms, QControls, QGraphics,
{$ELSE}
  Windows, Messages, Controls, Forms, Graphics, MMSystem,
  StdCtrls, ExtCtrls, ComCtrls, Dialogs,
{$ENDIF !LINUX}
  SysUtils, Classes, glWindow, GL, GLU, GLext, DAOCConnection, DAOCObjs,
  GLRenderObjects, MapElementList, DAOCRegion, RenderPrefs, DAOCClasses,
  QuickSinCos, BackgroundHTTP, TexFont, GLUT;

type
  { A simple list box that you can prevent drawing }
  TLockableListBox = class(TListBox)
  private
    FLocked: boolean;
  protected
{$IFDEF MSWINDOWS}
    procedure WMEraseBkgnd(var Message: TWmEraseBkgnd); message WM_ERASEBKGND;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
{$ENDIF}
{$IFDEF LINUX}
    function WidgetFlags: integer; override;
{$ENDIF}
  public
    constructor Create(AOwner: TComponent); override;

    property Locked: boolean read FLocked write FLocked;
  end;

  TfrmGLRender = class(TForm)
    slideZoom: TTrackBar;
    tmrMinFPS: TTimer;
    pnlMap: TPanel;
    pnlLeft: TPanel;
    lblObjCounts: TLabel;
    pnlGridHeader: TPanel;
    procedure glMapDraw(Sender: TObject);
    procedure glMapInit(Sender: TObject);
    procedure glMapResize(Sender: TObject);
    procedure slideZoomChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure glMapClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure tmrMinFPSTimer(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure glMapMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure lstObjectsDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure glMapMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure MobListMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pnlLeftEndDock(Sender, Target: TObject; X, Y: Integer);
  private
    glMap:     TglWindow;
    FDControl: TDAOCConnection;
    FRange:         Cardinal;
    FRenderBounds:  TRect;
    FGLInitsCalled:       boolean;
    FDirty:   boolean;
    FInvaderHighlight:    boolean;
    FInvaderHighlightLastSwap:  Cardinal;
    FMapElementsListList:   TVectorMapElementListList;
    FMapTexturesListList:   TTextureMapElementListList;
    FRangeCircles:  TRangeCircleList;
    FMobTriangle:   T3DArrowHead;
    FObjectTriangle:    T3DPyramid;
    FGroundTarget:      TGLBullsEye;
    FVisibleRangeRep:   TGLFlatViewFrustum;
    FMapToPlayerOffset: TPoint;
    FFilteredObjects:   TDAOCObjectList;
    FRenderPrefs:   TRenderPreferences;
    FPrefsFile:     string;
    FFrameStats:    string;
    FFrameCount:    integer;
    FDirtyCount:    integer;
    FInvalidateCount: integer;
    FZoneName:      string;
    FLastInvaderWarningTicks:   Cardinal;
    FBoat:    TGLBoat;
    FTargetHUDWidth:  integer;
    FMouseLocX:   Cardinal;
    FMouseLocY:   Cardinal;
    FHTTPFetch:   TBackgroundHTTPManager;
    FTxfH10:      TTexFont;
    FTxfH12:      TTexFont;
    lstObjects:   TLockableListBox;
    FPushPins:    TVectorMapElementList;
    FUnknownStealther:  TGLUnkownStealther;
    FPresicenceNode:    TGLPrescienceNode;
    FBasePath:    string;
    FMaxTXFTextWidth:   integer;

    procedure GLInits;
    procedure GLCleanups;
    procedure SetupRadarProjectionMatrix;
    procedure SetupScreenProjectionMatrix;
    procedure CheckGLError;

    procedure DrawMapRulers;
    procedure DrawRangeCircles;
    procedure DrawPlayerTriangle;
    procedure DrawLineToSelected;
    procedure DrawMobsAndPlayers;
    procedure DrawMapElements;
    procedure DrawPlayerHighlightRing(ADAOCObject: TDAOCPlayer);
    procedure DrawTargetHUD;
    procedure DrawLocalPlayerHUD;
    procedure DrawMobTypeTag(AMob: TDAOCMob);
    procedure DrawGroundTarget;
    procedure DrawFrameStats;
    procedure DrawStealtherAlert;
    procedure DrawLineToMobTarget(AMob: TDAOCMob);
    procedure DrawAIDestination(AObj: TDAOCObject; AColor: TColor);
    procedure DrawGrid;
    procedure DrawMouseTooltip;
    procedure DrawUnknownStealthers;

    procedure SetDControl(const Value: TDAOCConnection);
    procedure Log(const s: string);
    procedure RefreshFilteredList;
    procedure GridSelectObject(ADAOCObject: TDAOCObject);
    function FilteredObjectInsert(ADAOCObject: TDAOCObject) : integer;
    function FilteredObjectInsertByName(ADAOCObject: TDAOCObject) : integer;
    function FilteredObjectInsertByDistance(ADAOCObject: TDAOCObject) : integer;
    procedure UpdateObjectCounts;
    function SetObjectListRowCount(ACount: integer) : boolean;
    procedure RENDERPrefsObjectFilterChanged(Sender: TObject);
    procedure RENDERPrefsMobListOptionChanged(Sender: TObject);
    procedure RENDERPrefsMobTriangleSizeChanged(Sender: TObject);
    procedure UpdateFrameStats(ATime: integer);
    procedure InvalidateListObject(AObj: TDAOCObject);
    procedure UpdateStayOnTop;
    procedure ReloadMapElementsAndTextures;
    procedure DoPrefsDialog;
    function PlayerMobListText(AMob: TDAOCPlayer) : string;
    procedure MapUnproject(var X, Y: Cardinal; ANeedMVPSetup: boolean);
    function CompareObjectClasses(A, B: TDAOCObjectClass): integer;
    procedure UpdateMapURLs;
    function WriteTXFTextH10(X, Y: integer; const s: string) : integer;
    function WriteTXFTextH12(X, Y: integer; const s: string) : integer;
    procedure CreateObjectListBox;
    procedure LoadRegionPushpins;
    procedure AddPushPin;
    procedure SetSmoothingOpts;
    procedure CreateGLWindow;
    procedure AdjustMobTriangleSize;
    function ZDeltaStr(AObj: TDAOCObject; AVerbose: boolean) : string;
    procedure DisplaySelectedObjectInventory;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    procedure DAOCAddObject(AObj: TDAOCObject);
    procedure DAOCDeleteObject(AObj: TDAOCObject);
    procedure DAOCUpdateObject(AObj: TDAOCObject);
    procedure DAOCSelectedObjectChanged(AObj: TDAOCObject);
    procedure DAOCRegionChanged;
    procedure DAOCZoneChanged;
    procedure DAOCSetGroundTarget;
    procedure DAOCCharacterLogin;
    procedure DAOCPlayerPosUpdate;
    procedure DAOCUnknownStealther(AObj: TDAOCObject);

    procedure Dirty;
    property DAOCControl: TDAOCConnection read FDControl write SetDControl;
    property PrefsFile: string read FPrefsFile write FPrefsFile;
    property RangeCircles: TRangeCircleList read FRangeCircles;
  end;

var
  frmGLRender: TfrmGLRender;

implementation

uses Unit1, GlobalTickCounter, AddPushPin;

const
  COL_NAME = 0;
  COL_LEVEL = 1;
  COL_HEALTH = 2;

resourcestring
  S_CAPTION_SUFFIX = ' -- Press F1 for options';

{$R *.dfm}

function RealmColor(ARealm: TDAOCRealm) : TColor;
begin
  case ARealm of
    drNeutral:  Result := clWhite;
    drAlbion:   Result := clRed;
    drMidgard:  Result := $efae00;
    drHibernia: Result := $33cc33;
    else
      Result := clFuchsia;
  end;
end;

function ListDeadRealmColor(ARealm: TDAOCRealm) : TColor;
begin
  case ARealm of
    drNeutral:  Result := clWhite;
    drAlbion:   Result := $ccccff;
    drMidgard:  Result := $ffcccc;
    drHibernia: Result := $ccffcc;
    else
      Result := clFuchsia;
  end;
end;

function min(a, b: integer) : integer;
begin
  if a < b then
    Result := a
  else
    Result := b;
end;

function GetGLVersion : string;
begin
    { must have a current GL context active this function is called }
  Result := string(PChar(glGetString(GL_VERSION)));
end;

{ TLockableListBox }

constructor TLockableListBox.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csOpaque];
end;

{$IFDEF LINUX}
function TLockableListBox.WidgetFlags: integer;
begin
  Result := inherited WidgetFlags or integer(WidgetFlags_WRepaintNoErase) or
    integer(WidgetFlags_WResizeNoErase);
end;
{$ENDIF LINUX}

{$IFDEF MSWINDOWS}
procedure TLockableListBox.WMEraseBkgnd(var Message: TWmEraseBkgnd);
begin
    { redraw the background only if our list doesn't fill the whole area }
  if not FLocked and ((Count * ItemHeight) < Height) then
    inherited
  else
    Message.Result := 1;
end;

procedure TLockableListBox.WMPaint(var Message: TWMPaint);
begin
  if not FLocked then
    inherited;
end;
{$ENDIF MSWINDOWS}

{ TfrmGLRender }

procedure TfrmGLRender.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params do begin
//    ExStyle := ExStyle or WS_EX_TOPMOST;
    WndParent := GetDesktopWindow;
  end;
end;

procedure TfrmGLRender.SetDControl(const Value: TDAOCConnection);
begin
  FDControl := Value;
end;

procedure TfrmGLRender.glMapDraw(Sender: TObject);
var
  dwStartTickCount:  Cardinal;
begin
  if not Assigned(FDControl) then
    exit;

  try
    if not FGLInitsCalled then
      GLInits;

    dwStartTickCount := GetTickCount;
    if FInvaderHighlightLastSwap + 1000 < dwStartTickCount then begin
      UpdateFrameStats(dwStartTickCount - FInvaderHighlightLastSwap);
      FDControl.CheckForStaleObjects;
      FInvaderHighlightLastSwap := dwStartTickCount;
      FInvaderHighlight := not FInvaderHighlight;
    end;

    glClear(GL_COLOR_BUFFER_BIT);

    SetupRadarProjectionMatrix;
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    SetSmoothingOpts;
      { at origin }
    if GetAsyncKeyState(VK_CONTROL) <> 0 then
      MapUnproject(FMouseLocX, FMouseLocY, false);
    DrawMapElements;
    DrawGrid;
    DrawUnknownStealthers;
    DrawMobsAndPlayers;
    DrawLineToSelected;
    DrawGroundTarget;

    glTranslatef(FDControl.LocalPlayer.XProjected, FDControl.LocalPlayer.YProjected, 0);

      { at player pos }
    DrawMapRulers;
    DrawRangeCircles;
    DrawPlayerTriangle;

      { in a screen-size ortho }
    SetupScreenProjectionMatrix;
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity;
    DrawTargetHUD;
    DrawLocalPlayerHUD;
    DrawFrameStats;
    DrawMouseTooltip;
    DrawStealtherAlert;

    CheckGLError();

    inc(FFrameCount);
    FDirty := false;
  except
    on e: Exception do
      Log('RenderError: ' + e.Message);
  end;
end;

procedure TfrmGLRender.glMapInit(Sender: TObject);
const
  lightpos: array[0..3] of GLfloat = (-0.5, 0.0, 1.0, 0.0);
  diffuse: array[0..3] of GLfloat = (1.0, 1.0, 1.0, 1.0);
  ambient: array[0..3] of GLfloat = (0.0, 0.0, 0.0, 1.0);
  material: array[0..3] of GLfloat = (1.0, 1.0, 1.0, 1.0);
begin
  glClearColor(0, 0, 0, 0);
  glPointSize(3);

  glEnable(GL_CULL_FACE);
  glFrontFace(GL_CCW);
  glCullFace(GL_BACK);

  glShadeModel(GL_FLAT);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  glDisable(GL_DEPTH_TEST);
  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);
  glEnable(GL_COLOR_MATERIAL);
  glEnable(GL_NORMALIZE);
  glEnable(GL_BLEND);

  glColorMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE);
  glLightfv(GL_LIGHT0, GL_POSITION, @lightpos);
  glLightfv(GL_LIGHT0, GL_DIFFUSE, @diffuse);
  glLightfv(GL_LIGHT0, GL_AMBIENT, @ambient);
  glMaterialfv(GL_FRONT, GL_AMBIENT, @material);
  glMaterialfv(GL_FRONT, GL_DIFFUSE, @material);

  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  FGLInitsCalled := false;
  CheckGLError;
end;

procedure TfrmGLRender.glMapResize(Sender: TObject);
begin
  glViewport(0, 0, glMap.Width, glMap.Height);
  CheckGLError;
end;

procedure TfrmGLRender.slideZoomChange(Sender: TObject);
begin
  FRange := slideZoom.Position;
  if FRenderPrefs.ScaleMobTriangle then
    AdjustMobTriangleSize;

  Dirty;
end;

procedure TfrmGLRender.FormShow(Sender: TObject);
begin
  if FPrefsFile <> '' then begin
    FRenderPrefs.LoadSettings(FPrefsFile);
    FRangeCircles.LoadFromFile(FPrefsFile);
    Left := FRenderPrefs.Left;
    Top := FRenderPrefs.Top;
    Width := FRenderPrefs.Width;
    Height := FRenderPrefs.Height;
    FRange := FRenderPrefs.Range;
    slideZoom.Position := FRange;
    UpdateStayOnTop;
    
    FMapTexturesListList.AttemptDownload := FRenderPrefs.AttemptMapDownload;
    FMapElementsListList.AttemptDownload := FRenderPrefs.AttemptMapDownload;
    UpdateMapURLs;
  end
  else
    slideZoomChange(Self);
end;

procedure TfrmGLRender.Log(const s: string);
begin
  frmMain.Log(s);
end;

procedure TfrmGLRender.CheckGLError;
var
  err:  GLenum;
begin
  err := glGetError();
  if err <> GL_NO_ERROR then
    Log(string(PChar(gluErrorString(err))));
end;

procedure TfrmGLRender.DrawMapRulers;
var
  r:      GLfloat;
  s, c:   single;
begin
  if not FRenderPrefs.DrawRulers then
    exit;

  glDisable(GL_LIGHTING);

  r := FRange * 1.5;
  sincos_quick(FDControl.LocalPlayer.Head, s, c);

    { Draw map rulers }
  glLineWidth(1.0);
  glBegin(GL_LINES);
    glColor3f(0.45, 0.45, 0.45);
    glVertex3f(-r, 0, 0);
    glVertex3f(r, 0, 0);
    glVertex3f(0, -r, 0);
    glVertex3f(0, r, 0);

    glColor3f(0.6, 0.6, 0.6);
    glVertex3f(0, 0, 0);
    glVertex3f(-s * r, c * r, 0);
  glEnd();
end;

procedure TfrmGLRender.DrawPlayerTriangle;
begin
  glEnable(GL_LIGHTING);
  glRotatef(FDControl.LocalPlayer.Head, 0, 0, 1);

  if FRenderPrefs.ViewFrustum then
    FVisibleRangeRep.GLRender(FRenderBounds);

  glColor3f(1, 1, 0);
  FMobTriangle.GLRender(FRenderBounds);
end;

procedure TfrmGLRender.DrawRangeCircles;
begin
  if not FRenderPrefs.DrawRangeCircles then
    exit;

  glDisable(GL_LIGHTING);
  FRangeCircles.GLRender(FRenderBounds);
end;

procedure TfrmGLRender.Dirty;
begin
  inc(FDirtyCount);
  if not FDirty then begin
    inc(FInvalidateCount);

    FDirty := true;
    glMap.Invalidate;
//    lstObjects.Invalidate;
  end;
end;

procedure TfrmGLRender.DAOCAddObject(AObj: TDAOCObject);
var
  iOldIndex:  integer;
  iOldTop:    integer;
  iPos:       integer;
begin
  if FRenderPrefs.IsObjectInFilter(AObj) then begin
    iPos := FilteredObjectInsert(AObj);

    UpdateObjectCounts;
    lstObjects.Locked := true;

    iOldIndex := lstObjects.ItemIndex;
    iOldTop := lstObjects.TopIndex;
    SetObjectListRowCount(FFilteredObjects.Count);

      { if we inserted an object before the selected index, update the
        selected index to keep it the same }
    if iPos <= iOldIndex then
      SendMessage(lstObjects.Handle, LB_SETCURSEL, iOldIndex + 1, 0)
    else if iOldIndex <> -1 then
      SendMessage(lstObjects.Handle, LB_SETCURSEL, iOldIndex, 0);

    if iPos <= iOldTop then
      SendMessage(lstObjects.Handle, LB_SETTOPINDEX, iOldTop + 1, 0)
    else
      SendMessage(lstObjects.Handle, LB_SETTOPINDEX, iOldTop, 0);

    lstObjects.Locked := false;
    lstObjects.Invalidate;

    if FRenderPrefs.RedrawOnAdd then
      Dirty;

{$IFDEF MSWINDOWS}
    if FRenderPrefs.InvaderWarning and
      (AObj.ObjectClass = ocPlayer) and
      (AObj.Realm <> FDControl.LocalPlayer.Realm) and AObj.IsAlive then
      if GlobalTickCount - FLastInvaderWarningTicks >= FRenderPrefs.InvaderWarnMinTicks then begin
        // Log('Invader: ' + AObj.Name);
        PlaySound('invader.wav', 0, SND_FILENAME or SND_ASYNC or SND_NOWAIT);
        FLastInvaderWarningTicks := GlobalTickCount;
      end;
{$ENDIF MSWINDOWS}
  end;  { if onject in filter }
end;

procedure TfrmGLRender.DAOCDeleteObject(AObj: TDAOCObject);
var
  iOldPos:  integer;
  iOldTop:  integer;
  iPos:     integer;
begin
  if FRenderPrefs.IsObjectInFilter(AObj) then begin
    iPos := FFilteredObjects.Remove(AObj);
    if iPos = -1 then begin
      Log('Removing: ' + AObj.Name + ' not in list');
      exit;
    end;

    UpdateObjectCounts;
    lstObjects.Locked := true;

    iOldPos := lstObjects.ItemIndex;
    iOldTop := lstObjects.TopIndex;
    SetObjectListRowCount(FFilteredObjects.Count);
    if iPos <= iOldPos then
      SendMessage(lstObjects.Handle, LB_SETCURSEL, iOldPos - 1, 0)
    else
      SendMessage(lstObjects.Handle, LB_SETCURSEL, iOldPos, 0);

    if (iPos <= iOldTop) and (iOldTop > 0) then
      SendMessage(lstObjects.Handle, LB_SETTOPINDEX, iOldTop - 1, 0)
    else if iOldTop < lstObjects.Items.Count then
      SendMessage(lstObjects.Handle, LB_SETTOPINDEX, iOldTop, 0);

    lstObjects.Locked := false;
    lstObjects.Invalidate;

    if FRenderPrefs.RedrawOnDelete then
      Dirty;
  end;
end;

procedure TfrmGLRender.DAOCUpdateObject(AObj: TDAOCObject);
begin
  if AObj.HitPoints <> AObj.HitPointsLast then
    InvalidateListObject(AObj);
    { RefreshFilteredList calls Dirty for us }
  if FRenderPrefs.MobListSortOrder = msoDistance then
    RefreshFilteredList
  else if FRenderPrefs.RedrawOnUpdate then
    Dirty;
end;

procedure TfrmGLRender.glMapClick(Sender: TObject);
var
  pNearest: TDAOCObject;
  x, y:     Cardinal;
begin
  if not FRenderPrefs.TrackMapClick then
    exit;

  MapUnproject(X, Y, true);

    { if this is a dungeon, use 3d distance else use 2d }
  if Assigned(FDControl.Zone) and (FDControl.Zone.ZoneType = dztDungeon) then
    pNearest := FFilteredObjects.FindNearest3D(x, y, FDControl.LocalPlayer.Z)
  else
    pNearest := FFilteredObjects.FindNearest2D(x, y);

  if Assigned(pNearest) then begin
    if FRenderPrefs.TrackInGameSelect then
        { callback will update screen }
      FDControl.SelectedObject := pNearest
    else
      GridSelectObject(pNearest);
    Dirty;
  end;  { if pNearest }
end;

procedure TfrmGLRender.DrawLineToSelected;
var
  pSelected:  TDAOCObject;
begin
  pSelected := FDControl.SelectedObject;
  if Assigned(pSelected) then begin
    glDisable(GL_LIGHTING);

    glColor3f(1.0, 1.0, 1.0);
    glLineWidth(2.0);
    glBegin(GL_LINES);
    glVertex3i(FDControl.LocalPlayer.XProjected, FDControl.LocalPlayer.YProjected, 0);
    if pSelected is TDAOCMovingObject then
      glVertex3i(TDAOCMovingObject(pSelected).XProjected, TDAOCMovingObject(pSelected).YProjected, 0)
    else
      glVertex3i(pSelected.X, pSelected.Y, 0);
    glEnd();
  end;
end;

procedure TfrmGLRender.DrawMobsAndPlayers;
var
  I:    integer;
  clMob:  TColor;
  pObj:   TDAOCObject;
  pMovingObj:  TDAOCMovingObject;
begin
  glEnable(GL_BLEND);
  glEnable(GL_LIGHTING);

  for I := 0 to FFilteredObjects.Count - 1 do begin
    pObj := FFilteredObjects[I];
    if pObj.ObjectClass in [ocUnknown, ocMob, ocPlayer] then begin
      pMovingObj := TDAOCMovingObject(pObj);
      if pObj.Stealthed then
        clMob := clBlack
      else
        clMob := pObj.GetConColor(FDControl.LocalPlayer.Level);

      DrawAIDestination(pObj, clMob);

      glTranslatef(pMovingObj.XProjected, pMovingObj.YProjected, 0);
      glRotatef(pObj.Head, 0, 0, 1);

      if pObj.ObjectClass = ocPlayer then
        DrawPlayerHighlightRing(TDAOCPlayer(pObj))
      else if FRenderPrefs.DrawTypeTag and (pObj.ObjectClass = ocMob) then
        DrawMobTypeTag(TDAOCMob(pObj));

      if pObj.LiveDataConfidence < LIVE_DATA_CONFIDENCE_MAX then
        SetGLColorFromTColor(clMob, pObj.LiveDataConfidencePct)
      else
        glColor3ubv(@clMob);
      FMobTriangle.GLRender(FRenderBounds);

      glRotatef(-pObj.Head, 0, 0, 1);
      glTranslatef(-pMovingObj.XProjected, -pMovingObj.YProjected, 0);
    end  { if a class to draw }

    else if pObj.ObjectClass = ocObject then begin
      glTranslatef(pObj.X, pObj.Y, 0);
      if AnsiSameText(pObj.Name, 'Prescience Node') then
        FPresicenceNode.GLRender(FRenderBounds)
      else
        FObjectTriangle.GLRender(FRenderBounds);
      glTranslatef(-pObj.X, -pObj.Y, 0);
    end

    else if pObj.ObjectClass = ocVehicle then begin
      DrawAIDestination(pObj, FBoat.Color);  // brown

      glPushMatrix();
      glTranslatef(TDAOCVehicle(pObj).XProjected, TDAOCVehicle(pObj).YProjected, 0);
      glRotatef(pObj.Head, 0, 0, 1);
      if pObj.LiveDataConfidence < LIVE_DATA_CONFIDENCE_MAX then
        FBoat.Alpha := pObj.LiveDataConfidencePct
      else
        FBoat.Alpha := 1;
      FBoat.GLRender(FRenderBounds);
      glPopMatrix();
    end;
  end;  { for each object }
end;

procedure TfrmGLRender.FormCreate(Sender: TObject);
begin
    { create the glwindow first in case other loads require a context }
  CreateGLWindow;

  FBasePath := ExtractFilePath(ParamStr(0));
  FRangeCircles := TRangeCircleList.Create;

  FTxfH10 := TTexFont.Create;
  FTxfH10.LoadFont(FBasePath + 'helvetica10.txf');
  FTxfH12 := TTexFont.Create;
  FTxfH12.LoadFont(FBasePath + 'helvetica12.txf');

  FHTTPFetch := TBackgroundHTTPManager.Create;

  FMapElementsListList := TVectorMapElementListList.Create;
  FMapElementsListList.VersionFile := FBasePath + 'versions.ini';
  FMapElementsListList.VectorMapDir := FBasePath + 'maps\';
  FMapElementsListList.VectorMapCustomDir := FBasePath + 'custommaps\';
  FMapElementsListList.HTTPFetch := FHTTPFetch;

  FMapTexturesListList := TTextureMapElementListList.Create;
  FMapTexturesListList.VersionFile := FBasePath + 'versions.ini';
  FMapTexturesListList.TextureMapDir := FBasePath + 'maps\dds\';
  FMapTexturesListList.TextureMapCustomDir := FBasePath + 'custommaps\dds\';
  FMapTexturesListList.HTTPFetch := FHTTPFetch;

  FMobTriangle := T3DArrowHead.Create;
  FPresicenceNode := TGLPrescienceNode.Create;
  FPresicenceNode.ImageFileName := FBasePath + 'prescience.tga';
  FObjectTriangle := T3DPyramid.Create;
  FGroundTarget := TGLBullsEye.Create;
  FVisibleRangeRep := TGLFlatViewFrustum.Create;
  FBoat := TGLBoat.Create;
  FFilteredObjects := TDAOCObjectList.Create(false);
  FPushPins := TVectorMapElementList.Create;
  FUnknownStealther := TGLUnkownStealther.Create;
  FRenderPrefs := TRenderPreferences.Create;
  FRenderPrefs.OnObjectFilterChanged := RENDERPrefsObjectFilterChanged;
  FRenderPrefs.OnMobListOptionsChanged := RENDERPrefsMobListOptionChanged;
  FRenderPrefs.OnMobTriangleSizeChanged := RENDERPrefsMobTriangleSizeChanged; 
  FRenderPrefs.HasOpenGL13 := Load_GL_version_1_3;
  FRenderPrefs.HasGLUT := Assigned(glutInit);

  if FRenderPrefs.HasOpenGL13 then
    Log('OpenGL 1.3:  Available (' + GetGLVersion + ')')
  else
    Log('OpenGL 1.3:  NOT FOUND (' + GetGLVersion + ')');

  if FRenderPrefs.HasGLUT then
    Log('OpenGL GLUT:  Available')
  else
    Log('OpenGL GLUT:  NOT FOUND');

  UpdateObjectCounts;
  CreateObjectListBox;
end;

procedure TfrmGLRender.FormDestroy(Sender: TObject);
begin
  GLCleanups;
  FFilteredObjects.Free;
  FMobTriangle.Free;
  FGroundTarget.Free;
  FVisibleRangeRep.Free;
  FObjectTriangle.Free;
  FMapElementsListList.Free;
  FMapTexturesListList.Free;
  FRangeCircles.Free;
  FRenderPrefs.Free;
  FHTTPFetch.Shutdown;
  FHTTPFetch.Free;
  FTxfH12.UnloadFont;
  FTxfH12.Free;
  FTxfH10.UnloadFont;
  FTxfH10.Free;
  FPushPins.Free;
  FPresicenceNode.Free;
end;

procedure TfrmGLRender.GLCleanups;
begin
  FMobTriangle.GLCleanup;
  FObjectTriangle.GLCleanup;
  FRangeCircles.GLCleanup;
  FMapElementsListList.GLCleanup;
  FMapTexturesListList.GLCleanup;
  FGroundTarget.GLCleanup;
  FVisibleRangeRep.GLCleanup;
  FBoat.GLCleanup;
  FTxfH10.CleanupTexture;
  FTxfH12.CleanupTexture;
  FPushPins.GLCleanup;
  FUnknownStealther.GLCleanup;
  FPresicenceNode.GLCleanup;

  FGLInitsCalled := false;
end;

procedure TfrmGLRender.GLInits;
begin
  FGLInitsCalled := true;
  FMobTriangle.GLInitialize;
  FObjectTriangle.GLInitialize;
  FRangeCircles.GLInitialize;
  FMapElementsListList.GLInitialize;
  FMapTexturesListList.GLInitialize;
  FGroundTarget.GLInitialize;
  FVisibleRangeRep.GLInitialize;
  FBoat.GLInitialize;
  FPushPins.GLInitialize;
  FUnknownStealther.GLInitialize;
  FPresicenceNode.GLInitialize;

  FTxfH10.EstablishTexture;
  FTxfH12.EstablishTexture;
  CheckGLError;
end;

procedure TfrmGLRender.DrawMapElements;
begin
  glDisable(GL_LIGHTING);
  glDisable(GL_CULL_FACE);
  glDisable(GL_BLEND);
  glLineWidth(1.0);

  if FRenderPrefs.DrawMapTexture then
    FMapTexturesListList.GLRender(FRenderBounds);
  if FRenderPrefs.DrawMapVector then begin
    FMapElementsListList.DrawInfoPoints := FRenderPrefs.DrawInfoPoints;
    FMapElementsListList.GLRender(FRenderBounds);
  end;
  if FRenderPrefs.DrawPushPins then
    FPushPins.GLRender(FRenderBounds);
end;

procedure TfrmGLRender.DAOCZoneChanged;
begin
  if not Assigned(FDControl.Zone) then begin
    FZoneName := '';
    exit;
  end;

  FZoneName := FDControl.Zone.Name;

  { BRY:  We really need to select the GL context here, but I don't because
    glWindow doesn't have a function to activate its context and we'll just
    see if this works }
  ReloadMapElementsAndTextures;
end;

procedure TfrmGLRender.DAOCRegionChanged;
begin
  Caption := FDControl.LocalPlayer.Name + S_CAPTION_SUFFIX;
  UpdateMapURLs;
  FRenderPrefs.PlayerRealm := FDControl.LocalPlayer.Realm;
  DAOCSetGroundTarget;
  LoadRegionPushpins;
end;

procedure TfrmGLRender.GridSelectObject(ADAOCObject: TDAOCObject);
var
  I:    integer;
begin
  I := FFilteredObjects.IndexOf(ADAOCObject);

  if I <> lstObjects.ItemIndex then
    lstObjects.ItemIndex := I;
end;

procedure TfrmGLRender.DAOCSelectedObjectChanged(AObj: TDAOCObject);
begin
  FTargetHUDWidth := 0;
  
  if FRenderPrefs.TrackInGameSelect then begin
    GridSelectObject(AObj);
    Dirty;
  end;
end;

procedure TfrmGLRender.DrawPlayerHighlightRing(ADAOCObject: TDAOCPlayer);
var
  cl:     TColor;
  fSize:  GLfloat;
  fAlphaMax:  GLfloat;
begin
  cl := RealmColor(ADAOCObject.Realm);

  if ADAOCObject.IsInGroup or ADAOCObject.IsInGuild then
    fSize :=  FMobTriangle.Size * 1.75
  else
    fSize :=  FMobTriangle.Size * 1.33;

  if ADAOCObject.IsDead then
    SetGLColorFromTColorDarkened(cl, 1, 0.25)
  else begin
    fAlphaMax := 1;
    if (ADAOCObject.Realm <> FDControl.LocalPlayer.Realm) and FInvaderHighlight then
      fAlphaMax := 0.6;
    SetGLColorFromTColor(cl, fAlphaMax * ADAOCObject.LiveDataConfidencePct);
  end;

  glShadeModel(GL_SMOOTH);
  
  glBegin(GL_TRIANGLES);
    glNormal3f(0, 0, 1);
    glVertex3F(0, 2 * fSize, 0);
    if ADAOCObject.IsInGroup then
      SetGLColorFromTColor($3399ff, 1)
    else if ADAOCObject.IsInGuild then
      SetGLColorFromTColor($666600, 1);
    glVertex3f(fSize, -fSize, 0);
    glVertex3f(-fSize, -fSize, 0);
  glEnd();

  glShadeModel(GL_FLAT);
end;

procedure TfrmGLRender.tmrMinFPSTimer(Sender: TObject);
begin
  if FRenderPrefs.RedrawOnTimer then begin
    if FDControl.Active then
      UpdateGlobalTickCount;
    Dirty;
  end;
end;

procedure TfrmGLRender.DrawTargetHUD;
const
  TEXT_COLOR: array[0..3] of GLfloat = (0.35, 0.80, 1, 0.75);
var
  rastery:  integer;
  pMob: TDAOCObject;
  s:    string;

  procedure WriteMobNameCon(const AName: string);
  begin
    with TDAOCMovingObject(pMob) do begin
        { white background for the name }
      glColor3f(0.4, 0.4, 0.4);
      WriteTXFTextH12(4+1, rastery-1, AName);
        { con color for name }
      SetGLColorFromTColor(GetConColor(FDControl.LocalPlayer.Level), 1);
      rastery := WriteTXFTextH12(4, rastery, AName);
    end;
  end;

  procedure WriteMobLevelHealth;
  var
    s:  string;
  begin
    with TDAOCMovingObject(pMob) do begin
      s := 'Level ' + IntToStr(Level);
      if (pMob is TDAOCPlayer) and (TDAOCPlayer(pMob).RealmRank <> rrUnknown) then
        s := s + ' ' + TDAOCPlayer(pMob).RealmRankStr;
      if HitPoints <> 100 then
        if IsDead then
          s := s + ' (dead)'
        else
          s := s + ' (' + IntToStr(HitPoints) + '%)';
      rastery := WriteTXFTextH12(4, rastery, s);
    end;
  end;

begin
  if not FRenderPrefs.DrawHUD then
    exit;

  pMob := FDControl.SelectedObject;
  if not Assigned(pMob) then
    exit;

  glEnable(GL_BLEND);
  glDisable(GL_LIGHTING);

  rastery := glMap.ClientHeight - 1;

  if FTargetHUDWidth = 0 then
    FMaxTXFTextWidth := 0;

    { BRY: we don't use FTargetHUDWidth yet, because is needs to also be
      recalculated when the object's speed changes, and I'm not sure how I
      want to do that to keep the box from lagging one frame every time }
  ShadedRect(1, rastery, 160, rastery - 56);

  glEnable(GL_TEXTURE_2D);
  case pMob.ObjectClass of
    ocObject:
      begin
        glColor3f(0.9, 0.9, 0.9);
        rastery := WriteTXFTextH12(4, rastery, pMob.Name);
        glColor4fv(@TEXT_COLOR);
      end;

    ocMob:
      with TDAOCMob(pMob) do begin
        WriteMobNameCon(Name);
        glColor4fv(@TEXT_COLOR);
        if TypeTag <> '' then
          rastery := WriteTXFTextH12(4, rastery, TypeTag);
        WriteMobLevelHealth;
      end;  { ocMob }

    ocPlayer:
      with TDAOCPlayer(pMob) do begin
        WriteMobNameCon(FullName);
        glColor4fv(@TEXT_COLOR);
        if Guild <> '' then
          rastery := WriteTXFTextH12(4, rastery, '<' + Guild + '>');
        WriteMobLevelHealth;
      end;  { ocPlayer }

    ocVehicle:
      with TDAOCVehicle(pMob) do begin
        WriteMobNameCon(Name);
      end;  { ocVehicle }

    else
        glColor4fv(@TEXT_COLOR);
  end;    { case class }

  s := 'Dist: ' + FormatFloat('0', pMob.Distance3D(FDControl.LocalPlayer)) +
    ' ' + ZDeltaStr(pMob, false);
  if (pMob is TDAOCMovingObject) and (TDAOCMovingObject(pMob).Speed <> 0) then
    s := s + '  Speed: ' + TDAOCMovingObject(pMob).SpeedString;
  rastery := WriteTXFTextH10(4, rastery, s);

  if FTargetHUDWidth = 0 then
    FTargetHUDWidth := FMaxTXFTextWidth + 7;
    
  glDisable(GL_TEXTURE_2D);
end;

procedure TfrmGLRender.SetupRadarProjectionMatrix;
begin
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  if FRenderPrefs.RotateMapWithPlayer then
    glRotatef(FDControl.LocalPlayer.Head - 180, 0, 0, 1)
  else if Assigned(FDControl.Zone) and (FDControl.Zone.Rotate > 0) then
    glRotatef(FDControl.Zone.Rotate, 0, 0, 1);
  glRotatef(180, 1, 0, 0);

  FRenderBounds.Left := FDControl.LocalPlayer.XProjected - FRange;
  inc(FRenderBounds.Left, FMapToPlayerOffset.X);
  FRenderBounds.Right := FRenderBounds.Left + (integer(FRange) * 2);

  FRenderBounds.Top := FDControl.LocalPlayer.YProjected - FRange;
  inc(FRenderBounds.Top, FMapToPlayerOffset.Y);
  FRenderBounds.Bottom := FRenderBounds.Top + (integer(FRange) * 2);

  with FRenderBounds do
      { render bounds are in DAOC (top down) coordinates, so flip the top
        and bottom when we create our ortho }
    glOrtho(Left, Right, Top, Bottom, 1, -300);
end;

procedure TfrmGLRender.SetupScreenProjectionMatrix;
begin
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  glOrtho(0, glMap.ClientWidth, 0, glMap.ClientHeight, 1, -1);
end;

procedure TfrmGLRender.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_PRIOR:
      begin
        if lstObjects.Focused then
          exit;
        slideZoom.Position := slideZoom.Position - slideZoom.PageSize;
      end;
    VK_NEXT:
      begin
        if lstObjects.Focused then
          exit;
        slideZoom.Position := slideZoom.Position + slideZoom.PageSize;
      end;
    VK_HOME:
      begin
        FMapToPlayerOffset.X := 0;
        FMapToPlayerOffset.Y := 0;
        Key := 0;
      end;
    VK_LEFT:
      begin
        dec(FMapToPlayerOffset.X, FRange div 10);
        Key := 0;
      end;
    VK_UP:
      begin
        if lstObjects.Focused then
          exit;
        dec(FMapToPlayerOffset.Y, FRange div 10);
        Key := 0;
      end;
    VK_RIGHT:
      begin
        inc(FMapToPlayerOffset.X, FRange div 10);
        Key := 0;
      end;
    VK_DOWN:
      begin
        if lstObjects.Focused then
          exit;
        inc(FMapToPlayerOffset.Y, FRange div 10);
        Key := 0;
      end;
    VK_F1:
      begin
        DoPrefsDialog;
        Key := 0;
      end;
    VK_F2:
      begin
        pnlLeft.Visible := not pnlLeft.Visible; 
        Key := 0;
      end;
  end;
end;

procedure TfrmGLRender.glMapMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  glMap.SetFocus;
end;

procedure TfrmGLRender.FormMouseWheelUp(Sender: TObject;
  Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
  slideZoom.Position := slideZoom.Position + slideZoom.Frequency;
  Handled := true;
end;

procedure TfrmGLRender.FormMouseWheelDown(Sender: TObject;
  Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
  slideZoom.Position := slideZoom.Position - slideZoom.Frequency;
  Handled := true;
end;

procedure TfrmGLRender.FormKeyPress(Sender: TObject; var Key: Char);
begin
  case Key of
    '?':    DisplaySelectedObjectInventory;
    'a', 'A':
      begin
        FRenderPrefs.InvaderWarning := not FRenderPrefs.InvaderWarning;
        Dirty;
        Key := #0;
      end;
    'b', 'B':
      begin
        FRenderPrefs.DrawMapTexture := not FRenderPrefs.DrawMapTexture;
        Dirty;
        Key := #0;
      end;
    'c', 'C':
      begin
        FRenderPrefs.DrawRangeCircles := not FRenderPrefs.DrawRangeCircles;
        Dirty;
        Key := #0;
      end;
    'd', 'D':
      begin
        FRenderPrefs.DrawAIDestination := not FRenderPrefs.DrawAIDestination;
        Dirty;
        Key := #0;
      end;
    'f', 'F':
      begin
        FRenderPrefs.DrawFriendlyPlayers := not FRenderPrefs.DrawFriendlyPlayers;
        Key := #0;
      end;
    'g', 'G':
      begin
        FRenderPrefs.DrawGrid := not FRenderPrefs.DrawGrid;
        Dirty;
        Key := #0;
      end;
    'h', 'H':
      begin
        FRenderPrefs.DrawHUD := not FRenderPrefs.DrawHUD;
        Dirty;
        Key := #0;
      end;
    'i', 'I':
      begin
        AddPushPin;
        Key := #0;
      end;
    'm', 'M':
      begin
        FRenderPrefs.XORObjectClassFilter(ocMob);
        Key := #0;
      end;
    'o', 'O':
      begin
        FRenderPrefs.XORObjectClassFilter(ocObject);
        Key := #0;
      end;
    'p', 'P':
      begin
        FRenderPrefs.XORObjectClassFilter(ocPlayer);
        Key := #0;
      end;
    'r', 'R':
      begin
        FRenderPrefs.DrawRulers := not FRenderPrefs.DrawRulers;
        Dirty;
        Key := #0;
      end;
    't', 'T':
      begin
        FRenderPrefs.StayOnTop := not FRenderPrefs.StayOnTop;
        UpdateStayOnTop;
        Key := #0;
      end;
    'u', 'U':
      begin
        FRenderPrefs.XORObjectClassFilter(ocUnknown);
        RefreshFilteredList;
        Key := #0;
      end;
    'v', 'V':
      begin
        FRenderPrefs.DrawMapVector := not FRenderPrefs.DrawMapVector;
        Dirty;
        Key := #0;
      end;
    'y', 'Y':
      begin
        FRenderPrefs.DrawTypeTag := not FRenderPrefs.DrawTypeTag;
        FRenderPrefs.AlternateMobListText := FRenderPrefs.DrawTypeTag;
        lstObjects.Invalidate;
        Dirty;
        Key := #0;
      end;
  end;
end;

procedure TfrmGLRender.RefreshFilteredList;
var
  pObj:   TDAOCObject;
  I:      integer;
  R:      TRect;
  pOldFilteredList:  TDAOCObjectList;
begin
    { save the old list because we might need it for invalidating }
  pOldFilteredList := FFilteredObjects;
  FFilteredObjects := TDAOCObjectList.Create(false);

  pObj := FDControl.DAOCObjects.Head;
  while Assigned(pObj) do begin
    if FRenderPrefs.IsObjectInFilter(pObj) then
      FilteredObjectInsert(pObj);
    pObj := pObj.Next;
  end;

  UpdateObjectCounts;
    { if the number of items hasn't changed then we need to selectively invalidate }
  if not SetObjectListRowCount(FFilteredObjects.Count) then
    for I := 0 to pOldFilteredList.Count - 1 do
      if pOldFilteredList[I] <> FFilteredObjects[I] then begin
        R := lstObjects.ItemRect(I);
        InvalidateRect(lstObjects.Handle, @R, false);
      end;

  pOldFilteredList.Free;
  Dirty;
end;

procedure TfrmGLRender.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FPrefsFile <> '' then begin
    FRenderPrefs.Left := Left;
    FRenderPrefs.Top := Top;
    FRenderPrefs.Width := Width;
    FRenderPrefs.Height := Height;
    FRenderPrefs.Range := FRange;
    FRenderPrefs.SaveSettings(FPrefsFile);
    FRangeCircles.SaveToFile(FPrefsFile);
  end;
end;

function TfrmGLRender.FilteredObjectInsert(ADAOCObject: TDAOCObject) : integer;
begin
  case FRenderPrefs.MobListSortOrder of
    msoName:  Result := FilteredObjectInsertByName(ADAOCObject);
    msoDistance: Result := FilteredObjectInsertByDistance(ADAOCObject);
    else
      Result := FFilteredObjects.Add(ADAOCObject);
  end;  { case Sort order }
end;

procedure TfrmGLRender.UpdateObjectCounts;
var
  I:    integer;
  counts:  array[0..1, TDAOCRealm] of integer;
  pMob: TDAOCObject;
begin
  FillChar(counts, sizeof(counts), 0);
  
  for I := 0 to FFilteredObjects.Count - 1 do begin
    pMob := FFilteredObjects[I];
    if pMob is TDAOCMovingObject then begin
      inc(counts[0, pMob.Realm]);
      if TDAOCMovingObject(pMob).IsAlive then
        inc(counts[1, pMob.Realm]);
    end;
  end;

  lblObjCounts.Caption := Format(
    'Albs: %d (%d)        Mids: %d (%d)'#13'Hibs: %d (%d)        Mobs: %d', [
    counts[1, drAlbion], counts[0, drAlbion],
    counts[1, drMidgard], counts[0, drMidgard],
    counts[1, drHibernia], counts[0, drHibernia],
    counts[0, drNeutral]
  ]);
end;

procedure TfrmGLRender.DrawMobTypeTag(AMob: TDAOCMob);
begin
  if AMob.TypeTag <> '' then begin
    glDisable(GL_LIGHTING);
    WriteGLUTTextH10(30, 30, AMob.TypeTag);
    glEnable(GL_LIGHTING);
  end;
end;

function TfrmGLRender.SetObjectListRowCount(ACount: integer) : boolean;
{ Returns true if the number of items has changed }
begin
  if lstObjects.Count <> ACount then begin
    lstObjects.Count := ACount;
    Result := true;
  end
  else
    Result := false;
end;

function TfrmGLRender.PlayerMobListText(AMob: TDAOCPlayer) : string;
begin
  if AMob.Realm <> FDControl.LocalPlayer.Realm then begin
    Result := '';
    
    if AMob.RealmRank <> rrUnknown then
      Result := AMob.RealmRankStr + ' - ';

    Result := Result + AMob.Name;

    if AMob.CharacterClass <> ccUnknown then
      Result := Result + ' ' + DAOCCharacterClassToStr(AMob.CharacterClass);
  end

    { same realm }
  else begin
    if AMob.CharacterClass <> ccUnknown then
      Result := AMob.Name + ' (' + DAOCCharacterClassToStr(AMob.CharacterClass) + ')'
    else
      Result := AMob.Name;
  end;
end;

procedure TfrmGLRender.lstObjectsDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  pMob:   TDAOCObject;
  R,G,B:  byte;
  sText:  string;
  cl:     TColor;
begin
  if Index < FFilteredObjects.Count then
    with lstObjects.Canvas do begin
      pMob := FFilteredObjects[Index];

        { objects are gray on white }
      if pMob.ObjectClass = ocObject then begin
        Font.Color := clGray;
        Brush.Color := clWhite;
      end  { object }

        { mobs are con color on white }
      else if pMob.Realm = drNeutral then begin
        cl := pMob.GetConColor(FDControl.LocalPlayer.Level);
        R := GetRValue(cl) shr 1;
        G := GetGValue(cl) shr 1;
        B := GetBValue(cl) shr 1;

        Font.Color := RGB(R, G, B);
        Brush.Color := clWhite;
      end

        { else (should be just players) black on realm color }
      else begin
        Font.Color := clBlack;
        if TDAOCPlayer(pMob).IsAlive then
          cl := RealmColor(pMob.Realm)
        else
          cl := ListDeadRealmColor(pMob.Realm);
        Brush.Color := cl;
      end;

      FillRect(Rect);

        { NAME }
      if pMob is TDAOCPlayer then
        sText := PlayerMobListText(TDAOCPlayer(pMob))
      else if FRenderPrefs.AlternateMobListText and (pMob is TDAOCMob) then
        sText := TDAOCMob(pMob).TypeTag
      else
        sText := pMob.Name;
      TextOut(Rect.Left + 3, Rect.Top + 2, sText);

        { LEVEL }
      sText := IntToStr(pMob.Level);
      TextOut(Rect.Left + 150, Rect.Top + 2, sText);

        { HEALTH }
      if pMob.HitPoints > 0 then begin
        sText := IntToStr(pMob.HitPoints);
        TextOut(Rect.Left + 175, Rect.Top + 2, sText);
      end;

        { If selected, draw the focus rect even if we're not focused }
      if (odSelected in State) and not (odFocused in State) then
        DrawFocusRect(Rect);
  end  { data row / with }

    { blank row }
  else begin
    lstObjects.Canvas.Brush.Color := clWhite;
    lstObjects.Canvas.FillRect(Rect);
  end;
end;

procedure TfrmGLRender.RENDERPrefsObjectFilterChanged(Sender: TObject);
begin
  RefreshFilteredList;
end;

procedure TfrmGLRender.DrawGroundTarget;
begin
  FGroundTarget.GLRender(FRenderBounds);
end;

procedure TfrmGLRender.DrawFrameStats;
begin
  if not FRenderPrefs.DrawFrameStats then
    exit;

  if FFrameStats <> '' then begin
    glDisable(GL_LIGHTING);
    glEnable(GL_TEXTURE_2D);
    glColor3f(1, 1, 0);
    WriteTXFTextH10(3, 15, FFrameStats);
    glDisable(GL_TEXTURE_2D);
  end;
end;

procedure TfrmGLRender.UpdateFrameStats(ATime: integer);
begin
  FFrameStats := Format('%d frames for %d dirty / %d invalidate in %d msec', [
    FFrameCount, FDirtyCount, FInvalidateCount, ATime]);

  FFrameCount := 0;
  FDirtyCount := 0;
  FInvalidateCount := 0;
end;

procedure TfrmGLRender.DAOCSetGroundTarget;
begin
  with FDControl.GroundTarget do
    FGroundTarget.Assign(X, Y);
end;

procedure TfrmGLRender.InvalidateListObject(AObj: TDAOCObject);
var
  I:    integer;
  R:    TRect;
begin
  I := FFilteredObjects.IndexOf(AObj);
  if I <> -1 then begin
    R := lstObjects.ItemRect(I);
    InvalidateRect(lstObjects.Handle, @R, false);
  end;
end;

procedure TfrmGLRender.UpdateStayOnTop;
var
  dwStyle:  Cardinal;
begin
  dwStyle := GetWindowLong(Handle, GWL_EXSTYLE);
  if FRenderPrefs.StayOnTop then begin
    dwStyle := dwStyle or WS_EX_TOPMOST;
    SetWindowLong(Handle, GWL_EXSTYLE, dwStyle);
    SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
  end
  else begin
    dwStyle := dwStyle and not WS_EX_TOPMOST;
    SetWindowLong(Handle, GWL_EXSTYLE, dwStyle);
    SetWindowPos(Handle, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
  end;
end;

procedure TfrmGLRender.ReloadMapElementsAndTextures;
begin
  FMapElementsListList.LoadForZone(FDControl.Zone, FRenderPrefs.AdjacentZones);
  FMapTexturesListList.LoadForZone(FDControl.Zone, FRenderPrefs.AdjacentZones);
end;

procedure TfrmGLRender.DoPrefsDialog;
var
  tmpPrefs:   TRenderPreferences;
begin
  tmpPrefs := FRenderPrefs.Clone;

  if TfrmRenderPrefs.Execute(Self, FRenderPrefs, FRangeCircles) then begin
    if tmpPrefs.AdjacentZones <> FRenderPrefs.AdjacentZones then
      ReloadMapElementsAndTextures;
    UpdateStayOnTop;
    tmpPrefs.Free;
  end

  else begin
    FRenderPrefs.Free;
    FRenderPrefs := tmpPrefs;
    FRenderPrefs.OnObjectFilterChanged := RENDERPrefsObjectFilterChanged;
    FRenderPrefs.OnMobListOptionsChanged := RENDERPrefsMobListOptionChanged;
    FRenderPrefs.OnMobTriangleSizeChanged := RENDERPrefsMobTriangleSizeChanged;

    RENDERPrefsObjectFilterChanged(FRenderPrefs);
    RENDERPrefsMobListOptionChanged(FRenderPrefs);
    RENDERPrefsMobTriangleSizeChanged(FRenderPrefs);
  end;
end;

procedure TfrmGLRender.DrawLineToMobTarget(AMob: TDAOCMob);
begin
  glLineWidth(3.0);
  glColor3f(1, 0, 0);
  glBegin(GL_LINES);
    glVertex3f(AMob.XProjected, AMob.YProjected, 0);
    glVertex3f(AMob.Target.XProjected, AMob.Target.YProjected, 0);
  glEnd();
end;

procedure TfrmGLRender.DrawLocalPlayerHUD;
var
  rastery:  integer;
  rasterx:  integer;
  s:    string;
begin
  if not FRenderPrefs.DrawHUD then
    exit;

  glEnable(GL_BLEND);
  glDisable(GL_LIGHTING);

  rastery := glMap.ClientHeight - 1;
  rasterx := glMap.ClientWidth - 125;

  ShadedRect(rasterx, rastery, rasterx + 124, rastery - 43);
  inc(rasterx, 2);

  glEnable(GL_TEXTURE_2D);
  glColor4f(1, 1, 1, 1);
  with FDControl do begin
    if FZoneName <> '' then
      rastery := WriteTXFTextH10(rasterx, rastery, FZoneName);
    s := Format('(%d,%d,%d)', [PlayerZoneX, PlayerZoneY, PlayerZoneZ]);
    rastery := WriteTXFTextH10(rasterx, rastery, s);
    s := 'Heading ' + IntToStr(PlayerZoneHead) + ' Speed ' + LocalPlayer.SpeedString;
    WriteTXFTextH10(rasterx, rastery, s);
  end;

  glDisable(GL_TEXTURE_2D);
end;

procedure TfrmGLRender.DrawAIDestination(AObj: TDAOCObject; AColor: TColor);
var
  pMovingObj:   TDAOCMovingObject;
begin
  if not FRenderPrefs.DrawAIDestination then
    exit;

    { if the mob is on the move, draw a line to its destination }
  if (AObj.ObjectClass = ocMob) and Assigned(TDAOCMob(AObj).Target) then
    DrawLineToMobTarget(TDAOCMob(AObj))
  else if (AObj.DestinationX <> 0) and (AObj.DestinationY <> 0) then begin
    pMovingObj := TDAOCMovingObject(AObj);

    glLineWidth(3.0);
    SetGLColorFromTColor(AColor, 0.33);

    glBegin(GL_LINES);
      glVertex3f(pMovingObj.XProjected, pMovingObj.YProjected, 0);
      glVertex3f(pMovingObj.DestinationX, pMovingObj.DestinationY, 0);
    glEnd();
  end;  { if destinaton set }
end;

procedure TfrmGLRender.DrawGrid;
const
  GRID_STEP = 10000;
var
  X:    integer;
  Y:    integer;
  XMin: integer;
  YMin: integer;
  XMax: integer;
  YMax: integer;
begin
  if not FRenderPrefs.DrawGrid then
    exit;

    { the grid only draws over the current zone }
  if not Assigned(FDControl.Zone) then
    exit;

  glDisable(GL_LIGHTING);
  glEnable(GL_BLEND);
  glLineWidth(1.0);
  glColor4f(0, 0, 1, 0.5);

    { round down to the next 10,000 mark }
//  XMin := (FRenderBounds.Left div GRID_STEP) * GRID_STEP;
//  YMin := (FRenderBounds.Top div GRID_STEP) * GRID_STEP;
    { round up to the next 10,000 mark }
//  XMax := ((FRenderBounds.Right + GRID_STEP - 1) div GRID_STEP) * GRID_STEP;
//  YMax := ((FRenderBounds.Bottom + GRID_STEP - 1) div GRID_STEP) * GRID_STEP;

  with FDControl.Zone do begin
    XMin := BaseLoc.X;
    YMin := BaseLoc.Y;
    XMax := MaxLoc.X;
    YMax := MaxLoc.Y;
  end;

  Y := YMin + GRID_STEP;
  while Y <= YMax do begin
    glBegin(GL_LINES);
        { horizontal line }
      glVertex2i(XMin, Y);
      glVertex2i(XMax, Y);
    glEnd();

    inc(Y, GRID_STEP);
  end;  { for Y }

  X := XMin + GRID_STEP;
  while X <= XMax do begin
    glBegin(GL_LINES);
        { vertical line }
      glVertex2i(X, YMin);
      glVertex2i(X, YMax);
    glEnd();

    inc(X, GRID_STEP);
  end;  { for X }
end;

procedure TfrmGLRender.MapUnproject(var X, Y: Cardinal; ANeedMVPSetup: boolean);
var
  projmatrix: T16dArray;
  modmatrix:  T16dArray;
  viewport:   TViewPortArray;
  fx, fy, fz: GLdouble;
  pt:         TPoint;
begin
  if ANeedMVPSetup then begin
    SetupRadarProjectionMatrix;
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
  end;

  glGetDoublev(GL_PROJECTION_MATRIX, @projmatrix);
  glGetDoublev(GL_MODELVIEW_MATRIX, @modmatrix);
  glGetIntegerv(GL_VIEWPORT, @viewport);

  pt := glMap.ScreenToClient(Mouse.CursorPos);
  gluUnProject(pt.X, glMap.Height - pt.Y, 0, modmatrix, projmatrix, viewport,
    @fx, @fy, @fz);

  X := round(fx);
  Y := round(fy);
end;

procedure TfrmGLRender.glMapMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
    { for mouse tooltip }
  if ssCtrl in Shift then
    Dirty;
end;

procedure TfrmGLRender.DrawMouseTooltip;
var
  ptMouse:  TPoint;
  iHeight:  integer;
  iDist:    integer;
  ZoneX:    Cardinal;
  ZoneY:    Cardinal;
  pNearest: TDAOCObject;
begin
  if (GetAsyncKeyState(VK_CONTROL) = 0) or not Assigned(FDControl.Zone) then
    exit;

    { distance from here to the mouse }
  iDist := round(FDControl.LocalPlayer.Distance2D(FMouseLocX, FMouseLocY));

  if FDControl.Zone.ZoneType = dztDungeon then
    pNearest := FFilteredObjects.FindNearest3D(FMouseLocX, FMouseLocY, FDControl.LocalPlayer.Z)
  else
    pNearest := FFilteredObjects.FindNearest2D(FMouseLocX, FMouseLocY);

  if Assigned(pNearest) and
    (round(pNearest.Distance2D(FMouseLocX, FMouseLocY)) > (2 * FMobTriangle.Size)) then
    pNearest := nil;

  if Assigned(pNearest) then
    iHeight := 42
  else
    iHeight := 14;

  ptMouse := glMap.ScreenToClient(Mouse.CursorPos);
  ptMouse.X := ptMouse.X + 2;
  ptMouse.Y := glMap.ClientHeight - ptMouse.Y + iHeight;

  ZoneX := FMouseLocX - Cardinal(FDControl.Zone.BaseLoc.X);
  ZoneY := FMouseLocY - Cardinal(FDControl.Zone.BaseLoc.Y);

  glEnable(GL_BLEND);
  glDisable(GL_LIGHTING);

  ShadedRect(ptMouse.X, ptMouse.Y, ptMouse.X + 120, ptMouse.Y - iHeight);
  glColor3f(1, 1, 1);

  ptMouse.X := ptMouse.X + 1;
  ptMouse.Y := ptMouse.Y + 2;
  glEnable(GL_TEXTURE_2D);
  if Assigned(pNearest) then begin
    ptMouse.Y := WriteTXFTextH10(ptMouse.X, ptMouse.Y, pNearest.Name);
    ptMouse.Y := WriteTXFTextH10(ptMouse.X, ptMouse.Y, ZDeltaStr(pNearest, true));
  end;
  WriteTXFTextH10(ptMouse.X, ptMouse.Y, Format('%d,%d Dist %d', [ZoneX, ZoneY, iDist]));
  glDisable(GL_TEXTURE_2D);
end;

procedure TfrmGLRender.MobListMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  pnlLeft.BeginDrag(false);
  if (lstObjects.ItemIndex <> -1) and (lstObjects.ItemIndex < FFilteredObjects.Count) then
    FDControl.SelectedObject := FFilteredObjects[lstObjects.ItemIndex];
end;

procedure TfrmGLRender.pnlLeftEndDock(Sender, Target: TObject; X,
  Y: Integer);
begin
  if Assigned(pnlLeft.Parent) then
    pnlLeft.Align := alLeft;
end;

procedure TfrmGLRender.DAOCCharacterLogin;
begin
  FRenderPrefs.PlayerLevel := FDControl.LocalPlayer.Level;
end;

procedure TfrmGLRender.RENDERPrefsMobListOptionChanged(Sender: TObject);
begin
  RefreshFilteredList;
  lstObjects.Invalidate;
end;

function TfrmGLRender.FilteredObjectInsertByDistance(ADAOCObject: TDAOCObject): integer;
var
  I:   integer;
begin
  if Assigned(FDControl.Zone) then
    for I := 0 to FFilteredObjects.Count - 1 do
      if CompareObjectClasses(ADAOCObject.ObjectClass, FFilteredObjects[I].ObjectClass) < 0 then begin
        FFilteredObjects.Insert(I, ADAOCObject);
        Result := I;
        exit;
      end
      else if CompareObjectClasses(ADAOCObject.ObjectClass, FFilteredObjects[I].ObjectClass) = 0 then begin
        if FRenderPrefs.GroupByRealm and (ADAOCObject.Realm < FFilteredObjects[I].Realm) then begin
          FFilteredObjects.Insert(I, ADAOCObject);
          Result := I;
          exit;
        end

        else if not FRenderPrefs.GroupByRealm or (ADAOCObject.Realm = FFilteredObjects[I].Realm) then begin
          if ((FDControl.Zone.ZoneType = dztDungeon) and
              (ADAOCObject.DistanceSqr3D(FDControl.LocalPlayer) < FFilteredObjects[I].DistanceSqr3D(FDControl.LocalPlayer)))
            or
            ((FDControl.Zone.ZoneType <> dztDungeon) and
              (ADAOCObject.DistanceSqr2D(FDControl.LocalPlayer) < FFilteredObjects[I].DistanceSqr2D(FDControl.LocalPlayer)))
            then begin
            FFilteredObjects.Insert(I, ADAOCObject);
            Result := I;
            exit;
          end;
        end;  { if same realm }
      end;  { if samce object class }

  Result := FFilteredObjects.Add(ADAOCObject);
end;

function TfrmGLRender.FilteredObjectInsertByName(ADAOCObject: TDAOCObject): integer;
var
  I:   integer;
begin
  for I := 0 to FFilteredObjects.Count - 1 do
    if CompareObjectClasses(ADAOCObject.ObjectClass, FFilteredObjects[I].ObjectClass) < 0 then begin
      FFilteredObjects.Insert(I, ADAOCObject);
      Result := I;
      exit;
    end

    else if CompareObjectClasses(ADAOCObject.ObjectClass, FFilteredObjects[I].ObjectClass) = 0 then begin
      if FRenderPrefs.GroupByRealm and (ADAOCObject.Realm < FFilteredObjects[I].Realm) then begin
        FFilteredObjects.Insert(I, ADAOCObject);
        Result := I;
        exit;
      end

      else if not FRenderPrefs.GroupByRealm or (ADAOCObject.Realm = FFilteredObjects[I].Realm) then begin
        if AnsiCompareText(ADAOCObject.Name, FFilteredObjects[I].Name) < 0 then begin
          FFilteredObjects.Insert(I, ADAOCObject);
          Result := I;
          exit;
        end;
      end;  { if same realm }
    end;  { if samce object class }

  Result := FFilteredObjects.Add(ADAOCObject);
end;

function TfrmGLRender.CompareObjectClasses(A, B: TDAOCObjectClass) : integer;
const
  OBJECT_ORDER: array[TDAOCObjectClass] of integer = (5, 4, 3, 2, 1, 0);
begin
  if not FRenderPrefs.GroupByClass then
    Result := 0
  else if OBJECT_ORDER[A] < OBJECT_ORDER[B] then
    Result := -1
  else if OBJECT_ORDER[A] > OBJECT_ORDER[B] then
    Result := 1
  else
    Result := 0;
end;

procedure TfrmGLRender.DAOCPlayerPosUpdate;
begin
    { RefreshFilteredList calls Dirty for us }
  if FRenderPrefs.MobListSortOrder = msoDistance then
    RefreshFilteredList
  else
    Dirty;
end;

procedure TfrmGLRender.UpdateMapURLs;
begin
  FMapTexturesListList.MapBaseURL := FRenderPrefs.MapBaseURL +
    's=' + FDControl.ServerIP + '&';
  FMapElementsListList.MapBaseURL := FRenderPrefs.MapBaseURL +
    's=' + FDControl.ServerIP + '&';
end;

function TfrmGLRender.WriteTXFTextH10(X, Y: integer; const s: string): integer;
var
  iWidth:   integer;
begin
  Result := Y - 13;
  iWidth := FTxfH10.RenderStringXYBind(X, Result, s);
  if iWidth > FMaxTXFTextWidth then
    FMaxTXFTextWidth := iWidth;
end;

function TfrmGLRender.WriteTXFTextH12(X, Y: integer; const s: string): integer;
var
  iWidth:   integer;
begin
  Result := Y - 13;
  iWidth := FTxfH12.RenderStringXYBind(X, Result, s);
  if iWidth > FMaxTXFTextWidth then
    FMaxTXFTextWidth := iWidth;
end;

procedure TfrmGLRender.CreateObjectListBox;
begin
  lstObjects := TLockableListBox.Create(Self);
  lstObjects.Parent := pnlLeft;
  lstObjects.Align := alClient;
  lstObjects.Style := lbVirtualOwnerDraw;
  lstObjects.BorderStyle := bsNone;
  lstObjects.Ctl3D := false;
  lstObjects.ItemHeight := 16;
  lstObjects.OnDrawItem := lstObjectsDrawItem;
  lstObjects.OnMouseDown := MobListMouseDown;
end;

procedure TfrmGLRender.LoadRegionPushpins;
begin
  FPushPins.GLCleanup;
  FPushPins.LoadFromFile(Format('%sregion%3.3d.pin', [FBasePath, FDControl.RegionID]));
  FPushPins.GLInitialize;
end;

procedure TfrmGLRender.AddPushPin;
var
  pPin:   TMapElementPoint;
begin
  if not Assigned(FDControl.Zone) then
    exit;

  pPin := TfrmAddPushpin.Execute(FDControl.LocalPlayer.X,
    FDControl.LocalPlayer.Y, FDControl.LocalPlayer.Z, FDControl.Zone.Name);

  if Assigned(pPin) then begin
    FPushPins.Add(pPin);
    FPushPins.Save('Pushpin format: P,<label>,<color>,<world x>,<world y>,<world z>');
  end;
end;

procedure TfrmGLRender.DAOCUnknownStealther(AObj: TDAOCObject);
begin
  Dirty;
end;

procedure TfrmGLRender.DrawUnknownStealthers;
var
  pObj:   TDAOCObject;
begin
  if not FRenderPrefs.AnonymousStealthers then
    exit;
    
  glEnable(GL_BLEND);
  glDisable(GL_LIGHTING);

  pObj := FDControl.UnknownStealthers.Head;
  while Assigned(pObj) do begin
    glTranslatef(pObj.X, pObj.Y, 0);
    FUnknownStealther.Alpha := pObj.LiveDataConfidencePct / 2;
    FUnknownStealther.GLRender(FRenderBounds);
    glTranslatef(-pObj.X, -pObj.Y, 0);

    pObj := pObj.Next;
  end;
end;

procedure TfrmGLRender.DrawStealtherAlert;
begin
  if not FRenderPrefs.AnonymousStealthers then
    exit;

  if not Assigned(FDControl.UnknownStealthers.Head) then
    exit;
    
  glEnable(GL_TEXTURE_2D);
  glColor3f(0, 0, 0);
  WriteTXFTextH12(glMap.ClientWidth - 117, 15, 'Stealther in proximity');
  glColor3f(1, 0, 0);
  WriteTXFTextH12(glMap.ClientWidth - 118, 16, 'Stealther in proximity');
  glDisable(GL_TEXTURE_2D);
end;

procedure TfrmGLRender.SetSmoothingOpts;
begin
  if FRenderPrefs.SmoothLines then
    glEnable(GL_LINE_SMOOTH)
  else
    glDisable(GL_LINE_SMOOTH);

  if FRenderPrefs.SmoothPolygons then
    glEnable(GL_POLYGON_SMOOTH)
  else
    glDisable(GL_POLYGON_SMOOTH);

  if FRenderPrefs.SmoothPoints then
    glEnable(GL_POINT_SMOOTH)
  else
    glDisable(GL_POINT_SMOOTH);
end;

procedure TfrmGLRender.CreateGLWindow;
begin
  glMap := TglWindow.Create(Self);
  
  glMap.OnClick := glMapClick;
  glMap.OnMouseDown := glMapMouseDown;
  glMap.OnMouseMove := glMapMouseMove;
  glMap.OnResize := glMapResize;
  glMap.OnDraw := glMapDraw;
  glMap.OnInit := glMapInit;

  glMap.Parent := pnlMap;
  glMap.Align := alClient;
  glMap.ColorDepth := c16bits;
  glMap.DepthBufferEnabled := False;
  glMap.WindowFlags := [wfDrawToWindow, wfSupportOpenGL, wfGenericAccelerated, wfDoubleBuffer];

  glMap.Initialize;
end;

procedure TfrmGLRender.AdjustMobTriangleSize;
var
  iSize:  integer;
  dwDiv:  Cardinal;
begin
  if FRenderPrefs.ScaleMobTriangle then begin
    dwDiv := 6000 div FRenderPrefs.MobTriangleNom;

    if dwDiv = 0 then
      dwDiv := 1;

    iSize := FRange div dwDiv;
    if iSize > FRenderPrefs.MobTriangleMax then
      iSize := FRenderPrefs.MobTriangleMax
    else if iSize < FRenderPrefs.MobTriangleMin then
      iSize := FRenderPrefs.MobTriangleMin;
  end
  else
    iSize := FRenderPrefs.MobTriangleNom;

  FMobTriangle.Size := iSize;
  FBoat.Size := 2 * iSize;

  if Visible then begin
    FMobTriangle.GLCleanup;
    FMobTriangle.GLInitialize;
    FBoat.GLCleanup;
    FBoat.GLInitialize;
    Dirty;
  end;
end;

procedure TfrmGLRender.RENDERPrefsMobTriangleSizeChanged(Sender: TObject);
begin
  AdjustMobTriangleSize;
end;

function TfrmGLRender.ZDeltaStr(AObj: TDAOCObject; AVerbose: boolean): string;
var
  iZDelta:    integer;
begin
  iZDelta := AObj.Z - FDControl.LocalPlayer.Z;
  if iZDelta > 0 then begin
    if AVerbose then
      Result := IntToStr(iZDelta) + ' above you'
    else
      Result := '+' + IntToStr(iZDelta);
  end
  else begin
    if AVerbose then
      Result := IntToStr(-iZDelta) + ' below you'
    else
      Result := IntToStr(iZDelta);
  end;
end;

procedure TfrmGLRender.DisplaySelectedObjectInventory;
var
  pSelected:  TDAOCObject;
  s:    string;
begin
  if FDControl.SelectedID <> 0 then begin
    pSelected := FDControl.SelectedObject;
    if pSelected.ObjectClass in [ocMob, ocPlayer, ocLocalPlayer] then begin
      s := TDAOCMovingObject(pSelected).Inventory.AsString(false);
      ShowMessage(s);
    end;
  end;  { if object selected }
end;

end.

