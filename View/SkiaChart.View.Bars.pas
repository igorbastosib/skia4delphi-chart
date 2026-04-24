unit SkiaChart.View.Bars;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  SkiaChart.View.Model, System.Skia, FMX.Ani, FMX.Controls.Presentation,
  FMX.Objects, FMX.Skia, FMX.Layouts;

type
  TFrmSkiaChartBars = class(TFrmSkiaChartModel)
    procedure skChartMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure tmrAnimationTimer(Sender: TObject);
  private
    const
      CBarSpacing = 10; // Espaçamento entre barras
      CBarMargin = 20; // Margem interna no gráfico
      CInitialSpeed = 0.05;
    var
      FLastBarRects: TArray<TRectF>;
      FLastBarItemIndex: TArray<Integer>;

    procedure UpdateLegend(AIndex: Integer);
    { Private declarations }
  protected
    procedure DoChartDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); override;
    { Protected declarations }
  public
    procedure StartAnimation; override;
    { Public declarations }
  end;

implementation

uses
  System.Math;

{$R *.fmx}

{ TFrmSkiaChartBars }

procedure TFrmSkiaChartBars.DoChartDraw(ASender: TObject;
  const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
var
  LMaxValue: Double;
  LEnabledCount: Integer;
  LBarWidth, LTotalWidth: Single;
  LPaint: ISkPaint;
  LPathBuilder: ISkPathBuilder;
  LPath: ISkPath;
  LRect: TRectF;
  i: Integer;
  LBarRects: TArray<TRectF>;
begin
  // inherited;
  // Contar barras habilitadas e encontrar o valor máximo
  LMaxValue := 0;
  LEnabledCount := 0;
  for i := 0 to High(FItems) do
  begin
    if FItems[i].Enabled then
    begin
      LMaxValue := Max(LMaxValue, FItems[i].Value);
      Inc(LEnabledCount);
    end;
  end;

  // Se nenhuma barra estiver habilitada, sair
  if LEnabledCount = 0 then
    Exit;

  // Configurar o pincel
  LPaint := TSkPaint.Create;
  LPaint.AntiAlias := True;
  LPaint.Style := TSkPaintStyle.Fill;

  // Calcular dimensões das barras
  LBarWidth := (ADest.Width - 2 * CBarMargin - (LEnabledCount - 1) * CBarSpacing) / LEnabledCount;
  LTotalWidth := LEnabledCount * LBarWidth + (LEnabledCount - 1) * CBarSpacing;
  var LStartX := ADest.Left + (ADest.Width - LTotalWidth) / 2; // Centralizar
  var LMaxHeight := ADest.Height - 2 * CBarMargin;

  // Armazenar retângulos para interação
  SetLength(LBarRects, LEnabledCount);
  SetLength(FLastBarRects, LEnabledCount);
  SetLength(FLastBarItemIndex, LEnabledCount);

  var LCurrentIndex := 0;

  // Desenhar as barras
  for i := 0 to High(FItems) do
  begin
    if not FItems[i].Enabled then
      Continue;

    // Calcular a altura da barra (proporcional ao valor máximo)
    var LHeight := (FItems[i].Value / LMaxValue) * LMaxHeight * FAnimationProgress;

    // Definir o retângulo da barra
    LRect.Left := LStartX + LCurrentIndex * (LBarWidth + CBarSpacing);
    LRect.Right := LRect.Left + LBarWidth;
    LRect.Bottom := ADest.Bottom - CBarMargin;
    LRect.Top := LRect.Bottom - LHeight;

    // Armazenar o retângulo para interação
    LBarRects[LCurrentIndex] := LRect;

    // Desenhar a barra
    LPaint.Color := FItems[i].Color;

    FLastBarRects[LCurrentIndex] := LRect;
    FLastBarItemIndex[LCurrentIndex] := i;

    ACanvas.DrawRect(LRect, LPaint);
    // If rounded corners are ever needed, use `ACanvas.DrawRoundRect`.

    Inc(LCurrentIndex);
  end;

  UpdateLegend(SelectedItem);
end;

procedure TFrmSkiaChartBars.skChartMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  i: Integer;
  LHit: Boolean;
begin
  // inherited; // this will call TFrame instead (check TODO20260422.md)
  LHit := False;
  for i := 0 to High(FLastBarRects) do
    if (X >= FLastBarRects[i].Left) and (X <= FLastBarRects[i].Right) then
    begin
      if FLastBarItemIndex[i] = SelectedItem then
        SelectedItem := -1
      else
        SelectedItem := FLastBarItemIndex[i];
      LHit := True;
      Break;
    end;
  if not LHit then
    SelectedItem := -1;
  skChart.Redraw;   // re-draws + UpdateLegend inside DoChartDraw
end;

procedure TFrmSkiaChartBars.StartAnimation;
begin
  FAnimationSpeed := CInitialSpeed;
  tmrAnimation.Interval := CTimerInterval;
  inherited;
end;

procedure TFrmSkiaChartBars.tmrAnimationTimer(Sender: TObject);
begin
  // inherited; // this will call TFrame instead (check TODO20260422.md)
  FAnimationProgress := FAnimationProgress + FAnimationSpeed;
  if FAnimationProgress >= 1 then
  begin
    FAnimationProgress := 1;
    tmrAnimation.Enabled := False;
  end;
  skChart.Redraw;
end;

procedure TFrmSkiaChartBars.UpdateLegend(AIndex: Integer);
var
  k, LRectIndex: Integer;
  LRect: TRectF;
begin
  if (AIndex < 0) or (AIndex >= Length(FItems)) or (not FItems[AIndex].Enabled) then
  begin
    lytSelectedItem.Visible := False;
    tmrLabel.Enabled := False;
    Exit;
  end;

  // Reverse-lookup: find which slot in FLastBarRects corresponds to AIndex
  LRectIndex := -1;
  for k := 0 to High(FLastBarItemIndex) do
    if FLastBarItemIndex[k] = AIndex then
    begin
      LRectIndex := k;
      Break;
    end;
  if LRectIndex = -1 then Exit;   // not drawn yet (first paint hasn't happened)

  LRect := FLastBarRects[LRectIndex];
  lblSelectedItemText.Text := FItems[AIndex].Text;
  lblSelectedItemValue.Text := 'R$ ' + FormatFloat('##0.,00', FItems[AIndex].Value);

  var LPosX := LRect.Left + (LRect.Width - lytSelectedItem.Width) / 2;
  var LPosY := LRect.Top - lytSelectedItem.Height - 10;
  var LColor := FItems[AIndex].Color;

  tmrLabel.Enabled := False;
  if lytSelectedItem.Visible then
  begin
    faniSelectedItemX.StartValue := lytSelectedItem.Position.X;
    faniSelectedItemY.StartValue := lytSelectedItem.Position.Y;
    caniSelectedItem.StartValue := rctSelectedItemColor.Fill.Color;
    faniSelectedItemX.StopValue := LPosX;
    faniSelectedItemY.StopValue := LPosY;
    caniSelectedItem.StopValue := LColor;
    faniSelectedItemX.Start;
    faniSelectedItemY.Start;
    caniSelectedItem.Start;
  end
  else
  begin
    rctSelectedItemColor.Fill.Color := LColor;
    lytSelectedItem.Position.X := LPosX;
    lytSelectedItem.Position.Y := LPosY;
    lytSelectedItem.Visible := True;
  end;
  tmrLabel.Enabled := True;
end;

end.
