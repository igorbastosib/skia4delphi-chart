unit FormMain;

interface

uses
  System.Generics.Collections,
  SkiaChart.View.Model,

  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, System.Skia,
  FMX.Skia, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Objects,
  FMX.Ani, FMX.ListBox, FMX.Edit, FMX.EditBox, FMX.NumberBox, FMX.Colors;

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
    Layout2: TLayout;
    Button2: TButton;
    Layout3: TLayout;
    NumberBox1: TNumberBox;
    Label3: TLabel;
    Layout4: TLayout;
    Label2: TLabel;
    ComboColorBox1: TComboColorBox;
    GridLayout1: TGridLayout;
    Button3: TButton;
    Button4: TButton;
    procedure Button1Click(Sender: TObject);
    procedure tbarLegendSizeChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    type
    ChartType = (ctBar, ctPie, ctSparkLine);
    var
    FFrmChart: TFrmSkiaChartModel;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  System.TypInfo,
  SkiaChart.View.Bars,
  SkiaChart.View.Pie,
  SkiaChart.View.SparkLine;

{$R *.fmx}

procedure TForm1.Button1Click(Sender: TObject);
const
  LClassMap: array[ChartType] of TFrmSkiaChartModelClass = (
    TFrmSkiaChartBars, TFrmSkiaChartPie, TFrmSkiaChartSparkLine);
var
  LType: ChartType;
begin
  LType := ChartType(GetEnumValue(TypeInfo(ChartType), cbxChartType.Text));

  if not Assigned(FFrmChart) then
  begin
    // First load: normal creation + sample data
    FFrmChart := LClassMap[LType].Create(Self);
    FFrmChart.Parent := Self;
    FFrmChart.Align := TAlignLayout.Client;
    FFrmChart.Margins.Top := 10;
    FFrmChart.LegendSize := tbarLegendSize.Value / 100;
    FFrmChart.ItemAdd(32415,    'Category 1');
    FFrmChart.ItemAdd(10000,    'Category 2');
    FFrmChart.ItemAdd(5000,     'Category 3');
    FFrmChart.ItemAdd(10661.88, 'Category 4');
    FFrmChart.ItemAdd(5000,     'Category 5');
    FFrmChart.ItemAdd(1518,     'Category 6');
    FFrmChart.ItemAdd(14206.67, 'Category 7');
    FFrmChart.StartAnimation;
  end
  else
    TFrmSkiaChartModel.SwitchType(FFrmChart, LClassMap[LType], Self);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  if not Assigned(FFrmChart) then
    Exit;
  if NumberBox1.IsFocused then
    Button4.SetFocus;
  if NumberBox1.Value = 0 then
    raise Exception.Create('Value must be bigger than 0');
  if ComboColorBox1.Color <> 0 then
    FFrmChart.ItemAdd(NumberBox1.Value, ComboColorBox1.Color, 'Category ' + Succ(FFrmChart.ItemsCount).ToString)
  else
    FFrmChart.ItemAdd(NumberBox1.Value, 'Category ' + Succ(FFrmChart.ItemsCount).ToString);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  if Assigned(FFrmChart) then
    FFrmChart.StartAnimation;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  ComboColorBox1.Color := 0;
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
    FFrmChart.LegendSize := tbarLegendSize.Value / 100;
  lblLegendSize.Text := 'Legend size: ' + tbarLegendSize.Value.ToString;
end;

end.
