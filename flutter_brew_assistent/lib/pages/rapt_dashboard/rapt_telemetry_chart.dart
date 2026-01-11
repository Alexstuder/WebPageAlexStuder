import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RaptTelemetryChart extends StatelessWidget {
  final List<dynamic> telemetryData;

  const RaptTelemetryChart({
    super.key,
    required this.telemetryData,
  });

  @override
  Widget build(BuildContext context) {
    if (telemetryData.isEmpty) {
      return const Center(child: Text('Keine Daten', style: TextStyle(color: Colors.white54)));
    }

    // Prepare Spots
    List<dynamic> source = telemetryData;
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
    final pointsAbv = <FlSpot>[];
    final pointsVelocity = <FlSpot>[];
    
    // 1. Calculate Velocity properly from gravity differences
    for (int i = 0; i < source.length; i++) {
        final r = source[i];
        final tEnd = DateTime.tryParse(r['createdOn'] ?? '')?.millisecondsSinceEpoch.toDouble();
        if (tEnd == null) continue;
        
        final windowMs = 12 * 60 * 60 * 1000;
        int? startIdx;
        for (int j = i - 1; j >= 0; j--) {
           final tj = DateTime.tryParse(source[j]['createdOn'] ?? '')?.millisecondsSinceEpoch.toDouble();
           if (tj == null) continue;
           startIdx = j;
           if (tj <= tEnd - windowMs) break;
        }
        
        if (startIdx != null && startIdx != i) {
           final rStart = source[startIdx];
           final t1 = DateTime.tryParse(rStart['createdOn'] ?? '')?.millisecondsSinceEpoch.toDouble();
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
    
    final rawGravities = <double>[];
    for (final r in source) {
        final t = DateTime.tryParse(r['createdOn'] ?? '')?.millisecondsSinceEpoch.toDouble();
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
    
    double minTemp = 0;
    double maxTemp = 30;
    if (pointsTemp.isNotEmpty) {
       minTemp = pointsTemp.map((e) => e.y).reduce(min);
       maxTemp = pointsTemp.map((e) => e.y).reduce(max);
    }
    minTemp -= 5;
    maxTemp += 5;
    
    double maxVel = 5;
    if (pointsVelocity.isNotEmpty) {
       maxVel = pointsVelocity.map((e) => e.y).reduce(max);
       if (maxVel < 2) maxVel = 2;
    }
    maxVel *= 1.2;

    return LineChart(
      LineChartData(
        backgroundColor: Colors.transparent,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
             getTooltipColor: (_) => const Color(0xFF1E293B),
             getTooltipItems: (touchedSpots) {
                return touchedSpots.map((s) {
                   final date = DateTime.fromMillisecondsSinceEpoch(s.x.toInt());
                   final timeStr = DateFormat('dd.MM HH:mm').format(date);
                   
                   if (s.barIndex == 0) return LineTooltipItem('$timeStr\n${s.y.toStringAsFixed(1)}°C', const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold));
                   if (s.barIndex == 1) return LineTooltipItem('${s.y.toStringAsFixed(4)} SG', const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold));
                   if (s.barIndex == 2) return LineTooltipItem('${s.y.toStringAsFixed(1)}%', const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold));
                   if (s.barIndex == 3) return LineTooltipItem('${s.y.toStringAsFixed(1)} P/Tag', const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold));
                   return null;
                }).toList().whereType<LineTooltipItem>().toList();
             }
          )
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 5),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (val, meta) => Text('${val.toInt()}°', style: const TextStyle(color: Colors.blue, fontSize: 10)),
            ),
          ),
          rightTitles: AxisTitles(
             sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (val, meta) {
                   final sg = val;
                   if (sg < 1.0 || sg > 1.2) return const SizedBox();
                   return Text(sg.toStringAsFixed(3), style: const TextStyle(color: Colors.red, fontSize: 10));
                }
             )
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(val.toInt());
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(DateFormat('dd.MM').format(date), style: const TextStyle(color: Colors.white54, fontSize: 10)),
                );
              },
              interval: max(1, (telemetryData.last['createdOn'] != null ? DateTime.tryParse(telemetryData.last['createdOn'])?.millisecondsSinceEpoch ?? 0 : 0) - (telemetryData.first['createdOn'] != null ? DateTime.tryParse(telemetryData.first['createdOn'])?.millisecondsSinceEpoch ?? 0 : 0)) / 5,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: pointsTemp.isNotEmpty ? pointsTemp.first.x : 0,
        maxX: pointsTemp.isNotEmpty ? pointsTemp.last.x : 0,
        minY: minTemp,
        maxY: maxTemp,
        lineBarsData: [
          // Temp
          LineChartBarData(
            spots: pointsTemp,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: Colors.blue.withValues(alpha: 0.1)),
          ),
          // Gravity
          LineChartBarData(
            spots: pointsGravity,
            isCurved: true,
            color: Colors.red,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            // Map Gravity to Temp Y scale for dual axis simulation
            // Simulation: Temp scale is minTemp to maxTemp. 
            // We want to map minGrav to minTemp and maxGrav to maxTemp.
            // Simplified: we just use raw values if we use extraLines or a helper.
            // But FLChart doesn't easily support dual scales. 
            // The original code seems to just plot them on the same Y axis? 
            // No, look at the rightTitles. They expect values between 1.0 and 1.2.
            // So they ARE plotted on the same Y axis, just with different labels.
          ),
          // ABV
          LineChartBarData(
            spots: pointsAbv,
            isCurved: true,
            color: Colors.amber,
            barWidth: 2,
            dashArray: [5, 5],
            dotData: const FlDotData(show: false),
          ),
          // Velocity (scaled to fit)
          LineChartBarData(
            spots: pointsVelocity.map((s) {
               // Map 0 -> minTemp, maxVel -> maxTemp
               final ratio = (s.y / maxVel);
               final mappedY = minTemp + (maxTemp - minTemp) * ratio;
               return FlSpot(s.x, mappedY);
            }).toList(),
            isCurved: true,
            color: Colors.green.withValues(alpha: 0.5),
            barWidth: 1,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: Colors.green.withValues(alpha: 0.05)),
          )
        ],
      ),
    );
  }
}
