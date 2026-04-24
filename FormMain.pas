unit FormMain;

interface

uses
  System.Generics.Collections,

  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, System.Skia,
  FMX.Skia, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Objects,
  FMX.Ani, FMX.ListBox;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Layout1: TLayout;
    tbarLegendSize: TTrackBar;
    lytChartType: TLayout;
    lytOptions: TLayout;
    lblLegendSize: TLabel;
    Label1: TLabel;
    cbxChartType: TComboBox;
    procedure Button1Click(Sender: TObject);
    procedure tbarLegendSizeChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    type
    ChartType = (ctBar, ctPie);
    var
    FFrmChart: TFrame;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  System.TypInfo,
  SkiaChart.View.Model,
  SkiaChart.View.Bars,
  SkiaChart.View.Pie;

{$R *.fmx}

procedure TForm1.Button1Click(Sender: TObject);
begin
  case ChartType(GetEnumValue(TypeInfo(ChartType), cbxChartType.Text)) of
    ChartType.ctPie:
      begin
        if (Assigned(FFrmChart)) and (not FFrmChart.InheritsFrom(TFrmSkiaChartPie)) then
            FreeAndNil(FFrmChart);
        if not (Assigned(FFrmChart)) then
          FFrmChart := TFrmSkiaChartPie.Create(Self);
      end;
    ChartType.ctBar:
      begin
        if (Assigned(FFrmChart)) and (not FFrmChart.InheritsFrom(TFrmSkiaChartBars)) then
            FreeAndNil(FFrmChart);
        if not (Assigned(FFrmChart)) then
          FFrmChart := TFrmSkiaChartBars.Create(Self);
      end;
  end;

  FFrmChart.Parent := Self;
  FFrmChart.Align := TAlignLayout.Client;
  FFrmChart.Margins.Top := 10;

  TFrmSkiaChartModel(FFrmChart).LegendSize := tbarLegendSize.Value / 100;
  TFrmSkiaChartModel(FFrmChart).Clear;
  TFrmSkiaChartModel(FFrmChart).ItemAdd(32415, 'Category 1');
  TFrmSkiaChartModel(FFrmChart).ItemAdd(10000, 'Category 2');
  TFrmSkiaChartModel(FFrmChart).ItemAdd(5000, 'Category 3');
  TFrmSkiaChartModel(FFrmChart).ItemAdd(10661.88, 'Category 4');
  TFrmSkiaChartModel(FFrmChart).ItemAdd(5000, 'Category 5');
  TFrmSkiaChartModel(FFrmChart).ItemAdd(1518, 'Category 6');
  TFrmSkiaChartModel(FFrmChart).ItemAdd(14206.67, 'Category 7');
  TFrmSkiaChartModel(FFrmChart).StartAnimation;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FFrmChart := nil;
  for var LItem := Low(ChartType) to High(ChartType) do
  begin
    cbxChartType.Items.Add(GetEnumName(TypeInfo(ChartType), Ord(LItem)));
  end;
  cbxChartType.ItemIndex := 0;
end;

procedure TForm1.tbarLegendSizeChange(Sender: TObject);
begin
  if Assigned(FFrmChart) then
    TFrmSkiaChartModel(FFrmChart).LegendSize := tbarLegendSize.Value / 100;
  lblLegendSize.Text := 'Legend size: ' + tbarLegendSize.Value.ToString;
end;

end.
