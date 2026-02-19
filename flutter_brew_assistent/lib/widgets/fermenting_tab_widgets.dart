import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/bf_batch.dart';
import '../services/calendar_service.dart';
import '../widgets/batch_detail_widgets.dart';

class FermentingMesswerteSection extends StatelessWidget {
  const FermentingMesswerteSection({
    super.key,
    required this.useRaptData,
    required this.isLoadingRapt,
    required this.raptError,
    required this.raptData,
    required this.raptStartDate,
    required this.raptEndDate,
    required this.targetTempSpots,
    required this.onUseRaptChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
  });

  final bool useRaptData;
  final bool isLoadingRapt;
  final String? raptError;
  final List<dynamic> raptData;
  final DateTime? raptStartDate;
  final DateTime? raptEndDate;
  final List<FlSpot> targetTempSpots;

  final ValueChanged<bool> onUseRaptChanged;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime> onEndDateChanged;

  @override
  Widget build(BuildContext context) {
    return BatchDetailCardSection(
      title: 'Messwerte',
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Get Controller Date',
                style: TextStyle(fontSize: 12, color: Colors.white)),
            Switch(
              value: useRaptData,
              onChanged: onUseRaptChanged,
              activeThumbColor: Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (useRaptData) ...[
          Row(
            children: [
              Expanded(
                child: _buildDatePickerField('Start Datum', raptStartDate, context, onStartDateChanged),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePickerField('End Datum', raptEndDate, context, onEndDateChanged),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoadingRapt)
            const Center(child: CircularProgressIndicator())
          else if (raptError != null)
            Text(raptError!, style: const TextStyle(color: Colors.red))
          else if (raptData.isEmpty && raptStartDate != null && raptEndDate != null)
            const Text('Keine Daten für diesen Zeitraum.',
                style: TextStyle(color: Colors.grey))
          else if (raptData.isNotEmpty)
            SizedBox(height: 300, child: FermentingChart(raptData: raptData))
          else
            const SizedBox(
                height: 100,
                child: Center(
                    child: Text('Bitte Daten wählen',
                        style: TextStyle(color: Colors.grey)))),
        ] else ...[
          AspectRatio(
            aspectRatio: 1.7,
            child: LineChart(LineChartData(
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) =>
                        const FlLine(color: Colors.white10, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (val, meta) => Text(
                              val.toInt().toString(),
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey)))),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          interval: 2,
                          getTitlesWidget: (val, meta) => Text('${val.toInt()}d',
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey)))),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: targetTempSpots,
                    isCurved: false,
                    color: Colors.greenAccent,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                        show: true,
                        color: Colors.greenAccent.withValues(alpha: 0.1)),
                  )
                ])),
          )
        ]
      ],
    );
  }

  Widget _buildDatePickerField(
      String label, DateTime? date, BuildContext context, Function(DateTime) onChanged) {
    final fmt = DateFormat('dd.MM.yyyy HH:mm');
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime.now());
        if (picked != null) {
          if (!context.mounted) return;
          final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(date ?? DateTime.now()));
          if (time != null) {
            onChanged(DateTime(picked.year, picked.month, picked.day, time.hour,
                time.minute));
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white.withValues(alpha: 0.05)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date != null ? fmt.format(date) : '-',
                    style: const TextStyle(color: Colors.white)),
                const Icon(Icons.calendar_today, size: 14, color: Colors.white54),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class FermentingChart extends StatelessWidget {
  const FermentingChart({super.key, required this.raptData});

  final List<dynamic> raptData;

  @override
  Widget build(BuildContext context) {
    List<dynamic> source = raptData;
    if (source.length > 500) {
      final step = (source.length / 500).ceil();
      List<dynamic> reduced = [];
      for (int i = 0; i < source.length; i += step) {
        reduced.add(source[i]);
      }
      source = reduced;
    }

    final pointsTemp = <FlSpot>[];
    final pointsGravity = <FlSpot>[];
    final rawGravities = <double>[];

    for (final r in source) {
      final t = DateTime.tryParse(r['createdOn'] ?? '')
          ?.millisecondsSinceEpoch
          .toDouble();
      final temp = (r['temperature'] as num?)?.toDouble();
      double? grav = (r['gravity'] as num?)?.toDouble();
      if (grav != null && grav > 500) grav = grav / 1000.0;

      if (t != null) {
        if (temp != null) pointsTemp.add(FlSpot(t, temp));
        if (grav != null) {
          pointsGravity.add(FlSpot(t, grav));
          rawGravities.add(grav);
        }
      }
    }

    double minTemp = pointsTemp.isEmpty
        ? -5
        : pointsTemp.map((e) => e.y).reduce(min) - 5;
    double maxTemp = pointsTemp.isEmpty
        ? 35
        : pointsTemp.map((e) => e.y).reduce(max) + 5;

    double minGrav = pointsGravity.isEmpty
        ? 0.995
        : pointsGravity.map((e) => e.y).reduce(min) - 0.005;
    double maxGrav = pointsGravity.isEmpty
        ? 1.085
        : pointsGravity.map((e) => e.y).reduce(max) + 0.005;

    double normalizeG(double g) {
      if (maxGrav == minGrav) return minTemp + (maxTemp - minTemp) / 2;
      return (g - minGrav) / (maxGrav - minGrav) * (maxTemp - minTemp) + minTemp;
    }

    final pointsAbv = <FlSpot>[];
    final pointsVelocity = <FlSpot>[];

    for (int i = 0; i < source.length; i++) {
      final r = source[i];
      final tEnd = DateTime.tryParse(r['createdOn'] ?? '')
          ?.millisecondsSinceEpoch
          .toDouble();
      if (tEnd == null) continue;

      final windowMs = 12 * 60 * 60 * 1000;
      int? startIdx;
      for (int j = i - 1; j >= 0; j--) {
        final tj = DateTime.tryParse(source[j]['createdOn'] ?? '')
            ?.millisecondsSinceEpoch
            .toDouble();
        if (tj == null) continue;
        startIdx = j;
        if (tj <= tEnd - windowMs) break;
      }

      if (startIdx != null && startIdx != i) {
        final rStart = source[startIdx];
        final t1 = DateTime.tryParse(rStart['createdOn'] ?? '')
            ?.millisecondsSinceEpoch
            .toDouble();
        if (t1 != null) {
          final dtDays = (tEnd - t1) / (1000 * 60 * 60 * 24);
          if (dtDays >= 0.05) {
            double g1 = (rStart['gravity'] as num?)?.toDouble() ?? 0;
            double g2 = (r['gravity'] as num?)?.toDouble() ?? 0;
            if (g1 > 500) g1 /= 1000;
            if (g2 > 500) g2 /= 1000;

            final dg = (g1 - g2) * 1000;
            double vel = dg / dtDays;

            if (vel < 0.3 && i < source.length * 0.2) vel = 0;
            if (vel < 0) vel = 0;

            pointsVelocity.add(FlSpot(tEnd, vel));
          }
        }
      } else {
        pointsVelocity.add(FlSpot(tEnd, 0));
      }
    }

    if (rawGravities.isNotEmpty) {
      final double og = rawGravities.reduce(max);
      double lastAbv = 0.0;

      for (final spot in pointsGravity) {
        final g = spot.y;
        double currentAbv = (og - g) * 131.25;
        if (currentAbv < 0) currentAbv = 0;
        if (currentAbv < lastAbv) {
          currentAbv = lastAbv;
        } else {
          lastAbv = currentAbv;
        }
        pointsAbv.add(FlSpot(spot.x, currentAbv));
      }
    }

    double maxAbv =
        pointsAbv.isEmpty ? 8.0 : pointsAbv.map((e) => e.y).reduce(max) + 1.0;
    double minAbv = -0.5;

    double maxVel = pointsVelocity.isEmpty
        ? 10.0
        : (pointsVelocity.map((e) => e.y).reduce(max) * 1.2 / 5).ceil() * 5.0;
    if (maxVel < 5) maxVel = 5;
    double minVel = 0;

    double normalizeAbv(double a) {
      if (maxAbv == minAbv) return minTemp + (maxTemp - minTemp) / 2;
      return (a - minAbv) / (maxAbv - minAbv) * (maxTemp - minTemp) + minTemp;
    }

    double normalizeVel(double v) {
      if (maxVel == minVel) return minTemp + (maxTemp - minTemp) / 2;
      return (v - minVel) / (maxVel - minVel) * (maxTemp - minTemp) + minTemp;
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: LineChart(LineChartData(
              minY: minTemp,
              maxY: maxTemp,
              lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                touchedSpots.sort((a, b) => a.barIndex.compareTo(b.barIndex));

                return touchedSpots.asMap().entries.map((entry) {
                  int idx = entry.key;
                  LineBarSpot spot = entry.value;

                  String txt = '';
                  Color col = Colors.white;

                  if (spot.barIndex == 0) {
                    txt = '${spot.y.toStringAsFixed(1)} °C';
                    col = Colors.blue;
                  } else if (spot.barIndex == 1) {
                    double denorm = (spot.y - minTemp) /
                            (maxTemp - minTemp) *
                            (maxGrav - minGrav) +
                        minGrav;
                    txt = denorm.toStringAsFixed(4);
                    col = Colors.red;
                  } else if (spot.barIndex == 2) {
                    double denorm = (spot.y - minTemp) /
                            (maxTemp - minTemp) *
                            (maxAbv - minAbv) +
                        minAbv;
                    txt = '${denorm.toStringAsFixed(1)} %';
                    col = Colors.amber;
                  } else if (spot.barIndex == 3) {
                    double denorm = (spot.y - minTemp) /
                            (maxTemp - minTemp) *
                            (maxVel - minVel) +
                        minVel;
                    txt = '${(denorm / 1000).toStringAsFixed(4)} SG/Tag';
                    col = Colors.purple;
                  }

                  if (idx == 0) {
                    DateTime date =
                        DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                    String dateStr = DateFormat('dd.MM.yyyy HH:mm').format(date);
                    return LineTooltipItem(
                        '$dateStr\n$txt',
                        TextStyle(color: col, fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                              text: '',
                              style: TextStyle(
                                  color: col, fontWeight: FontWeight.bold))
                        ]);
                  }

                  return LineTooltipItem(txt,
                      TextStyle(color: col, fontWeight: FontWeight.bold));
                }).toList();
              })),
              gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      const FlLine(color: Colors.white10)),
              titlesData: FlTitlesData(
                bottomTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (val, _) => Text(val.toInt().toString(),
                            style:
                                const TextStyle(color: Colors.blue, fontSize: 10)))),
                rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (val, _) {
                          if (val < minTemp || val > maxTemp) {
                            return const SizedBox.shrink();
                          }
                          double denorm = (val - minTemp) /
                                  (maxTemp - minTemp) *
                                  (maxGrav - minGrav) +
                              minGrav;
                          return Text(denorm.toStringAsFixed(3),
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 10));
                        })),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: pointsTemp,
                  color: Colors.blue,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: pointsGravity
                      .map((s) => FlSpot(s.x, normalizeG(s.y)))
                      .toList(),
                  color: Colors.red,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots:
                      pointsAbv.map((s) => FlSpot(s.x, normalizeAbv(s.y))).toList(),
                  color: Colors.amber,
                  barWidth: 2,
                  dashArray: [5, 5],
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: pointsVelocity
                      .map((s) => FlSpot(s.x, normalizeVel(s.y)))
                      .toList(),
                  color: Colors.purple.withValues(alpha: 0.5),
                  barWidth: 1.5,
                  isCurved: false,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true, color: Colors.purple.withValues(alpha: 0.1)),
                ),
              ])),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Temperatur', Colors.blue),
            const SizedBox(width: 16),
            _buildLegendItem('Extrakt', Colors.red),
            const SizedBox(width: 16),
            _buildLegendItem('Alkohol', Colors.amber),
            const SizedBox(width: 16),
            _buildLegendItem('Aktivität', Colors.purple),
          ],
        )
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

class FermentingGatProfileRow extends StatelessWidget {
  const FermentingGatProfileRow({
    super.key,
    required this.batch,
    required this.steps,
    required this.startDate,
    required this.bottlingDate,
    required this.brewDateMs,
  });

  final BfBatch batch;
  final List steps;
  final String startDate;
  final String bottlingDate;
  final int? brewDateMs;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd. MMM. yyyy');

    List<Widget> stepWidgets = [];
    int accumulatedDays = 0;
    DateTime startDt = brewDateMs != null
        ? DateTime.fromMillisecondsSinceEpoch(brewDateMs!)
        : DateTime.now();

    for (var step in steps) {
      String name = step['name'] ?? '';
      num temp = step['stepTemp'] ?? 0;
      num days = step['stepTime'] ?? 0;

      DateTime stepDate = startDt.add(Duration(days: accumulatedDays));
      accumulatedDays += days.toInt();

      stepWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${dateFormat.format(stepDate)} - $name - $temp °C - $days Tage',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              IconButton(
                icon: const Icon(Icons.event_available, size: 16, color: Colors.greenAccent),
                onPressed: () {
                  CalendarService.addToGoogleCalendar(
                    title: 'Gärung: ${batch.name} ($name)',
                    startTime: stepDate,
                    description: 'Sud: ${batch.name}\nTemperatur: $temp °C\nDauer: $days Tage',
                  );
                },
                tooltip: 'In Kalender eintragen',
              ),
            ],
          ),
        ),
      );
    }

    return BatchDetailCardSection(
      title: 'Gärprofil',
      children: [
        Align(alignment: Alignment.center, child: Column(children: stepWidgets)),
        const SizedBox(height: 20),
        const Divider(color: Colors.white12),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gärung Start',
                    style: TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(startDate,
                      style: const TextStyle(fontWeight: FontWeight.bold))
                ]),
                const SizedBox(height: 4),
                Container(height: 1, width: 120, color: Colors.white24)
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Datum Abfüllung',
                    style: TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(bottlingDate,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (batch.data['bottlingDate'] != null)
                    IconButton(
                      icon: const Icon(Icons.event_available, size: 16, color: Colors.greenAccent),
                      onPressed: () {
                        final bDate = DateTime.fromMillisecondsSinceEpoch(batch.data['bottlingDate']);
                        CalendarService.addToGoogleCalendar(
                          title: 'Abfüllung: ${batch.name}',
                          startTime: bDate,
                          description: 'Sud: ${batch.name} abfüllen.',
                        );
                      },
                      tooltip: 'In Kalender eintragen',
                    ),
                ]),
                const SizedBox(height: 4),
                Container(height: 1, width: 120, color: Colors.white24)
              ],
            )
          ],
        )
      ],
    );
  }
}

class FermentingBeigabenSection extends StatelessWidget {
  const FermentingBeigabenSection({
    super.key,
    required this.yeasts,
    required this.miscs,
  });

  final List yeasts;
  final List miscs;

  Widget _buildBeigabenRow(String amount, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Text(' - ', style: TextStyle(color: Colors.grey)),
          Expanded(
              child:
                  Text(name, style: const TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> items = [];
    for (var y in yeasts) {
      dynamic amount = y is Map ? y['amount'] : y.amount;
      String unit = y is Map ? (y['unit'] ?? '') : (y.unit ?? '');
      String name = y is Map ? (y['name'] ?? '') : y.name;
      items.add(_buildBeigabenRow('$amount $unit', name));
    }
    for (var m in miscs) {
      dynamic amount = m is Map ? m['amount'] : m.amount;
      String unit = m is Map ? (m['unit'] ?? '') : (m.unit ?? '');
      String name = m is Map ? (m['name'] ?? '') : m.name;
      items.add(_buildBeigabenRow('$amount $unit', name));
    }
    if (items.isEmpty) {
      items.add(const Text('Keine Beigaben',
          style: TextStyle(color: Colors.grey)));
    }

    return BatchDetailCardSection(title: 'Beigaben', children: items);
  }
}

class FermentingGemesseneWerteSection extends StatelessWidget {
  const FermentingGemesseneWerteSection({super.key, required this.batch});

  final BfBatch batch;

  Widget _buildDottedRow(String label, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CustomPaint(
                painter: DottedLinePainter(),
              ),
            ),
          ),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 4),
          Text(unit, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = batch.data;
    final recipe = data['recipe'] ?? {};

    return BatchDetailCardSection(
      title: 'Gemessene Werte',
      children: [
        _buildDottedRow(
            'Stammwürze', data['measuredOg']?.toString() ?? 'Infinity', 'SG'),
        _buildDottedRow('Gärtank-Vol',
            recipe['equipment']?['fermenterVolume']?.toString() ?? '0', 'L'),
        _buildDottedRow('Abfüllmenge',
            recipe['equipment']?['bottlingVolume']?.toString() ?? '0', 'L'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDottedRow('Auffüllmenge Gärtank', '0', 'L')),
            const SizedBox(width: 16),
            Expanded(
                child: _buildDottedRow('Restextrakt',
                    data['measuredFg']?.toString() ?? 'Infinity', 'SG')),
          ],
        ),
        const SizedBox(height: 8),
        _buildDottedRow('Temperatur Karbonisierung', '4', '°C'),
      ],
    );
  }
}

class FermentingKarbonisierungSection extends StatelessWidget {
  const FermentingKarbonisierungSection({super.key, required this.batch});

  final BfBatch batch;

  @override
  Widget build(BuildContext context) {
    final recipe = batch.data['recipe'] ?? {};
    final dynamic carbonationField = recipe['carbonation'];

    double? carbonationVolumes;
    String? carbonationMethod;

    if (carbonationField is Map) {
      carbonationVolumes = (carbonationField['vols'] as num?)?.toDouble();
      carbonationMethod = carbonationField['method']?.toString();
    } else if (carbonationField is num) {
      carbonationVolumes = carbonationField.toDouble();
    }

    String method =
        batch.data['carbonationType'] ?? carbonationMethod ?? 'Keg';
    String info =
        '-1.05 Bar bei 4 °C\nfür etwa 1 Wochen\num ${carbonationVolumes ?? 0} Vol CO₂ zu erreichen';

    return BatchDetailCardSection(
      title: 'Karbonisierung',
      children: [
        const Text('Typ', style: TextStyle(color: Colors.grey, fontSize: 12)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(method, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Icon(Icons.arrow_drop_down, color: Colors.grey)
          ],
        ),
        const Divider(color: Colors.white12),
        const SizedBox(height: 8),
        Center(
          child: Text(info,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        )
      ],
    );
  }
}

class FermentingStatistikenSection extends StatelessWidget {
  const FermentingStatistikenSection({super.key, required this.batch});

  final BfBatch batch;

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = batch.data['recipe'] ?? {};
    final abv = r['abv'] ?? 0;
    final att = r['attenuation'] ?? 0;
    final mashEff = r['mashEfficiency'] ?? 0;
    final totEff = r['efficiency'] ?? 0;

    return BatchDetailCardSection(
      title: 'Statistiken',
      children: [
        Row(
          children: [
            Expanded(child: _buildStatItem('ALK', '$abv', '%')),
            Expanded(child: _buildStatItem('Vergärungsgrad', '$att', '%')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatItem('Maische Effizienz', '$mashEff', '%')),
            Expanded(child: _buildStatItem('Gesamteffizienz', '$totEff', '%')),
          ],
        ),
      ],
    );
  }
}

class FermentingZusammenfassungSection extends StatelessWidget {
  const FermentingZusammenfassungSection({super.key});

  Widget _buildSummaryRow(String label, String target, String actual, bool isDiff) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey))),
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(target, style: const TextStyle(fontSize: 12)),
                Text(actual,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDiff ? Colors.redAccent : Colors.greenAccent)),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BatchDetailCardSection(
      title: 'Zusammenfassung',
      children: [
        _buildSummaryRow('Kessel nach dem Kochen', '25.0', '25.5', true),
        _buildSummaryRow('Stammwürze nach dem Kochen', '1.048', '1.050', true),
        _buildSummaryRow('Sudhausausbeute', '70', '72', false),
      ],
    );
  }
}

class FermentingEreignisseSection extends StatelessWidget {
  const FermentingEreignisseSection({super.key, required this.batch});

  final BfBatch batch;

  @override
  Widget build(BuildContext context) {
    final events = (batch.data['events'] as List?) ?? [];
    final dateFormat = DateFormat('EEEE, d. MMMM yyyy HH:mm', 'de_DE');

    return BatchDetailCardSection(
      title: 'Ereignisse',
      children: [
        ...events.map((e) {
          DateTime dt = DateTime.fromMillisecondsSinceEpoch(e['time']);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    flex: 4,
                    child: Text(dateFormat.format(dt),
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontStyle: FontStyle.italic))),
                Expanded(
                    flex: 6,
                    child: Text(e['title'] ?? e['eventType'] ?? '',
                        style: const TextStyle(
                            fontSize: 11, fontStyle: FontStyle.italic))),
                const Icon(Icons.edit, size: 14, color: Colors.grey)
              ],
            ),
          );
        })
      ],
    );
  }
}
