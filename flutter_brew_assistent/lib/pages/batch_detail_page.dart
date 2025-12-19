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


    return Scaffold(
      appBar: AppBar(
        title: Text(widget.batch.name),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF66B342), // Brewfatherish Green
          labelColor: const Color(0xFF66B342),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'IN PLANUNG'),
            Tab(text: 'BRAUEN'),
            Tab(text: 'IN GÄRUNG'),
            Tab(text: 'ABGESCHLOSSEN'),
            Tab(text: 'JSON'),
            Tab(text: 'JSON ROH'),
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
    String fmtVal(dynamic v, {String suffix = ''}) => v != null ? '$v$suffix' : '-';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive layout: Column on small screens, Row on large
          bool isWide = constraints.maxWidth > 800;
          
          Widget leftColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               _buildPlanningIngredientSection('MALZ & GÄRBARES', fermentables, (item) {
                 return _buildPlanningRow(
                    item['name'], 
                    "${item['color']} EBC", 
                    "${item['amount']} kg"
                 );
               }),
               _buildPlanningIngredientSection('HOPFEN', hops, (item) {
                 // Hops formatting logic
                 double amountRaw = (item['amount'] as num? ?? 0).toDouble();
                 double amount = (amountRaw < 2.0 && (item['unit'] == 'kg' || item['unit'] == null)) ? amountRaw * 1000 : amountRaw;
                 
                 return _buildPlanningRow(
                    item['name'], 
                    "${item['alpha']}% AA @ ${item['time']} min (${item['use']})", 
                    '${amount.toStringAsFixed(1)} g' // Display as int if possible or 1 decimal
                 );
               }),
               _buildPlanningIngredientSection('HEFE', yeast, (item) {
                 return _buildPlanningRow(
                    item['name'], 
                    "Typ: ${item['type']}", 
                    "${item['amount']} ${item['amountUnit'] ?? 'pkg'}"
                 );
               }),
               if (miscs.isNotEmpty)
                  _buildPlanningIngredientSection('SONSTIGES', miscs, (item) {
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
               Text('Braudatum', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
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
                             const Text('Maischesud', style: TextStyle(color: Colors.grey, fontSize: 12)), // Hardcoded per screenshot or derived
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
                  const Text('Wasser', style: TextStyle(color: Colors.grey)),
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
                  const Text('Protokoll', style: TextStyle(color: Colors.grey)),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: (){}, 
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[700]!),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        minimumSize: const Size(0, 24)
                    ),
                    child: const Text('+ HINZUFÜGEN', style: TextStyle(fontSize: 10, color: Colors.white))
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
                       return const Text('Keine Einträge', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12));
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
               const Text('Sud Notizen', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                             if (mashWater != null) Text('Maischwasser: $mashWater L', style: textStyle),
                             if (spargeWater != null) Text('Nachgusswasser: $spargeWater L @ $spargeTemp °C', style: textStyle),
                             if (totalWater != null) Text('Wasser gesamt: $totalWater L', style: textStyle),
                             if (kochVol != null) Text('Kochvolumen: $kochVol L', style: textStyle),
                             if (preBoilOg != null) Text('Stammwürze vor Kochen: $preBoilOg', style: textStyle),
                             const SizedBox(height: 16),
                        ]
                    );
                } else {
                    return const SizedBox.shrink();
                }
            }
          ),
          
          // 4. Eckdaten (Benchmarks)
          Text('Eckdaten', style: headerStyle),
          Text("Stammwürze: ${recipe['og'] ?? recipe['preBoilGravity'] ?? '-'} SG", style: textStyle),
          Text("Restextrakt: ${recipe['fg'] ?? '-'} SG", style: textStyle),
          Text("IBU (Tinseth): ${recipe['ibu'] == 0 ? '-' : (recipe['ibu'] ?? '-')}", style: textStyle),
          Text("Farbe: ${recipe['color'] ?? '-'} EBC", style: textStyle),
          const SizedBox(height: 24),

          // 5. Maischen
          Text('Maischen', style: headerStyle),
          if (mashSteps.isEmpty) Text('-', style: textStyle),
          ...mashSteps.map((step) => Text(
             "${step['name'] ?? 'Schritt'} — ${step['stepTemp']} °C — ${step['stepTime']} min",
             style: textStyle
          )),
          const SizedBox(height: 24),
          
          // 6. Malze
          Text('Malze (${totalFermentables.toStringAsFixed(2)} kg)', style: headerStyle),
          if (fermentables == null || fermentables.isEmpty) Text('-', style: textStyle),
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
                     TextSpan(text: '${amount.toStringAsFixed(2)} kg ', style: boldText),
                     TextSpan(text: '(${percent.toStringAsFixed(1)}%) — '),
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
          Text('Hopfen (${totalHops.toStringAsFixed(1)} g)', style: headerStyle), // Showing g is safer if converted
          if (hops == null || hops.isEmpty) Text('-', style: textStyle),
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
                     TextSpan(text: '${amountG.toStringAsFixed(0)} g ', style: boldText),
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
          Text('Hefe', style: headerStyle),
          if (yeasts == null || yeasts.isEmpty) Text('-', style: textStyle),
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
          Text('Gärung', style: headerStyle),
           if (fermSteps == null || fermSteps.isEmpty) Text('-', style: textStyle),
           if (fermSteps != null) ...fermSteps.map((s) => Text(
             "${s['type'] ?? 'Step'} — ${s['stepTemp']} °C — ${s['stepTime']} Tage",
             style: textStyle
           )),
          const SizedBox(height: 24),

          // 10. Wasserprofil
          Text('Wasserprofil', style: headerStyle),
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
                                _buildWaterIon('Ca²⁺', adjustments['calcium'] ?? adjustments['Ca']),
                                _buildWaterIon('Mg²⁺', adjustments['magnesium'] ?? adjustments['Mg']),
                                _buildWaterIon('Na⁺', adjustments['sodium'] ?? adjustments['Na']),
                                _buildWaterIon('Cl⁻', adjustments['chloride'] ?? adjustments['Cl']),
                                _buildWaterIon('SO₄²⁻', adjustments['sulfate'] ?? adjustments['SO4']),
                                _buildWaterIon('HCO₃⁻', adjustments['bicarbonate'] ?? adjustments['HCO3']),
                            ],
                        ),
                      ],
                    );
                } else {
                    return const Text('Kein Wasserprofil', style: TextStyle(color: Colors.grey));
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
    
    // -- Data Parsing --
    final yeasts = widget.batch.data['batchYeastsLocal'] ?? recipe['yeasts'] ?? [];
    final miscs = widget.batch.data['batchMiscsLocal'] ?? []; 
    
    // Dates
    final brewDateMs = widget.batch.data['fermentationStartDate'] ?? widget.batch.data['brewDate'];
    final bottlingDateMs = widget.batch.data['bottlingDate'];
    final dateFormat = DateFormat('dd.MM.yyyy');
    
    final startDateStr = brewDateMs != null ? dateFormat.format(DateTime.fromMillisecondsSinceEpoch(brewDateMs)) : '-';
    final bottlingDateStr = bottlingDateMs != null ? dateFormat.format(DateTime.fromMillisecondsSinceEpoch(bottlingDateMs)) : '-';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 900;
          
          Widget leftColumn = Column(
             crossAxisAlignment: CrossAxisAlignment.stretch,
             children: [
               _buildMesswerteSection(),
               const SizedBox(height: 16),
               _buildGatProfilSection(steps, startDateStr, bottlingDateStr, brewDateMs),
               const SizedBox(height: 16),
               _buildBeigabenSection(yeasts, miscs),
             ],
          );

          Widget rightColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGemesseneWerteSection(),
              const SizedBox(height: 16),
              _buildKarbonisierungSection(),
               const SizedBox(height: 16),
              _buildStatistikenSection(),
              const SizedBox(height: 16),
              _buildZusammenfassungSection(),
               const SizedBox(height: 16),
              _buildEreignisseSection(),
            ],
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: leftColumn),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: rightColumn),
              ],
            );
          } else {
            return Column(
              children: [
                leftColumn,
                const SizedBox(height: 16),
                rightColumn,
              ],
            );
          }
        }
      ),
    );
  }

  // --- Sections for Fermenting Tab ---

  Widget _buildMesswerteSection() {
     final recipe = widget.batch.data['recipe'] ?? {};
     final steps = (recipe['fermentation']?['steps'] as List?) ?? [];
     List<FlSpot> targetTempSpots = [];
     double currentDay = 0;
     if (steps.isNotEmpty) {
      double startTemp = (steps.first['stepTemp'] as num).toDouble();
      targetTempSpots.add(FlSpot(0, startTemp));
     }
     for (var step in steps) {
      double temp = (step['stepTemp'] as num).toDouble();
      double days = (step['stepTime'] as num).toDouble();
      targetTempSpots.add(FlSpot(currentDay + days, temp));
      currentDay += days;
     }

     return _buildCardSection('Messwerte', [
         Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             const Text('Keine Messwerte gefunden...', style: TextStyle(fontSize: 12, color: Colors.grey)), 
             OutlinedButton.icon(
                onPressed: () {}, 
                icon: const Icon(Icons.add, size: 14), 
                label: const Text('GERÄTE', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  minimumSize: const Size(0, 30)
                ),
             )
           ],
         ),
         const SizedBox(height: 12),
         AspectRatio(
             aspectRatio: 1.7,
             child: LineChart(
               LineChartData(
                 gridData: FlGridData(
                    show: true, 
                    drawVerticalLine: false, 
                    getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1)
                 ),
                 titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)))),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 2, getTitlesWidget: (val, meta) => Text('${val.toInt()}d', style: const TextStyle(fontSize: 10, color: Colors.grey)))),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                 ),
                 borderData: FlBorderData(show: false),
                 lineBarsData: [
                   LineChartBarData(
                     spots: targetTempSpots,
                     isCurved: false,
                     color: Colors.greenAccent,
                     barWidth: 2,
                     dotData: const FlDotData(show: false),
                     belowBarData: BarAreaData(show: true, color: Colors.greenAccent.withValues(alpha: 0.1)), 
                   )
                 ]
               )
             ),
         )
     ]);
  }

  Widget _buildGatProfilSection(List steps, String startDate, String bottlingDate, int? brewDateMs) {
      final dateFormat = DateFormat('dd. MMM. yyyy');
      
      List<Widget> stepWidgets = [];
      int accumulatedDays = 0;
      DateTime startDt = brewDateMs != null ? DateTime.fromMillisecondsSinceEpoch(brewDateMs) : DateTime.now();
      
      for(var step in steps) {
          String name = step['name'] ?? '';
          num temp = step['stepTemp'] ?? 0;
          num days = step['stepTime'] ?? 0;
          
          DateTime stepDate = startDt.add(Duration(days: accumulatedDays));
          accumulatedDays += days.toInt();

          stepWidgets.add(
              Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                      '${dateFormat.format(stepDate)} - $name - $temp °C - $days Tage', 
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center,
                  ),
              )
          );
      }

      return _buildCardSection('Gärprofil', [
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
                         const Text('Gärung Start', style: TextStyle(color: Colors.grey, fontSize: 11)),
                         const SizedBox(height: 4),
                         Row(children: [const Icon(Icons.calendar_today, size: 14, color: Colors.white), const SizedBox(width: 6), Text(startDate, style: const TextStyle(fontWeight: FontWeight.bold))]),
                         const SizedBox(height: 4),
                         Container(height: 1, width: 120, color: Colors.white24)
                     ],
                 ),
                 Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                         const Text('Datum Abfüllung', style: TextStyle(color: Colors.grey, fontSize: 11)),
                         const SizedBox(height: 4),
                         Row(children: [const Icon(Icons.calendar_today, size: 14, color: Colors.white), const SizedBox(width: 6), Text(bottlingDate, style: const TextStyle(fontWeight: FontWeight.bold))]),
                         const SizedBox(height: 4),
                         Container(height: 1, width: 120, color: Colors.white24)
                     ],
                 )
             ],
         )
      ]);
  }

  Widget _buildBeigabenSection(List yeasts, List miscs) {
      List<Widget> items = [];
      for(var y in yeasts) {
         dynamic amount = y is Map ? y['amount'] : y.amount;
         String unit = y is Map ? (y['unit'] ?? '') : (y.unit ?? '');
         String name = y is Map ? (y['name'] ?? '') : y.name;
         items.add(_buildBeigabenRow('$amount $unit', name));
      }
      for(var m in miscs) {
          dynamic amount = m is Map ? m['amount'] : m.amount;
          String unit = m is Map ? (m['unit'] ?? '') : (m.unit ?? '');
          String name = m is Map ? (m['name'] ?? '') : m.name;
          items.add(_buildBeigabenRow('$amount $unit', name));
      }
      if (items.isEmpty) items.add(const Text('Keine Beigaben', style: TextStyle(color: Colors.grey)));

      return _buildCardSection('Beigaben', items);
  }

  Widget _buildBeigabenRow(String amount, String name) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
              children: [
                  Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Text(' - ', style: TextStyle(color: Colors.grey)),
                  Expanded(child: Text(name, style: const TextStyle(color: Colors.white70))),
              ],
          ),
      );
  }

  Widget _buildGemesseneWerteSection() {
     final data = widget.batch.data;
     final recipe = data['recipe'] ?? {};
     
     return _buildCardSection('Gemessene Werte', [
         _buildDottedRow('Stammwürze', data['measuredOg']?.toString() ?? 'Infinity', 'SG'),
         _buildDottedRow('Gärtank-Vol', recipe['equipment']?['fermenterVolume']?.toString() ?? '0', 'L'),
         _buildDottedRow('Abfüllmenge', recipe['equipment']?['bottlingVolume']?.toString() ?? '0', 'L'),
         const SizedBox(height: 12),
         Row(
             children: [
                 Expanded(child: _buildDottedRow('Auffüllmenge Gärtank', '0', 'L')),
                 const SizedBox(width: 16),
                 Expanded(child: _buildDottedRow('Restextrakt', data['measuredFg']?.toString() ?? 'Infinity', 'SG')),
             ],
         ),
          const SizedBox(height: 8),
         _buildDottedRow('Temperatur Karbonisierung', '4', '°C'),
     ]);
  }
  
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
             Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
             const SizedBox(width: 4),
             Text(unit, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      );
  }

  Widget _buildKarbonisierungSection() {
      final recipe = widget.batch.data['recipe'] ?? {};
      final dynamic carbonationField = recipe['carbonation'];

      double? carbonationVolumes;
      String? carbonationMethod;

      if (carbonationField is Map) {
         carbonationVolumes = (carbonationField['vols'] as num?)?.toDouble();
         carbonationMethod = carbonationField['method']?.toString();
      } else if (carbonationField is num) {
         carbonationVolumes = carbonationField.toDouble();
      }

      String method = widget.batch.data['carbonationType'] ?? carbonationMethod ?? 'Keg';
      String info = "-1.05 Bar bei 4 °C\nfür etwa 1 Wochen\num ${carbonationVolumes ?? 0} Vol CO₂ zu erreichen"; 

      return _buildCardSection('Karbonisierung', [
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
             child: Text(info, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          )
      ]);
  }

  Widget _buildStatistikenSection() {
      final r = widget.batch.data['recipe'] ?? {};
      final abv = r['abv'] ?? 0;
      final att = r['attenuation'] ?? 0;
      final mashEff = r['mashEfficiency'] ?? 0;
      final totEff = r['efficiency'] ?? 0;

      return _buildCardSection('Statistiken', [
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
      ]);
  }
  
  Widget _buildStatItem(String label, String value, String unit) {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 4),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                       Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                       Text(unit, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
              )
          ],
      );
  }

  Widget _buildZusammenfassungSection() {
     final r = widget.batch.data['recipe'] ?? {};
     final d = r['data'] ?? {};
     
     return _buildCardSection('Zusammenfassung', [
         const Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
                 Text('Messung', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                 Row( children: [
                    Text('Rezept', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    SizedBox(width: 32),
                    Text('Sud', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                 ])
             ],
         ),
         const SizedBox(height: 8),
         const Divider(color: Colors.white24),
         _buildSummaryRow('Volumen vor Kochen (Heiß)', "${r['boilSize'] ?? '-'}", "${r['boilSize'] ?? '-'}"),
         _buildSummaryRow('Verdampfung pro Stunde', "${r['equipment']?['boilOffPerHr'] ?? '-'}", "${r['equipment']?['boilOffPerHr'] ?? '-'}"),
         _buildSummaryRow('Sudgröße', "${r['batchSize'] ?? '-'}", "${r['batchSize'] ?? '-'}"),
         _buildSummaryRow('Stammwürze vor Kochen', "${r['preBoilGravity'] ?? '-'}", "${r['preBoilGravity'] ?? '-'}"), 
       _buildSummaryRow('Stammwürze nach dem Kochen', "${r['og'] ?? '-'}", "${widget.batch.data['measuredOg'] ?? '-'}"),
       _buildSummaryRow('Stammwürze', "${r['og'] ?? '-'}", "${widget.batch.data['measuredOg'] ?? '-'}"),
       _buildSummaryRow('Restextrakt', "${r['fg'] ?? '-'}", "${widget.batch.data['measuredFg'] ?? '-'}"),
       _buildSummaryRow('Gesamteffizienz', "${r['efficiency'] ?? '-'}%", "${r['efficiency'] ?? '-'}%"),
       _buildSummaryRow('Farbe', "${r['color'] ?? '-'} EBC", "${r['color'] ?? '-'} EBC"),
       _buildSummaryRow('Maische pH', "${d['mashPh'] ?? '-'}", "${widget.batch.data['measuredMashPh'] ?? '-'}"),
     ]);
  }
  
  Widget _buildSummaryRow(String label, String target, String actual) {
      bool isDiff = target != actual && actual != '-' && actual != 'Infinity' && actual != 'null EBC';
      return Container(
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10))
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                  Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                  SizedBox(
                      width: 120, 
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                              Text(target, style: const TextStyle(fontSize: 12)),
                              Text(actual, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDiff ? Colors.redAccent : Colors.greenAccent)),
                          ],
                      ),
                  )
              ],
          ),
      );
  }

  Widget _buildEreignisseSection() {
     final events = (widget.batch.data['events'] as List?) ?? [];
     final dateFormat = DateFormat('EEEE, d. MMMM yyyy HH:mm', 'de_DE'); 
     
     return _buildCardSection('Ereignisse', [
         ...events.map((e) {
             DateTime dt = DateTime.fromMillisecondsSinceEpoch(e['time']);
             return Padding(
                 padding: const EdgeInsets.symmetric(vertical: 8),
                 child: Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                         Expanded(flex: 4, child: Text(dateFormat.format(dt), style: const TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic))), 
                         Expanded(flex: 6, child: Text(e['title'] ?? e['eventType'] ?? '', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic))),
                         const Icon(Icons.edit, size: 14, color: Colors.grey)
                     ],
                 ),
             );
         })
     ]);
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
  


  Widget _buildCompletedTab() {
     // Data extraction
     final batchData = widget.batch.data;
     final recipe = batchData['recipe'] ?? {};
     
     // Helper for formatting
     String val(dynamic v, {String suffix = '', String def = '-'}) {
       if (v == null || v == '') return def;
       if (v is num && (v.isInfinite || v.isNaN)) return 'Infinity'; // Match screenshot behavior if needed, or handle gracefully
       return '$v$suffix';
     }
     
     return SingleChildScrollView(
       padding: const EdgeInsets.all(16),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            // 1. Geschmack (Taste)
            _buildSectionHeader('Geschmack', icon: Icons.local_drink),
            const SizedBox(height: 16),
            const Text('Bewertung', style: TextStyle(color: Colors.grey, fontSize: 12)),
            Slider(
              value: (batchData['tasteRating'] as num? ?? 0).toDouble().clamp(0, 50),
              min: 0,
              max: 50,
              divisions: 50,
              activeColor: const Color(0xFF66B342), 
              inactiveColor: Colors.grey[800],
              onChanged: (val) {}, // Read-only for now or impl update
              label: (batchData['tasteRating'] as num? ?? 0).toString(),
            ),
            Align(
              alignment: Alignment.centerRight, 
              child: Text((batchData['tasteRating'] as num? ?? 0).toDouble().toString(), style: const TextStyle(fontSize: 12))
            ),
            const SizedBox(height: 12),
            const Text('Anmerkungen zum Geschmack', style: TextStyle(color: Colors.grey, fontSize: 12)),
            Text(batchData['tasteNotes'] ?? '', style: const TextStyle(fontSize: 14)),
            const Divider(height: 48, color: Colors.white12),

            // 2. Gemessene Werte (Measured Values)
            _buildSectionHeader('Gemessene Werte', icon: Icons.straighten, action: OutlinedButton(
                onPressed: (){},
                style: OutlinedButton.styleFrom(
                   side: const BorderSide(color: Colors.white24),
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                   minimumSize: const Size(0, 28)
                ),
                child: const Text('+ HINZUFÜGEN', style: TextStyle(color: Colors.white, fontSize: 10))
            )),
            const SizedBox(height: 16),
            _buildGridValues([
               _buildGridItem('Maischen', val(batchData['measuredMashPh']), 'pH'),
               _buildGridItem('Kochvolumen', val(batchData['measuredBoilSize']), 'L'),
               
               _buildGridItem('Stammwürze vor Kochen', val(recipe['preBoilGravity']), 'SG'), // Often this is where it comes from
               _buildGridItem('Stammwürze nach dem Kochen', val(batchData['measuredPostBoilGravity']), 'SG'),

               _buildGridItem('Kochkessel Vol', val(batchData['measuredKettleVolume']), 'L'),
               _buildGridItem('Stammwürze', val(batchData['measuredOg']), 'SG'), // Measured OG

               _buildGridItem('Auffüllmenge Gärtank', val(batchData['topUpWater']), 'L'), // Logic check needed
               _buildGridItem('Gärtank Vol', val(batchData['measuredFermenterVolume']), 'L'),

               _buildGridItem('Restextrakt', val(batchData['measuredFg']), 'SG'),
               _buildGridItem('Abfüllmenge', val(batchData['measuredBottlingSize']), 'L'),
               
               _buildGridItem('Temperatur Karbonisierung', val(batchData['carbonationTemp']), '°C'),
               const SizedBox(), // Spacer for grid if needed
            ]),
            const Divider(height: 48, color: Colors.white12),

            // 3. Statistiken
            _buildSectionHeader('Statistiken', icon: Icons.bar_chart),
            const SizedBox(height: 16),
             _buildGridValues([
               _buildGridItem('ALK', val(batchData['measuredAbv']), '%'),
               _buildGridItem('Vergärungsgrad', val(batchData['measuredAttenuation']), '%'),
               
               _buildGridItem('Maische Effizienz', val(batchData['measuredMashEfficiency']), '%'),
               _buildGridItem('Gesamteffizienz', val(batchData['measuredEfficiency']), '%'),
             ]),
             
            const Divider(height: 48, color: Colors.white12),

            // 4. Zusammenfassung Toggle & Table
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(children: [
                   Icon(Icons.list, color: Colors.grey, size: 18),
                   SizedBox(width: 8),
                   Text('Zusammenfassung', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ]),
                Row(
                   children: [
                       Switch(value: true, onChanged: (v){}, activeTrackColor: const Color(0xFF66B342)), // Dummy state
                       const SizedBox(width: 8),
                       OutlinedButton(onPressed: (){}, child: const Text('ANGEPASSTES REZEPT', style: TextStyle(fontSize: 10)))
                   ],
                )
              ],
            ),
            const SizedBox(height: 16),
            _buildCompletedSummaryRow('Messung', 'Rezept', 'Sud', isHeader: true),
            const Divider(color: Colors.white24),
            _buildCompletedSummaryRow('Volumen vor Kochen (Heiß)', val(recipe['boilSize']), val(recipe['boilSize'])), // Simplify mapping
            _buildCompletedSummaryRow('Verdampfung pro Stunde', val(recipe['equipment']?['boilOffPerHr']), val(recipe['equipment']?['boilOffPerHr'])),
            _buildCompletedSummaryRow('Sudgröße', val(recipe['batchSize']), val(recipe['batchSize'])),
            _buildCompletedSummaryRow('Stammwürze vor Kochen', val(recipe['preBoilGravity']), val(recipe['preBoilGravity'])),
            
            const Divider(height: 48, color: Colors.white12),
            
            // 5. Protokoll
            _buildSectionHeader('Protokoll', icon: Icons.edit, action: OutlinedButton(
                onPressed: (){}, 
                style: OutlinedButton.styleFrom(
                   side: const BorderSide(color: Colors.white24),
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                   minimumSize: const Size(0, 28)
                ),
                child: const Text('+ HINZUFÜGEN', style: TextStyle(fontSize: 10, color: Colors.white))
            )),
            const SizedBox(height: 16),
            ...((batchData['notes'] as List? ?? []).map((n) {
                final note = n is Map ? n : {'note': n.toString(), 'timestamp': 0, 'status': ''};
                final dateStr = note['timestamp'] != null ? DateFormat('dd. MMM. yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(note['timestamp'])) : '-';
                String msg = note['note'] ?? '';
                final status = note['status'];
                if (status != null && status.toString().isNotEmpty) {
                    // Logic to hide empty status changes if note is empty, based on screenshot?
                    // Screenshot shows: "20. Nov ... - In Gärung"
                    msg += ' \u2192 $status';
                }
                if (msg.trim().isEmpty && note['type'] == 'statusChanged') return const SizedBox.shrink(); // Skip empty status changes if desired
                
               return Padding(
                 padding: const EdgeInsets.only(bottom: 16.0),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Row(children: [
                         Text('$dateStr ', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                         if (status != null) Text(status == 'Fermenting' ? '\u2192 In Gärung' : (status == 'Brewing' ? '\u2192 Brauen' : status), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ]),
                      const SizedBox(height: 4),
                      Text(note['note'] ?? '', style: const TextStyle(fontSize: 14)),
                   ],
                 ),
               );
            })),

            const Divider(height: 48, color: Colors.white12),

            // 6. Ereignisse
            _buildSectionHeader('Ereignisse', icon: Icons.event, action: Switch(value: true, onChanged: (v){}, activeTrackColor: const Color(0xFF66B342))),
            const SizedBox(height: 8),
            ...((batchData['events'] as List? ?? []).map((e) {
                final dateStr = e['time'] != null ? DateFormat('EEEE, d. MMMM yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(e['time'])) : '-';
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                     border: Border(bottom: BorderSide(color: Colors.white10))
                  ),
                  child: Row(
                    children: [
                       Expanded(child: Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12))),
                       Expanded(child: Text(e['eventText'] ?? e['title'] ?? '', style: const TextStyle(fontSize: 12))),
                       const Icon(Icons.edit, size: 14, color: Colors.grey)
                    ],
                  ), 
                );
            })),
            
            const SizedBox(height: 40),
            // Footer text
            Text("Erstellt ${DateFormat('dd. MMM yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(batchData['_created']['_seconds'] * 1000))} Zuletzt gespeichert ${DateFormat('dd. MMM yyyy HH:mm').format(DateTime.now())}", style: const TextStyle(fontSize: 10, color: Colors.grey))
         ],
       ),
     );
  }

  Widget _buildSectionHeader(String title, {IconData? icon, Widget? action}) {
      return Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          color: const Color(0xFF1E1E1E), // Dark header bg
          child: Row(
              children: [
                  if (icon != null) ...[Icon(icon, size: 16, color: Colors.grey), const SizedBox(width: 8)],
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const Spacer(),
                  if (action != null) action
              ],
          ),
      );
  }

  Widget _buildGridValues(List<Widget> items) {
      // Simple custom grid
      return LayoutBuilder(builder: (ctx, constr) {
          int cols = constr.maxWidth > 600 ? 2 : 1;
          return Wrap(
              spacing: 32,
              runSpacing: 16,
              children: items.map((i) => SizedBox(width: (constr.maxWidth - (cols-1)*32) / cols, child: i)).toList(),
          );
      });
  }

  Widget _buildGridItem(String label, String value, String unit) {
      return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0), // Align baseline
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                      Text(unit, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
                  ],
                ),
              )
          ],
      );
  }
  
  Widget _buildCompletedSummaryRow(String col1, String col2, String col3, {bool isHeader = false}) {
      final style = TextStyle(fontSize: 12, color: isHeader ? Colors.white : Colors.grey[400], fontWeight: isHeader ? FontWeight.bold : FontWeight.normal);
      final valStyle = TextStyle(fontSize: 12, color: isHeader ? Colors.white : Colors.green[300], fontWeight: isHeader ? FontWeight.normal : FontWeight.bold); // Highlight Sud values
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Expanded(flex: 4, child: Text(col1, style: isHeader ? style : const TextStyle(fontSize: 12, color: Colors.white))),
            Expanded(flex: 1, child: Text(col2, textAlign: TextAlign.right, style: isHeader ? style : const TextStyle(fontSize: 12, color: Colors.white))),
            Expanded(flex: 1, child: Text(col3, textAlign: TextAlign.right, style: valStyle)),
          ],
        ),
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
            title: Text('$key: {}', style: const TextStyle(fontFamily: 'monospace')),
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
            title: Text('$key: []', style: const TextStyle(fontFamily: 'monospace')),
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
            SelectableText('$key: ', style: const TextStyle(color: Colors.grey)),
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

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    var max = size.width;
    var dashWidth = 3;
    var dashSpace = 3;
    double startX = 0;
    while (startX < max) {
      canvas.drawLine(Offset(startX, size.height / 2), Offset(startX + dashWidth, size.height / 2), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
