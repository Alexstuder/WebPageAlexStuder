import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/bf_batch.dart';

class BatchDetailPage extends StatefulWidget {
  final BfBatch batch;

  const BatchDetailPage({super.key, required this.batch});

  @override
  State<BatchDetailPage> createState() => _BatchDetailPageState();
}

class _BatchDetailPageState extends State<BatchDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine status color
    Color statusColor = Colors.grey;
    String status = widget.batch.status ?? 'Unknown';
    if (status == 'Planning') statusColor = Colors.blue;
    if (status == 'Brewing') statusColor = Colors.orange;
    if (status == 'Fermenting') statusColor = Colors.green;
    if (status == 'Completed') statusColor = Colors.grey[800]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.batch.name),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF66B342), // Brewfatherish Green
          labelColor: const Color(0xFF66B342),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "IN PLANUNG"),
            Tab(text: "BRAUEN"),
            Tab(text: "IN GÄRUNG"),
            Tab(text: "ABGESCHLOSSEN"),
            Tab(text: "JSON"),
            Tab(text: "JSON ROH"),
          ],
        ),
      ),
      body: Column(
        children: [

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPlanningTab(),
                _buildBrewingTab(),
                _buildFermentingTab(),
                _buildCompletedTab(),
                _buildJsonTab(),
                _buildRawJsonTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPlanningTab() {
    final recipe = widget.batch.data['recipe'] ?? {};
    final fermentables = (recipe['fermentables'] as List?) ?? [];
    final hops = (recipe['hops'] as List?) ?? [];
    final yeast = (recipe['yeasts'] as List?) ?? [];
    final miscs = (recipe['miscs'] as List?) ?? [];
    
    // Data sources for water - prioritized from recipe['data'] as per previous fix
    final rData = recipe['data'] ?? {};
    final waterData = recipe['water'] ?? {};
    final mashWater = rData['mashWaterAmount'] ?? waterData['mashWaterAmount'];
    final spargeWater = rData['hltWaterAmount'] ?? waterData['spargeWaterAmount'];
    final spargeTemp = waterData['spargeWaterTemp'];
    final totalWater = rData['totalWaterAmount'] ?? waterData['totalWaterAmount'];
    final mashVolume = rData['mashVolume']; // Use specific field for mash volume (water + grain)
    
    // Formatting helper
    String fmtVal(dynamic v, {String suffix = ''}) => v != null ? "$v$suffix" : "-";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive layout: Column on small screens, Row on large
          bool isWide = constraints.maxWidth > 800;
          
          Widget leftColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               _buildPlanningIngredientSection("MALZ & GÄRBARES", fermentables, (item) {
                 return _buildPlanningRow(
                    item['name'], 
                    "${item['color']} EBC", 
                    "${item['amount']} kg"
                 );
               }),
               _buildPlanningIngredientSection("HOPFEN", hops, (item) {
                 // Hops formatting logic
                 double amountRaw = (item['amount'] as num? ?? 0).toDouble();
                 double amount = (amountRaw < 2.0 && (item['unit'] == 'kg' || item['unit'] == null)) ? amountRaw * 1000 : amountRaw;
                 
                 return _buildPlanningRow(
                    item['name'], 
                    "${item['alpha']}% AA @ ${item['time']} min (${item['use']})", 
                    "${amount.toStringAsFixed(1)} g" // Display as int if possible or 1 decimal
                 );
               }),
               _buildPlanningIngredientSection("HEFE", yeast, (item) {
                 return _buildPlanningRow(
                    item['name'], 
                    "Typ: ${item['type']}", 
                    "${item['amount']} ${item['amountUnit'] ?? 'pkg'}"
                 );
               }),
               if (miscs.isNotEmpty)
                  _buildPlanningIngredientSection("SONSTIGES", miscs, (item) {
                     return _buildPlanningRow(
                        item['name'], 
                        "${item['type']} @ ${item['time'] ?? '-'} ${item['timeUnit'] ?? ''}", 
                        "${item['amount']} ${item['amountUnit'] ?? ''}"
                     );
                  }),
            ],
          );
          
          Widget rightColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               // Brew Date
               Text("Braudatum", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
               Text(
                   widget.batch.brewDate != null 
                    ? DateFormat('dd.MM.yyyy').format(DateTime.fromMillisecondsSinceEpoch(widget.batch.brewDate!)) 
                    : '-', 
                   style: const TextStyle(fontSize: 14)
               ),
               const SizedBox(height: 24),
               
               // Recipe Summary Card
               Container(
                 decoration: BoxDecoration(
                   color: const Color(0xFF1E1E1E),
                   borderRadius: BorderRadius.circular(4),
                 ),
                 padding: const EdgeInsets.all(8),
                 child: Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      // Image thumbnail
                       Container(
                         width: 48, height: 48,
                         color: Colors.grey[800],
                         child: Center(child: Icon(Icons.receipt, color: Colors.grey[600])), // Placeholder or actual image
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(recipe['name'] ?? 'Rezept', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                             const Text("Maischesud", style: TextStyle(color: Colors.grey, fontSize: 12)), // Hardcoded per screenshot or derived
                             Text(
                               "STW ${recipe['og'] ?? '-'}  IBU ${recipe['ibu'] ?? '-'}  EBC ${recipe['color'] ?? '-'}",
                               style: TextStyle(color: Colors.grey[400], fontSize: 11)
                             ),
                           ],
                         ),
                       ),
                       Row(
                         children: [
                           IconButton(icon: const Icon(Icons.print, size: 18), onPressed: () {}),
                           IconButton(icon: const Icon(Icons.open_in_new, size: 18), onPressed: () {}), // 'open' icon
                         ],
                       )
                   ],
                 ),
               ),
               
               const SizedBox(height: 24),
               
               // Water Section
               Row(children: [
                  Icon(Icons.water_drop, size: 16, color: Colors.blue[300]),
                  const SizedBox(width: 8),
                  const Text("Wasser", style: TextStyle(color: Colors.grey)),
                  const Spacer(),
                  // Optional pH value per screenshot
                  if (waterData['ph'] != null) Text("pH ${waterData['ph']}", style: TextStyle(color: Colors.green[300], fontSize: 12)),
               ]),
               const SizedBox(height: 8),
               _buildRightColRow("${fmtVal(mashWater, suffix: ' L')} Hauptguss"),
               _buildRightColRow("${fmtVal(spargeWater, suffix: ' L')} Nachgusswasser ${spargeTemp != null ? '@ $spargeTemp °C' : ''}"),
               _buildRightColRow("${fmtVal(totalWater, suffix: ' L')} Wasser gesamt", isBold: true),
               _buildRightColRow("${fmtVal(mashVolume, suffix: ' L')} Maischevolumen (Wasser + Malz)"),
               
               const SizedBox(height: 24),
               
               // Protokoll (Log)
               Row(children: [
                  const Icon(Icons.edit_note, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text("Protokoll", style: TextStyle(color: Colors.grey)),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: (){}, 
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[700]!),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        minimumSize: const Size(0, 24)
                    ),
                    child: const Text("+ HINZUFÜGEN", style: TextStyle(fontSize: 10, color: Colors.white))
                  )
               ]),
               const SizedBox(height: 8),
               // Currently no real logs in BfBatch model exposed, check later; placeholder
               // If widget.batch.data includes 'events' or 'logs', map them.
               // Assuming batch.data['events'] exists based on standard BF structure?
               // Let's check safely.
               Builder(builder: (c) {
                   var events = widget.batch.data['events'] as List?;
                   if (events == null || events.isEmpty) {
                       return const Text("Keine Einträge", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12));
                   }
                   return Column(
                       children: events.map((e) => Padding(
                           padding: const EdgeInsets.only(bottom: 8.0),
                           child: Row(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                   Text(_formatDate(e['time']), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                                   const SizedBox(width: 8),
                                   Expanded(child: Text(e['note'] ?? e['title'] ?? '-', style: const TextStyle(fontSize: 12))),
                               ],
                           ),
                       )).toList(),
                   );
               }),

               const SizedBox(height: 24),
               
               // Notes
               const Text("Sud Notizen", style: TextStyle(color: Colors.grey, fontSize: 12)),
               const SizedBox(height: 4),
               Text(widget.batch.data['notes'] is String ? widget.batch.data['notes'] : '', style: const TextStyle(fontSize: 12)),
            ],
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: leftColumn),
                const SizedBox(width: 32),
                Expanded(flex: 2, child: rightColumn),
              ],
            );
          } else {
            return Column(
              children: [
                leftColumn,
                const Divider(height: 48),
                rightColumn,
              ],
            );
          }
        },
      ),
    );
  }
  
  String _formatDate(dynamic ts) {
      if (ts == null) return '';
      // Timestamp logic: BF uses millis in 'time' mostly
      try {
          DateTime dt = DateTime.fromMillisecondsSinceEpoch(ts is int ? ts : int.parse(ts.toString()));
          return DateFormat('dd. MMM HH:mm').format(dt);
      } catch (e) {
          return ts.toString();
      }
  }

  Widget _buildPlanningIngredientSection(String title, List items, Widget Function(dynamic) rowBuilder) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Text(title, style: TextStyle(color: Colors.green[400], fontWeight: FontWeight.bold, fontSize: 12)),
              const Divider(color: Colors.grey, thickness: 0.5),
              ...items.map((i) => rowBuilder(i)),
              const SizedBox(height: 24),
          ],
      );
  }

  Widget _buildPlanningRow(String title, String subtitle, String amount) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Container(
                      margin: const EdgeInsets.only(top: 4, right: 12),
                      width: 6, height: 6,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green[400]),
                  ),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                          ],
                      ),
                  ),
                  Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
          ),
      );
  }
  
  Widget _buildRightColRow(String text, {bool isBold = false}) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(text, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      );
  }

  Widget _buildBrewingTab() {
    final recipe = widget.batch.data['recipe'] ?? {};
    final equipment = recipe['equipment'] ?? {};
    final water = recipe['water'] ?? {};
    final mash = recipe['mash'] ?? {};
    final mashSteps = mash['steps'] as List? ?? [];
    final fermentables = recipe['fermentables'] as List?; // Nullable check
    final hops = recipe['hops'] as List?;
    final yeasts = recipe['yeasts'] as List?;
    final fermentation = recipe['fermentation'] ?? {};
    final fermSteps = fermentation['steps'] as List?;
    
    // Helper to calculate total weight
    double totalFermentables = 0;
    if (fermentables != null) {
      for (var f in fermentables) {
        totalFermentables += (f['amount'] as num? ?? 0).toDouble();
      }
    }
    
    double totalHops = 0;
    if (hops != null) {
      for (var h in hops) {
          double raw = (h['amount'] as num? ?? 0).toDouble();
          if (raw < 2.0 && (h['unit'] == 'kg' || h['unit'] == null)) {
              totalHops += raw * 1000;
          } else {
              totalHops += raw;
          }
      }
    }

    // Determine type string (e.g. All Grain)
    String type = recipe['type'] ?? 'Unknown';
    if (type == 'All Grain') type = 'Maischesud';
    
    TextStyle headerStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white);

    TextStyle textStyle = const TextStyle(fontSize: 12, color: Colors.grey, height: 1.5);
    TextStyle boldText = const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Center aligned like screenshot
        children: [
          // 1. Title & Type
          Text(recipe['name'] ?? 'Unbenannt', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(type, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),

          // 2. Equipment
          if (equipment.isNotEmpty) ...[
            Text(equipment['name'] ?? '', style: boldText),
            Text("${recipe['efficiency'] ?? '-'}% Ausbeute", style: textStyle),
            Text("Sudgröße: ${recipe['batchSize'] ?? '-'} L", style: textStyle),
            Text("Kochzeit: ${recipe['boilTime'] ?? '-'} min", style: textStyle),
            const SizedBox(height: 16),
          ],

          // 3. Water Info
          // 3. Water Info
          Builder(
            builder: (context) {
                final rData = recipe['data'] ?? {};
                
                // Prefer data from recipe['data'] if available, otherwise fallback to recipe['water'] or recipe root
                final mashWater = rData['mashWaterAmount'] ?? water['mashWaterAmount']; // L
                final spargeWater = rData['hltWaterAmount'] ?? water['spargeWaterAmount']; // L (HLT is often sparge)
                final totalWater = rData['totalWaterAmount'] ?? water['totalWaterAmount']; // L
                final kochVol = rData['boilSize'] ?? water['boilSize'] ?? recipe['boilSize']; // L
                final spargeTemp = water['spargeWaterTemp'] ?? '-'; // Not in data usually
                
                // Pre-boil gravity is often in recipe root or calculated
                final preBoilOg = recipe['preBoilGravity']; // e.g. 1.043

                if (mashWater != null || totalWater != null) {
                    return Column(
                        children: [
                             if (mashWater != null) Text("Maischwasser: $mashWater L", style: textStyle),
                             if (spargeWater != null) Text("Nachgusswasser: $spargeWater L @ $spargeTemp °C", style: textStyle),
                             if (totalWater != null) Text("Wasser gesamt: $totalWater L", style: textStyle),
                             if (kochVol != null) Text("Kochvolumen: $kochVol L", style: textStyle),
                             if (preBoilOg != null) Text("Stammwürze vor Kochen: $preBoilOg", style: textStyle),
                             const SizedBox(height: 16),
                        ]
                    );
                } else {
                    return const SizedBox.shrink();
                }
            }
          ),
          
          // 4. Eckdaten (Benchmarks)
          Text("Eckdaten", style: headerStyle),
          Text("Stammwürze: ${recipe['og'] ?? '-'} SG", style: textStyle),
          Text("Restextrakt: ${recipe['fg'] ?? '-'} SG", style: textStyle),
          Text("IBU (Tinseth): ${recipe['ibu'] ?? '-'}", style: textStyle),
          Text("Farbe: ${recipe['color'] ?? '-'} EBC", style: textStyle),
          const SizedBox(height: 24),

          // 5. Maischen
          Text("Maischen", style: headerStyle),
          if (mashSteps.isEmpty) Text("-", style: textStyle),
          ...mashSteps.map((step) => Text(
             "${step['name'] ?? 'Schritt'} — ${step['stepTemp']} °C — ${step['stepTime']} min",
             style: textStyle
          )),
          const SizedBox(height: 24),
          
          // 6. Malze
          Text("Malze (${totalFermentables.toStringAsFixed(2)} kg)", style: headerStyle),
          if (fermentables == null || fermentables.isEmpty) Text("-", style: textStyle),
          if (fermentables != null) ...fermentables.map((f) {
             double amount = (f['amount'] as num? ?? 0).toDouble();
             double percent = totalFermentables > 0 ? (amount / totalFermentables * 100) : 0;
             return Padding(
               padding: const EdgeInsets.symmetric(vertical: 2.0),
               child: RichText(
                 textAlign: TextAlign.center,
                 text: TextSpan(
                   style: textStyle,
                   children: [
                     TextSpan(text: "${amount.toStringAsFixed(2)} kg ", style: boldText),
                     TextSpan(text: "(${percent.toStringAsFixed(1)}%) — "),
                     TextSpan(text: "${f['name']} "),
                     TextSpan(text: "— ${f['supplier'] ?? ''} — "),
                     TextSpan(text: "${f['color']} EBC"),
                   ]
                 )
               ),
             );
          }),
          const SizedBox(height: 24),

          // 7. Hopfen
          Text("Hopfen (${totalHops.toStringAsFixed(1)} g)", style: headerStyle), // Showing g is safer if converted
          if (hops == null || hops.isEmpty) Text("-", style: textStyle),
          if (hops != null) ...hops.map((h) {
             // Brewfather API usually returns hops in grams (e.g. 25 for 25g) despite displaying 'g' unit.
             // However, some internal representations might be kg.
             double rawAmount = (h['amount'] as num? ?? 0).toDouble();
             // Heuristic: if amount is tiny (< 1), assume it's kg and convert to g. If it's > 1 (e.g. 25), assume it's already g.
             // But actually Brewfather API standard for hops is Grams in many places, or Kg.
             // Looking at the screenshot provided by user, they see "73000.0 g" for 73g total. So the input 'amount' was likely already 25, 15 etc (grams), and I multiplied by 1000.
             
             double amountG = rawAmount;
             // Only convert if it seems to be in kg (e.g. 0.025 for 25g)
             if (amountG < 2.0 && (h['unit'] == 'kg' || h['unit'] == null)) { 
                amountG = amountG * 1000;
             }

             
             return Padding(
               padding: const EdgeInsets.symmetric(vertical: 2.0),
               child: RichText(
                 textAlign: TextAlign.center,
                 text: TextSpan(
                   style: textStyle,
                   children: [
                     TextSpan(text: "${amountG.toStringAsFixed(0)} g ", style: boldText),
                     TextSpan(text: "— ${h['name']} ${h['alpha']}% — "),
                     TextSpan(text: "${h['use']} — ", style: const TextStyle(color: Colors.redAccent)), // Highlight usage like screenshot
                     TextSpan(text: "${h['time']} min"),
                   ]
                 )
               ),
             );
          }),
          const SizedBox(height: 24),

          // 8. Hefe
          Text("Hefe", style: headerStyle),
          if (yeasts == null || yeasts.isEmpty) Text("-", style: textStyle),
          if (yeasts != null) ...yeasts.map((y) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                    style: textStyle,
                    children: [
                        TextSpan(text: "${y['amount'] ?? '-'} ${y['amountUnit'] ?? 'unit'} ", style: boldText),
                        TextSpan(text: "— ${y['name']} ${y['attenuation'] != null ? '${y['attenuation']}%' : ''}"),
                    ]
                )
            )
          )),
          const SizedBox(height: 24),

          // 9. Gärung
          Text("Gärung", style: headerStyle),
           if (fermSteps == null || fermSteps.isEmpty) Text("-", style: textStyle),
           if (fermSteps != null) ...fermSteps.map((s) => Text(
             "${s['type'] ?? 'Step'} — ${s['stepTemp']} °C — ${s['stepTime']} Tage",
             style: textStyle
           )),
          const SizedBox(height: 24),

          // 10. Wasserprofil
          Text("Wasserprofil", style: headerStyle),
          Builder(
            builder: (context) {
                // Try to find the ion profile. usually in water['totalAdjustments'] or water['meta']
                final adjustments = water['totalAdjustments'] ?? water['meta'];
                
                if (adjustments != null) {
                    return Column(
                      children: [
                        const SizedBox(height: 8),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                _buildWaterIon("Ca²⁺", adjustments['calcium'] ?? adjustments['Ca']),
                                _buildWaterIon("Mg²⁺", adjustments['magnesium'] ?? adjustments['Mg']),
                                _buildWaterIon("Na⁺", adjustments['sodium'] ?? adjustments['Na']),
                                _buildWaterIon("Cl⁻", adjustments['chloride'] ?? adjustments['Cl']),
                                _buildWaterIon("SO₄²⁻", adjustments['sulfate'] ?? adjustments['SO4']),
                                _buildWaterIon("HCO₃⁻", adjustments['bicarbonate'] ?? adjustments['HCO3']),
                            ],
                        ),
                      ],
                    );
                } else {
                    return const Text("Kein Wasserprofil", style: TextStyle(color: Colors.grey));
                }
            }
          ),
          
          const SizedBox(height: 40),
          // Footer note
          if (recipe['notes'] != null) ...[
             if (recipe['notes'] is String)
                Text(recipe['notes'], style: textStyle, textAlign: TextAlign.center)
             else if (recipe['notes'] is List)
                ...((recipe['notes'] as List).map((n) => Text(n is Map ? (n['note'] ?? '') : n.toString(), style: textStyle, textAlign: TextAlign.center))),
          ]

        ],
      ),
    );
  }

  Widget _buildWaterIon(String name, dynamic value) {
      String displayValue = '-';
      if (value != null) {
          if (value is num) {
              displayValue = value.round().toString();
          } else {
              displayValue = value.toString();
          }
      }

      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
              children: [
                   Text(name, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                   Text(displayValue, style: const TextStyle(color: Colors.lightBlue, fontWeight: FontWeight.bold)),
              ],
          ),
      );
  }

  Widget _buildFermentingTab() {
    final recipe = widget.batch.data['recipe'] ?? {};
    final fermentation = recipe['fermentation'] ?? {};
    final steps = (fermentation['steps'] as List?) ?? [];
    
    // -- Data Parsing for Chart (Target Temperature) --
    List<FlSpot> targetTempSpots = [];
    double currentDay = 0;
    
    // Initial point
    if (steps.isNotEmpty) {
      double startTemp = (steps.first['stepTemp'] as num).toDouble();
      targetTempSpots.add(FlSpot(0, startTemp));
    }

    for (var step in steps) {
      double temp = (step['stepTemp'] as num).toDouble();
      double days = (step['stepTime'] as num).toDouble();
      
      // Horizontal line for the duration of the step
      targetTempSpots.add(FlSpot(currentDay + days, temp));
      
      currentDay += days;
    }

    // -- Stats Data --
    // Measured Values
    final measuredOg = widget.batch.data['measuredOg'];
    final fermenterVol = recipe['equipment']?['fermenterVolume'];
    final bottlingVol = recipe['equipment']?['bottlingVolume'];
    
    // Carbonation
    final carbType = widget.batch.data['carbonationType'] ?? '-';
    final carbVol = recipe['carbonation']?.toString() ?? '-';
    final carbPressure = widget.batch.data['carbonationForce']?.toString() ?? '-';

    // Dates
    final brewDateMs = widget.batch.data['brewDate'];
    final bottlingDateMs = widget.batch.data['bottlingDate'];
    final dateFormat = DateFormat('dd.MM.yyyy');
    
    String brewDateStr = brewDateMs != null ? dateFormat.format(DateTime.fromMillisecondsSinceEpoch(brewDateMs)) : '-';
    String bottlingDateStr = bottlingDateMs != null ? dateFormat.format(DateTime.fromMillisecondsSinceEpoch(bottlingDateMs)) : '-';


    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Layout: Left (Chart + Profile) | Right (Stats)
          // Using LayoutBuilder to handle responsiveness if needed, but for now simple Row/Column
          LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 800;
              
              Widget leftColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Result Chart ---
                  _buildSectionHeader("Gärverlauf (Soll-Temperatur)"),
                  Container(
                    height: 350,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E), // Dark background for chart
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: targetTempSpots.isEmpty 
                      ? const Center(child: Text("Kein Gärprofil vorhanden", style: TextStyle(color: Colors.white54)))
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
                              getDrawingVerticalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
                            ),
                            titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true, 
                                    reservedSize: 30,
                                    getTitlesWidget: (value, meta) => Text("${value.toInt()}d", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                  )
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true, 
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) => Text("${value.toInt()}°", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                  )
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: targetTempSpots,
                                isCurved: false, // Step layout usually preferred for temperature schedules, but Brewfather uses line
                                color: Colors.greenAccent,
                                barWidth: 2,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(show: true, color: Colors.greenAccent.withValues(alpha: 0.1)),
                              ),
                            ],
                            // Add Touch data later
                          ),
                        ),
                  ),
                  const SizedBox(height: 20),
                  
                  // --- Gärprofil Steps ---
                  _buildSectionHeader("Gärprofil"),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        ...steps.map((step) => ListTile(
                          title: Text("${step['name'] ?? step['type'] ?? 'Schritt'}"),
                          subtitle: Text("${step['stepTemp']} °C  —  ${step['stepTime']} Tage"),
                          leading: const Icon(Icons.thermostat, color: Colors.orangeAccent),
                        )),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Gärung Start", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(brewDateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text("Datum Abfüllung", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(bottlingDateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              );

              Widget rightColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // --- Gemessene Werte ---
                   _buildCardSection("Gemessene Werte", [
                     _buildDetailRow("Stammwürze", "${measuredOg ?? '-'} SG", highlight: true),
                     _buildDetailRow("Gärtank-Vol", "${fermenterVol ?? '-'} L"),
                     _buildDetailRow("Abfüllmenge", "${bottlingVol ?? '-'} L"),
                   ]),
                   const SizedBox(height: 16),
                   
                   // --- Karbonisierung ---
                   _buildCardSection("Karbonisierung", [
                      _buildDetailRow("Typ", carbType),
                      const SizedBox(height: 8),
                      Text("$carbPressure Bar (Force Carbonation)", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text("um $carbVol vol CO2 zu erreichen", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                   ]),
                   const SizedBox(height: 16),
                   
                   // --- Statistiken ---
                   _buildCardSection("Statistiken", [
                      _buildDetailRow("Vvergärungsgrad", "${widget.batch.data['measuredAttenuation'] ?? '-'} %"),
                      _buildDetailRow("Maische Effizienz", "${widget.batch.data['measuredMashEfficiency'] ?? '-'} %"),
                   ]),
                ],
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: leftColumn),
                    const SizedBox(width: 20),
                    Expanded(flex: 1, child: rightColumn),
                  ],
                );
              } else {
                return Column(
                  children: [
                    leftColumn,
                    const SizedBox(height: 20),
                    rightColumn
                  ],
                );
              }
            }
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, size: 16, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          ...children
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: highlight ? 18 : 14,
            color: highlight ? Colors.white : Colors.white70
          )),
        ],
      ),
    );
  }

  Widget _buildCompletedTab() {
    final measured = widget.batch.data['measuredValues'] ?? {};
    final recipe = widget.batch.data['recipe'] ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Zusammenfassung"),
          _buildStatGrid({
            "Abfüllmenge": "${measured['bottlingVolume'] ?? '-'} L",
            "FG Gemessen": "${measured['fg'] ?? '-'} SG",
            "Alkohol (ABV)": "${measured['abv'] ?? '-'} %",
            "Effizienz": "${measured['efficiency'] ?? '-'} %",
            "Karbonisierung": "${recipe['carbonation'] ?? '-'} vol CO2",
          }),
          const SizedBox(height: 20),
          _buildSectionHeader("Notizen"),
           ...((widget.batch.data['notes'] as List? ?? []).map((n) => Card(
             child: Padding(
               padding: const EdgeInsets.all(8.0),
               child: Text(n['note'] ?? ''),
             ),
           ))),
           if((widget.batch.data['notes'] as List? ?? []).isEmpty) const Text("Keine Notizen"),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF66B342),
          letterSpacing: 1.0,
        ),
      ),
    );
  }
  


  Widget _buildStatGrid(Map<String, String> stats) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: stats.entries.map((e) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(e.key, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(e.value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      )).toList(),
    );
  }

  Widget _buildJsonTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: widget.batch.data.entries.map((e) => _buildJsonNode(e.key, e.value)).toList(),
      ),
    );
  }

  Widget _buildJsonNode(String key, dynamic value) {
    if (value is Map) {
      if (value.isEmpty) {
        return ListTile(
            title: Text("$key: {}", style: const TextStyle(fontFamily: 'monospace')),
            dense: true,
            contentPadding: EdgeInsets.zero,
        );
      }
      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF66B342))),
          subtitle: Text('{ ... }', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(left: 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: value.entries.map((e) => _buildJsonNode(e.key.toString(), e.value)).toList(),
        ),
      );
    } else if (value is List) {
      if (value.isEmpty) {
        return ListTile(
            title: Text("$key: []", style: const TextStyle(fontFamily: 'monospace')),
            dense: true,
            contentPadding: EdgeInsets.zero,
        );
      }
      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF66B342))),
          subtitle: Text('[${value.length}]', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(left: 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: value.asMap().entries.map((e) => _buildJsonNode('[${e.key}]', e.value)).toList(),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText("$key: ", style: const TextStyle(color: Colors.grey)),
            Expanded(
              child: SelectableText(
                value.toString(),
                style: const TextStyle(fontFamily: 'monospace', color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildRawJsonTab() {
    String prettyJson = const JsonEncoder.withIndent('  ').convert(widget.batch.data);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        prettyJson,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }
}
