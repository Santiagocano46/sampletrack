
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sample_track_shell/data/sample_seed.dart';
import 'package:sample_track_shell/widgets/sample_card.dart';

void main() {
  testWidgets(
    'La tarjeta muestra los datos de la muestra',
    (WidgetTester tester) async {
      final sample = sampleSeed.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SampleCard(
              sample: sample,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text(sample.id), findsOneWidget);
      expect(find.text(sample.type), findsOneWidget);
      expect(find.text(sample.priority), findsOneWidget);
      expect(find.text('Sin eventos'), findsOneWidget);
    },
  );
}
