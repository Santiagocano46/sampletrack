
import 'package:flutter/material.dart';

import '../models/sample.dart';
import '../models/sample_event.dart';
import '../repositories/sample_event_repository.dart';
import '../services/sample_logic.dart';
import '../widgets/delay_indicator.dart';

class SampleDetailPage extends StatefulWidget {
  const SampleDetailPage({
    super.key,
    required this.sample,
    required this.repository,
  });

  final Sample sample;
  final SampleEventRepository repository;

  @override
  State<SampleDetailPage> createState() =>
      _SampleDetailPageState();
}

class _SampleDetailPageState extends State<SampleDetailPage> {
  List<SampleEvent> events = [];

  bool loading = true;
  bool saving = false;
  bool isLocal = false;
  String? error;

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await widget.repository
          .loadEventsForSample(widget.sample.id);

      if (!mounted) return;

      setState(() {
        events = SampleLogic.sortEvents(result.events);
        isLocal = result.isLocal;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'No se pudo cargar el historial: $e';
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> registerNextEvent() async {
    if (saving || isLocal || loading) return;

    final next = SampleLogic.getNextState(events);

    if (next == null) return;

    setState(() => saving = true);

    try {
      final event = SampleEvent(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        sampleId: widget.sample.id,
        type: next,
        createdAt: DateTime.now().toUtc(),
      );

      // Primero Firestore y después Drift.
      // El repositorio valida la transición.
      await widget.repository.registerEvent(event);

      if (!mounted) return;

      await loadEvents();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Evento registrado correctamente',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo registrar el evento: $e'),
        ),
      );

      await loadEvents();
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = SampleLogic.getCurrentState(events);
    final next = SampleLogic.getNextState(events);

    final delayed = SampleLogic.isDelayed(
      events: events,
      priority: widget.sample.priority,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sample.id),
        actions: [
          IconButton(
            onPressed: saving || loading ? null : loadEvents,
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
                        onPressed: loadEvents,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.sample.id,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge,
                            ),
                            const SizedBox(height: 12),
                            Text('Tipo: ${widget.sample.type}'),
                            Text(
                              'Origen: ${widget.sample.origin}',
                            ),
                            Text(
                              'Prioridad: '
                              '${widget.sample.priority}',
                            ),
                            const SizedBox(height: 12),
                            Chip(label: Text(state)),
                            if (delayed) ...[
                              const SizedBox(height: 8),
                              const DelayIndicator(),
                            ],
                          ],
                        ),
                      ),
                    ),

                    if (isLocal)
                      const Card(
                        color: Color(0xFFFFF3CD),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Estás consultando datos '
                            'guardados localmente en Drift.',
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    Text(
                      'Historial de procesamiento',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge,
                    ),

                    const SizedBox(height: 12),

                    if (events.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text('Esta muestra no tiene eventos.',
                            ),
                          ),
                        ),
                      ),

                    ...events.map(
                      (event) => Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.history,
                          ),
                          title: Text(event.type),
                          subtitle: Text(
                            event.createdAt
                                .toLocal()
                                .toString(),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    FilledButton.icon(
                      onPressed: saving ||
                              isLocal ||
                              next == null
                          ? null
                          : registerNextEvent,
                      icon: const Icon(Icons.add),
                      label: Text(
                        saving
                            ? 'Guardando...'
                            : next == null
                                ? 'Procesamiento finalizado'
                                : 'Registrar $next',
                      ),
                    ),
                  ],
                ),
    );
  }
}
