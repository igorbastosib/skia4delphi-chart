# skia4delphi-chart

Animated, interactive **charts** for Delphi FireMonkey (FMX), powered by [Skia4Delphi](https://github.com/skia4delphi/skia4delphi).

---

## What it does

Drop a chart frame into your FMX form, feed it data, and get a fully animated, interactive chart — with zero external dependencies beyond Skia4Delphi.

![Demonstration](https://github.com/igorbastosib/skia4delphi-chart/blob/main/Files/presentation.gif?raw=true)

---

## Features

- **Three chart types** — Pie, Bar, and SparkLine, switchable at runtime
- **Smooth draw animation** — slices and bars animate in from zero on every data load
- **Click-to-select** — tap any slice or bar to highlight it and show its value in a popup
- **Interactive legend** — click legend items to toggle individual series on or off
- **Auto color palette** — 11 built-in colors that cycle automatically; or supply your own per item
- **SparkLine** — compact trend chart with per-item colored segments and a translucent fill; optional `LineColor` property to use a single color for the whole line
- **Cross-platform** — same code runs on Windows, Android, and iOS

---

## Roadmap

Contributions and ideas are welcome. Current backlog, roughly in priority order:

### Planned
| Status | Title | Description | ToDo.md? |
|---|---|---|---|
| ✅ | **SparkLine chart type** | Compact trend chart with per-item colored segments, translucent area fill, left-to-right animation, and optional single-color override via `LineColor` |  |
| | **More chart types** | To add more chart types as Line, Area, Donut |  |
| | **vsync-aligned animation** | To migrate from `TTimer` to `TSkAnimatedPaintBox` for smoother animation and lower CPU use | [`TODO20260422.md`](Past%20ToDos/TODO20260422.md) — A4 |
|  | **Per-item removal** | `RemoveItem(AIndex)` without a full `Clear` |  |
| | **Tapping legend change behaviour** | Tapping on Legend Box add the PopUp on selected item (keep the hid/show while tapping on Legend label) |  |
| | **Pie with same first and last colors** | To avoid same colors on Pie Chart for the first and last item |  |
| | **PopUp value, small/big screen** | Showing PopUp value must respect the limit Width (left, right) and Height (top, bottom); If small screen, as Mobile, selecting the most left or right, cuts part of the PopUp value; If highest value is selected, PopValue might cover the Legend; |  |

### Under consideration
| Status | Title | Description | ToDo.md? |
|---|---|---|---|
| | **Data model / view separation** | decouple `TChartDataSet` from the FMX frame so chart data can be managed and tested independently of the UI | [`TODO20260422.md`](Past%20ToDos/TODO20260422.md) — A2  |
| | **Theming** | expose a `TLegendStyle` record for font, color-rect size, and spacing without subclassing | |

### Known limitations
- No built-in support for negative values or dual axes
- Color palette cycles through 11 built-in colors; adding 22+ items repeats colors with no visual distinction between cycles

---

## Quick Start

### Pie / Bar chart

```delphi
uses
  SkiaChart.View.Model, SkiaChart.View.Pie;

var FFrmChart: TFrmSkiaChartModel;
FFrmChart := TFrmSkiaChartPie.Create(Self);
FFrmChart.Parent := Self;
FFrmChart.Align  := TAlignLayout.Client;

FFrmChart.ItemAdd(32415,    'Revenue');
FFrmChart.ItemAdd(10000,    'Costs');
FFrmChart.ItemAdd(14206.67, 'Profit');
FFrmChart.StartAnimation;
```

### SparkLine chart

```delphi
uses
  SkiaChart.View.Model, SkiaChart.View.SparkLine;

// Declare as the concrete type only when you need SparkLine-specific properties.
var FFrmChart: TFrmSkiaChartSparkLine;
FFrmChart := TFrmSkiaChartSparkLine.Create(Self);
FFrmChart.Parent := Self;
FFrmChart.Align  := TAlignLayout.Client;

// Each item becomes one data point on the trend line.
// Its Color is used for the segment arriving at that point and its fill area.
FFrmChart.ItemAdd(1518,     'Jan');
FFrmChart.ItemAdd(5000,     'Feb');
FFrmChart.ItemAdd(10000,    'Mar');
FFrmChart.ItemAdd(32415,    'Apr');
FFrmChart.ItemAdd(14206.67, 'May');
FFrmChart.StartAnimation;

// Optional: force a single color for the entire line instead of per-item colors.
// Set to 0 to restore per-item coloring.
FFrmChart.LineColor := TAlphaColors.Crimson;
```

### Switching chart types at runtime

`TFrmSkiaChartModel.SwitchType` replaces the current frame with one of a different type while preserving all items, their enabled/disabled state, and the legend size. Parent, alignment, and margins are copied from the old frame automatically.

```delphi
uses
  SkiaChart.View.Model, SkiaChart.View.Bars, SkiaChart.View.Pie,
  SkiaChart.View.SparkLine;

// FFrmChart is TFrmSkiaChartModel — declare at the base type to allow switching.
var FFrmChart: TFrmSkiaChartModel;

// Initial creation (normal pattern — no switching yet)
FFrmChart := TFrmSkiaChartBars.Create(Self);
FFrmChart.Parent := Self;
FFrmChart.Align  := TAlignLayout.Client;
FFrmChart.ItemAdd(32415, 'Q1');
FFrmChart.ItemAdd(10000, 'Q2');
FFrmChart.StartAnimation;

// Later: switch to Pie — items transfer automatically, animation restarts
TFrmSkiaChartModel.SwitchType(FFrmChart, TFrmSkiaChartPie, Self);

// Switch again to SparkLine
TFrmSkiaChartModel.SwitchType(FFrmChart, TFrmSkiaChartSparkLine, Self);
```

Calling `SwitchType` with the type that is already active just re-triggers the animation without recreating the frame.

`ItemAdd` signatures:

```delphi
// Auto-assigns the next color from the built-in palette
procedure ItemAdd(AValue: Double; AText: string);

// Supply an explicit color for this item
procedure ItemAdd(AValue: Double; AColor: TAlphaColor; AText: string);
```

---

## About the author

Check my other links: <https://linktr.ee/igorbastosib>

## Donation

Help me keep my almost great work!

<img src="https://i.imgur.com/G1Gx14O.png" alt="Donation QR code" width="200" />

## ⚠️ License

This repository is free and open-source software licensed under the [MIT License](https://github.com/igorbastosib/skia4delphi-chart/blob/main/LICENSE). 

## 📐 Tests

![Delphi 12.3](https://img.shields.io/badge/Delphi-12.3-red)
![FMX-Win64 Coverage ](https://img.shields.io/badge/FMX%20Win64-100%25-blue)
![Android Coverage ](https://img.shields.io/badge/Android%2010~14-100%25-blue)
![iOS Coverage ](https://img.shields.io/badge/iOS%2015.7-100%25-blue)