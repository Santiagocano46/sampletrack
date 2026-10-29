
import '../database/app_database.dart';
import '../models/sample_event.dart';
import '../services/sample_event_remote_service.dart';
import '../services/sample_logic.dart';

class EventLoadResult {
  const EventLoadResult({
    required this.events,
    required this.isLocal,
  });

  final List<SampleEvent> events;
  final bool isLocal;
}

class SampleEventRepository {
  SampleEventRepository({
    required AppDatabase database,
    required SampleEventRemoteService remoteService,
  })  : _database = database,
        _remoteService = remoteService;

  final AppDatabase _database;
  final SampleEventRemoteService _remoteService;

  Future<EventLoadResult> loadEventsForSample(
    String sampleId,
  ) async {
    try {
      final remoteEvents = await _remoteService.getEvents();

      await _database.saveEvents(remoteEvents);

      final events = remoteEvents
          .where((event) => event.sampleId == sampleId)
          .toList();

      return EventLoadResult(
        events: SampleLogic.sortEvents(events),
        isLocal: false,
      );
    } catch (_) {
      final localEvents =
          await _database.getEventsForSample(sampleId);

      return EventLoadResult(
        events: SampleLogic.sortEvents(localEvents),
        isLocal: true,
      );
    }
  }

  Future<List<SampleEvent>> getEventsForSample(
    String sampleId,
  ) async {
    final result = await loadEventsForSample(sampleId);
    return result.events;
  }

  Future<void> registerEvent(SampleEvent event) async {
    final remoteEvents = await _remoteService.getEvents();

    final history = remoteEvents
        .where((item) => item.sampleId == event.sampleId)
        .toList();

    if (!SampleLogic.isValidTransition(
      history,
      event.type,
    )) {
      throw StateError(
        'Transición inválida hacia ${event.type}.',
      );
    }

    await _remoteService.saveEvent(event);

    await _database.saveEvent(event);
  }
}
