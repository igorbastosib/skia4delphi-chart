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
  LRadius := Min(ADest.Width, ADest.Height) / 2 * 0.8; // 80% of current size

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

  try
    UpdateLegend(FSelectedItem, LCenter, LRadius, LTotal);
  except
    
  end;
end;

procedure TFrmSkiaChartPie.skChartMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LCenter: TPointF;
  LRadius: Single;
  LTotal, LCurrentAngle, LSweepAngle: Single;
  LAngle: Single;
  LDistance: Single;
  LSlice: TChartItem;
  i: Integer;
begin
  inherited;
  // Check the center and radius
  LCenter := TPointF.Create(skChart.Width / 2, skChart.Height / 2);
  LRadius := Min(skChart.Width, skChart.Height) / 2 * 0.8;

  // Calculate the Clicked angle based on the center
  LAngle := ArcTan2(Y - LCenter.Y, X - LCenter.X) * 180 / Pi;
  if LAngle < 0 then
    LAngle := LAngle + 360; // Normalizar para 0-360 graus

  // Fix the angle based on stating angle 270
  LAngle := LAngle - 270;
  if LAngle < 0 then
    LAngle := LAngle + 360;

  // Check if the click is in the chart radius
  LDistance := Sqrt(Sqr(X - LCenter.X) + Sqr(Y - LCenter.Y));
  if LDistance <= LRadius then
  begin
    // Sum of enabled values
    LTotal := 0;
    for LSlice in FItems do
      if LSlice.Enabled then
        LTotal := LTotal + LSlice.Value;

    // Find the clicked slice
    LCurrentAngle := 0;
    for i := 0 to High(FItems) do
    begin
      if not FItems[i].Enabled then
        Continue;
      LSweepAngle := (FItems[i].Value / LTotal) * 360;
      if (LAngle >= LCurrentAngle) and (LAngle < LCurrentAngle + LSweepAngle) then
      begin
        if i = FSelectedItem then
          FSelectedItem := -1 // Deselect if second click
        else
          FSelectedItem := i; // Select the slice
        Break;
      end;
      LCurrentAngle := LCurrentAngle + LSweepAngle;
    end;
    UpdateLegend(FSelectedItem, LCenter, LRadius, LTotal);
    skChart.Redraw;
  end
  else
  begin
    FSelectedItem := -1; // Deselect
    UpdateLegend(FSelectedItem, LCenter, LRadius, LTotal);
  end;
end;

procedure TFrmSkiaChartPie.StartAnimation;
begin
  FAnimationSpeed := 5;
  tmrAnimation.Interval := 3;
  inherited;
end;

procedure TFrmSkiaChartPie.tmrAnimationTimer(Sender: TObject);
begin
  inherited;
  FAnimationProgress := FAnimationProgress + FAnimationSpeed;
  if FAnimationProgress >= 360 then
  begin
    tmrAnimation.Enabled := False; // Stop animation
    FAnimationProgress := 360; // Full circle
  end;
  FAnimationSpeed := FAnimationSpeed * 1.05;
  skChart.Redraw;
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
    (Length(FItems) = 0) or
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
        ACenter.X + Cos(LAngle) * ARadius * 0.7,
        ACenter.Y + Sin(LAngle) * ARadius * 0.7
        );
      lblSelectedItemText.Text := FItems[i].Text;
      lblSelectedItemValue.Text := 'R$ ' + FormatFloat('##0.,00', FItems[i].Value);
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
