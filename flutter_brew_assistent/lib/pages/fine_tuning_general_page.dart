import 'package:flutter/material.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.beerName} (${widget.beerType})')),
      body: const Center(
        child: Text('Fine Tuning Page (Stub) - See main.dart for original'),
      ),
    );
  }
}
