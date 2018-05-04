unit frm_DM;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.FMXUI.Wait,
  FireDAC.Comp.UI, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client;

type
  Tdm = class(TDataModule)
    conn: TFDConnection;
    qryTemp: TFDQuery;
    fdphysqltdrvrlnk1: TFDPhysSQLiteDriverLink;
    fdgxwtcrsr1: TFDGUIxWaitCursor;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure GetPatListInfo;
    procedure OpenSql(const ASql: string);
    procedure ExecSql(const ASql: string);
    function GetParamStr(const AName: string): string;
    function GetParamInt(const AName: string; const ADefValue: Integer): Integer;
    function SetParam(const AName, AValue: string): Boolean;
  end;

var
  dm: Tdm;

implementation

uses
  emr_Common;

{$R *.dfm}

procedure Tdm.DataModuleCreate(Sender: TObject);
var
  vDBPath: string;
begin
  vDBPath := ExtractFilePath(ParamStr(0)) + 'clt.db';
  if FileExists(vDBPath) then
    conn.ConnectionString := 'DriverID=SQLite;Password=emr171212.;Database=' + vDBPath
  else  // �������ݿ�
  begin
    conn.Params.Add('DriverID=SQLite');
    conn.Params.Add('Database=' + vDBPath);
    conn.Params.Add('Password=emr171212.');
  end;

  // �жϲ������Ƿ���ڣ��������򴴽�
  qryTemp.Open('SELECT COUNT(*) AS tbcount FROM sqlite_master where type=''table'' and name=''params''');
  if qryTemp.FieldByName('tbcount').AsInteger = 0 then  // ������params��
  begin
    conn.ExecSQL('CREATE TABLE params (' +
      'name nvarchar(20) primary key, ' +      // ������(����)
      'value nvarchar(255))');      // ����ֵ
    conn.ExecSQL(Format('INSERT INTO params (name, value) VALUES (''%s'', ''%s'')', [PARAM_LOCAL_MSGHOST, '']));  // ��Ϣ������
    conn.ExecSQL(Format('INSERT INTO params (name, value) VALUES (''%s'', ''%s'')', [PARAM_LOCAL_BLLHOST, '']));  // ҵ�������
    conn.ExecSQL(Format('INSERT INTO params (name, value) VALUES (''%s'', ''%s'')', [PARAM_LOCAL_MSGPORT, '']));  // ��Ϣ�˿�
    conn.ExecSQL(Format('INSERT INTO params (name, value) VALUES (''%s'', ''%s'')', [PARAM_LOCAL_BLLPORT, '']));  // ҵ��˿�
    conn.ExecSQL(Format('INSERT INTO params (name, value) VALUES (''%s'', %d)', [PARAM_LOCAL_VERSIONID, 0]));  // �汾��
    conn.ExecSQL(Format('INSERT INTO params (name, value) VALUES (''%s'', ''%s'')', [PARAM_LOCAL_UPDATEHOST, '']));  // ���·�����
    conn.ExecSQL(Format('INSERT INTO params (name, value) VALUES (''%s'', %d)', [PARAM_LOCAL_UPDATEPORT, '']));  // ���·������˿�
  end;

  qryTemp.Open('SELECT COUNT(*) AS tbcount FROM sqlite_master where type=''table'' and name=''clientcache''');
  if qryTemp.FieldByName('tbcount').AsInteger = 0 then  // ������clientcache��
  begin
    conn.ExecSQL('CREATE TABLE clientcache (' +
      'id int not null, ' +  // ���
      'tbName nvarchar(32) not null, ' +  // ����
      'tbField nvarchar(32) not null, ' +  // �ֶ�
      'tbVer int not null, ' +  // ���汾
      'dataVer int not null)');  // ���ݰ汾
  end;
end;

procedure Tdm.OpenSql(const ASql: string);
begin
  qryTemp.Open(ASql);
end;

function Tdm.SetParam(const AName, AValue: string): Boolean;
begin
  qryTemp.Open('SELECT COUNT(*) AS fieldcount FROM params WHERE name=:a', [AName]);
  if qryTemp.FieldByName('fieldcount').AsInteger > 0 then
    Result := conn.ExecSQL('UPDATE [params] SET value=:b WHERE name=:a', [AValue, AName]) = 1
  else
    Result := conn.ExecSQL('INSERT INTO [params] (value, name) VALUES (:a, :b)', [AValue, AName]) = 1;
end;

procedure Tdm.ExecSql(const ASql: string);
begin
  qryTemp.ExecSQL(ASql);
end;

function Tdm.GetParamInt(const AName: string;
  const ADefValue: Integer): Integer;
var
  vsValue: string;
begin
  vsValue := GetParamStr(AName);
  Result := StrToIntDef(vsValue, ADefValue);
end;

function Tdm.GetParamStr(const AName: string): string;
begin
  qryTemp.Open(Format('SELECT value FROM params WHERE name=''%s''',[AName]));
  Result := qryTemp.FieldByName('value').AsString;
  qryTemp.Close;
end;

procedure Tdm.GetPatListInfo;
begin
  qryTemp.Open('SELECT id, col, colname, left, top, right, bottom, fontsize, visible, sys FROM pat_list');
end;

end.