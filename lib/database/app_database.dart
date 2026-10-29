
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/sample_event.dart' as model;

part 'app_database.g.dart';

class SampleEvents extends Table {
  TextColumn get id => text()();

  TextColumn get sampleId => text()();

  TextColumn get type => text()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [SampleEvents])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<List<model.SampleEvent>> getAllEvents() async {
    final rows = await select(sampleEvents).get();

    return rows.map((row) {
      return model.SampleEvent(
        id: row.id,
        sampleId: row.sampleId,
        type: row.type,
        createdAt: row.createdAt,
      );
    }).toList();
  }

  Future<List<model.SampleEvent>> getEventsForSample(
    String sampleId,
  ) async {
    final rows = await (select(sampleEvents)
          ..where((table) => table.sampleId.equals(sampleId)))
        .get();

    return rows.map((row) {
      return model.SampleEvent(
        id: row.id,
        sampleId: row.sampleId,
        type: row.type,
        createdAt: row.createdAt,
      );
    }).toList();
  }

  Future<void> saveEvent(model.SampleEvent event) async {
    await into(sampleEvents).insertOnConflictUpdate(
      SampleEventsCompanion.insert(
        id: event.id,
        sampleId: event.sampleId,
        type: event.type,
        createdAt: event.createdAt,
      ),
    );
  }

  Future<void> saveEvents(
    List<model.SampleEvent> events,
  ) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        sampleEvents,
        events.map(
          (event) => SampleEventsCompanion.insert(
            id: event.id,
            sampleId: event.sampleId,
            type: event.type,
            createdAt: event.createdAt,
          ),
        ).toList(),
      );
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();

    final file = File(
      p.join(directory.path, 'sample_track.sqlite'),
    );

    return NativeDatabase.createInBackground(file);
  });
}
