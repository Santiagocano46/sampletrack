
import '../models/sample_event.dart';

class SampleLogic {
  static const List<String> states = [
    'RECEIVED',
    'PREPARED',
    'IN_ANALYSIS',
    'VALIDATED',
    'ARCHIVED',
  ];

  static List<SampleEvent> sortEvents(
    List<SampleEvent> events,
  ) {
    final sorted = [...events];

    sorted.sort((a, b) {
      final result = b.createdAt.compareTo(a.createdAt);
      return result != 0 ? result : b.id.compareTo(a.id);
    });

    return sorted;
  }

  static String getCurrentState(
    List<SampleEvent> events,
  ) {
    if (events.isEmpty) {
      return 'Sin eventos';
    }

    return sortEvents(events).first.type;
  }

  static String? getNextState(
    List<SampleEvent> events,
  ) {
    if (events.isEmpty) {
      return 'RECEIVED';
    }

    final current = getCurrentState(events);
    final index = states.indexOf(current);

    if (index == -1 || index == states.length - 1) {
      return null;
    }

    return states[index + 1];
  }

  static bool isValidTransition(
    List<SampleEvent> events,
    String newState,
  ) {
    return getNextState(events) == newState;
  }

  static int getMaxMinutes(String priority) {
    switch (priority.trim().toLowerCase()) {
      case 'urgente':
        return 15;
      case 'alta':
        return 30;
      case 'normal':
        return 45;
      default:
        return 0;
    }
  }

  static bool isDelayed({
    required List<SampleEvent> events,
    required String priority,
    DateTime? now,
  }) {
    if (events.isEmpty) {
      return false;
    }

    final latest = sortEvents(events).first;

    if (latest.type == 'ARCHIVED') {
      return false;
    }

    final maxMinutes = getMaxMinutes(priority);

    if (maxMinutes == 0) {
      return false;
    }

    final elapsed =
        (now ?? DateTime.now()).difference(latest.createdAt);

    return elapsed > Duration(minutes: maxMinutes);
  }
}
