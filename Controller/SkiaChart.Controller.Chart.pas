unit SkiaChart.Controller.Chart;

interface

uses
  System.Messaging,
  System.UITypes,
  System.Classes,

  FMX.Layouts,
  FMX.Objects,
  FMX.StdCtrls;

type
  TMessagingItemEnabled = class(System.Messaging.TMessage)
  private
    FIndex: Integer;
    FEnabled: Boolean;
  protected
  public
    constructor Create(AIndex: Integer; AEnabled: Boolean);
    property &Index: Integer read FIndex write FIndex;
    property Enabled: Boolean read FEnabled write FEnabled;
  end;

  TChartItem = record
    Value: Double;
    Color: TAlphaColor;
    Text: string; // Text for the legend
    Enabled: Boolean;

    constructor Create(AValue: Double; AColor: TAlphaColor; AText: string; AEnabled: Boolean = True);
  end;

  TLayoutLegend = class(TLayout)
  private
    const
    FRectColorWidth = 35;
    FRectColorHeight = 20;

    var
    FRectColor: TRectangle;
    FLbl: TLabel;
    FIndex: Integer;
    FLegendSize: Single;

    procedure SetLegendSize(const Value: Single);
    function GetColor: TAlphaColor;
    procedure SetColor(const Value: TAlphaColor);
    { Private declarations }
  protected
    procedure Painting; override;
    procedure Click; override;
    procedure MessageListener(const Sender: TObject; const M: TMessage);
    { Protected declarations }
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property LegendSize: Single read FLegendSize write SetLegendSize;
    property Color: TAlphaColor read GetColor write SetColor;
    property Text: TLabel read FLbl;
    property &Index: Integer read FIndex write FIndex;
    { Public declarations }
  end;

implementation

uses
  System.Types,
  System.Math,

  FMX.Controls,
  FMX.Types,
  FMX.Graphics;

{ TMessagingItemEnabled }

constructor TMessagingItemEnabled.Create(AIndex: Integer; AEnabled: Boolean);
begin
  FIndex := AIndex;
  FEnabled := AEnabled;
end;

{ TChartItem }

constructor TChartItem.Create(AValue: Double; AColor: TAlphaColor;
  AText: string; AEnabled: Boolean);
begin
  Value := AValue;
  Color := AColor;
  Text := AText;
  Enabled := AEnabled;
end;

{ TLayoutLegend }

procedure TLayoutLegend.Click;
begin
{$IFDEF MSWINDOWS}
  Tap(TPointF.Create(0, 0));
{$ELSE}
  inherited;
{$ENDIF}
end;

constructor TLayoutLegend.Create(AOwner: TComponent);
begin
  inherited;
  HitTest := True;
  Height := 25;
  var
  LLytColor := TLayout.Create(Self);
  LLytColor.Parent := Self;
  LLytColor.Align := TAlignLayout.MostLeft;
  LLytColor.Width := FRectColorWidth;
  LLytColor.TabStop := False;
  LLytColor.HitTest := False;
  LLytColor.Margins.Left := 10;

  FRectColor := TRectangle.Create(Self);
  FRectColor.Parent := LLytColor;
  FRectColor.Align := TAlignLayout.VertCenter;
  FRectColor.Stroke.Kind := TBrushKind.None;
  FRectColor.Height := FRectColorHeight;
  FRectColor.Margins.Left := 5;
  FRectColor.Margins.Right := 5;
  FRectColor.HitTest := False;

  FLbl := TLabel.Create(Self);
  FLbl.Parent := Self;
  FLbl.Align := TAlignLayout.Left;
  FLbl.AutoSize := True;
  FLbl.WordWrap := False;
  FLbl.Margins.Left := 5;
  FLbl.HitTest := False;
  FLbl.StyledSettings := FLbl.StyledSettings - [TStyledSetting.Size, TStyledSetting.Style];

  TMessageManager.DefaultManager.SubscribeToMessage(TMessagingItemEnabled, MessageListener);
end;

destructor TLayoutLegend.Destroy;
begin
  TMessageManager.DefaultManager.Unsubscribe(TMessagingItemEnabled, MessageListener);
  inherited;
end;

function TLayoutLegend.GetColor: TAlphaColor;
begin
  Result := FRectColor.Fill.Color;
end;

procedure TLayoutLegend.MessageListener(const Sender: TObject;
  const M: TMessage);
begin
  if (M.InheritsFrom(TMessagingItemEnabled)) then
  begin
    var
    LMSE := M as TMessagingItemEnabled;
    if LMSE.Index = &Index then
    begin
      if (TFontStyle.fsStrikeOut in FLbl.TextSettings.Font.Style) then
        FLbl.TextSettings.Font.Style := FLbl.TextSettings.Font.Style - [TFontStyle.fsStrikeOut]
      else
        FLbl.TextSettings.Font.Style := FLbl.TextSettings.Font.Style + [TFontStyle.fsStrikeOut];
    end;
  end;
end;

procedure TLayoutLegend.Painting;
begin
  inherited;
  var LNewWidth := FLbl.Position.X + FLbl.Width + 10;
  if not SameValue(Width, LNewWidth) then
    Width := LNewWidth;
end;

procedure TLayoutLegend.SetColor(const Value: TAlphaColor);
begin
  FRectColor.Fill.Color := Value;
end;

procedure TLayoutLegend.SetLegendSize(const Value: Single);
begin
  if SameValue(FLegendSize, Value) then
    Exit;
  FLegendSize := Value;
  TControl(FRectColor.Parent).Width := FRectColorWidth * Value;
  FRectColor.Height := FRectColorHeight * Value;
  FLbl.TextSettings.Font.Size := 12 * Value;
  // Intentionally NOT setting Width here — FLbl.Width is stale until next paint.
end;

end.
