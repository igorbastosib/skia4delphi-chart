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

    procedure UpdateLegend(AIndex: Integer; const ABarRects: TArray<TRectF> = []);
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
    ACanvas.DrawRect(LRect, LPaint);
    // If rounded corners are ever needed, use `ACanvas.DrawRoundRect`.

    Inc(LCurrentIndex);
  end;

  UpdateLegend(SelectedItem, LBarRects);
end;

procedure TFrmSkiaChartBars.skChartMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LMaxValue: Double;
  LEnabledCount: Integer;
  LBarWidth, LTotalWidth: Single;
  LStartX, LMaxHeight: Single;
  LRect: TRectF;
  i, LCurrentIndex: Integer;
  LBarRects: TArray<TRectF>;
begin
  inherited;
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

  if LEnabledCount = 0 then
    Exit;

  // Calcular dimensões
  LBarWidth := (skChart.Width - 2 * CBarMargin - (LEnabledCount - 1) * CBarSpacing) / LEnabledCount;
  LTotalWidth := LEnabledCount * LBarWidth + (LEnabledCount - 1) * CBarSpacing;
  LStartX := (skChart.Width - LTotalWidth) / 2;
  LMaxHeight := skChart.Height - 2 * CBarMargin;

  // Criar array de retângulos
  SetLength(LBarRects, LEnabledCount);
  LCurrentIndex := 0;
  var LSelectedFound := False;

  for i := 0 to High(FItems) do
  begin
    if not FItems[i].Enabled then
      Continue;

    // Definir o retângulo da barra
    LRect.Left := LStartX + LCurrentIndex * (LBarWidth + CBarSpacing);
    LRect.Right := LRect.Left + LBarWidth;
    LRect.Bottom := skChart.Height - CBarMargin;
    LRect.Top := LRect.Bottom - (FItems[i].Value / LMaxValue) * LMaxHeight * FAnimationProgress;

    // Armazenar o retângulo para interação
    LBarRects[LCurrentIndex] := LRect;

    // Verificar se o clique está na faixa vertical da barra (apenas coordenada X)
    if (X >= LRect.Left) and (X <= LRect.Right) then
    begin
      if i = SelectedItem then
        SelectedItem := -1 // Desselecionar se clicar novamente
      else
        SelectedItem := i; // Selecionar a barra
      LSelectedFound := True;
      Break;
    end;

    Inc(LCurrentIndex);
  end;

  // Desselecionar se o clique estiver fora das faixas verticais de todas as barras
  if not LSelectedFound then
    SelectedItem := -1;

  UpdateLegend(SelectedItem, LBarRects);
  skChart.Redraw;
end;

procedure TFrmSkiaChartBars.StartAnimation;
begin
  FAnimationSpeed := CInitialSpeed;
  tmrAnimation.Interval := CTimerInterval;
  inherited;
end;

procedure TFrmSkiaChartBars.tmrAnimationTimer(Sender: TObject);
begin
  inherited;
  FAnimationProgress := FAnimationProgress + FAnimationSpeed;
  if FAnimationProgress >= 1 then
  begin
    FAnimationProgress := 1;
    tmrAnimation.Enabled := False;
  end;
  skChart.Redraw;
end;

procedure TFrmSkiaChartBars.UpdateLegend(AIndex: Integer;
  const ABarRects: TArray<TRectF>);
var
  i, LCurrentIndex: Integer;
  LMaxValue, LMaxHeight, LBarWidth, LTotalWidth, LStartX: Single;
  LRect: TRectF;
  LBarRectsLocal: TArray<TRectF>;
begin
  if
    (AIndex < 0) or
    (AIndex >= Length(FItems)) or
    (not FItems[AIndex].Enabled)
  then
  begin
    lytSelectedItem.Visible := False;
    tmrLabel.Enabled := False;
    Exit;
  end;

  // Calcular dimensões para posicionar o rótulo
  LMaxValue := 0;
  LCurrentIndex := 0;
  for i := 0 to High(FItems) do
  begin
    if FItems[i].Enabled then
      LMaxValue := Max(LMaxValue, FItems[i].Value);
  end;

  // Contar barras habilitadas
  var LEnabledCount := 0;
  for i := 0 to High(FItems) do
    if FItems[i].Enabled then
      Inc(LEnabledCount);

  if LEnabledCount = 0 then
  begin
    lytSelectedItem.Visible := False;
    tmrLabel.Enabled := False;
    Exit;
  end;

  // Se ABarRects estiver vazio, recalcular os retângulos
  if Length(ABarRects) = 0 then
  begin
    LBarWidth := (skChart.Width - 2 * CBarMargin - (LEnabledCount - 1) * CBarSpacing) / LEnabledCount;
    LTotalWidth := LEnabledCount * LBarWidth + (LEnabledCount - 1) * CBarSpacing;
    LStartX := (skChart.Width - LTotalWidth) / 2;
    LMaxHeight := skChart.Height - 2 * CBarMargin;

    SetLength(LBarRectsLocal, LEnabledCount);
    LCurrentIndex := 0;
    for i := 0 to High(FItems) do
    begin
      if not FItems[i].Enabled then
        Continue;
      LRect.Left := LStartX + LCurrentIndex * (LBarWidth + CBarSpacing);
      LRect.Right := LRect.Left + LBarWidth;
      LRect.Bottom := skChart.Height - CBarMargin;
      LRect.Top := LRect.Bottom - (FItems[i].Value / LMaxValue) * LMaxHeight * FAnimationProgress;
      LBarRectsLocal[LCurrentIndex] := LRect;
      Inc(LCurrentIndex);
    end;
  end
  else
  begin
    LBarRectsLocal := ABarRects;
  end;

  // Encontrar a barra selecionada
  LCurrentIndex := 0;
  for i := 0 to High(FItems) do
  begin
    if not FItems[i].Enabled then
      Continue;
    if i = AIndex then
    begin
      LRect := LBarRectsLocal[LCurrentIndex];
      lblSelectedItemText.Text := FItems[i].Text;

      lblSelectedItemValue.Text := EmptyStr;
      if not CurrencySymbol.Trim.IsEmpty then
        lblSelectedItemValue.Text := CurrencySymbol + ' ';
      lblSelectedItemValue.Text := lblSelectedItemValue.Text + FormatFloat(CurrencyFormat, FItems[i].Value);

      var LPosX := LRect.Left + (LRect.Width - lytSelectedItem.Width) / 2;
      var LPosY := LRect.Top - lytSelectedItem.Height - CBarSpacing;
      var LColor := FItems[i].Color;

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
      Break;
    end;
    Inc(LCurrentIndex);
  end;
end;

end.
