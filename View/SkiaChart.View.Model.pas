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
  TChartItemSelectedEvent = procedure(Sender: TObject; AIndex: Integer) of object;
  TFrmSkiaChartModelClass = class of TFrmSkiaChartModel;

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
    const
    CLegendHeightBaseFactor = 25; // was 25 inline

    var
    FOnItemSelected: TChartItemSelectedEvent;

    FCurrencySymbol: string;
    FCurrencyFormat: string;

    procedure SetSelectedItem(AValue: Integer);
    function GetCurrencySymbol: string;
    function GetCurrencyFormat: string;
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

      CTimerInterval = 16;    // was 3, see TODO20260422.md P4
    var
      FItems: TArray<TChartItem>;
      FAnimationProgress: Single; // Progresso da animação (0 a 1)
      FAnimationSpeed: Single; // Velocidade da animação
      FSelectedItem: Integer; // Índice da barra selecionada (-1 = nenhuma)
      FObjLstLegend: TObjectList<TLayoutLegend>;
      FLegendSize: Single;
    procedure OnLegendTap(Sender: TObject; const APoint: TPointF); virtual;
    procedure SetLegendSize(const Value: Single); virtual;
    procedure DoItemSelected; virtual;

    procedure DoChartDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); virtual; abstract;
    { Protected declarations }
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure StartAnimation; virtual;
    procedure Clear; virtual;
    procedure CopyItemsFrom(ASource: TFrmSkiaChartModel);
    class procedure SwitchType(var AChart: TFrmSkiaChartModel;
      ANewClass: TFrmSkiaChartModelClass; AOwner: TComponent);

    procedure ItemAdd(AValue: Double; AText: string); overload; virtual;
    procedure ItemAdd(AValue: Double; AColor: TAlphaColor; AText: string); overload; virtual;
    function ItemsCount: Integer;

    property LegendSize: Single read FLegendSize write SetLegendSize;

    property SelectedItem: Integer read FSelectedItem write SetSelectedItem;
    property OnItemSelected: TChartItemSelectedEvent read FOnItemSelected write FOnItemSelected;

    property CurrencySymbol: string read GetCurrencySymbol write FCurrencySymbol;
    property CurrencyFormat: string read GetCurrencyFormat write FCurrencyFormat;
    { Public declarations }
  end;

implementation

uses
  System.Math;

{$R *.fmx}

{ TBarItem }

procedure TFrmSkiaChartModel.CopyItemsFrom(ASource: TFrmSkiaChartModel);
var
  i: Integer;
begin
  Clear;
  for i := 0 to High(ASource.FItems) do
    ItemAdd(ASource.FItems[i].Value, ASource.FItems[i].Color, ASource.FItems[i].Text);
  // ItemAdd always creates items with Enabled=True; restore the original toggle state
  for i := 0 to High(FItems) do
    FItems[i].Enabled := ASource.FItems[i].Enabled;
  LegendSize := ASource.FLegendSize;
end;

class procedure TFrmSkiaChartModel.SwitchType(var AChart: TFrmSkiaChartModel;
  ANewClass: TFrmSkiaChartModelClass; AOwner: TComponent);
var
  LNew: TFrmSkiaChartModel;
begin
  if Assigned(AChart) and (AChart.ClassType = ANewClass) then
  begin
    AChart.StartAnimation; // already the right type — just re-animate
    Exit;
  end;

  LNew := ANewClass.Create(AOwner);

  if Assigned(AChart) then
  begin
    LNew.CopyItemsFrom(AChart);       // transfer data + legend state + LegendSize
    LNew.Parent := AChart.Parent;
    LNew.Align  := AChart.Align;
    LNew.Margins.Rect := AChart.Margins.Rect;
    AChart.Free;
  end;

  AChart := LNew;
  AChart.StartAnimation;
end;

procedure TFrmSkiaChartModel.Clear;
begin
  skChart.OnDraw := nil;
  lytLegend.OnPainting := nil;
  try
    SetLength(FItems, 0);
    FObjLstLegend.Clear;
    FSelectedItem := -1;
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

  CurrencySymbol := EmptyStr;
  CurrencyFormat := EmptyStr;
end;

destructor TFrmSkiaChartModel.Destroy;
begin
  FreeAndNil(FObjLstLegend); // No need to loop removing items, since Parent will forcedly free them
  inherited;
end;

procedure TFrmSkiaChartModel.DoItemSelected;
begin
  if Assigned(FOnItemSelected) then
    FOnItemSelected(Self, FSelectedItem);
end;

function TFrmSkiaChartModel.GetCurrencyFormat: string;
begin
  Result := FCurrencyFormat;
  if Result.Trim.IsEmpty then
    Result := '##0' + FormatSettings.ThousandSeparator + FormatSettings.DecimalSeparator + '00';
end;

function TFrmSkiaChartModel.GetCurrencySymbol: string;
begin
  Result := FCurrencyFormat;
  if Result.Trim.IsEmpty then
    Result := FormatSettings.CurrencyString;
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
    var // Keep Owner=NIL, so the Parent will free the Layout
    LLyt := TLayoutLegend.Create(nil);
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

function TFrmSkiaChartModel.ItemsCount: Integer;
begin
  Result := Length(FItems);
end;

procedure TFrmSkiaChartModel.ItemAdd(AValue: Double; AText: string);
begin
  var
  LIndex := Length(FItems) mod Length(CAryColors);
  ItemAdd(AValue, CAryColors[LIndex], AText);
end;

procedure TFrmSkiaChartModel.lytLegendPainting(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  lytLegend.OnPainting := nil;
  try
    var LHeightBase := CLegendHeightBaseFactor * FLegendSize;
    var LHeight := LHeightBase;
    var LPos: Single := 0;
    for var i := 0 to Pred(FObjLstLegend.Count) do
    begin
      var LLyt := FObjLstLegend[i];
      LLyt.LegendSize := FLegendSize;
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
var
  LIndex, LEnabledCount, i: Integer;
  LIsDisabling: Boolean;
begin
  LIndex := TLayoutLegend(Sender).&Index;
  LIsDisabling := FItems[LIndex].Enabled;

  if LIsDisabling then
  begin
    LEnabledCount := 0;
    for i := Low(FItems) to High(FItems) do
      if FItems[i].Enabled then
        Inc(LEnabledCount);
    if LEnabledCount <= 1 then
      Exit; // refuse to disable the last visible item
  end;

  FItems[LIndex].Enabled := not FItems[LIndex].Enabled;
  TMessageManager.DefaultManager.SendMessage(Sender,
    TMessagingItemEnabled.Create(LIndex, FItems[LIndex].Enabled));
  skChart.Redraw;
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

procedure TFrmSkiaChartModel.SetSelectedItem(AValue: Integer);
begin
  if FSelectedItem = AValue then
    Exit;
  FSelectedItem := AValue;
  DoItemSelected;
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
