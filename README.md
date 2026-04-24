# skia4delphi-chart

Animated, interactive **charts** for Delphi FireMonkey (FMX), powered by [Skia4Delphi](https://github.com/skia4delphi/skia4delphi).

---

## What it does

Drop a chart frame into your FMX form, feed it data, and get a fully animated, interactive chart — with zero external dependencies beyond Skia4Delphi.

![Demonstration](https://github.com/igorbastosib/skia4delphi-chart/blob/main/Files/presentation.gif?raw=true)

---

## Features

- **Two chart types** (yet) — Pie and Bar, switchable at runtime
- **Smooth draw animation** — slices and bars animate in from zero on every data load
- **Click-to-select** — tap any slice or bar to highlight it and show its value in a popup
- **Interactive legend** — click legend items to toggle individual series on or off
- **Auto color palette** — 11 built-in colors that cycle automatically; or supply your own per item
- **Cross-platform** — same code runs on Windows, Android, and iOS

---

## Roadmap

Contributions and ideas are welcome. Current backlog, roughly in priority order:

### Planned
| Status | Title | Description | ToDo.md? |
|---|---|---|---|
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

```delphi
// 1. Add the chart frame to your form (e.g. FFrmChart : TFrmSkiaChartPie)
//    and embed it in a container panel at runtime or design-time.

uses
  SkiaChart.View.Model, SkiaChart.View.Pie;

// 2. Load data
TFrmSkiaChartModel(FFrmChart).Clear;
TFrmSkiaChartModel(FFrmChart).ItemAdd(32415,    'Revenue');
TFrmSkiaChartModel(FFrmChart).ItemAdd(10000,    'Costs');
TFrmSkiaChartModel(FFrmChart).ItemAdd(14206.67, 'Profit');

// 3. Start the draw animation
TFrmSkiaChartModel(FFrmChart).StartAnimation;
```

`ItemAdd` signature:

```delphi
procedure ItemAdd(AValue: Double; AText: string;
                  AColor: TAlphaColor = TAlphaColors.Null);
```

Pass a custom `AColor` to override the automatic palette for that item.

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