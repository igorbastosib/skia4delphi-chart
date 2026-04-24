unit SkiaChart.View.Pie;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  SkiaChart.View.Model, System.Skia, FMX.Ani, FMX.Controls.Presentation,
  FMX.Objects, FMX.Skia, FMX.Layouts;

type
  TFrmSkiaChartPie = class(TFrmSkiaChartModel)
    procedure skChartMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure tmrAnimationTimer(Sender: TObject);
  private
    const
    CStartAngle = 270; // Start from 270 (12 hours)
    CRadiusFactor = 0.8;   // was 0.8 inline, correspond of 80% of current size
    CLabelRadiusFactor = 0.7;  // was 0.7 inline
    CAccelerationRate = 1.02;  // was 1.05 inline, see TODO20260422.md P4 (extra info)
    CInitialSpeed = 5;

    procedure UpdateLegend(AIndex: Integer; ACenter: TPointF; ARadius: Single; ATotal: Single);
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

{ TFrmSkiaChartPie }

procedure TFrmSkiaChartPie.DoChartDraw(ASender: TObject;
  const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
var
  LCenter: TPointF;
  LRadius: Single;
  LStartAngle, LSweepAngle, LTotal, LCurrentAngle: Single;
  LSlice: TChartItem;
  LPaint: ISkPaint;
  LPathBuilder: ISkPathBuilder;
  LPath: ISkPath;
  LRect: TRectF;
  LFont: ISkFont;
  i: Integer;
begin
  // inherited;
  // Center and radius of chart
  LCenter := TPointF.Create(ADest.Width / 2, ADest.Height / 2);
  LRadius := Min(ADest.Width, ADest.Height) / 2 * CRadiusFactor;

  // Sum of enabled values
  LTotal := 0;
  for LSlice in FItems do
    if LSlice.Enabled then
    begin
      LTotal := LTotal + LSlice.Value
    end;

  // Initialize
  LPaint := TSkPaint.Create;
  LPaint.AntiAlias := True;
  LPaint.Style := TSkPaintStyle.Fill;

  // Paint the slices based on the animation angle
  LStartAngle := CStartAngle;
  LCurrentAngle := 0;

  for i := 0 to High(FItems) do
  begin
    if not FItems[i].Enabled then
      Continue;
    // Check the Slice's angle
    LSweepAngle := (FItems[i].Value / LTotal) * 360;

    // Check if paint the Slice (artially or complete)
    if (LCurrentAngle < FAnimationProgress) then
    begin
      var
      LDrawAngle := Min(LSweepAngle, FAnimationProgress - LCurrentAngle); // Angle to draw
      if LDrawAngle > 0 then
      begin
        // Slice color
        LPaint.Color := FItems[i].Color;

        // draw the path
        LPathBuilder := TSkPathBuilder.Create;
        try
          LRect := TRectF.Create(LCenter.X - LRadius, LCenter.Y - LRadius, LCenter.X + LRadius, LCenter.Y + LRadius);
          LPathBuilder.MoveTo(LCenter); // Start from center

          if LDrawAngle >= 360 then
          begin
            LPathBuilder.AddCircle(LCenter.X, LCenter.Y, LRadius)
          end
          else
          begin
            LPathBuilder.ArcTo(LRect, LStartAngle, LDrawAngle, False); // Add arc
            LPathBuilder.LineTo(LCenter); // Back to center
            LPathBuilder.Close; // close path
          end;

          LPath := LPathBuilder.Detach;
          ACanvas.DrawPath(LPath, LPaint);
        finally
          LPathBuilder := nil;
        end;
      end;
    end;

    // Update angles
    LStartAngle := LStartAngle + LSweepAngle;
    LCurrentAngle := LCurrentAngle + LSweepAngle;
  end;

  UpdateLegend(SelectedItem, LCenter, LRadius, LTotal);
end;

procedure TFrmSkiaChartPie.skChartMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LCenter: TPointF;
  LRadius: Single;
  LTotal, LSweepAngle: Single;
  LAngle: Single;
  LDistance: Single;
  LSlice: TChartItem;
  i: Integer;
begin
  inherited;
  // Check the center and radius
  LCenter := TPointF.Create(skChart.Width / 2, skChart.Height / 2);
  LRadius := Min(skChart.Width, skChart.Height) / 2 * CRadiusFactor;

  // Calculate the Clicked angle based on the center
  LAngle := ArcTan2(Y - LCenter.Y, X - LCenter.X) * 180 / Pi;
  if LAngle < 0 then
    LAngle := LAngle + 360; // Normalizar para 0-360 graus

  // Fix the angle based on stating angle 270
  LAngle := LAngle - 270;
  if LAngle < 0 then
    LAngle := LAngle + 360;

  // Sum of enabled values
  LTotal := 0;
  // Check if the click is in the chart radius
  LDistance := Sqrt(Sqr(X - LCenter.X) + Sqr(Y - LCenter.Y));
  if LDistance <= LRadius then
  begin
    for LSlice in FItems do
      if LSlice.Enabled then
        LTotal := LTotal + LSlice.Value;

    var // Find the clicked slice
    LCurrentAngle : Single := 0;
    for i := 0 to High(FItems) do
    begin
      if not FItems[i].Enabled then
        Continue;
      LSweepAngle := (FItems[i].Value / LTotal) * 360;
      if (LAngle >= LCurrentAngle) and (LAngle < LCurrentAngle + LSweepAngle) then
      begin
        if i = SelectedItem then
          SelectedItem := -1 // Deselect if second click
        else
          SelectedItem := i; // Select the slice
        Break;
      end;
      LCurrentAngle := LCurrentAngle + LSweepAngle;
    end;
    UpdateLegend(SelectedItem, LCenter, LRadius, LTotal);
    skChart.Redraw;
  end
  else
  begin
    SelectedItem := -1; // Deselect
    UpdateLegend(SelectedItem, LCenter, LRadius, LTotal);
  end;
end;

procedure TFrmSkiaChartPie.StartAnimation;
begin
  FAnimationSpeed := CInitialSpeed;
  tmrAnimation.Interval := CTimerInterval;
  inherited;
end;

procedure TFrmSkiaChartPie.tmrAnimationTimer(Sender: TObject);
begin
  FAnimationProgress := FAnimationProgress + FAnimationSpeed;
  if FAnimationProgress >= 360 then
  begin
    tmrAnimation.Enabled := False;
    FAnimationProgress := 360;
  end
  else
    FAnimationSpeed := FAnimationSpeed * CAccelerationRate;
  skChart.Redraw; // always runs, final frame draws correctly
end;

procedure TFrmSkiaChartPie.UpdateLegend(AIndex: Integer; ACenter: TPointF;
  ARadius, ATotal: Single);
var
  LStartAngle, LSweepAngle, LAngle: Single;
  LCurrentAngle: Single;
  LLabelPos: TPointF;
  i: Integer;
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

  // Calculate the Legend position based on selected Slice
  LStartAngle := CStartAngle;
  LCurrentAngle := 0;
  for i := 0 to High(FItems) do
  begin
    if not FItems[i].Enabled then
      Continue;
    LSweepAngle := (FItems[i].Value / ATotal) * 360;
    if i = AIndex then
    begin
      LAngle := DegToRad(LStartAngle + LSweepAngle / 2);
      LLabelPos := TPointF.Create(
        ACenter.X + Cos(LAngle) * ARadius * CLabelRadiusFactor,
        ACenter.Y + Sin(LAngle) * ARadius * CLabelRadiusFactor
        );
      lblSelectedItemText.Text := FItems[i].Text;

      lblSelectedItemValue.Text := EmptyStr;
      if not CurrencySymbol.Trim.IsEmpty then
        lblSelectedItemValue.Text := CurrencySymbol + ' ';
      lblSelectedItemValue.Text := lblSelectedItemValue.Text + FormatFloat(CurrencyFormat, FItems[i].Value);
      var
      LPosX := LLabelPos.X - lytSelectedItem.Width / 2; // Horizontal center
      var
      LPosY := LLabelPos.Y - lytSelectedItem.Height / 2; // Vertical center
      var
      LColor := FItems[i].Color;
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
    LStartAngle := LStartAngle + LSweepAngle;
    LCurrentAngle := LCurrentAngle + LSweepAngle;
  end;
end;

end.
