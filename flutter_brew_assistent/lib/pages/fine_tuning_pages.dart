import 'package:flutter/material.dart';
import '../models/fine_tuning_profile.dart';
import '../models/beer_presets.dart';
import '../widgets/user_name_banner.dart';
import '../widgets/fine_tuning_widgets.dart';
import 'recipe_summary_page.dart';

class FineTuningGeneralPage extends StatefulWidget {
  const FineTuningGeneralPage({
    super.key,
    required this.beerName,
    required this.beerType,
  });

  final String beerName;
  final String beerType;

  @override
  State<FineTuningGeneralPage> createState() => _FineTuningGeneralPageState();
}

class _FineTuningGeneralPageState extends State<FineTuningGeneralPage> {
  late final FineTuningProfile profile;

  @override
  void initState() {
    super.initState();
    profile =
        FineTuningProfile(beerName: widget.beerName, beerType: widget.beerType);
    final preset = beerPresets[widget.beerName];
    if (preset != null) {
      profile.applyPreset(preset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feintuning Generell'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/icon_small.png',
              height: 40,
              filterQuality: FilterQuality.none,
              semanticLabel: 'AiBrewGenius',
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const UserNameBanner(),
              const SizedBox(height: 20),
              Text(
                'Erste Anpassungen für ${profile.beerName}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Hopfen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              IndentedBlock(
                child: Column(
                  children: [
                    SliderBlock(
                      label: 'Aromaintensität',
                      minLabel: 'wenig',
                      maxLabel: 'stark',
                      value: profile.hopIntensity,
                      baselineKey: 'hopIntensity',
                    ),
                    FineSlider(
                      value: profile.hopIntensity,
                      onChanged: (v) =>
                          setState(() => profile.hopIntensity = v),
                      baselineKey: 'hopIntensity',
                    ),
                    const SizedBox(height: 12),
                    SliderBlock(
                      label: 'Kräuterig',
                      minLabel: 'wenig',
                      maxLabel: 'stark',
                      value: profile.hopHerbal,
                      baselineKey: 'hopHerbal',
                    ),
                    FineSlider(
                      value: profile.hopHerbal,
                      onChanged: (v) => setState(() => profile.hopHerbal = v),
                      baselineKey: 'hopHerbal',
                    ),
                    const SizedBox(height: 12),
                    SliderBlock(
                      label: 'Blumig',
                      minLabel: 'wenig',
                      maxLabel: 'stark',
                      value: profile.hopFloral,
                      baselineKey: 'hopFloral',
                    ),
                    FineSlider(
                      value: profile.hopFloral,
                      onChanged: (v) => setState(() => profile.hopFloral = v),
                      baselineKey: 'hopFloral',
                    ),
                    const SizedBox(height: 12),
                    SliderBlock(
                      label: 'Fruchtig',
                      minLabel: 'wenig',
                      maxLabel: 'stark',
                      value: profile.hopFruity,
                      baselineKey: 'hopFruity',
                    ),
                    FineSlider(
                      value: profile.hopFruity,
                      onChanged: (v) => setState(() => profile.hopFruity = v),
                      baselineKey: 'hopFruity',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Verteilung',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              IndentedBlock(
                child: Column(
                  children: [
                    SliderBlock(
                      label: 'Nase',
                      minLabel: 'wenig',
                      maxLabel: 'stark',
                      value: profile.hopNose,
                      baselineKey: 'hopNose',
                    ),
                    FineSlider(
                      value: profile.hopNose,
                      onChanged: (v) => setState(() => profile.hopNose = v),
                      baselineKey: 'hopNose',
                    ),
                    const SizedBox(height: 12),
                    SliderBlock(
                      label: 'Gaumen',
                      minLabel: 'wenig',
                      maxLabel: 'stark',
                      value: profile.hopPalate,
                      baselineKey: 'hopPalate',
                    ),
                    FineSlider(
                      value: profile.hopPalate,
                      onChanged: (v) => setState(() => profile.hopPalate = v),
                      baselineKey: 'hopPalate',
                    ),
                    const SizedBox(height: 12),
                    SliderBlock(
                      label: 'Abgang',
                      minLabel: 'wenig',
                      maxLabel: 'stark',
                      value: profile.hopFinish,
                      baselineKey: 'hopFinish',
                    ),
                    FineSlider(
                      value: profile.hopFinish,
                      onChanged: (v) => setState(() => profile.hopFinish = v),
                      baselineKey: 'hopFinish',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => FineTuningPage(profile: profile),
                      ),
                    );
                  },
                  child: const Text('Weiter zu Feintuning Antrunk'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class FineTuningPage extends StatefulWidget {
  const FineTuningPage({super.key, required this.profile});

  final FineTuningProfile profile;

  @override
  State<FineTuningPage> createState() => _FineTuningPageState();
}

class _FineTuningPageState extends State<FineTuningPage> {
  FineTuningProfile get profile => widget.profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feintuning Antrunk'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/icon_small.png',
              height: 40,
              filterQuality: FilterQuality.none,
              semanticLabel: 'AiBrewGenius',
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: UserNameBanner(),
            ),
            const SizedBox(height: 20),
            Text(
              'Lass uns ein neues leckeres und einzigartiges ${profile.beerName} Bier entwerfen',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SliderBlock(
              label: 'Mundgefühl',
              minLabel: 'Wasser',
              maxLabel: 'Motorenöl',
              value: profile.mouthfeel,
              baselineKey: 'mouthfeel',
            ),
            FineSlider(
              value: profile.mouthfeel,
              onChanged: (v) => setState(() => profile.mouthfeel = v),
              baselineKey: 'mouthfeel',
            ),
            const SizedBox(height: 12),
            SliderBlock(
              label: 'Malzaroma',
              minLabel: 'leicht',
              maxLabel: 'kräftig',
              value: profile.antrunkMalt,
              baselineKey: 'antrunkMalt',
            ),
            FineSlider(
              value: profile.antrunkMalt,
              onChanged: (v) => setState(() => profile.antrunkMalt = v),
              baselineKey: 'antrunkMalt',
            ),
            const SizedBox(height: 12),
            SliderBlock(
              label: 'Röstmalzaroma',
              minLabel: 'leicht',
              maxLabel: 'kräftig',
              value: profile.antrunkRoast,
              baselineKey: 'antrunkRoast',
            ),
            FineSlider(
              value: profile.antrunkRoast,
              onChanged: (v) => setState(() => profile.antrunkRoast = v),
              baselineKey: 'antrunkRoast',
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FineTuningMainTrunkPage(profile: profile),
                    ),
                  );
                },
                child: const Text('Weiter zu Feintuning Haupttrunk'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class FineTuningMainTrunkPage extends StatefulWidget {
  const FineTuningMainTrunkPage({super.key, required this.profile});

  final FineTuningProfile profile;

  @override
  State<FineTuningMainTrunkPage> createState() =>
      _FineTuningMainTrunkPageState();
}

class _FineTuningMainTrunkPageState extends State<FineTuningMainTrunkPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feintuning Haupttrunk'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/icon_small.png',
              height: 40,
              filterQuality: FilterQuality.none,
              semanticLabel: 'AiBrewGenius',
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const UserNameBanner(),
                const SizedBox(height: 20),
                Text(
                  'Feintuning für ${widget.profile.beerName} · Haupttrunk',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                SliderBlock(
                  label: 'süffig',
                  minLabel: 'leicht',
                  maxLabel: 'kräftig',
                  value: widget.profile.smooth,
                  baselineKey: 'smooth',
                ),
                FineSlider(
                  value: widget.profile.smooth,
                  onChanged: (v) => setState(() => widget.profile.smooth = v),
                  baselineKey: 'smooth',
                ),
                const SizedBox(height: 12),
                SliderBlock(
                  label: 'vollmundig',
                  minLabel: 'leicht',
                  maxLabel: 'kräftig',
                  value: widget.profile.fullBody,
                  baselineKey: 'fullBody',
                ),
                FineSlider(
                  value: widget.profile.fullBody,
                  onChanged: (v) => setState(() => widget.profile.fullBody = v),
                  baselineKey: 'fullBody',
                ),
                const SizedBox(height: 12),
                SliderBlock(
                  label: 'Malzaroma',
                  minLabel: 'leicht',
                  maxLabel: 'kräftig',
                  value: widget.profile.mainMalt,
                  baselineKey: 'mainMalt',
                ),
                FineSlider(
                  value: widget.profile.mainMalt,
                  onChanged: (v) => setState(() => widget.profile.mainMalt = v),
                  baselineKey: 'mainMalt',
                ),
                const SizedBox(height: 12),
                SliderBlock(
                  label: 'Röstaroma',
                  minLabel: 'leicht',
                  maxLabel: 'kräftig',
                  value: widget.profile.mainRoast,
                  baselineKey: 'mainRoast',
                ),
                FineSlider(
                  value: widget.profile.mainRoast,
                  onChanged: (v) =>
                      setState(() => widget.profile.mainRoast = v),
                  baselineKey: 'mainRoast',
                ),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              FineTuningAftertastePage(profile: widget.profile),
                        ),
                      );
                    },
                    child: const Text('Weiter zu Feintuning Nachtrunk'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FineTuningAftertastePage extends StatefulWidget {
  const FineTuningAftertastePage({super.key, required this.profile});

  final FineTuningProfile profile;

  @override
  State<FineTuningAftertastePage> createState() =>
      _FineTuningAftertastePageState();
}

class _FineTuningAftertastePageState extends State<FineTuningAftertastePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feintuning Nachtrunk'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/icon_small.png',
              height: 40,
              filterQuality: FilterQuality.none,
              semanticLabel: 'AiBrewGenius',
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const UserNameBanner(),
                const SizedBox(height: 20),
                Text(
                  'Feintuning für ${widget.profile.beerName} · Nachtrunk',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                SliderBlock(
                  label: 'abklingen',
                  minLabel: 'leicht',
                  maxLabel: 'kräftig',
                  value: widget.profile.fade,
                  baselineKey: 'fade',
                ),
                FineSlider(
                  value: widget.profile.fade,
                  onChanged: (v) => setState(() => widget.profile.fade = v),
                  baselineKey: 'fade',
                ),
                const SizedBox(height: 12),
                SliderBlock(
                  label: 'erfrischend',
                  minLabel: 'leicht',
                  maxLabel: 'kräftig',
                  value: widget.profile.fresh,
                  baselineKey: 'fresh',
                ),
                FineSlider(
                  value: widget.profile.fresh,
                  onChanged: (v) => setState(() => widget.profile.fresh = v),
                  baselineKey: 'fresh',
                ),
                const SizedBox(height: 12),
                SliderBlock(
                  label: 'trocken',
                  minLabel: 'leicht',
                  maxLabel: 'kräftig',
                  value: widget.profile.dry,
                  baselineKey: 'dry',
                ),
                FineSlider(
                  value: widget.profile.dry,
                  onChanged: (v) => setState(() => widget.profile.dry = v),
                  baselineKey: 'dry',
                ),
                const SizedBox(height: 12),
                SliderBlock(
                  label: 'langanhaltend',
                  minLabel: 'leicht',
                  maxLabel: 'kräftig',
                  value: widget.profile.lasting,
                  baselineKey: 'lasting',
                ),
                FineSlider(
                  value: widget.profile.lasting,
                  onChanged: (v) => setState(() => widget.profile.lasting = v),
                  baselineKey: 'lasting',
                ),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SpecialAdditionsPage(
                            profile: widget.profile,
                          ),
                        ),
                      );
                    },
                    child: const Text('Spezielle Zugaben festlegen'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SpecialAdditionsPage extends StatefulWidget {
  const SpecialAdditionsPage({super.key, required this.profile});

  final FineTuningProfile profile;

  @override
  State<SpecialAdditionsPage> createState() => _SpecialAdditionsPageState();
}

class _SpecialAdditionsPageState extends State<SpecialAdditionsPage> {
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController storageCtrl = TextEditingController();
  double focusValue = 0.5;
  double intensityValue = 0.5;
  String? titleError;
  String? storageError;

  @override
  void dispose() {
    titleCtrl.dispose();
    storageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spezielle Zugaben'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/icon_small.png',
              height: 40,
              filterQuality: FilterQuality.none,
              semanticLabel: 'AiBrewGenius',
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const UserNameBanner(),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  Text(
                    'Füge deinem Bier besondere Schritte wie Barrel Aging, Holzchips oder Speziallagerungen hinzu.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bisherige Zugaben',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (widget.profile.specialAdditions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Text(
                        'Noch keine speziellen Zugaben definiert.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  else
                    Column(
                      children: [
                        ...widget.profile.specialAdditions.asMap().entries.map(
                          (entry) {
                            final addition = entry.value;
                            final antrunkPercent =
                                ((1 - addition.focus) * 100).round();
                            final abgangPercent = 100 - antrunkPercent;
                            final intensityPercent =
                                (addition.intensity * 100).round();
                            return Card(
                              color: const Color(0xFF0F172A),
                              child: ListTile(
                                title: Text(addition.title),
                                subtitle: Text(
                                  'Antrunk $antrunkPercent% · Abgang $abgangPercent% · Intensität $intensityPercent%',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => removeAddition(entry.key),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Neue Zugabe hinzufügen',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Bezeichnung',
                      hintText: 'z. B. Rumfass Lagerung',
                      errorText: titleError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FocusSlider(
                    value: focusValue,
                    onChanged: (v) => setState(() => focusValue = v),
                  ),
                  const SizedBox(height: 12),
                  IntensitySlider(
                    value: intensityValue,
                    onChanged: (v) => setState(() => intensityValue = v),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: addAddition,
                      icon: const Icon(Icons.add),
                      label: const Text('Hinzufügen'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(
                    height: 32,
                    thickness: 1,
                    color: Colors.white24,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Spezielle Lagerung',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (widget.profile.specialStorage.isEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Text(
                        'Noch keine Lagerungsarten definiert.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  else
                    Column(
                      children: [
                        ...widget.profile.specialStorage.asMap().entries.map(
                              (entry) => Card(
                                color: const Color(0xFF0F172A),
                                child: ListTile(
                                  title: Text(entry.value),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => removeStorage(entry.key),
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
                  TextField(
                    controller: storageCtrl,
                    decoration: InputDecoration(
                      labelText: 'z. B. Barrel Aged',
                      errorText: storageError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: addStorage,
                      icon: const Icon(Icons.add),
                      label: const Text('Lagerung hinzufügen'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: goToSummary,
                  child: const Text('Überspringen'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: goToSummary,
                  child: const Text('Weiter zum Rezept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void addAddition() {
    final title = titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => titleError = 'Bezeichnung erforderlich');
      return;
    }
    setState(() {
      titleError = null;
      widget.profile.specialAdditions.add(
        SpecialAddition(
          title: title,
          focus: focusValue,
          intensity: intensityValue,
        ),
      );
      titleCtrl.clear();
      focusValue = 0.5;
      intensityValue = 0.5;
    });
  }

  void removeAddition(int index) {
    setState(() {
      widget.profile.specialAdditions.removeAt(index);
    });
  }

  void addStorage() {
    final entry = storageCtrl.text.trim();
    if (entry.isEmpty) {
      setState(() => storageError = 'Bitte eine Lagerung eingeben');
      return;
    }
    setState(() {
      storageError = null;
      widget.profile.specialStorage.add(entry);
      storageCtrl.clear();
    });
  }

  void removeStorage(int index) {
    setState(() {
      widget.profile.specialStorage.removeAt(index);
    });
  }

  void goToSummary() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeSummaryPage(profile: widget.profile),
      ),
    );
  }
}
