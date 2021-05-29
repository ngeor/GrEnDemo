unit GrEn;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Classes, Graphics,
  Controls, Forms, Dialogs;

type
  TRMode = (rmWframe, rmSld, rmSldShade);

  TXBt = record
    StartX, EndX: integer;
  end;

  TPoint3D = record
    X, Y, Z: single;
  end;

  TLine3D = record
    StartPoint, EndPoint: TPoint3D;
  end;

  TPolygon = record
    Point: array [0..3] of TPoint3D;
    PointsNum: integer;
    Visible: boolean;
    AverageZ: single;
    PolygoneCol: TColor;
  end;

  PObject3D = ^TObject3D;

  TObject3D = record
    PolygoneStor: array [0..49] of TPolygon;
    PolygoneNum: integer;
    Color: TColor;
  end;


  TGrEn = class(TComponent)
  private
    FBBuff: TBitmap;
    FFBuff: TCanvas;
    FColor: TColor;
    ViewWidth, ViewHeight: integer;
    FWinHand: THandle;
    FRenMd: TRMode;
    HScrWidth, HScrHeight, ViewingDistance: integer;
    FDistance: integer;
    YBt: array [0..479] of TXBt;
    ViewPoint, LS: TPoint3D;
    LightStrength: single;
    AmL: integer;
    procedure DrawLine3D(X1, Y1, Z1, X2, Y2, Z2: single);
    procedure DrawLine2D(X1, Y1, X2, Y2: integer);
    procedure DrawSolidLine2D(X1, Y1, X2, Y2: integer);
    procedure SetDistance(Distance: integer);
    procedure GVec(var EndPoint, StartPoint, Vector: TPoint3D);
    procedure CrProd(var U, V, Normal: TPoint3D);
    procedure GetNormal(var P1, P2, P3, normal: TPoint3D);
    function VMgn(var Normal: TPoint3D): single;
    function DProd(var U, V: TPoint3D): single;
    procedure Rmf(var AOb: TObject3D);
    procedure ClearYBt;
    procedure RenderYBt;
    procedure DrHorL(Y, X1, X2: integer);
    procedure OrderZ(var Object3D: TObject3D);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ClearBackPage;
    procedure RenderNow(var Object3D: TObject3D);
    procedure FlipBackPage;
    procedure Rotate(X, Y, Z, Angle: single; var Object3D: TObject3D);
    procedure ChObjCol(var Object3D: TObject3D; Color: TColor);
    procedure SLSPos(Position, Direction: TPoint3D);
  published
    property BackColor: TColor read FColor write FColor;
    property ZDistance: integer read FDistance write SetDistance default -50;
    property RenderMode: TRMode read FRenMd write FRenMd;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Custom', [TGrEn]);
end;

procedure TGrEn.DrawLine3D(X1, Y1, Z1, X2, Y2, Z2: single);
var
  ScreenX1, ScreenY1, ScreenX2, ScreenY2: integer;
begin
  ScreenX1 := HScrWidth + Round(X1 * ViewingDistance / (Z1 + ZDistance));
  ScreenY1 := Round(HScrHeight - Y1 * ViewingDistance / (Z1 + ZDistance));
  ScreenX2 := HScrWidth + Round(X2 * ViewingDistance / (Z2 + ZDistance));
  ScreenY2 := Round(HScrHeight - Y2 * ViewingDistance / (Z2 + ZDistance));
  case RenderMode of
    rmWframe: DrawLine2D(ScreenX1, ScreenY1, ScreenX2, ScreenY2);
    rmSld: DrawSolidLine2D(ScreenX1, ScreenY1, ScreenX2, ScreenY2);
    rmSldShade: DrawSolidLine2D(ScreenX1, ScreenY1, ScreenX2, ScreenY2);
  end;
end;

procedure TGrEn.DrawLine2D(X1, Y1, X2, Y2: integer);
begin
  FBBuff.Canvas.PenPos := Point(X1, Y1);
  FBBuff.Canvas.LineTo(X2, Y2);
end;

procedure TGrEn.DrawSolidLine2D(X1, Y1, X2, Y2: integer);
var
  CurrentX, XIncr: single;
  Y, Temp, Length: integer;
begin
  if Y1 = Y2 then
    Exit;
  if Y2 < Y1 then
  begin
    Temp := Y1;
    Y1 := Y2;
    Y2 := Temp;
    Temp := X1;
    X1 := X2;
    X2 := Temp;
  end;
  Length := (Y2 - Y1) + 1;
  XIncr := ((X2 - X1) + 1) / Length;
  CurrentX := X1;
  for Y := Y1 to Y2 do
  begin
    if YBt[Y].StartX = -16000 then
    begin
      YBt[Y].StartX := Round(CurrentX);
      YBt[Y].EndX := Round(CurrentX);
    end
    else
    begin
      if CurrentX < YBt[Y].StartX then
        YBt[Y].StartX := Round(CurrentX);
      if CurrentX > YBt[Y].EndX then
        YBt[Y].EndX := Round(CurrentX);
    end;
    CurrentX := CurrentX + XIncr;
  end;
end;

procedure TGrEn.SetDistance(Distance: integer);
begin
  FDistance := Distance;
end;

procedure TGrEn.GVec(var EndPoint, StartPoint, Vector: TPoint3D);
begin
  Vector.X := EndPoint.X - StartPoint.X;
  Vector.Y := EndPoint.Y - StartPoint.Y;
  Vector.Z := EndPoint.Z - StartPoint.Z;
end;

procedure TGrEn.CrProd(var U, V, Normal: TPoint3D);
begin
  Normal.X := -(U.Y * (V.Z) - (U.Z) * V.Y);
  Normal.Y := -(-U.X * (V.Z + ZDistance) + V.X * (U.Z + ZDistance));
  Normal.Z := -(U.X * V.Y - V.X * U.Y);
end;

procedure TGrEn.GetNormal(var P1, P2, P3, Normal: TPoint3D);
var
  U, V: TPoint3D;
begin
  GVec(P2, P1, U);
  GVec(P3, P1, V);
  CrProd(U, V, Normal);
end;

function TGrEn.VMgn(var Normal: TPoint3D): single;
var
  X1: single;
begin
  X1 := Sqrt(Sqr(Normal.X) + Sqr(Normal.Y) + Sqr(Normal.Z));
  if X1 = 0 then
    X1 := 0.0000002;
  Result := X1;
end;

function TGrEn.DProd(var U, V: TPoint3D): single;
begin
  Result := ((U.X * V.X) + (U.Y * V.Y) + (U.Z * V.Z));
end;

procedure TGrEn.Rmf(var AOb: TObject3D);
var
  CurPl: longint;
  Dp, Inten: single;
  Sight, Normal: TPoint3D;
  R, G, B: longint;
begin
  for CurPl := 0 to AOb.PolygoneNum - 1 do
  begin
    Sight.X := (ViewPoint.X - AOb.PolygoneStor[CurPl].Point[0].X);
    Sight.Y := (ViewPoint.Y - AOb.PolygoneStor[CurPl].Point[0].Y);
    Sight.Z := (ViewPoint.Z - (AOb.PolygoneStor[CurPl].Point[0].Z - ZDistance));
    GetNormal(AOb.PolygoneStor[CurPl].Point[0],
      AOb.PolygoneStor[CurPl].Point[1],
      AOb.PolygoneStor[CurPl].Point[2], Normal);
    Dp := DProd(Normal, Sight);
    if Dp > 0 then
    begin
      AOb.PolygoneStor[CurPl].Visible := True;
      Dp := DProd(Normal, LS);
      Inten := Dp * (31 / VMgn(Normal)) * LightStrength;
      if Inten < 0 then
        Inten := 0;
      Inten := Inten + AmL;
      if Inten > 31 then
        Inten := 31;
      R := Round(((255 - GetRValue(AOb.Color)) / 31) * Inten) + GetRValue(AOb.Color);
      G := Round(((255 - GetGValue(AOb.Color)) / 31) * Inten) + GetGValue(AOb.Color);
      B := Round(((255 - GetBValue(AOb.Color)) / 31) * Inten) + GetBValue(AOb.Color);
      if R < 0 then
        R := 0
      else if R > 255 then
        R := 255;
      if G < 0 then
        G := 0
      else if G > 255 then
        G := 255;
      if B < 0 then
        B := 0
      else if B > 255 then
        B := 255;
      AOb.PolygoneStor[CurPl].PolygoneCol := RGB(R, G, B);
    end
    else
      AOb.PolygoneStor[CurPl].Visible := False;
  end; {for-loop}
end;

procedure TGrEn.ClearYBt;
var
  X: integer;
begin
  for X := 0 to 479 do
    YBt[X].StartX := -16000;
end;

procedure TGrEn.RenderYBt;
var
  Y: integer;
begin
  for Y := 0 to 479 do
  begin
    if YBt[Y].StartX = -16000 then
      Continue;
    DrHorL(Y, YBt[Y].StartX, YBt[Y].EndX);
  end;
end;

procedure TGrEn.DrHorL(Y, X1, X2: integer);
begin
  FBBuff.Canvas.PenPos := Point(X1, Y);
  FBBuff.Canvas.LineTo(X2, Y);
end;

procedure TGrEn.OrderZ(var Object3D: TObject3D);
var
  X, Y: integer;
  Temp: TPolygon;
begin
  for Y := 0 to Object3D.PolygoneNum - 1 do
  begin
    if Object3D.PolygoneStor[Y].PointsNum = 3 then
      Object3D.PolygoneStor[Y].AverageZ :=
        (Object3D.PolygoneStor[Y].Point[0].Z +
        Object3D.PolygoneStor[Y].Point[1].Z +
        Object3D.PolygoneStor[Y].Point[2].Z) / 3
    else if Object3D.PolygoneStor[Y].PointsNum = 4 then
      Object3D.PolygoneStor[Y].AverageZ :=
        (Object3D.PolygoneStor[Y].Point[0].Z +
        Object3D.PolygoneStor[Y].Point[1].Z +
        Object3D.PolygoneStor[Y].Point[2].Z +
        Object3D.PolygoneStor[Y].Point[3].Z) / 4;
  end;
  for X := 0 to Object3D.PolygoneNum - 1 do
    for Y := 0 to Object3D.PolygoneNum - 2 do
      if Object3D.PolygoneStor[Y].AverageZ > Object3D.PolygoneStor[Y +
        1].AverageZ then
      begin
        Temp := Object3D.PolygoneStor[Y];
        Object3D.PolygoneStor[Y] := Object3D.PolygoneStor[Y + 1];
        Object3D.PolygoneStor[Y + 1] := Temp;
      end;
end;

constructor TGrEn.Create(AOwner: TComponent);
var
  Position, Direction: TPoint3D;
begin
  inherited;
  FBBuff := TBitmap.Create;
  FFBuff := TForm(AOwner).Canvas;
  ViewHeight := TForm(AOwner).Height;
  ViewWidth := TForm(AOwner).Width;
  FBBuff.Width := ViewWidth;
  FBBuff.Height := ViewHeight;
  HScrWidth := ViewWidth div 2;
  HScrHeight := ViewHeight div 2;
  FWinHand := TForm(AOwner).Handle;
  ViewingDistance := 200;
  ZDistance := -50;
  LightStrength := 1;
  AmL := 7;
  Position.X := 100;
  Position.Y := 0;
  Position.Z := -100;
  Direction.X := 0;
  Direction.Y := 0;
  Direction.Z := 0;
  ViewPoint.X := 0;
  ViewPoint.Y := 0;
  ViewPoint.Z := 0;
  SLSPos(Position, Direction);
end;

destructor TGrEn.Destroy;
begin
  FBBuff.Free;
  inherited;
end;

procedure TGrEn.ClearBackPage;
var
  ARect: TRect;
begin
  ARect := Rect(0, 0, ViewWidth, ViewHeight);
  FBBuff.Canvas.Brush.Color := FColor;
  FBBuff.Canvas.FillRect(ARect);
end;

procedure TGrEn.RenderNow(var Object3D: TObject3D);
var
  X, I: integer;
begin
  case RenderMode of
    rmWframe:
    begin
      FBBuff.Canvas.Pen.Color := Object3D.Color;
      for X := 0 to Object3D.PolygoneNum - 1 do
        with Object3D.PolygoneStor[x] do
        begin
          DrawLine3D(Point[0].X, Point[0].Y, Point[0].Z, Point[1].X,
            Point[1].Y, Point[1].Z);
          DrawLine3D(Point[1].X, Point[1].Y, Point[1].Z, Point[2].X,
            Point[2].Y, Point[2].Z);
          if PointsNum = 3 then
            DrawLine3D(Point[2].X, Point[2].Y, Point[2].Z, Point[0].X,
              Point[0].Y, Point[0].Z)
          else
          begin
            DrawLine3D(Point[2].X, Point[2].Y, Point[2].Z,
              Point[3].X, Point[3].Y, Point[3].Z);
            DrawLine3D(Point[3].X, Point[3].Y, Point[3].Z,
              Point[0].X, Point[0].Y, Point[0].Z);
          end;
        end;
    end;
    rmSld:
    begin
      FBBuff.Canvas.Pen.Color := Object3D.Color;
      for X := 0 to Object3D.PolygoneNum - 1 do
        with Object3D.PolygoneStor[X] do
        begin
          ClearYBt;
          for I := 0 to PointsNum - 1 do
            if I < (PointsNum - 1) then
              DrawLine3D(Point[I].X, Point[I].Y, Point[I].Z,
                Point[I + 1].X, Point[I + 1].Y, Point[I + 1].Z)
            else
              DrawLine3D(Point[I].X, Point[I].Y, Point[I].Z,
                Point[0].X, Point[0].Y, Point[0].Z);
          RenderYBt;
        end;
    end;
    rmSldShade:
    begin
      Rmf(Object3D);
      OrderZ(Object3D);
      for X := 0 to Object3D.PolygoneNum - 1 do
        with Object3D.PolygoneStor[X] do
        begin
          if not Object3D.PolygoneStor[X].Visible then
            Continue;
          FBBuff.Canvas.Pen.Color := PolygoneCol;
          ClearYBt;
          for I := 0 to PointsNum - 1 do
            if I < (PointsNum - 1) then
              DrawLine3D(Point[I].X, Point[I].Y, Point[I].Z,
                Point[I + 1].X, Point[I + 1].Y, Point[I + 1].Z)
            else
              DrawLine3D(Point[I].X, Point[I].Y, Point[I].Z,
                Point[0].X, Point[0].Y, Point[0].Z);

          RenderYBt;
        end;
    end;
  end;
end;

procedure TGrEn.FlipBackPage;
var
  ARect: TRect;
begin
  ARect := Rect(0, 0, ViewWidth, ViewHeight);
  FFBuff.CopyRect(ARect, FBBuff.Canvas, ARect);
end;

procedure TGrEn.Rotate(X, Y, Z, Angle: single; var Object3D: TObject3D);
var
  P, I: integer;
  NewX, NewY, NewZ: single;
begin
  for P := 0 to Object3D.PolygoneNum - 1 do
    with Object3D.PolygoneStor[P] do
    begin
      if Z <> 0 then
        for I := 0 to PointsNum - 1 do
        begin
          NewX := Point[I].X * cos(Angle) - Point[I].Y * sin(Angle);
          NewY := Point[I].X * sin(Angle) + Point[I].Y * cos(Angle);
          Point[I].X := NewX;
          Point[I].Y := NewY;
        end;
      if X <> 0 then
        for I := 0 to PointsNum - 1 do
        begin
          NewY := Point[I].Y * cos(Angle) - Point[I].Z * sin(Angle);
          NewZ := Point[I].Y * sin(Angle) + Point[I].Z * cos(Angle);
          Point[I].Y := NewY;
          Point[I].Z := NewZ;
        end;
      if Y <> 0 then
        for I := 0 to PointsNum - 1 do
        begin
          NewZ := Point[I].Z * cos(Angle) - Point[I].X * sin(Angle);
          NewX := Point[I].Z * sin(Angle) + Point[I].X * cos(Angle);
          Point[I].Z := NewZ;
          Point[I].X := NewX;
        end;
    end;
end;

procedure TGrEn.ChObjCol(var Object3D: TObject3D; Color: TColor);
begin
  Object3D.Color := Color;
end;

procedure TGrEn.SLSPos(Position, Direction: TPoint3D);
var
  Result: TPoint3D;
  Length: single;
begin
  GVec(Position, Direction, Result);
  Length := VMgn(Result);
  if Length = 0 then
    Length := 0.00001;
  Result.X := Result.X / Length;
  Result.Y := Result.Y / Length;
  Result.Z := Result.Z / Length;
  LS := Result;
end;

end.
