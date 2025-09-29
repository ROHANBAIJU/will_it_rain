# TODO: Fix Mobile Overflow and Implement Widgets

## Tasks
- [x] Task 1: Fix Mobile Overflow in main.dart (WeatherDashboard)
  - Remove outer SingleChildScrollView and fixed-height SizedBox for OutputsPanel
  - Use Column with InputsPanel and Expanded(OutputsPanel)
- [x] Task 2: Refactor InputsPanel Location Chip in inputs_panel.dart
  - Replace custom Container/InkWell with Chip widget in _buildLocationChip
- [x] Task 3: Implement ChartTimeSeries in ui/widgets/chart_time_series.dart
  - Create ConsumerWidget with LineChart from fl_chart
  - Display series data with proper axes and legend
- [x] Task 4: Implement ExportBar in ui/widgets/export_bar.dart
  - Create stateless widget with three export buttons (CSV, JSON, PNG)
