program SkiaChart;

uses
  System.StartUpCopy,
  FMX.Forms,
  FMX.Skia,
  FormMain in '..\FormMain.pas' {Form1},
  SkiaChart.Controller.Chart in '..\..\Controller\SkiaChart.Controller.Chart.pas',
  SkiaChart.View.Model in '..\..\View\SkiaChart.View.Model.pas' {FrmSkiaChartModel: TFrame},
  SkiaChart.View.Bars in '..\..\View\SkiaChart.View.Bars.pas' {FrmSkiaChartBars: TFrame},
  SkiaChart.View.Pie in '..\..\View\SkiaChart.View.Pie.pas' {FrmSkiaChartPie: TFrame};

{$R *.res}

begin
  GlobalUseSkia := True;
  ReportMemoryLeaksOnShutdown := True;

  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
