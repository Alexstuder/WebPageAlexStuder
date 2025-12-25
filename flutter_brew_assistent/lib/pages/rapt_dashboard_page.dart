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
  
  bool _isFallbackData = false;

  // Dashboard Metrics
  double? _latestTemp;
  double? _latestGravity;
  double? _latestAbv;
  double? _og;
  double? _latestBattery;
  double? _delta24h;
  String? _generatedAt;
  String? _currentProfileName;

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
      
      final service = RaptService(
        userId: profile.raptUserId!,
        apiKey: profile.raptApiKey!,
      );
      
      final controllers = await service.getControllers();
      if (controllers.isEmpty) throw Exception('Keine Controller gefunden.');
      
      setState(() {
        _controllers = controllers;
        _selectedControllerId = _getControllerId(controllers.first);
      });
      
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

  Future<void> _loadTelemetry(String controllerId, {DateTime? startOverride, bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final service = RaptService(
        userId: _profile!.raptUserId!,
        apiKey: _profile!.raptApiKey!,
      );
      
      final dataEnv = await service.fetchTelemetry(
        controllerId: controllerId,
        startDate: startOverride,
        forceRefresh: forceRefresh,
        useCacheOnly: !forceRefresh && startOverride == null,
      );
      
      final rows = (dataEnv['rows'] as List?)?.map((e) => e as Map<String,dynamic>).toList() ?? [];
      final genAt = dataEnv['generatedAt'] as String?;
      final isFallback = dataEnv['isFallback'] == true; // Capture fallback flag
      
      if (dataEnv['resolvedStartDate'] != null) {
         _startDate = DateTime.tryParse(dataEnv['resolvedStartDate']);
      } else if (startOverride != null) {
         _startDate = startOverride;
      }

      setState(() {
        _generatedAt = genAt;
        _isFallbackData = isFallback;
      });
      
      _processTelemetry(rows);
      
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  // (Rest of methods) ... skip to build ...

  
  // New helper to reset
  Future<void> _resetDateAndReload() async {
     setState(() => _isLoading = true);
     try {
       final service = RaptService(
          userId: _profile!.raptUserId!,
          apiKey: _profile!.raptApiKey!,
        );
       await service.resetStartDate();
       setState(() => _startDate = null);
       // Reload with force refresh to clear any stale cache state on proxy side regarding date override
       await _loadTelemetry(_selectedControllerId!, forceRefresh: true);
     } catch (e) {
        if (mounted) setState(() => _error = e.toString());
        setState(() => _isLoading = false);
     }
  }



// ... (existing code omitted)

  void _processTelemetry(List<dynamic> rows) {
    if (rows.isEmpty) {
      setState(() {
        _telemetryData = [];
        _latestTemp = null;
        _latestGravity = null;
        _latestAbv = null;
        _latestBattery = null;
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
    
    // Helper
    double normalize(double? val) {
      if (val == null) return 0.0;
      if (val > 500) return val / 1000.0;
      return val;
    }

    final last = rows.last;
    final temp = (last['temperature'] as num?)?.toDouble();
    double? gravity = (last['gravity'] as num?)?.toDouble();
    if (gravity != null) gravity = normalize(gravity);
    
    // Battery
    final battery = (last['battery'] as num?)?.toDouble();
    
    // OG
    final gravities = rows.map((r) => normalize((r['gravity'] as num?)?.toDouble())).where((g) => g > 0).toList();
    final og = gravities.isNotEmpty ? gravities.reduce(max) : null;
    
    // ABV
    double? abv;
    if (og != null && gravities.isNotEmpty) {
       double lastAbv = 0.0;
       for (final r in rows) {
          double? g = (r['gravity'] as num?)?.toDouble();
          if (g != null) {
             g = normalize(g);
             double currentAbv = (og - g) * 131.25;
             if (currentAbv < 0) currentAbv = 0;
             if (currentAbv < lastAbv) {
                currentAbv = lastAbv;
             } else {
                lastAbv = currentAbv;
             }
             abv = currentAbv;
          }
       }
    }
    
    // Delta 24h
    double? delta;
    if (gravity != null) {
       final now = DateTime.tryParse(last['createdOn'] ?? '');
       if (now != null) {
         final target = now.subtract(const Duration(hours: 24));
         int minDiff = 999999999;
         Map<String, dynamic>? closest;
         
         for (final r in rows) {
            final t = DateTime.tryParse(r['createdOn'] ?? '');
            if (t == null) continue;
            final diff = (t.difference(target)).inSeconds.abs();
            if (diff < minDiff) {
               minDiff = diff;
               closest = r;
            }
         }
         
         if (closest != null && minDiff < 3600 * 2) {
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
      _latestBattery = battery;
      _og = og;
      _delta24h = delta;
      _currentProfileName = last['profileName'] ?? last['ProfileName'];
    });
  }

  Widget _buildBatteryBadge(double percent) {
     Color color = Colors.green;
     if (percent < 30) {
       color = Colors.red;
     } else if (percent < 60) {
       color = Colors.yellow;
     }
     
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
       decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5))
       ),
       child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             Text('Pill Batterie', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
             const SizedBox(width: 6),
             Icon(Icons.battery_std, color: color, size: 16),
             const SizedBox(width: 4),
             Text('${percent.floor()}%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold))
          ]
       )
     );
  }

  @override
  Widget build(BuildContext context) {
    if (_profile == null && _isLoading && _controllers.isEmpty) {
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
        centerTitle: true,
        actions: [
           if (_latestBattery != null)
             Padding(
                padding: const EdgeInsets.only(right: 16), 
                child: Center(child: _buildBatteryBadge(_latestBattery!))
             ),
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
            if (_isFallbackData && _telemetryData.isNotEmpty) ...[
               Builder(
                 builder: (context) {
                   final first = _telemetryData.first;
                   final last = _telemetryData.last;
                   
                   final profileName = first['profileName'] ?? first['ProfileName'] ?? 'Unknown Profile';
                   final start = DateTime.tryParse(first['createdOn'] ?? '');
                   final end = DateTime.tryParse(last['createdOn'] ?? '');
                   final fmt = DateFormat('dd.MM.yyyy HH:mm');
                   
                   return Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        Text(
                          'Letzter Sud: $profileName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (start != null && end != null)
                          Text(
                            'Gebraut vom ${fmt.format(start)} bis ${fmt.format(end)}',
                             style: const TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        const SizedBox(height: 24),
                        if (_error != null)
                           Container(
                             padding: const EdgeInsets.all(12),
                             margin: const EdgeInsets.only(bottom: 16),
                             decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                             child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                           ),
                     ],
                   );
                 }
               )
            ] else ...[
                Text(
                  _currentProfileName ?? 'RAPT Temperature Controller',
                  style: const TextStyle(
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
                
                 const SizedBox(height: 16),
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
                           setState(() {
                             _selectedControllerId = v;
                             _startDate = null; 
                           });
                           _loadTelemetry(v); 
                        }
                     },
                   ),
                 ),
                 const SizedBox(height: 24),
            ],
             
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
                     
                     // CHART
                     SizedBox(
                       height: 400,
                       child: _telemetryData.isEmpty 
                         ? const Center(child: Text('Keine Daten', style: TextStyle(color: Colors.white54)))
                         : _buildChart(),
                     ),
                     const SizedBox(height: 24),
                     
                     // Controls Row (Date, Apply, Reset, Reload)
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         const Text('Startdatum (optional)', style: TextStyle(color: Colors.white54, fontSize: 12)),
                         const SizedBox(height: 8),
                         Wrap(
                           spacing: 12,
                           runSpacing: 12,
                           crossAxisAlignment: WrapCrossAlignment.center,
                           children: [
                              // Date Picker
                              InkWell(
                                 onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context, 
                                      initialDate: _startDate ?? DateTime.now(), 
                                      firstDate: DateTime(2020), 
                                      lastDate: DateTime.now()
                                    );
                                    if (picked != null) {
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
                                   width: 200,
                                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                   decoration: BoxDecoration(
                                       color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                                      border: Border.all(color: Colors.white24),
                                      borderRadius: BorderRadius.circular(10),
                                   ),
                                   child: Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       Text(
                                         _startDate != null ? DateFormat('dd.MM.yyyy, HH:mm').format(_startDate!) : 'Datum wählen...',
                                         style: const TextStyle(color: Colors.white),
                                       ),
                                       const Icon(Icons.calendar_today, size: 16, color: Colors.white54),
                                     ],
                                   ),
                                 ),
                              ),
                              
                              // Übernehmen
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                   onPressed: () {
                                      if (_selectedControllerId != null) {
                                         _loadTelemetry(_selectedControllerId!, startOverride: _startDate, forceRefresh: true);
                                      }
                                   },
                                   style: ElevatedButton.styleFrom(
                                     backgroundColor: const Color(0xFF1E293B),
                                     foregroundColor: Colors.white,
                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.white24)),
                                   ),
                                   child: const Text('Übernehmen'),
                                ),
                              ),
                              
                              // Zurücksetzen
                              SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                   onPressed: () {
                                      _resetDateAndReload();
                                   },
                                   style: OutlinedButton.styleFrom(
                                     foregroundColor: Colors.white,
                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                     side: const BorderSide(color: Colors.white24),
                                   ),
                                   child: const Text('Zurücksetzen'),
                                ),
                              ),
                              
                              // Stand info
                              if (_generatedAt != null)
                                Text(
                                  'Stand ${_formatTime(_generatedAt!)}', // e.g. "Stand 07:00 MEZ"
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                                ),
                                
                              // Reload
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Reload', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.white24),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.refresh, color: Colors.white),
                                      onPressed: () {
                                         if (_selectedControllerId != null) {
                                            // Reload keeps current date if set, but forces refresh
                                            _loadTelemetry(_selectedControllerId!, startOverride: _startDate, forceRefresh: true);
                                         }
                                      },
                                    ),
                                  ),
                                ],
                              )
                           ],
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
  
  String _formatTime(String iso) {
     final dt = DateTime.tryParse(iso);
     if (dt == null) return iso;
     return '${DateFormat('HH:mm').format(dt)} MEZ'; // Assuming local is close enough to MEZ or converting explicitly if needed
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
            isActive ? 'Gärt gerade' : 'Gärt nicht',
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
      final pointsVelocity = <FlSpot>[];
     
     // 1. Calculate Velocity properly from gravity differences
     for (int i = 0; i < source.length; i++) {
        final r = source[i];
        final tEnd = DateTime.tryParse(r['createdOn'] ?? '')?.millisecondsSinceEpoch.toDouble();
        if (tEnd == null) continue;
        
        // Find a point about 12 hours ago
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
                 
                 // Noise filter
                 if (vel < 0.3 && i < source.length * 0.2) vel = 0;
                 if (vel < 0) vel = 0;
                 
                 pointsVelocity.add(FlSpot(tEnd, vel));
              }
           }
        } else {
           pointsVelocity.add(FlSpot(tEnd, 0));
        }
     }
     
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
     double maxAbv = 7.0; 
     if (pointsAbv.isNotEmpty) {
        minAbv = pointsAbv.map((e) => e.y).reduce(min);
        maxAbv = pointsAbv.map((e) => e.y).reduce(max);
     }
     minAbv = -0.5; 
     maxAbv += 1.0;
 
     double minVel = 0;
     double maxVel = 10.0; 
     if (pointsVelocity.isNotEmpty) {
        final actualMax = pointsVelocity.map((e) => e.y).reduce(max);
        maxVel = (actualMax * 1.2 / 5).ceil() * 5.0; // Dynamic scale with buffer, rounded to 5
        if (maxVel < 5) maxVel = 5;
     }
     
     // Normalizers
     double normalizeG(double g) {
        if (maxGrav == minGrav) return minTemp + (maxTemp - minTemp)/2;
        return (g - minGrav) / (maxGrav - minGrav) * (maxTemp - minTemp) + minTemp;
     }
 
     double normalizeAbv(double a) {
        if (maxAbv == minAbv) return minTemp + (maxTemp - minTemp)/2;
        return (a - minAbv) / (maxAbv - minAbv) * (maxTemp - minTemp) + minTemp;
     }
 
      double normalizeVel(double v) {
         if (maxVel == minVel) return minTemp + (maxTemp - minTemp)/2;
         return (v - minVel) / (maxVel - minVel) * (maxTemp - minTemp) + minTemp;
      }
 
      final normalizedGravityPoints = pointsGravity.map((e) => FlSpot(e.x, normalizeG(e.y))).toList();
      final normalizedAbvPoints = pointsAbv.map((e) => FlSpot(e.x, normalizeAbv(e.y))).toList();
      final normalizedVelocityPoints = pointsVelocity.map((e) => FlSpot(e.x, normalizeVel(e.y))).toList();
      
      return LineChart(
         LineChartData(
            minY: minTemp,
            maxY: maxTemp,
            minX: pointsTemp.isNotEmpty ? pointsTemp.first.x : (pointsGravity.isNotEmpty ? pointsGravity.first.x : (pointsAbv.isNotEmpty ? pointsAbv.first.x : 0)),
            maxX: pointsTemp.isNotEmpty ? pointsTemp.last.x : (pointsGravity.isNotEmpty ? pointsGravity.last.x : (pointsAbv.isNotEmpty ? pointsAbv.last.x : 0)),
            lineBarsData: [
               // Temp (Index 0)
               LineChartBarData(
                  spots: pointsTemp,
                  color: Colors.blue,
                  isCurved: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: Colors.blue.withValues(alpha: 0.1)),
               ),
               // Gravity (Index 1)
               LineChartBarData(
                  spots: normalizedGravityPoints,
                  color: Colors.red,
                  isCurved: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: Colors.red.withValues(alpha: 0.1)),
               ),
               // Alcohol (Index 2)
               LineChartBarData(
                  spots: normalizedAbvPoints,
                  color: Colors.amber,
                  isCurved: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: Colors.amber.withValues(alpha: 0.1)),
               ),
               // Velocity (Index 3)
               LineChartBarData(
                  spots: normalizedVelocityPoints,
                  color: Colors.brown, 
                  isCurved: false, // Linear to prevent undershooting 0
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                  barWidth: 1.5,
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
                    interval: (pointsTemp.isNotEmpty) ? (pointsTemp.last.x - pointsTemp.first.x) / 5 : 1000000, 
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
                          // Gravity
                          double g = (spot.y - minTemp) / (maxTemp - minTemp) * (maxGrav - minGrav) + minGrav;
                          return LineTooltipItem('${g.toStringAsFixed(4)} SG', const TextStyle(color: Colors.red));
                       } else if (spot.barIndex == 2) {
                          // Alcohol
                          double a = (spot.y - minTemp) / (maxTemp - minTemp) * (maxAbv - minAbv) + minAbv;
                          return LineTooltipItem('${a.toStringAsFixed(1)} %', const TextStyle(color: Colors.amber));
                       } else {
                          // Velocity (Index 3)
                          double v = (spot.y - minTemp) / (maxTemp - minTemp) * (maxVel - minVel) + minVel;
                          return LineTooltipItem('${v.toStringAsFixed(1)} P/Tag', const TextStyle(color: Colors.brown));
                       }
                    }).toList();
                 }
              ),
           ),
        ),
     );
  }
}
