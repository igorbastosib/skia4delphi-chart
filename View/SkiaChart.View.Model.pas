unit SkiaChart.View.Model;

interface

uses
  System.Generics.Collections,
  System.Messaging,

  SkiaChart.Controller.Chart,

  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  System.Skia, FMX.Ani, FMX.Controls.Presentation, FMX.Objects, FMX.Skia,
  FMX.Layouts;

type
  TFrmSkiaChartModel = class(TFrame)
    lytLegend: TLayout;
    skChart: TSkPaintBox;
    lytSelectedItem: TLayout;
    rctSelectedItemBackground: TRectangle;
    lytSelectedItemBackground: TLayout;
    lblSelectedItemText: TLabel;
    lytSelectedItemBottom: TLayout;
    lblSelectedItemValue: TLabel;
    lytSelectedItemColor: TLayout;
    rctSelectedItemColor: TRectangle;
    caniSelectedItem: TColorAnimation;
    tmrLabel: TTimer;
    faniSelectedItemX: TFloatAnimation;
    faniSelectedItemY: TFloatAnimation;
    tmrAnimation: TTimer;
    procedure rctSelectedItemBackgroundClick(Sender: TObject);
    procedure rctSelectedItemBackgroundTap(Sender: TObject; const Point: TPointF);
    procedure tmrLabelTimer(Sender: TObject);
    procedure lytSelectedItemBottomPainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure lytLegendPainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure skChartDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
  public
    type
    TChartItem = SkiaChart.Controller.Chart.TChartItem;
  private
    { Private declarations }
  protected
    const
      CAryColors: array [0 .. 10] of LongWord = (
        $FF36A2EB, // 0
        $FFFE6383,
        $FFFE9F3E,
        $FFFFCB55,
        $FF4AC0C0,
        $FF9966FF,
        $FFCACACA,
        $FF4CAF50,
        $FFFFF59D,
        $FFE1F5FE,
        $FFFF4081 // Hot pink
      );
    var
      FItems: TArray<TChartItem>;
      FAnimationProgress: Single; // Progresso da animação (0 a 1)
      FAnimationSpeed: Single; // Velocidade da animação
      FSelectedItem: Integer; // Índice da barra selecionada (-1 = nenhuma)
      FObjLstLegend: TObjectList<TLayoutLegend>;
      FLegendSize: Single;
    procedure OnLegendTap(Sender: TObject; const APoint: TPointF); virtual;
    procedure SetLegendSize(const Value: Single); virtual;

    procedure DoChartDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); virtual; abstract;
    { Protected declarations }
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure StartAnimation; virtual;
    procedure Clear; virtual;
    procedure ItemAdd(AValue: Double; AText: string); overload; virtual;
    procedure ItemAdd(AValue: Double; AColor: TAlphaColor; AText: string); overload; virtual;
    property LegendSize: Single read FLegendSize write SetLegendSize;
    { Public declarations }
  end;

implementation

uses
  System.Math;

{$R *.fmx}

{ TBarItem }

procedure TFrmSkiaChartModel.Clear;
begin
  skChart.OnDraw := nil;
  lytLegend.OnPainting := nil;
  try
    SetLength(FItems, 0);
    FObjLstLegend.Clear;
  finally
    skChart.OnDraw := skChartDraw;
    lytLegend.OnPainting := lytLegendPainting;
  end;
end;

constructor TFrmSkiaChartModel.Create(AOwner: TComponent);
begin
  inherited;
  SetLength(FItems, 0);
  FLegendSize := 1;
  FObjLstLegend := TObjectList<TLayoutLegend>.Create;
end;

destructor TFrmSkiaChartModel.Destroy;
begin
  if Assigned(FObjLstLegend) then
  begin
    try
      while FObjLstLegend.Count > 0 do
        FObjLstLegend.ExtractAt(0);
      FreeAndNil(FObjLstLegend);
    except
    end;
  end;
  inherited;
end;

procedure TFrmSkiaChartModel.ItemAdd(AValue: Double; AColor: TAlphaColor;
  AText: string);
begin
  var LIndex := -1;
  for var i := Low(FItems) to High(FItems) do
  begin
    if FItems[i].Text = AText then
    begin
      LIndex := i;
      Break;
    end;
  end;
  if LIndex = -1 then
  begin
    LIndex := Length(FItems);
    SetLength(FItems, Succ(LIndex));
    FItems[LIndex] := TChartItem.Create(AValue, AColor, AText);
    var LLyt := TLayoutLegend.Create(Self);
    LLyt.Parent := lytLegend;
    LLyt.OnTap := OnLegendTap;
    LLyt.Text.Text := FItems[LIndex].Text;
    LLyt.Color := FItems[LIndex].Color;
    LLyt.&Index := LIndex;
    FObjLstLegend.Add(LLyt);
  end
  else
  begin
    FItems[LIndex].Value := AValue;
  end;
  skChart.Redraw;
end;

procedure TFrmSkiaChartModel.ItemAdd(AValue: Double; AText: string);
begin
  var LIndex := Length(FItems);
  if LIndex > Pred(Length(CAryColors)) then
    LIndex := LIndex - Length(CAryColors);
  ItemAdd(AValue, CAryColors[LIndex], AText);
end;

procedure TFrmSkiaChartModel.lytLegendPainting(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  lytLegend.OnPainting := nil;
  try
    var LHeightBase := 25 * FLegendSize;
    var LHeight := LHeightBase;
    var LPos: Single := 0;
    for var i := 0 to Pred(FObjLstLegend.Count) do
    begin
      var LLyt := FObjLstLegend[i];
      LLyt.LegendSize := FLegendSize;
      lytLegend.Height := LHeightBase;
      var LPosNew := LPos + LLyt.Width;
      if LPosNew > (lytLegend.Width - 5) then
      begin
        LHeight := LHeight + LHeightBase;
        LPos := 0;
      end;
      LLyt.Position.Y := LHeight - LHeightBase;
      LLyt.Position.X := LPos;
      LPos := LLyt.Position.X + LLyt.Width;
    end;
    lytLegend.Height := LHeight + 5;
  finally
    lytLegend.OnPainting := lytLegendPainting;
  end;
end;

procedure TFrmSkiaChartModel.lytSelectedItemBottomPainting(Sender: TObject;
  Canvas: TCanvas; const ARect: TRectF);
begin
  lytSelectedItem.Height := lytSelectedItemBottom.Position.Y + lytSelectedItemBottom.Height + 5;
end;

procedure TFrmSkiaChartModel.OnLegendTap(Sender: TObject; const APoint: TPointF);
begin
  var LEnabledCount := 2;
  if FItems[TLayoutLegend(Sender).&Index].Enabled then
  begin
    LEnabledCount := 0;
    for var i := Low(FItems) to High(FItems) do
    begin
      if FItems[i].Enabled then
        Inc(LEnabledCount);
      if LEnabledCount > 1 then
        Break;
    end;
  end;
  if LEnabledCount > 1 then
  begin
    FItems[TLayoutLegend(Sender).&Index].Enabled := not FItems[TLayoutLegend(Sender).&Index].Enabled;
    TMessageManager.DefaultManager.SendMessage(Sender, TMessagingItemEnabled.Create(TLayoutLegend(Sender).&Index, FItems[TLayoutLegend(Sender).&Index].Enabled));
    skChart.Redraw;
  end;
end;

procedure TFrmSkiaChartModel.rctSelectedItemBackgroundClick(Sender: TObject);
begin
{$IFDEF MSWINDOWS}
  if (Sender.InheritsFrom(TControl)) and (Assigned(TControl(Sender).OnTap)) then
    TControl(Sender).OnTap(Sender, TPointF.Create(0, 0));
{$ENDIF}
end;

procedure TFrmSkiaChartModel.rctSelectedItemBackgroundTap(Sender: TObject;
  const Point: TPointF);
begin
  if tmrLabel.Enabled then
    Exit;
  FSelectedItem := -1;
end;

procedure TFrmSkiaChartModel.SetLegendSize(const Value: Single);
begin
  FLegendSize := Value;
  lytLegend.Repaint;
end;

procedure TFrmSkiaChartModel.skChartDraw(ASender: TObject;
  const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
begin
  DoChartDraw(ASender, ACanvas, ADest, AOpacity);
end;

procedure TFrmSkiaChartModel.StartAnimation;
begin
  FAnimationProgress := 0;
  FSelectedItem := -1;
  lytSelectedItem.Visible := False;
  tmrAnimation.Enabled := True;
  skChart.Redraw;
end;

procedure TFrmSkiaChartModel.tmrLabelTimer(Sender: TObject);
begin
  tmrLabel.Enabled := False;
end;

end.
