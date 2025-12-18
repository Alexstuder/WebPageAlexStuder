import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_profile.dart';
import '../services/rapt_service.dart';
import '../services/user_profile_service.dart'; // To get profile

class RaptDashboardPage extends StatefulWidget {
  const RaptDashboardPage({super.key});

  static const String routeName = '/rapt_dashboard';

  @override
  State<RaptDashboardPage> createState() => _RaptDashboardPageState();
}

class _RaptDashboardPageState extends State<RaptDashboardPage> {
  bool _isLoading = false;
  String? _error;
  
  UserProfile? _profile;
  List<dynamic> _controllers = [];
  String? _selectedControllerId;
  
  List<dynamic> _telemetryData = [];
  DateTime? _startDate;
  
  // Dashboard Metrics
  double? _latestTemp;
  double? _latestGravity;
  double? _latestAbv;
  double? _og;
  double? _delta24h;
  

  @override
  void initState() {
    super.initState();
    _loadProfileAndControllers();
  }

  Future<void> _loadProfileAndControllers() async {
    setState(() => _isLoading = true);
    try {
      final profile = await UserProfileService().fetchDefaultProfile();
      if (profile == null) throw Exception('Kein Benutzerprofil gefunden.');
      if ((profile.raptUserId ?? '').isEmpty || (profile.raptApiKey ?? '').isEmpty) {
        throw Exception('Keine RAPT Zugangsdaten im Profil hinterlegt.');
      }
      
      _profile = profile;
      
      // Update Service with credentials
      final service = RaptService(
        userId: profile.raptUserId!,
        apiKey: profile.raptApiKey!,
      );
      
      final controllers = await service.getControllers();
      if (controllers.isEmpty) throw Exception('Keine Controller gefunden.');
      
      setState(() {
        _controllers = controllers;
        // Select first or default
        // Try to find one with active session?
        // Logic: specific ID logic or just first.
        _selectedControllerId = _getControllerId(controllers.first);
      });
      
      // Load Telemetry for selected
      if (_selectedControllerId != null) {
        await _loadTelemetry(_selectedControllerId!);
      }
      
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _getControllerId(dynamic c) {
    return c['id'] ?? c['Id'] ?? c['temperatureControllerId'] ?? c['TemperatureControllerId'];
  }

  Future<void> _loadTelemetry(String controllerId, {DateTime? startOverride}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final service = RaptService(
        userId: _profile!.raptUserId!,
        apiKey: _profile!.raptApiKey!,
      );
      
      // Default start date logic: 
      // If we have an active session, use its start date?
      // Or default to some reasonable lookback if no active session?
      // JS logic: finds earliest valid row or session start.
      
      // For now, let's request without explicit start (Service handles it or API default)
      // Or if startOverride is provided use it.
      
      DateTime start = startOverride ?? DateTime.now().subtract(const Duration(days: 7)); // Default 7d
      
      // Refine start date based on active session if available in controller data
      final controller = _controllers.firstWhere((c) => _getControllerId(c) == controllerId, orElse: () => null);
      if (controller != null && startOverride == null) {
         // Check for ActiveProfileSession
         final session = controller['activeProfileSession'] ?? controller['ActiveProfileSession'];
         if (session != null) {
            final sDate = session['startDate'] ?? session['startTime']; // Simplified
            if (sDate != null) {
               start = DateTime.tryParse(sDate) ?? start;
            }
         }
      }
      
      _startDate = start;
      
      final data = await service.getTelemetry(controllerId, start);
      
      _processTelemetry(data);
      
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _processTelemetry(List<dynamic> rows) {
    if (rows.isEmpty) {
      setState(() {
        _telemetryData = [];
        _latestTemp = null;
        _latestGravity = null;
        _latestAbv = null;
        _og = null;
        _delta24h = null;
      });
      return;
    }
    
    // Sort by date
    rows.sort((a, b) {
      final da = DateTime.tryParse(a['createdOn'] ?? '') ?? DateTime(0);
      final db = DateTime.tryParse(b['createdOn'] ?? '') ?? DateTime(0);
      return da.compareTo(db);
    });
    
    // Compute Metrics
    // Helper to normalize gravity (some APIs return 1000x, e.g. 1040 instead of 1.040)
    double normalize(double? val) {
      if (val == null) return 0.0;
      if (val > 500) return val / 1000.0;
      return val;
    }

    final last = rows.last;
    final temp = (last['temperature'] as num?)?.toDouble();
    double? gravity = (last['gravity'] as num?)?.toDouble();
    if (gravity != null) gravity = normalize(gravity);
    
    // OG: Max gravity in set? Or first?
    // JS used max gravity.
    final gravities = rows.map((r) => normalize((r['gravity'] as num?)?.toDouble())).where((g) => g > 0).toList();
    final og = gravities.isNotEmpty ? gravities.reduce(max) : null;
    
    // ABV
    // Formula: (OG - FG) * 131.25
    double? abv;
    if (og != null && gravity != null) {
      abv = (og - gravity) * 131.25;
    }
    
    // Delta 24h
    // Find point ~24h ago
    double? delta;
    if (gravity != null) {
       final now = DateTime.tryParse(last['createdOn'] ?? '');
       if (now != null) {
         final target = now.subtract(const Duration(hours: 24));
         // Find closest row
         Map<String, dynamic>? closest;
         int minDiff = 999999999;
         
         for (final r in rows) {
            final t = DateTime.tryParse(r['createdOn'] ?? '');
            if (t == null) continue;
            final diff = (t.difference(target)).inSeconds.abs();
            if (diff < minDiff) {
               minDiff = diff;
               closest = r;
            }
         }
         
         if (closest != null && minDiff < 3600 * 2) { // Within 2 hours
             double? oldG = (closest['gravity'] as num?)?.toDouble();
             if (oldG != null) {
               oldG = normalize(oldG);
               delta = gravity - oldG;
             }
         }
       }
    }
    
    setState(() {
      _telemetryData = rows;
      _latestTemp = temp;
      _latestGravity = gravity;
      _latestAbv = abv;
      _og = og;
      _delta24h = delta;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_profile == null && _isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF020617),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('RAPT Dashboard'),
        actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                 if (_selectedControllerId != null) {
                    _loadTelemetry(_selectedControllerId!, startOverride: _startDate);
                 }
              },
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            _buildStatusBadge(),
            const SizedBox(height: 16),
            const Text(
              'RAPT Temperature Controller',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
             const SizedBox(height: 8),
             if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                ),
            const SizedBox(height: 24),
            
            // Status Line
            Text(
              'Stand: ${_latestTimestamp()}',
              style: TextStyle(color: Colors.amber[400], fontSize: 13),
            ),
             const SizedBox(height: 4),
            Text(
              'Zeitraum: ${_startDate != null ? DateFormat('dd.MM.yyyy HH:mm').format(_startDate!) : '?'} \u2192 Heute',
              style: TextStyle(color: Colors.indigo[100], fontSize: 13),
            ),
             const SizedBox(height: 24),
             
             // Main Panel
             Container(
               padding: const EdgeInsets.all(24),
               decoration: BoxDecoration(
                 color: const Color(0xFF04060F).withValues(alpha: 0.94),
                 borderRadius: BorderRadius.circular(40),
                 boxShadow: [
                   BoxShadow(color: Colors.blue.withValues(alpha: 0.05), blurRadius: 0, spreadRadius: 1), // inset simulation
                 ]
               ),
               child: Column(
                  children: [
                     // Cards
                     LayoutBuilder(
                       builder: (ctx, constraints) {
                         // Responsive switch: if too small, stack
                         if (constraints.maxWidth < 600) {
                            return Column(
                               children: [
                                  _buildSummaryTile('Temperatur', _latestTemp, '°C', Colors.blue, null),
                                  const SizedBox(height: 16),
                                  _buildSummaryTile('Gravity', _latestGravity, 'SG', Colors.red, _buildGravityExtra()),
                                  const SizedBox(height: 16),
                                  _buildSummaryTile('Alkohol', _latestAbv, 'Vol.%', Colors.amber, null),
                               ],
                            );
                         }
                         return IntrinsicHeight(
                           child: Row(
                             crossAxisAlignment: CrossAxisAlignment.stretch,
                             children: [
                               Expanded(child: _buildSummaryTile('Temperatur', _latestTemp, '°C', Colors.blue, null)),
                               const SizedBox(width: 16),
                               Expanded(child: _buildSummaryTile('Gravity', _latestGravity, 'SG', Colors.red, _buildGravityExtra())),
                               const SizedBox(width: 16),
                               Expanded(child: _buildSummaryTile('Alkohol', _latestAbv, 'Vol.%', Colors.amber, null)),
                             ],
                           ),
                         );
                       },
                     ),
                     const SizedBox(height: 24),
                     
                     // Dropdown
                     const Align(alignment: Alignment.centerLeft, child: Text('Temperature Controller', style: TextStyle(color: Colors.white54, fontSize: 12))),
                     const SizedBox(height: 8),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 12),
                       decoration: BoxDecoration(
                          color: const Color(0xFF020B1D),
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(10),
                       ),
                       child: DropdownButton<String>(
                         value: _selectedControllerId,
                         isExpanded: true,
                         dropdownColor: const Color(0xFF020B1D),
                         underline: const SizedBox(),
                         style: const TextStyle(color: Colors.white),
                         items: _controllers.map((c) {
                            final id = _getControllerId(c);
                            final name = c['name'] ?? c['controllerName'] ?? id;
                            return DropdownMenuItem<String>(
                               value: id,
                               child: Text(name),
                            );
                         }).toList(),
                         onChanged: (v) {
                            if (v != null) {
                               setState(() => _selectedControllerId = v);
                               _loadTelemetry(v);
                            }
                         },
                       ),
                     ),
                     const SizedBox(height: 24),
                     
                     // CHART
                     SizedBox(
                       height: 400,
                       child: _telemetryData.isEmpty 
                         ? const Center(child: Text('Keine Daten', style: TextStyle(color: Colors.white54)))
                         : _buildChart(),
                     ),
                     const SizedBox(height: 24),
                     
                     // Date Picker
                     const Align(alignment: Alignment.centerLeft, child: Text('Startdatum (optional)', style: TextStyle(color: Colors.white54, fontSize: 12))),
                     const SizedBox(height: 8),
                     Row(
                       children: [
                          Expanded(
                            child: InkWell(
                               onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context, 
                                    initialDate: _startDate ?? DateTime.now(), 
                                    firstDate: DateTime(2020), 
                                    lastDate: DateTime.now()
                                  );
                                  if (picked != null) {
                                     // Also time?
                                      if (!context.mounted) return;
                                      // ignore: use_build_context_synchronously
                                      final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_startDate ?? DateTime.now()));
                                      if (time != null) {
                                         final dt = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
                                         setState(() => _startDate = dt);
                                      }
                                  }
                               },
                               child: Container(
                                 padding: const EdgeInsets.all(12),
                                 decoration: BoxDecoration(
                                     color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                                    border: Border.all(color: Colors.white24),
                                    borderRadius: BorderRadius.circular(10),
                                 ),
                                 child: Text(
                                   _startDate != null ? DateFormat('dd.MM.yyyy HH:mm').format(_startDate!) : 'Datum wählen...',
                                   style: const TextStyle(color: Colors.white),
                                 ),
                               ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                             onPressed: () {
                                if (_selectedControllerId != null) {
                                   _loadTelemetry(_selectedControllerId!, startOverride: _startDate);
                                }
                             },
                             child: const Text('Übernehmen'),
                          ),
                       ],
                     ),
                  ],
               ),
             ),
             
             // Footer Button
             const SizedBox(height: 32),
             Center(
               child: TextButton(
                 onPressed: () => Navigator.pop(context),
                 child: const Text('Zur Startseite'),
               ),
             ),
             const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusBadge() {
      // Check active session
      bool isActive = false;
      if (_selectedControllerId != null) {
         final c = _controllers.firstWhere((c) => _getControllerId(c) == _selectedControllerId, orElse: () => null);
         if (c != null && (c['activeProfileSession'] != null || c['ActiveProfileSession'] != null)) {
            isActive = true;
         }
      }
      
      return Container(
         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
         decoration: BoxDecoration(
            color: isActive ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
            border: Border.all(color: isActive ? Colors.green : Colors.red.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(20),
         ),
         child: Text(
            isActive ? 'Currently Brewing' : 'Currently Not Brewing',
            style: TextStyle(
               color: isActive ? Colors.greenAccent : Colors.redAccent,
               fontSize: 12,
               fontWeight: FontWeight.bold,
            ),
         ),
      );
  }

  Widget _buildSummaryTile(String label, double? value, String unit, Color color, Widget? extra) {
     return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
           color: const Color(0xFF0F172A).withValues(alpha: 0.65),
           border: Border.all(color: color.withValues(alpha: 0.4)),
           borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           mainAxisSize: MainAxisSize.min,
           children: [
              Text(label.toUpperCase(), style: TextStyle(color: Colors.indigo[100], fontSize: 13, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Row(
                 crossAxisAlignment: CrossAxisAlignment.baseline,
                 textBaseline: TextBaseline.alphabetic,
                 children: [
                    Text(value != null ? (label == 'Gravity' ? value.toStringAsFixed(4) : value.toStringAsFixed(1)) : '–', 
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(width: 4),
                    Text(unit, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                 ],
              ),
              if (extra != null) ...[
                 const SizedBox(height: 8),
                 extra,
              ]
           ],
        ),
     );
  }
  
  Widget _buildGravityExtra() {
     return Column(
        children: [
           _buildRow('OG', _og != null ? _og!.toStringAsFixed(4) : '–'),
           _buildRow('\u0394 24h', _delta24h != null ? _delta24h!.toStringAsFixed(4) : '–'),
        ],
     );
  }
  
  Widget _buildRow(String label, String val) {
     return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
           Text(val, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
     );
  }
  
  String _latestTimestamp() {
     if (_telemetryData.isEmpty) return '–';
     final last = _telemetryData.last;
     final dt = DateTime.tryParse(last['createdOn'] ?? '');
     if (dt == null) return '–';
     return DateFormat('dd.MM.yyyy HH:mm').format(dt);
  }

  Widget _buildChart() {
     // Prepare Spots
     // Downsample if too many points?
     // Let's take every Nth point if length > 500
     List<dynamic> source = _telemetryData;
     if (source.length > 500) {
        // Simple decimator
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
     
     // Store raw gravity values for ABV calculation
     final rawGravities = <double>[];
     
     for (final r in source) {
        final t = DateTime.tryParse(r['createdOn'] ?? '')?.millisecondsSinceEpoch.toDouble();
        final temp = (r['temperature'] as num?)?.toDouble();
        double? grav = (r['gravity'] as num?)?.toDouble(); // typically 1.0xx
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
        
        // We iterate pointsGravity to align time
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
     
     // Normalize Gravity to fit right axis?
     // FlChart supports multiple axes properly?
     // We define minY/maxY for left (Temp) and right (Gravity).
     // Wait, LineChartData allows sets to use different indices?
     // No, yAxisID is ChartJS. FlChart has one Y axis system unless we use SideTitles for visualization, but the PLOTTING is on the same scale unless we normalize.
     // To plot 20C and 1.050 SG on same chart, 1.050 is way down.
     // We MUST normalize gravity to the temp scale or use a second axis visualization and plot normalized values.
     
     // Visualization approach:
     // Map Gravity [1.000, 1.100] to range [0, 30] (example Temp range).
     // Let's say Temp range is 0..30. Gravity range 1.000..1.080.
     // Formula: y_plot = (grav - 1.000) * 1000 * scale + offset?
     // Simpler: Plot gravity on Right Axis logic.
     // FlChart checks: does it support multi-axis? Not natively for SCALING. We have to scale data manually.
     
     double minTemp = 0;
     double maxTemp = 30;
     if (pointsTemp.isNotEmpty) {
        minTemp = pointsTemp.map((e) => e.y).reduce(min);
        maxTemp = pointsTemp.map((e) => e.y).reduce(max);
     }
     // Add padding
     minTemp -= 5;
     maxTemp += 5;
     
     double minGrav = 1.000;
     double maxGrav = 1.080;
     if (pointsGravity.isNotEmpty) {
        minGrav = pointsGravity.map((e) => e.y).reduce(min);
        maxGrav = pointsGravity.map((e) => e.y).reduce(max);
     }
     // Add padding
     minGrav -= 0.005;
     maxGrav += 0.005;
     
     double minAbv = 0.0;
     double maxAbv = 7.0; // Default range
     if (pointsAbv.isNotEmpty) {
        minAbv = pointsAbv.map((e) => e.y).reduce(min);
        maxAbv = pointsAbv.map((e) => e.y).reduce(max);
     }
     minAbv = -0.5; // Start slightly below 0
     maxAbv += 1.0;
     
     // Normalizers
     double normalizeG(double g) {
        // Map [minGrav, maxGrav] -> [minTemp, maxTemp]
        // (g - minG) / (maxG - minG) * (maxT - minT) + minT
        if (maxGrav == minGrav) return minTemp + (maxTemp - minTemp)/2;
        return (g - minGrav) / (maxGrav - minGrav) * (maxTemp - minTemp) + minTemp;
     }

     double normalizeAbv(double a) {
        if (maxAbv == minAbv) return minTemp + (maxTemp - minTemp)/2;
        return (a - minAbv) / (maxAbv - minAbv) * (maxTemp - minTemp) + minTemp;
     }

     final normalizedGravityPoints = pointsGravity.map((e) => FlSpot(e.x, normalizeG(e.y))).toList();
     final normalizedAbvPoints = pointsAbv.map((e) => FlSpot(e.x, normalizeAbv(e.y))).toList();
     
     return LineChart(
        LineChartData(
           minY: minTemp,
           maxY: maxTemp,
           minX: pointsTemp.isNotEmpty ? pointsTemp.first.x : (pointsGravity.isNotEmpty ? pointsGravity.first.x : (pointsAbv.isNotEmpty ? pointsAbv.first.x : 0)),
           maxX: pointsTemp.isNotEmpty ? pointsTemp.last.x : (pointsGravity.isNotEmpty ? pointsGravity.last.x : (pointsAbv.isNotEmpty ? pointsAbv.last.x : 0)),
           lineBarsData: [
              // Temp
              LineChartBarData(
                 spots: pointsTemp,
                 color: Colors.blue,
                 isCurved: true,
                 dotData: const FlDotData(show: false),
                 belowBarData: BarAreaData(show: true, color: Colors.blue.withValues(alpha: 0.1)),
              ),
              // Gravity
              LineChartBarData(
                 spots: normalizedGravityPoints,
                 color: Colors.red,
                 isCurved: true,
                 dotData: const FlDotData(show: false),
                 belowBarData: BarAreaData(show: true, color: Colors.red.withValues(alpha: 0.1)),
              ),
              // Alcohol
              LineChartBarData(
                 spots: normalizedAbvPoints,
                 color: Colors.amber,
                 isCurved: true,
                 dotData: const FlDotData(show: false),
                 belowBarData: BarAreaData(show: true, color: Colors.amber.withValues(alpha: 0.1)),
              ),
           ],
           titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                 sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                       final dt = DateTime.fromMillisecondsSinceEpoch(val.toInt());
                       return Padding(
                         padding: const EdgeInsets.only(top: 8.0),
                         child: Text(DateFormat('dd.MM\nHH:mm').format(dt), style: const TextStyle(color: Colors.white54, fontSize: 10), textAlign: TextAlign.center),
                       );
                    },
                    interval: (pointsTemp.isNotEmpty) ? (pointsTemp.last.x - pointsTemp.first.x) / 5 : 1000000, // 5 ticks, handle empty case
                    reservedSize: 40,
                 ),
              ),
              leftTitles: AxisTitles(
                 sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                       return Text(val.toStringAsFixed(1), style: const TextStyle(color: Colors.blue, fontSize: 10));
                    },
                    reservedSize: 30,
                 ),
              ),
              rightTitles: AxisTitles(
                 sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                       // Reverse normalization:
                       // val = (g - minG) / (maxG - minG) * (maxT - minT) + minT
                       // (val - minT) / RangeT * RangeG + minG = g
                       double g = (val - minTemp) / (maxTemp - minTemp) * (maxGrav - minGrav) + minGrav;
                       return Text(g.toStringAsFixed(3), style: const TextStyle(color: Colors.red, fontSize: 10));
                    },
                    reservedSize: 40,
                 ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
           ),
           gridData: FlGridData(
             show: true, 
             drawVerticalLine: true, 
             getDrawingHorizontalLine: (_) => const FlLine(color: Colors.white10),
             getDrawingVerticalLine: (_) => const FlLine(color: Colors.white10),
           ),
           borderData: FlBorderData(show: false),
           lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                 getTooltipColor: (_) => Colors.black87,
                 getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                       if (spot.barIndex == 0) {
                          // Temp
                          return LineTooltipItem('${spot.y.toStringAsFixed(1)} °C', const TextStyle(color: Colors.blue));
                       } else if (spot.barIndex == 1) {
                          // Gravity (Normalized) -> Restore real value
                          double g = (spot.y - minTemp) / (maxTemp - minTemp) * (maxGrav - minGrav) + minGrav;
                          return LineTooltipItem('${g.toStringAsFixed(4)} SG', const TextStyle(color: Colors.red));
                       } else {
                          // Alcohol
                          // Reverse normalization:
                          // val = (a - minA) / (maxA - minA) * (maxT - minT) + minT
                          // (val - minT) / (maxT - minT) * (maxA - minA) + minA = a
                          double a = (spot.y - minTemp) / (maxTemp - minTemp) * (maxAbv - minAbv) + minAbv;
                          return LineTooltipItem('${a.toStringAsFixed(1)} %', const TextStyle(color: Colors.amber));
                       }
                    }).toList();
                 }
              ),
           ),
        ),
     );
  }
}
