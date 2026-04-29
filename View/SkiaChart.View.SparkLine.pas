unit SkiaChart.View.SparkLine;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  SkiaChart.View.Model, System.Skia, FMX.Ani, FMX.Controls.Presentation,
  FMX.Objects, FMX.Skia, FMX.Layouts;

type
  TFrmSkiaChartSparkLine = class(TFrmSkiaChartModel)
    procedure tmrAnimationTimer(Sender: TObject);
  private
    const
      CInitialSpeed   = 0.05;
      CStrokeWidth    = 1.5;
      CRangePadding   = 5;
      CFillAlphaShift = $40000000;
    var
      FLineColor: TAlphaColor;
  protected
    procedure DoChartDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure StartAnimation; override;
    // When set to a non-zero color, every segment is drawn in that color
    // instead of the per-item Color. Set to 0 to restore per-item coloring.
    property LineColor: TAlphaColor read FLineColor write FLineColor;
  end;

implementation

uses
  System.Math;

{$R *.fmx}

{ TFrmSkiaChartSparkLine }

constructor TFrmSkiaChartSparkLine.Create(AOwner: TComponent);
begin
  inherited;
  FLineColor := 0;
end;

procedure TFrmSkiaChartSparkLine.DoChartDraw(ASender: TObject;
  const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
var
  LEnabledCount, i: Integer;
  LMin, LMax, LRange: Double;
  LStep, LDrawWidth: Single;
  LX, LY: TArray<Single>;
  LColors: TArray<TAlphaColor>;
  LSegFill: ISkPathBuilder;
  LSegStroke: ISkPathBuilder;
  LFillPath, LStrokePath: ISkPath;
  LPaint: ISkPaint;
  LFirst: Boolean;
  LSegColor, LSegFillColor: TAlphaColor;
  LClipRect: TRectF;
begin
  LEnabledCount := 0;
  LMin := 0;
  LMax := 0;
  LFirst := True;
  SetLength(LX, Length(FItems));
  SetLength(LY, Length(FItems));
  SetLength(LColors, Length(FItems));

  for i := 0 to High(FItems) do
  begin
    if not FItems[i].Enabled then
      Continue;
    if LFirst then
    begin
      LMin := FItems[i].Value;
      LMax := FItems[i].Value;
      LFirst := False;
    end
    else
    begin
      if FItems[i].Value > LMax then LMax := FItems[i].Value;
      if FItems[i].Value < LMin then LMin := FItems[i].Value;
    end;
    Inc(LEnabledCount);
  end;

  if LEnabledCount < 2 then
    Exit;

  LRange := LMax - LMin;
  if LRange < CRangePadding then
  begin
    LMax   := LMax + (CRangePadding - LRange) / 2;
    LMin   := Max(0, LMin - (CRangePadding - LRange) / 2);
    LRange := LMax - LMin;
  end;
  if LRange <= 0 then
    LRange := 1;

  LStep      := ADest.Width / (LEnabledCount - 1);
  LDrawWidth := ADest.Width * FAnimationProgress;

  SetLength(LX, LEnabledCount);
  SetLength(LY, LEnabledCount);
  SetLength(LColors, LEnabledCount);

  var LPlot := 0;
  for i := 0 to High(FItems) do
  begin
    if not FItems[i].Enabled then
      Continue;
    LX[LPlot]      := ADest.Left + LPlot * LStep;
    LY[LPlot]      := ADest.Bottom - ((FItems[i].Value - LMin) / LRange) * ADest.Height;
    LY[LPlot]      := Max(ADest.Top + 1, Min(ADest.Bottom - 1, LY[LPlot]));
    LColors[LPlot] := FItems[i].Color;
    Inc(LPlot);
  end;

  LClipRect := TRectF.Create(ADest.Left, ADest.Top, ADest.Left + LDrawWidth, ADest.Bottom);
  ACanvas.Save;
  try
    ACanvas.ClipRect(LClipRect);

    LPaint := TSkPaint.Create;
    LPaint.AntiAlias := True;

    for i := 0 to LEnabledCount - 2 do
    begin
      if FLineColor <> 0 then
        LSegColor := FLineColor
      else
        LSegColor := LColors[i + 1];
      LSegFillColor := (LSegColor and $00FFFFFF) or CFillAlphaShift;

      LSegFill := TSkPathBuilder.Create;
      LSegFill.MoveTo(LX[i],     ADest.Bottom);
      LSegFill.LineTo(LX[i],     LY[i]);
      LSegFill.LineTo(LX[i + 1], LY[i + 1]);
      LSegFill.LineTo(LX[i + 1], ADest.Bottom);
      LSegFill.Close;
      LFillPath := LSegFill.Detach;

      LSegStroke := TSkPathBuilder.Create;
      LSegStroke.MoveTo(LX[i],     LY[i]);
      LSegStroke.LineTo(LX[i + 1], LY[i + 1]);
      LStrokePath := LSegStroke.Detach;

      LPaint.Style := TSkPaintStyle.Fill;
      LPaint.Color := LSegFillColor;
      ACanvas.DrawPath(LFillPath, LPaint);

      LPaint.Style := TSkPaintStyle.Stroke;
      LPaint.Color := LSegColor;
      LPaint.StrokeWidth := CStrokeWidth;
      ACanvas.DrawPath(LStrokePath, LPaint);
    end;
  finally
    ACanvas.Restore;
  end;
end;

procedure TFrmSkiaChartSparkLine.StartAnimation;
begin
  FAnimationSpeed := CInitialSpeed;
  tmrAnimation.Interval := CTimerInterval;
  inherited;
end;

procedure TFrmSkiaChartSparkLine.tmrAnimationTimer(Sender: TObject);
begin
  FAnimationProgress := FAnimationProgress + FAnimationSpeed;
  if FAnimationProgress >= 1 then
  begin
    FAnimationProgress := 1;
    tmrAnimation.Enabled := False;
  end;
  skChart.Redraw;
end;

end.
