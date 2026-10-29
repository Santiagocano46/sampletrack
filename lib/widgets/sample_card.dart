
import 'dart:async';

import 'package:flutter/material.dart';

import '../data/sample_seed.dart';
import '../models/sample.dart';
import '../models/sample_event.dart';
import '../widgets/sample_card.dart';
import 'sample_detail_page.dart';

class SampleListPage extends StatefulWidget {
  const SampleListPage({super.key});

  @override
  State<SampleListPage> createState() => _SampleListPageState();
}

class _SampleListPageState extends State<SampleListPage> {
  final Map<String, List<SampleEvent>> eventsBySample = {};

  Timer? delayTimer;
  DateTime currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();

    delayTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) {
        if (!mounted) return;

        setState(() {
          currentTime = DateTime.now();
        });
      },
    );
  }

  @override
  void dispose() {
    delayTimer?.cancel();
    super.dispose();
  }

  Future<void> _openDetail(Sample sample) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SampleDetailPage(sample: sample),
      ),
    );

    if (!mounted) return;

    setState(() {
      currentTime = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.biotech_outlined),
            SizedBox(width: 10),
            Text('SampleTrack'),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sampleSeed.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final sample = sampleSeed[index];

            final events =
                eventsBySample[sample.id] ?? <SampleEvent>[];

            return SampleCard(
              sample: sample,
              events: events,
              currentTime: currentTime,
              onTap: () => _openDetail(sample),
            );
          },
        ),
      ),
    );
  }
}
