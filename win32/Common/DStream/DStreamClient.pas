unit DStreamClient;

(****************************************************************************
**
** Copyright (C) 2003 Bryan Mayland.  All rights reserved.
**
** This file may be distributed and/or modified under the terms of the
** GNU General Public License version 2 as published by the Free Software
** Foundation.
**
****************************************************************************)

interface

uses
  SysUtils, Classes, IdException, IdTCPClient, DStreamDefs, INIFiles, WinSock;

type
  TDStreamDAOCConnectionDetailsNotify = procedure (Sender: TObject;
    AConnectionID: Cardinal; AServerIP: Cardinal; AServerPort: WORD;
    AClientIP: Cardinal; AClientPort: WORD) of object;
  TDStreamDAOCDataNotify = procedure (Sender: TObject;
    AConnectionID: Cardinal; AIsFromClient: boolean; AIsTCP: boolean;
    AData: Pointer; ADataLen: integer) of object;

  TDStreamClient = class(TThread)
  private
    FClientSock:    TIdTCPClient;
    FCurrentPacket: PDStream_Header;

    FPort: integer;
    FHost: string;
    FOnDSPacket: TDStreamPacketNotify;
    FActive: boolean;
    FReconnectDelay: Cardinal;
    FOnDAOCDisconnect: TDStreamDAOCConnectionDetailsNotify;
    FOnDAOCConnect: TDStreamDAOCConnectionDetailsNotify;
    FOnDAOCData: TDStreamDAOCDataNotify;
    FBytesSend: Cardinal;
    FBytesRecv: Cardinal;
    FStatus: string;
    FPassword: string;
//    FOnError: TNotifyEvent;
    FOnStatusChange: TNotifyEvent;
    function GetHostPretty: string;
  protected
    procedure DoRead;
    procedure DoConnect;
    procedure Execute; override;
    procedure DoOnConnectError(E: EIdSocketError);
    procedure SetStatus(const AStatus: string);
    procedure SyncDoOnNewPacket;
//    procedure SyncDoOnError;
    procedure SyncDoOnStatusUpdate;

    procedure DoOnDAOCConnectionOpened(AData: Pointer); virtual;
    procedure DoOnDAOCConnectionClosed(AData: Pointer); virtual;
    procedure DoOnDAOCConnectionData(AData: Pointer); virtual;
  public
    constructor Create;
    destructor Destroy; override;

    procedure SetConnectString(const AHostPort: string);
    procedure Shutdown;
    procedure Open;
    procedure Close;

      { config properties }
    property Active: boolean read FActive write FActive;
    property Host: string read FHost write FHost;
    property HostPretty: string read GetHostPretty;
    property Password: string read FPassword write FPassword;
    property Port: integer read FPort write FPort;
    property ReconnectDelay: Cardinal read FReconnectDelay write FReconnectDelay;

      { status properties }
    property BytesRecv: Cardinal read FBytesRecv;
    property BytesSend: Cardinal read FBytesSend;
    property Status: string read FStatus;

      { events }
    property OnDSPacket: TDStreamPacketNotify read FOnDSPacket write FOnDSPacket;
    property OnDAOCConnect: TDStreamDAOCConnectionDetailsNotify read FOnDAOCConnect write FOnDAOCConnect;
    property OnDAOCData: TDStreamDAOCDataNotify read FOnDAOCData write FOnDAOCData;
    property OnDAOCDisconnect: TDStreamDAOCConnectionDetailsNotify read FOnDAOCDisconnect write FOnDAOCDisconnect;
//    property OnError: TNotifyEvent read FOnError write FOnError;
    property OnStatusChange: TNotifyEvent read FOnStatusChange write FOnStatusChange;
  end;

  TDStreamClientList = class(TObject)
  private
    FList:    TList;
    FOnDAOCDisconnect: TDStreamDAOCConnectionDetailsNotify;
    FOnDAOCConnect: TDStreamDAOCConnectionDetailsNotify;
    FOnDAOCData: TDStreamDAOCDataNotify;
    FOnStatusChange: TNotifyEvent;
//    FOnError: TNotifyEvent;
    
    function GetItems(I: integer): TDStreamClient;
    function GetCount: integer;
  protected
    procedure CLIENTOnDAOCConnect(Sender: TObject;
      AConnectionID: Cardinal; AServerIP: Cardinal; AServerPort: WORD;
      AClientIP: Cardinal; AClientPort: WORD);
    procedure CLIENTOnDAOCDisconnect(Sender: TObject;
      AConnectionID: Cardinal; AServerIP: Cardinal; AServerPort: WORD;
      AClientIP: Cardinal; AClientPort: WORD);
    procedure CLIENTOnDAOCData(Sender: TObject;
      AConnectionID: Cardinal; AIsFromClient: boolean; AIsTCP: boolean;
      AData: Pointer; ADataLen: integer);
//    procedure CLIENTOnError(Sender: TObject);
    procedure CLIENTStatusChange(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;

    procedure OpenAll;
    
    procedure Add(AItem: TDStreamClient);
    procedure Clear;
    procedure Delete(AIndex: integer);
    procedure LoadFromINI(const AFileName: string);
    procedure SaveToINI(const AFileName: string);

    property Count: integer read GetCount;
    property Items[I: integer]: TDStreamClient read GetItems; default;

    property OnDAOCConnect: TDStreamDAOCConnectionDetailsNotify read FOnDAOCConnect write FOnDAOCConnect;
    property OnDAOCData: TDStreamDAOCDataNotify read FOnDAOCData write FOnDAOCData;
    property OnDAOCDisconnect: TDStreamDAOCConnectionDetailsNotify read FOnDAOCDisconnect write FOnDAOCDisconnect;
//    property OnError: TNotifyEvent read FOnError write FOnError;
    property OnStatusChange: TNotifyEvent read FOnStatusChange write FOnStatusChange;
  end;

implementation

resourcestring
  S_INISECTION = 'DStreamServers';
  
{ TDStreamClient }

procedure TDStreamClient.Close;
begin
  if not FActive then
    exit;

  FActive := false;
  if FClientSock.Connected then
    FClientSock.Disconnect;
end;

constructor TDStreamClient.Create;
begin
  FClientSock := TIdTCPClient.Create(nil);
  FPort := DSTREAM_DEFAULT_PORT;
  FReconnectDelay := 2000;

  inherited Create(false);
end;

destructor TDStreamClient.Destroy;
begin
  FreeAndNil(FClientSock);
  inherited;
end;

procedure TDStreamClient.DoConnect;
begin
  SetStatus('Connecting...');

  FClientSock.Host := FHost;
  FClientSock.Port := FPort;
  try
    FClientSock.Connect;
    SetStatus('Connected');
  except
    On E: EIdSocketError do
      DoOnConnectError(E);
  end;
end;

procedure TDStreamClient.DoOnConnectError(E: EIdSocketError);
begin
  case E.LastError of
    WSAETIMEDOUT:
        SetStatus('Connect timed out');
    WSAECONNREFUSED:
        SetStatus('Connect refused');
    WSAEHOSTDOWN:
        SetStatus('Host down');
    WSAEHOSTUNREACH:
        SetStatus('Host unreachable');
    else
        SetStatus('Error ' + IntToStr(E.LastError));
  end;

//  Synchronize(SyncDoOnError);
  
  sleep(FReconnectDelay);
end;

procedure TDStreamClient.DoOnDAOCConnectionClosed(AData: Pointer);
begin
  if Assigned(FOnDAOCDisconnect) then
    with PDStream_DAOCConnectionDetails(AData)^ do
      FOnDAOCDisconnect(Self, ConnectionID, ServerIP, ServerPort, ClientIP, ClientPort);
end;

procedure TDStreamClient.DoOnDAOCConnectionData(AData: Pointer);
var
  IsFromClient: boolean;
  IsTCP:  boolean;
  pData:  Pointer;
begin
  with PDStream_DAOCDataHeader(AData)^ do begin
    IsFromClient := Origin = 1;
    IsTCP := Protocol = 0;
    pData := Pointer(Cardinal(AData) + sizeof(TDStream_DAOCDataHeader));

    if Assigned(FOnDAOCData) then
      FOnDAOCData(Self, ConnectionID, IsFromClient, IsTCP, pData, DataSize);
  end;  { with PDStream_DAOCDataHeader^ }     
end;

procedure TDStreamClient.DoOnDAOCConnectionOpened(AData: Pointer);
begin
  if Assigned(FOnDAOCConnect) then
    with PDStream_DAOCConnectionDetails(AData)^ do
      FOnDAOCConnect(Self, ConnectionID, ServerIP, ServerPort, ClientIP, ClientPort);
end;

procedure TDStreamClient.SyncDoOnNewPacket;
  { this function is synchronized to the main thread }
var
  pData:  Pointer;
begin

  if Assigned(FOnDSPacket) then
    FOnDSPacket(Self, FCurrentPacket);

  pData := DStreamPointToData(FCurrentPacket);
  
  case FCurrentPacket^.command_id of
    DPACKET_DAOC_CONNECTION_OPENED:
        DoOnDAOCConnectionOpened(pData);
    DPACKET_DAOC_CONNECTION_CLOSED:
        DoOnDAOCConnectionClosed(pData);
    DPACKET_DAOC_DATA:
        DoOnDAOCConnectionData(pData);
  end;
end;

procedure TDStreamClient.DoRead;
var
  RecvHeader:   TDStream_Header;
  pRecvBuffer:  PDStream_Header;
  pDataDest:    Pointer;
begin
  FClientSock.ReadBuffer(RecvHeader, sizeof(RecvHeader));
  if RecvHeader.total_length > sizeof(RecvHeader) then begin
      { get enough memory to store the total new packet, and copy the
        existing header into it }
    GetMem(pRecvBuffer, RecvHeader.total_length);
    Move(RecvHeader, pRecvBuffer^, sizeof(RecvHeader));

      { point past the header for the next read }
    pDataDest := DStreamPointToData(pRecvBuffer);
    FClientSock.ReadBuffer(pDataDest^, RecvHeader.total_length - sizeof(RecvHeader));
    inc(FBytesRecv, RecvHeader.total_length);

    FCurrentPacket := pRecvBuffer;
    Synchronize(SyncDoOnNewPacket);
    FreeMem(pRecvBuffer);
  end
  else
    inc(FBytesRecv, sizeof(RecvHeader));
end;

procedure TDStreamClient.Execute;
begin
  FStatus := 'Executing';
  
  while not Terminated do begin
    if FActive then
      if FClientSock.Connected then
        DoRead
      else
        DoConnect
    else
      sleep(1000);  // todo:  do a wait here.  Polling is fucking asinine
  end;  { while !Terminated }
end;

procedure TDStreamClient.Open;
begin
  if FActive then
    exit;

  FActive := true;
end;

procedure TDStreamClient.SetConnectString(const AHostPort: string);
var
  iPos:   integer;
begin
  iPos := Pos(':', AHostPort);
  if iPos <> 0 then begin
    FHost := copy(AHostPort, 1, iPos - 1);
    FPort := StrToIntDef(copy(AHostPort, iPos + 1, Length(AHostPort)), DSTREAM_DEFAULT_PORT);
  end
  else begin
    FHost := AHostPort;
    FPort := DSTREAM_DEFAULT_PORT;
  end;
end;

procedure TDStreamClient.SetStatus(const AStatus: string);
begin
  FStatus := AStatus;
  Synchronize(SyncDoOnStatusUpdate);  
end;

procedure TDStreamClient.Shutdown;
begin
  Close;
  FClientSock.Disconnect;
  Terminate;
  // BRY: Should I check to make sure that this isn't the thread folding back
  // on itself?  Should be safe.
  WaitFor;
end;

//procedure TDStreamClient.SyncDoOnError;
//begin
//  if Assigned(FOnError) then
//    FOnError(Self);
//end;

procedure TDStreamClient.SyncDoOnStatusUpdate;
begin
  if Assigned(FOnStatusChange) then
    FOnStatusChange(Self);
end;

function TDStreamClient.GetHostPretty: string;
begin
  if FPort <> DSTREAM_DEFAULT_PORT then
    Result := FHost + ':' + IntToStr(FPort)
  else
    Result := FHost;
end;

{ TDStreamClientList }

procedure TDStreamClientList.Add(AItem: TDStreamClient);
begin
  AItem.OnDAOCConnect := CLIENTOnDAOCConnect;
  AItem.OnDAOCData := CLIENTOnDAOCData;
  AItem.OnDAOCDisconnect := CLIENTOnDAOCDisconnect;
  //AItem.OnError := CLIENTOnError;
  AItem.OnStatusChange := CLIENTStatusChange;
  
  FList.Add(AItem);
end;

procedure TDStreamClientList.Clear;
var
  I:    integer;
begin
  for I := 0 to Count - 1 do begin
    Items[I].Shutdown;
    Items[I].Free;
  end;
  
  FList.Clear;
end;

//procedure TDStreamClientList.CLIENTOnError(Sender: TObject);
//begin
//  if Assigned(FOnError) then
//    FOnError(Sender);
//end;

procedure TDStreamClientList.CLIENTOnDAOCConnect(Sender: TObject;
  AConnectionID, AServerIP: Cardinal; AServerPort: WORD;
  AClientIP: Cardinal; AClientPort: WORD);
begin
  if Assigned(FOnDAOCConnect) then
    FOnDAOCConnect(Sender, AConnectionID, AServerIP, AServerPort, AClientIP, AClientPort);
end;

procedure TDStreamClientList.CLIENTOnDAOCData(Sender: TObject;
  AConnectionID: Cardinal; AIsFromClient, AIsTCP: boolean; AData: Pointer;
  ADataLen: integer);
begin
  if Assigned(FOnDAOCData) then
    FOnDAOCData(Sender, AConnectionID, AIsFromClient, AIsTCP, AData, ADataLen);
end;

procedure TDStreamClientList.CLIENTOnDAOCDisconnect(Sender: TObject;
  AConnectionID, AServerIP: Cardinal; AServerPort: WORD;
  AClientIP: Cardinal; AClientPort: WORD);
begin
  if Assigned(FOnDAOCConnect) then
    FOnDAOCDisconnect(Sender, AConnectionID, AServerIP, AServerPort, AClientIP, AClientPort);
end;

constructor TDStreamClientList.Create;
begin
  inherited;
  FList := TList.Create;
end;

procedure TDStreamClientList.Delete(AIndex: integer);
begin
  with Items[AIndex] do begin
    Shutdown;
    Free;
  end;
  
  FList.Delete(AIndex);
end;

destructor TDStreamClientList.Destroy;
begin
  Clear;
  FList.Free;
  inherited;
end;

function TDStreamClientList.GetCount: integer;
begin
  Result := FList.Count;
end;

function TDStreamClientList.GetItems(I: integer): TDStreamClient;
begin
  Result := TDStreamClient(FList[I]);
end;

procedure TDStreamClientList.LoadFromINI(const AFileName: string);
var
  iCnt: integer;
  I:    integer;
  pTmp: TDStreamClient;
begin
  Clear;

  with TINIFile.Create(AFileName) do begin
    iCnt := ReadInteger(S_INISECTION, 'Count', 0);
    for I := 0 to iCnt - 1 do begin
      pTmp := TDStreamClient.Create;
      pTmp.Host := ReadString(S_INISECTION, 'Host' + IntToStr(I), '');
      pTmp.Port := ReadInteger(S_INISECTION, 'Port' + IntToStr(I), DSTREAM_DEFAULT_PORT);
      pTmp.Password := ReadString(S_INISECTION, 'Password' + IntToStr(I), '');

      Add(pTmp);
    end;  { for I to count }

    Free;
  end;  { with INIFile }
end;

procedure TDStreamClientList.OpenAll;
var
  I:  integer;
begin
  for I := 0 to Count - 1 do
    Items[I].Active := true;
end;

procedure TDStreamClientList.SaveToINI(const AFileName: string);
var
  I: integer;
begin
  with TINIFile.Create(AFileName) do begin
    WriteInteger(S_INISECTION, 'Count', Count);
    for I := 0 to Count - 1 do
      with Items[I] do begin
        WriteString(S_INISECTION, 'Host' + IntToStr(I), Host);
        WriteInteger(S_INISECTION, 'Port' + IntToStr(I), Port);
        WriteString(S_INISECTION, 'Password' + IntToStr(I), Password);
      end;

    Free;
  end;  { with INIFile }
end;

procedure TDStreamClientList.CLIENTStatusChange(Sender: TObject);
begin
  if Assigned(FOnStatusChange) then
    FOnStatusChange(Sender);
end;

end.
