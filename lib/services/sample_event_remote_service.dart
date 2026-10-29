
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sample_event.dart';

class SampleEventRemoteService {
  SampleEventRemoteService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection('sample_events');

  Future<List<SampleEvent>> getEvents() async {
    final snapshot = await _events.get(const GetOptions(source: Source.server),);

    return snapshot.docs.map((doc) {
      final data = doc.data();

      final createdAt = data['createdAt'];

      return SampleEvent(
        id: (data['id'] ?? doc.id) as String,
        sampleId: data['sampleId'] as String,
        type: data['type'] as String,
        createdAt: createdAt is Timestamp
            ? createdAt.toDate()
            : DateTime.parse(createdAt as String),
      );
    }).toList();
  }

  Future<void> saveEvent(SampleEvent event) async {
    await _events.doc(event.id).set({
      'id': event.id,
      'sampleId': event.sampleId,
      'type': event.type,
      'createdAt': Timestamp.fromDate(event.createdAt),
    });
  }
}
