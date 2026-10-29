
import 'dart:async';

import 'package:flutter/material.dart';

import '../data/sample_seed.dart';
import '../models/sample.dart';
import '../models/sample_event.dart';
import '../repositories/sample_event_repository.dart';
import '../widgets/sample_card.dart';
import 'sample_detail_page.dart';

class SampleListPage extends StatefulWidget {
  const SampleListPage({
    super.key,
    required this.repository,
  });

  final SampleEventRepository repository;

  @override
  State<SampleListPage> createState() =>
      _SampleListPageState();
}

class _SampleListPageState extends State<SampleListPage> {
  final Map<String, List<SampleEvent>> eventsBySample = {};

  Timer? delayTimer;
  DateTime currentTime = DateTime.now();

  bool loading = true;
  bool usingLocalData = false;
  String? error;

  @override
  void initState() {
    super.initState();

    loadSamples();

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

  Future<void> loadSamples() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final results = await Future.wait(
        sampleSeed.map(
          (sample) => widget.repository
              .loadEventsForSample(sample.id),
        ),
      );

      if (!mounted) return;

      final loaded = <String, List<SampleEvent>>{};

      for (int i = 0; i < sampleSeed.length; i++) {
        loaded[sampleSeed[i].id] = results[i].events;
      }

      setState(() {
        eventsBySample
          ..clear()
          ..addAll(loaded);

        usingLocalData =
            results.any((result) => result.isLocal);

        currentTime = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Error al cargar muestras: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> openDetail(Sample sample) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SampleDetailPage(
          sample: sample,
          repository: widget.repository,
        ),
      ),
    );

    if (!mounted) return;

    await loadSamples();
  }

  @override
  void dispose() {
    delayTimer?.cancel();
    super.dispose();
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
        actions: [
          IconButton(
            tooltip: 'Actualizar eventos',
            onPressed: loading ? null : loadSamples,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error!),
                      TextButton(
                        onPressed: loadSamples,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (usingLocalData)
                      const MaterialBanner(
                        content: Text(
                          'Sin conexión remota. '
                          'Mostrando datos locales de Drift.',
                        ),
                        leading: Icon(Icons.wifi_off),
                        actions: [
                          SizedBox.shrink(),
                        ],
                      ),

                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: loadSamples,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: sampleSeed.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final sample = sampleSeed[index];

                            final events =
                                eventsBySample[sample.id] ??
                                <SampleEvent>[];

                            return SampleCard(
                              sample: sample,
                              events: events,
                              currentTime: currentTime,
                              onTap: () => openDetail(sample),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
