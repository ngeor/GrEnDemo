unit main;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Classes, Graphics,
  Controls, Forms, Dialogs,
  Menus, ExtCtrls, GrEn;

type
  TPyrArray = array [0..47] of integer;
  TPyrPolygones = array [0..4] of integer;
  TCubeArray = array [0..71] of integer;
  TCubePolygones = array [0..5] of integer;

  TForm1 = class(TForm)
    MainMenu1: TMainMenu;
    GrEn1: TGrEn;
    Timer1: TTimer;
    SelectObject1: TMenuItem;
    SelectStyle1: TMenuItem;
    Cube1: TMenuItem;
    Pyramid1: TMenuItem;
    Lines1: TMenuItem;
    Surface1: TMenuItem;
    Shadows1: TMenuItem;
    Epsilon1: TMenuItem;
    procedure Cube1Click(Sender: TObject);
    procedure Pyramid1Click(Sender: TObject);
    procedure Lines1Click(Sender: TObject);
    procedure Surface1Click(Sender: TObject);
    procedure Shadows1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Epsilon1Click(Sender: TObject);
  private
    { Private declarations }
  public
    Pyramid: TObject3D;
    Cube: TObject3D;
    Epsilon: TObject3D;
    CurrentObject: PObject3D;
  end;

  TDrawThread = class(TThread)
    constructor Create;
    procedure Execute; override;
    procedure Method1;
  end;

var
  Form1: TForm1;
  aThread: TDrawThread;

const
  PyrPoints: TPyrArray = (0, -20, 0, 20, 20, 20, -20, 20, 20,
    0, -20, 0, -20, 20, 20, -20, 20, -20,
    0, -20, 0, -20, 20, -20, 20, 20, -20,
    0, -20, 0, 20, 20, -20, 20, 20, -20,
    -20, 20, 20, 20, 20, 20, 20, 20, -20,
    -20, 20, -20);
  PyrFace: TPyrPolygones = (3, 3, 3, 3, 4);

implementation

{$R *.lfm}

constructor TDrawThread.Create;
begin
  inherited Create(False);
end;

procedure TDrawThread.Method1;
begin
  Form1.gren1.ClearBackPage;
  Form1.gren1.Rotate(0, 1, 0, 0.1, Form1.CurrentObject^);
  Form1.gren1.RenderNow(Form1.CurrentObject^);
  Form1.gren1.FlipBackPage;
end;

procedure TDrawThread.Execute;
begin
  while not Terminated do
  begin
    Synchronize(Method1);
    Sleep(50);
  end;
end;

procedure TForm1.Cube1Click(Sender: TObject);
begin
  if Cube1.Checked then
    Exit;
  Cube1.Checked := True;
  CurrentObject := @Cube;
end;

procedure TForm1.Pyramid1Click(Sender: TObject);
begin
  if Pyramid1.Checked then
    Exit;
  Pyramid1.Checked := True;
  CurrentObject := @Pyramid;
end;

procedure TForm1.Lines1Click(Sender: TObject);
begin
  Lines1.Checked := True;
  gren1.RenderMode := rmWframe;
end;

procedure TForm1.Surface1Click(Sender: TObject);
begin
  Surface1.Checked := True;
  gren1.RenderMode := rmSld;
end;

procedure TForm1.Shadows1Click(Sender: TObject);
begin
  Shadows1.Checked := True;
  gren1.RenderMode := rmSldShade;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  gren1.ClearBackPage;
  gren1.Rotate(0, 1, 0, 0.1, CurrentObject^);
  gren1.RenderNow(CurrentObject^);
  gren1.FlipBackPage;
end;

function Point3D(x, y, z: single): TPoint3D;
begin
  Result.x := x;
  Result.y := y;
  Result.z := z;
end;

function OffsetPoint3D(const Pt: TPoint3D; dx, dy, dz: single): TPoint3D;
begin
  Result.X := Pt.X + dx;
  Result.Y := pt.y + dy;
  Result.Z := pt.z + dz;
end;

function OffsetPolygon(const Poly: TPolygon; dx, dy, dz: single): TPolygon;
var
  i: integer;
begin
  Result := Poly;
  for i := 0 to Poly.PointsNum - 1 do
    Result.Point[i] := OffsetPoint3D(Poly.Point[i], dx, dy, dz);
end;

function OffsetObject3D(const Obj: TObject3D; dx, dy, dz: single): TObject3D;
var
  i: integer;
begin
  Result.Color := Obj.Color;
  Result.PolygoneNum := Obj.PolygoneNum;
  for i := 0 to Obj.PolygoneNum - 1 do
    Result.PolygoneStor[i] := OffsetPolygon(Obj.PolygoneStor[i], dx, dy, dz);
end;

function RectPolygonX(y1, z1, y2, z2, x: single): TPolygon;
begin
  Result.PointsNum := 4;
  Result.Point[0] := Point3D(x, y1, z1);
  Result.Point[1] := Point3D(x, y2, z1);
  Result.Point[2] := Point3D(x, y2, z2);
  Result.Point[3] := Point3D(x, y1, z2);
end;

function RectPolygonY(x1, z1, x2, z2, y: single): TPolygon;
begin
  Result.PointsNum := 4;
  Result.Point[0] := Point3D(x1, y, z1);
  Result.Point[1] := Point3D(x2, y, z1);
  Result.Point[2] := Point3D(x2, y, z2);
  Result.Point[3] := Point3D(x1, y, z2);
end;

function RectPolygonZ(x1, y1, x2, y2, z: single): TPolygon;
begin
  Result.PointsNum := 4;
  Result.Point[0] := Point3D(x1, y1, z);
  Result.Point[1] := Point3D(x2, y1, z);
  Result.Point[2] := Point3D(x2, y2, z);
  Result.Point[3] := Point3D(x1, y2, z);
end;


function InitVRectObject3D(x1, y1, z1, x2, y2, z2: integer; color: TColor): TObject3D;
var
  i: integer;
begin
  Result.PolygoneNum := 6;
  Result.Color := color;
  for i := 0 to 5 do
    Result.PolygoneStor[i].PointsNum := 4;
  Result.PolygoneStor[0] := RectPolygonZ(x1, y1, x2, y2, z1);
  Result.PolygoneStor[1] := OffsetPolygon(Result.PolygoneStor[0], 0, 0, z2 - z1);
  Result.PolygoneStor[2] := RectPolygonX(y1, z1, y2, z2, x1);
  Result.PolygoneStor[3] := OffsetPolygon(Result.PolygoneStor[2], x2 - x1, 0, 0);
  Result.PolygoneStor[4] := RectPolygonY(x1, z1, x2, z2, y1);
  Result.PolygoneStor[5] := OffsetPolygon(Result.PolygoneStor[4], 0, y2 - y1, 0);
end;

function MergeObject3D(const a, b: TObject3D): TObject3D;
var
  i: integer;
begin
  Result := a;
  Result.PolygoneNum := a.PolygoneNum + b.PolygoneNum;
  for i := a.PolygoneNum to Result.PolygoneNum - 1 do
    Result.PolygoneStor[i] := b.PolygoneStor[i - a.PolygoneNum];
end;

procedure TForm1.FormShow(Sender: TObject);
var
  LCount, PCount, ACount: integer;
begin
  Pyramid.PolygoneNum := 5;
  Pyramid.Color := clMaroon;

  for LCount := 0 to 4 do
  begin
    Pyramid.PolygoneStor[LCount].PointsNum := PyrFace[LCount];
    if LCount < 4 then
      for PCount := 0 to 2 do
      begin
        ACount := (PCount * 3) + (LCount * 9);
        Pyramid.PolygoneStor[LCount].Point[PCount].X := PyrPoints[ACount];
        Pyramid.PolygoneStor[LCount].Point[PCount].Y := PyrPoints[ACount + 1];
        Pyramid.PolygoneStor[LCount].Point[PCount].Z := PyrPoints[ACount + 2];
      end
    else
      for PCount := 0 to 3 do
      begin
        ACount := (PCount * 3) + (LCount * 9);
        Pyramid.PolygoneStor[LCount].Point[PCount].X := PyrPoints[ACount];
        Pyramid.PolygoneStor[LCount].Point[PCount].Y := PyrPoints[ACount + 1];
        Pyramid.PolygoneStor[LCount].Point[PCount].Z := PyrPoints[ACount + 2];
      end;
  end;
  CurrentObject := @Pyramid;

  Cube := InitVRectObject3D(-15, -15, -15, 15, 15, 15, clBlue);

  Epsilon := OffsetObject3D(MergeObject3D(
    InitVRectObject3D(0, 0, 0, 20, 5, -5, clBlue),
    MergeObject3D(InitVRectObject3D(0,
    5, 0, 5, 35, -5, clBlue), MergeObject3D(
    InitVRectObject3D(5, 15, 0, 18, 20, -5, clBlue),
    InitVRectObject3D(5, 30, 0, 20, 35, -5, clBlue)))),
    -10, -35 / 2, -2);
  Epsilon.Color := clNavy;
  aThread := TDrawThread.Create;
end;

procedure TForm1.Epsilon1Click(Sender: TObject);
begin
  Epsilon1.Checked := True;
  CurrentObject := @Epsilon;
end;

end.
