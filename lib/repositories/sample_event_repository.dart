
import '../database/app_database.dart' hide SampleEvent;
import '../models/sample_event.dart';
import '../services/sample_event_remote_service.dart';

class SampleEventRepository {
  SampleEventRepository({
    required AppDatabase database,
    required SampleEventRemoteService remoteService,
  })  : _database = database,
        _remoteService = remoteService;

  final AppDatabase _database;
  final SampleEventRemoteService _remoteService;

  static const List<String> _states = [
    'RECEIVED',
    'PREPARED',
    'IN_ANALYSIS',
    'VALIDATED',
    'ARCHIVED',
  ];

  Future<List<SampleEvent>> getEventsForSample(
    String sampleId,
  ) async {
    List<SampleEvent> remoteEvents;

    try {
      remoteEvents = await _remoteService.getEvents();
    } catch (_) {
      final localEvents = await _database.getEventsForSample(sampleId);
      localEvents.sort(
        (a, b) => a.createdAt.compareTo(b.createdAt),
      );
      return localEvents;
    }

    // Si la lectura remota funcionó, actualizar la copia local.
    await _database.saveEvents(remoteEvents);

    final events = remoteEvents
        .where((event) => event.sampleId == sampleId)
        .toList();

    events.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return events;
  }

  Future<void> registerEvent(SampleEvent event) async {
    // Leer el historial remoto antes de validar el siguiente estado.
    // Si falla la lectura, no confirmar el registro.
    final remoteEvents = await _remoteService.getEvents();

    await _database.saveEvents(remoteEvents);

    final history = remoteEvents
        .where((item) => item.sampleId == event.sampleId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final nextState = event.type.toUpperCase();

    if (!_states.contains(nextState)) {
      throw ArgumentError('Estado no válido: ${event.type}');
    }

    if (history.isEmpty) {
      if (nextState != 'RECEIVED') {
        throw StateError(
          'El primer estado debe ser RECEIVED.',
        );
      }
    } else {
      final currentState = history.last.type.toUpperCase();
      final currentIndex = _states.indexOf(currentState);

      if (currentIndex < 0 ||
          currentIndex + 1 >= _states.length ||
          _states[currentIndex + 1] != nextState) {
        throw StateError(
          'Transición no válida: $currentState → $nextState.',
        );
      }
    }

    // Orden obligatorio: primero remoto, después local.
    await _remoteService.saveEvent(event);
    await _database.saveEvent(event);
  }
}
